//
//  ServerController.m
//
//  Created by Daniel Anderton on 20/12/2012.
//  Copyright (c) 2012 Daniel Anderton. All rights reserved.
//

#import "ServerController.h"
#import "APIRequest.h"
#import "RMVAppDelegate.h"
#import "DAReachability.h"
#import <sys/utsname.h>
#import "SyncController.h"
#import "SyncObject.h"
#import "RMVMapController.h"
#define kBaseURL @"http://ratemyview.co.uk"


NSString* const kLastUpdatedNotificationKey = @"kLastUpdatedNotificationKey";
NSString* const kLastUpdatedFollowerKey = @"kLastUpdatedFollowerKey";
NSString* const kLastUpdatedStatsKey= @"kLastUpdatedStatsKey";
@interface ServerController()

@property(nonatomic,strong) NSMutableData* responseData;
@property(nonatomic,strong) NSURLConnection* connection;
@property(nonatomic,getter = isFetching) BOOL fetching;
@property(nonatomic,strong) NSMutableArray* cachedRequests;
@property(nonatomic,strong) APIRequest* currentRequest;
@property(nonatomic,strong) DAReachability* reachability;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@end

@implementation ServerController


+ (id)sharedController
{
    static dispatch_once_t once;
    static ServerController *sharedController;
    dispatch_once(&once, ^ { sharedController = [[self alloc] init]; });
    return sharedController;
}

-(id)init{
    if(!(self = [super init])){
        return nil;
    }
  
    self.cachedRequests = [NSMutableArray array];
    self.reachability = [DAReachability reachabilityWithHostname:@"ratemyview.co.uk"];
    
    __weak __block id blockSelf = self;
    [self cleanupConnection];
    // set the blocks for reachabilty 
    self.reachability.reachableBlock = ^(DAReachability*reach)
    {
        [blockSelf performSelectorOnMainThread:@selector(checkQueue) withObject:nil waitUntilDone:NO];
        [blockSelf performSelectorOnMainThread:@selector(presentInternetConnection) withObject:nil waitUntilDone:NO];
    };
    
    self.reachability.unreachableBlock = ^(DAReachability*reach)
    {
        [blockSelf performSelectorOnMainThread:@selector(cleanupConnection) withObject:nil waitUntilDone:NO];
        [NSObject cancelPreviousPerformRequestsWithTarget:blockSelf selector:@selector(sendUnlogged) object:nil];
        [blockSelf performSelectorOnMainThread:@selector(presentNoInternetConnection) withObject:nil waitUntilDone:NO];
    };
    
    // start the notifier which will cause the reachability object to retain itself!
    [self.reachability startNotifier];

    return self;
}

-(void)presentNoInternetConnection{
    [[RMVMapController sharedController] networkDown];
}

-(void)presentInternetConnection{
    [[RMVMapController sharedController] networkUp];
}

#pragma mark News Articles

