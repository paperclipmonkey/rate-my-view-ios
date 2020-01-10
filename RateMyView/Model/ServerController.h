//
//  ServerController.h
//
//  Created by Daniel Anderton on 20/12/2012.
//  Copyright (c) 2012 Daniel Anderton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIRequest.h"

NSString* const kLastUpdatedFollowerKey;
NSString* const kLastUpdatedStatsKey;

NSString* const kLastUpdatedNotificationKey;
/**
 This is in controller of the sending of data to the server for Guardian Angel
 */

@interface ServerController : NSObject


+ (id)sharedController;
- (void)fetchBoundingAreasWithCompletion:(void(^)(NSError* error, id jsonResponse))completion;
- (void)fetchViewsFromArea:(NSArray*)points withCompletion:(void(^)(NSError* error, id jsonResponse))completion;

-(void)postViewWithParameters:(NSDictionary*)parameters andWords:(NSArray*)words udid:(NSTimeInterval)time withCompletion:(void(^)(NSError* error, id jsonResponse))completion;

-(void)savePostRequestWithParameters:(NSDictionary*)dictionary andWords:(NSArray*)words;
#pragma mark Helpers
/**
 Checks if the response from server
 @param jsonresponse
 @return success
 */
+(BOOL)responseWasSuccessful:(id)jsonResponse;
-(NSString*)responseIDForResponse:(id)jsonResponse;
@end
