//
//  SyncController.m
//  Rate my View//
//  Created by Daniel Anderton on 22/07/2013.
//

#import "SyncController.h"
#import "DAReachability.h"
#define kInveniasErrorCount 4
NSString* const kCachedRequests = @"kCachedRequests";
NSString* const kCachedSyncSucess = @"kCachedSyncSucess";
@interface SyncController()

@property(nonatomic,strong) NSMutableArray* cachedRequests;
@property(nonatomic, getter = isSyncing) BOOL syncing;
@property(nonatomic,strong) DAReachability* reachability;

@end

@implementation SyncController

+(id)sharedController
{
    static dispatch_once_t onceToken;
    static id _sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[SyncController alloc] init];
    });
    
    return _sharedInstance;
}

-(void)configure
{
    self.cachedRequests = [NSMutableArray array];
    NSData *dataRepresentingSavedArray = [[NSUserDefaults standardUserDefaults] objectForKey:kCachedRequests];
    
    if(dataRepresentingSavedArray)
    {
        NSArray *oldSavedArray = [NSKeyedUnarchiver unarchiveObjectWithData:dataRepresentingSavedArray];
        self.cachedRequests = [NSMutableArray arrayWithArray:oldSavedArray];
    }
    
    if(!self.cachedRequests || ![self.cachedRequests count])
    {
        self.cachedRequests = [NSMutableArray array];
        
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(start) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forceSave) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    //Lets make sure the api we are using is up. We can update the queue based on this information
    NSString* hostname = @"http://www.ratemyview.co.uk";
    hostname = [hostname stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    hostname = [hostname stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    
    self.reachability = [DAReachability reachabilityWithHostname:hostname];
    // set the blocks for reachabilty
    __weak __block id blockSelf = self;
    self.reachability.reachableBlock = ^(DAReachability*reach)
    {
        [blockSelf performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
    };
    
    self.reachability.unreachableBlock = ^(DAReachability*reach)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:blockSelf selector:@selector(forceStartQueue) object:nil];
    };
    
    // start the notifier which will cause the reachability object to retain itself!
    [self.reachability startNotifier];
    //listen to notifications about signal and application state
}

-(void)start
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(forceStartQueue) withObject:nil afterDelay:5.0];
}

-(void)forceStartQueue
{
    
    if(self.isSyncing)
        return;
    
    if(![self isNetworkUp])
        return;
   

    //for each request in the queue, make sure the time since error was 3 minutes and the number of errors
    //meets the criteria
    
    SyncObject* object = nil;
    for(SyncObject* syncObject in self.cachedRequests)
    {
        int backgroundTimestamp = syncObject.syncDate;
        int timestamp = [[NSDate date] timeIntervalSince1970];
        int delta = (timestamp - backgroundTimestamp);
        
        if((delta >= 180) && ([syncObject.numberOfErrors integerValue] > 0)){
            object = syncObject;
            break;
        }
        else if([syncObject.numberOfErrors integerValue] == 0)
        {
            object = syncObject;
            break;
        }
        else
        {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceStartQueue) object:nil];
            [self performSelector:@selector(forceStartQueue) withObject:nil afterDelay:(180-delta)];
            return;
        }
        
    }
    
      
    if(!object)
        return;
    
        __weak __block SyncController* weakSelf = self;
        __weak __block SyncObject* weakObject = object;

        self.syncing = YES;
        
        NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:object.url]];
        [apiRequest setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        
        [apiRequest setHTTPMethod:[object.verb uppercaseString]];
        [apiRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
        NSData *myRequestData = [NSData dataWithBytes: [object.body UTF8String] length: [object.body length]];
        [apiRequest setHTTPBody: myRequestData];
        
        [NSURLConnection sendAsynchronousRequest:apiRequest
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       
                                       id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];

                                       if([jsonResponse isKindOfClass:[NSDictionary class]])
                                       {
                                           NSDictionary* object = (NSDictionary*)jsonResponse;
                                           NSString* error = [object objectForKey:@"err"];
                                           error =  [error length] ? error : [object objectForKey:@"error"];
                                           if([error length]){
                                               [weakSelf updateErrorCountForObject:weakObject];
                                               [weakSelf updateRequestsWithSuccess:NO];
                                               return;
                                           }
                                          
                                       }
                                       
                                       if (error)
                                       {
                                           [weakSelf updateRequestsWithSuccess:NO];
                                           [weakSelf updateErrorCountForObject:weakObject];
                                       } else{
                                           [weakSelf updateRequestsWithSuccess:YES];
                                       }
                                       
                                   });
                               }];
   
   
    
}

-(void)updateErrorCountForObject:(SyncObject*)object
{
    //if the number of errors has reached the max, lets remove it from the queue
    //the reason is else we could be looping forever trying to send a bad request
    //configuable
    
    NSInteger errorCount = [object.numberOfErrors integerValue];
    errorCount +=1;
    
    [self.cachedRequests removeObject:object];
    
    if(errorCount<kInveniasErrorCount)
    {
        object.syncDate = [[NSDate date] timeIntervalSince1970];
        object.numberOfErrors = [NSNumber numberWithInteger:errorCount];
        [self.cachedRequests addObject:object];
    }
    else
    {
        //tell people we removed the obkject
        [[NSNotificationCenter defaultCenter] postNotificationName:kCachedSyncSucess object:[NSNumber numberWithInteger:[self.cachedRequests count]]];
    }
    
}

-(void)updateRequestsWithSuccess:(BOOL)success
{
    
    if(success)
    {
        self.syncing = NO;
        if([self.cachedRequests count]) //best be safe
        {
            [[[UIAlertView alloc] initWithTitle:@"Saved Post" message:NSLocalizedString(@"Saved Post has been uploaded", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil] show];
            [self.cachedRequests removeObjectAtIndex:0];
            [self forceSave];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kCachedSyncSucess object:[NSNumber numberWithInteger:[self.cachedRequests count]]];
        [self forceStartQueue];
    }
    else{
        self.syncing = NO;
        [self forceStartQueue];
    }
    
    
}

-(void)forceSave
{
    [self.reachability stopNotifier];
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.cachedRequests] forKey:kCachedRequests];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)stopUpdates
{
    
}

-(void)removeCachedRequestForURI:(NSString*)url
{
    NSMutableArray* toRemove = [NSMutableArray array];
    for (SyncObject* object in self.cachedRequests){
        if([[object.url lowercaseString] isEqualToString:[url lowercaseString]]){
            [toRemove addObject:object];
        }
    }
    
    [self.cachedRequests removeObjectsInArray:toRemove];
    
}

-(void)addSyncObject:(SyncObject*)object
{
    SyncObject* found = nil;
    NSInteger index = NSNotFound;
    for(SyncObject* syn in self.cachedRequests)
    {
        if (syn.udid == object.udid){
            found = syn;
            index = [self.cachedRequests indexOfObject:syn];
            break;
        }
    }
    
    if(found && index!=NSNotFound)
    {
        [self.cachedRequests replaceObjectAtIndex:index withObject:object];
    }
    else
        [self.cachedRequests addObject:object];

    [[NSNotificationCenter defaultCenter] postNotificationName:kCachedSyncSucess object:[NSNumber numberWithInteger:[self.cachedRequests count]]];

}

-(NSInteger)numberOfItemsToSync
{
    return [self.cachedRequests count];
}

-(BOOL)isNetworkUp
{
    return [self.reachability isReachable];
}

@end
