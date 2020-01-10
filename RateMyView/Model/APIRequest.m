//
//  APIRequest.m
//  ADHD Angel
//
//  Created by Daniel Anderton on 20/12/2012.
//  Copyright (c) 2012 Daniel Anderton. All rights reserved.
//

#import "APIRequest.h"

@implementation APIRequest

-(id)initWithRequest:(NSMutableURLRequest*)request requestType:(kServerControllerOptions)requestOption completion:(void(^)(NSError* error, id jsonResponse))completion{
    
    if(!(self = [super init])){
        return nil;
    }
    
    self.apiRequest = request;
    self.requestOption = requestOption;
    self.completionBlock = completion;
    
    return self;
}

@end
