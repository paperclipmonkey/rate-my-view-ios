//
//  SyncObject.h
//  Rate my View//
//  Created by Daniel Anderton on 22/07/2013.
//

#import <Foundation/Foundation.h>

@interface SyncObject : NSObject

@property(nonatomic,strong) NSString *url;
@property(nonatomic,strong) NSString* body;
@property(nonatomic,strong) NSString *verb;
@property(nonatomic,strong) NSNumber *numberOfErrors;
@property(nonatomic) NSTimeInterval syncDate;
@property(nonatomic) NSTimeInterval udid;

-(id)initWithURI:(NSString*)uri fullURL:(NSString*)fullURI body:(NSString*)body andVerb:(NSString*)verb;

@end