- (void)fetchBoundingAreasWithCompletion:(void(^)(NSError* error, id jsonResponse))completion{
    
   
    NSMutableURLRequest* apiRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ratemyview.co.uk/areas/"]]];
    [apiRequest setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    APIRequest* newRequest = [[APIRequest alloc] initWithRequest:apiRequest requestType:kReturnResult completion:completion];

    [self cleanupConnection];
    //we are creating an account. remove the queue as we shouldnt be logging anyhow.
    self.currentRequest = nil;
    [self cleanupConnection];
    //this request we want done next
    [self.cachedRequests insertObject:newRequest atIndex:0];
    [self checkQueue];
}

- (void)fetchViewsFromArea:(NSArray*)points withCompletion:(void(^)(NSError* error, id jsonResponse))completion{
    
    NSString* baseUrl = [NSString stringWithFormat:@"%@/views/",kBaseURL];
    
    NSMutableDictionary* mutable = [NSMutableDictionary dictionary];
    
    
    if([points count])
    {
        NSError* error = nil;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:points options:NSJSONWritingPrettyPrinted error:&error];
        
        if(jsonData && !error)
        {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            if([jsonString length])
                
            {
                jsonString = [jsonString stringByReplacingOccurrencesOfString:@" " withString:@""];
                jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                [mutable setObject:jsonString forKey:@"withinarea"];
            }
        }
    }
    
    
    NSString* body = @"";

    for (NSString *key in mutable) {
        NSString *val = [mutable objectForKey:key];
        if ([body length])
            body = [body stringByAppendingString:@"&"];
        
        NSString* akey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* value = [self urlEncodeValue:val];
        NSString* format = [NSString stringWithFormat:@"%@=%@",akey,value];
        body = [body stringByAppendingString:format];
    }
    
    
    if([body length])
    {
        baseUrl = [NSString stringWithFormat:@"%@?%@",baseUrl,body];
    }
    
    NSMutableURLRequest* apiRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:baseUrl]];
    [apiRequest setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    [apiRequest setHTTPMethod:@"GET"];
    [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
                      
    APIRequest* newRequest = [[APIRequest alloc] initWithRequest:apiRequest requestType:kReturnResult completion:completion];
    
    [self cleanupConnection];
    //we are creating an account. remove the queue as we shouldnt be logging anyhow.
    self.currentRequest = nil;
    [self cleanupConnection];
    //this request we want done next
    [self.cachedRequests addObject:newRequest];
    [self checkQueue];
}

-(void)postViewWithParameters:(NSDictionary*)dictionary andWords:(NSArray*)words udid:(NSTimeInterval)udid withCompletion:(void(^)(NSError* error, id jsonResponse))completion
{
    NSString* baseUrl = [NSString stringWithFormat:@"%@/view/",kBaseURL];
    
    if(!dictionary || ![words count])
    {
        completion([NSError errorWithDomain:@"com.ratemyview" code:400 userInfo:@{NSLocalizedDescriptionKey:@"Invalid Post Parameters"}]
                   ,nil);
        return;
    }
    
    
    NSMutableDictionary* mutable = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    
    NSString* body = @"";
    
    for (NSString *key in mutable) {
        NSString *val = [mutable objectForKey:key];
        if ([body length])
            body = [body stringByAppendingString:@"&"];
        
        NSString* akey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* value = [self urlEncodeValue:val];
        NSString* format = [NSString stringWithFormat:@"%@=%@",akey,value];
        body = [body stringByAppendingString:format];
    }
    
    for(NSString* string in words)
    {
        if ([body length])
            body = [body stringByAppendingString:@"&"];
        NSString* akey = [@"words[]" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* value = [self urlEncodeValue:string];
        NSString* format = [NSString stringWithFormat:@"%@=%@",akey,value];
        body = [body stringByAppendingString:format];
    }
    
    if(![self.reachability isReachable])
    {
        SyncObject* obj = [[SyncObject alloc] initWithURI:baseUrl fullURL:baseUrl body:body andVerb:@"POST"];
        obj.udid = udid;
        [[SyncController sharedController] addSyncObject:obj];
        if (completion) {
            completion([NSError errorWithDomain:@"com.ratemyview" code:408 userInfo:nil],nil);
            return;
        }
    }
    
    
    NSMutableURLRequest* apiRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:baseUrl]];
    [apiRequest setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
 
    [apiRequest setHTTPMethod:@"POST"];
    [apiRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    NSData *myRequestData = [NSData dataWithBytes: [body UTF8String] length: [body length]];
    [apiRequest setHTTPBody: myRequestData];

    
    APIRequest* newRequest = [[APIRequest alloc] initWithRequest:apiRequest requestType:kReturnResult completion:completion];
    
    [self cleanupConnection];
    //we are creating an account. remove the queue as we shouldnt be logging anyhow.
    self.currentRequest = nil;
    [self cleanupConnection];
    //this request we want done next
    [self.cachedRequests insertObject:newRequest atIndex:0];
    [self checkQueue];
}

-(void)savePostRequestWithParameters:(NSDictionary*)dictionary andWords:(NSArray*)words
{
    NSString* baseUrl = [NSString stringWithFormat:@"%@/view/",kBaseURL];
    
    if(!dictionary || ![words count])
    {
        return;
    }
    
    
    NSMutableDictionary* mutable = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    
    NSString* body = @"";
    
    for (NSString *key in mutable) {
        NSString *val = [mutable objectForKey:key];
        if ([body length])
            body = [body stringByAppendingString:@"&"];
        
        NSString* akey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* value = [self urlEncodeValue:val];
        NSString* format = [NSString stringWithFormat:@"%@=%@",akey,value];
        body = [body stringByAppendingString:format];
    }
    
    for(NSString* string in words)
    {
        if ([body length])
            body = [body stringByAppendingString:@"&"];
        NSString* akey = [@"words[]" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* value = [self urlEncodeValue:string];
        NSString* format = [NSString stringWithFormat:@"%@=%@",akey,value];
        body = [body stringByAppendingString:format];
    }
    
    
    SyncObject* obj = [[SyncObject alloc] initWithURI:baseUrl fullURL:baseUrl body:body andVerb:@"POST"];
    [[SyncController sharedController] addSyncObject:obj];
    
}

-(void)startWithCurrentRequest:(APIRequest*)request{
    
    
    // no request lets stop. Just being safe really. Shouldnt happen
    if(!request){
        return;
    }
    
    //not on the main thread? We should be. Lets call ourselves again
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(startWithCurrentRequest:) withObject:request waitUntilDone:NO];
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [self cleanupConnection];
    self.fetching = YES;
    self.connection = [[NSURLConnection alloc] initWithRequest:request.apiRequest delegate:self startImmediately:NO];;
	[self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	[self.connection start];
}

-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError *)error{
    
    if(error){
        //if there is a completion block pass it to whos listening
        if(self.currentRequest && self.currentRequest.completionBlock){
            self.currentRequest.completionBlock(error,nil);
        }        
    }
    
    self.fetching = NO;
    [self checkQueue];
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
	if(!self.responseData) {
		self.responseData = [NSMutableData dataWithCapacity:[data length]];
	}
    
	[self.responseData appendData:data];
    
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
 
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
#ifdef DEBUG
    NSString* debug = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    NSLog(@"DEBUG: %@",debug);
#endif
    if(!self.responseData){
        if(self.currentRequest.requestOption == kReturnResult){
            if(self.currentRequest.completionBlock){
                self.currentRequest.completionBlock([NSError errorWithDomain:@"com.ratemyview" code:500 userInfo:[NSDictionary dictionaryWithObject:@"Unknown Server Response" forKey:NSLocalizedDescriptionKey]], nil);
            }
        }

        [self cleanupConnection];
        [self checkQueue];
        return;
    }

    if(!self.currentRequest){
        [self cleanupConnection];
        [self checkQueue];
        return;
    }
    
    NSError* error;
    id response = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableContainers error:&error];
    
    if(self.currentRequest.requestOption == kLogAndDelete){
        
        
    }
    
    //have we just happened in the background? if so lets just update the data with the server_id
    else if(self.currentRequest.requestOption == kLogAndUpdate){
        
    }
   //is the completion handler waiting for use. If so tell them.
    else if(self.currentRequest.requestOption == kReturnResult){
        if(self.currentRequest.completionBlock){
            self.currentRequest.completionBlock(nil, response);
        }
    }
    //clean up and check the queue
    [self cleanupConnection];
    [self checkQueue];
}

- (NSString *)urlEncodeValue:(NSString *)str
{
    return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(__bridge CFStringRef)str,NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
}


-(void)checkQueue{

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    //we are feteching so stop there.
    if(self.isFetching){
        return;
    }
    
    //just finished? remove it from the que
    if(self.currentRequest){
        [self.cachedRequests removeObject:self.currentRequest];
        self.currentRequest = nil;
    }
    
    //no internet so no point continuing.
    if(![self.reachability isReachable]){
        NSMutableArray* toRemove = [NSMutableArray array];
        for(APIRequest* request in self.cachedRequests){
            //tell whos listening there is an error
            if(request.requestOption == kReturnResult){
                if (request.completionBlock) {
                    NSError* error = [NSError errorWithDomain:@"com.ratemyview" code:400 userInfo:[NSDictionary dictionaryWithObject:@"No internet connection" forKey:NSLocalizedDescriptionKey]];
                    request.completionBlock(error,nil);
                    [toRemove addObject:request];
                }
            }
        }
        
        //of those requsts that are send and return, we have sent them an error so lets remove them from the que.
        for(APIRequest* request in toRemove){
            [self.cachedRequests removeObject:request];
        }
        
        //clean up and finish
        [self cleanupConnection];
        return;
    }
    
    //cancel checking the que.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendUnlogged) object:nil];
    
    //if we have a que. take the only off the top
    if([self.cachedRequests count]){
        self.currentRequest = (APIRequest*)[self.cachedRequests objectAtIndex:0];
        [self startWithCurrentRequest:self.currentRequest];
        return;
    }
    else{
        [self performSelector:@selector(sendUnlogged) withObject:nil afterDelay:3.0];
        //nothing to show. clean up 
        [self cleanupConnection];
    }

}

+(BOOL)responseWasSuccessful:(id)jsonResponse{
    if ([jsonResponse isKindOfClass:[NSDictionary class]]) {
        
        if([[jsonResponse valueForKey:@"code"] integerValue]==200){
            return YES;
        }
    }
    
    return NO;
}

-(NSString*)responseIDForResponse:(id)jsonResponse{
    if ([jsonResponse isKindOfClass:[NSDictionary class]]) {
        
        if([[jsonResponse objectForKey:@"results"] isKindOfClass:[NSDictionary class]]){
            NSDictionary* results = [jsonResponse objectForKey:@"results"];
            if([results valueForKey:@"id"] != [NSNull null]){
                return [NSString stringWithFormat:@"%@",[results valueForKey:@"id"]];
            }
        }
    }
    
    return @"";
}

-(void)sendUnlogged{
   
    //prevent queue from starting
    self.fetching = YES;
    
        
    [self cleanupConnection];

}

-(void)cleanupConnection{
    [self.connection cancel];
    self.connection = nil;
    self.responseData = nil;
    self.fetching = NO;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(void)dealloc{
    [self cleanupConnection];
    [self.reachability stopNotifier];
}

@end
