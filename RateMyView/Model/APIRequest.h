//
//  APIRequest.h
//  ADHD Angel
//
//  Created by Daniel Anderton on 20/12/2012.
//  Copyright (c) 2012 Daniel Anderton. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum{
    kReturnResult,
    kPostAndForget,
    kLogAndUpdate,
    kLogAndDelete
}kServerControllerOptions;

/**
 Cached object for server posts. This should include all the information needed to for us to post to the server at a later stage.
 */
@interface APIRequest : NSObject

-(id)initWithRequest:(NSMutableURLRequest*)request requestType:(kServerControllerOptions)requestOption completion:(void(^)(NSError* error, id jsonResponse))completion;

@property(nonatomic,strong) NSMutableURLRequest* apiRequest;
@property(nonatomic) kServerControllerOptions requestOption;
@property(nonatomic,copy) void(^completionBlock)(NSError* error, id jsonResponse);

@end
