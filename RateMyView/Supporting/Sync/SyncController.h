//
//  SyncController.h
//  Rate my View
//
//  Created by Daniel Anderton on 22/07/2013.
//

#import <Foundation/Foundation.h>
#import "SyncObject.h"
NSString* const kCachedRequests;
NSString* const kCachedSyncSucess;

@interface SyncController : NSObject

+(id)sharedController;
-(void)configure;
-(void)forceStartQueue;
-(void)stopUpdates;
-(void)removeCachedRequestForURI:(NSString*)url;
-(void)addSyncObject:(SyncObject*)object;
-(NSInteger)numberOfItemsToSync;
-(BOOL)isNetworkUp;
-(void)forceSave;


@end
