//
//  SyncObject.m
//  Rate my View
//
//  Created by Daniel Anderton on 22/07/2013.
//

#import "SyncObject.h"

#define kCodingKeyURL @"kCodingKeyURL"
#define kCodingKeyParametres @"kCodingKeyParametres"
#define kCodingKeyVerb @"kCodingKeyVerb"
#define kCodingKeyErrorCount @"kCodingKeyErrorCount"
#define kCodingKeySyncDate @"kCodingKeySyncDate"
#define kCodingKeyUDID @"kCodingKeyUDID"

@implementation SyncObject

-(id)initWithURI:(NSString*)uri fullURL:(NSString*)fullURI body:(NSString*)body andVerb:(NSString*)verb
{
    if(!(self=[super init]))
        return nil;
    
    self.url = uri;
    self.body = body;
    self.verb = verb;
    self.numberOfErrors = [NSNumber numberWithInteger:0];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.url forKey:kCodingKeyURL];
    [coder encodeObject:self.body forKey:kCodingKeyParametres];
    [coder encodeObject:self.verb forKey:kCodingKeyVerb];
    [coder encodeObject:self.numberOfErrors forKey:kCodingKeyErrorCount];
    [coder encodeInteger:self.syncDate forKey:kCodingKeySyncDate];
    [coder encodeInteger:self.udid forKey:kCodingKeySyncDate];

}

- (id)initWithCoder:(NSCoder *)coder;
{
    self = [[SyncObject alloc] init];
    if (self != nil)
    {
        self.url = [coder decodeObjectForKey:kCodingKeyURL];
        self.body = [coder decodeObjectForKey:kCodingKeyParametres];
        self.verb = [coder decodeObjectForKey:kCodingKeyVerb];
        self.numberOfErrors = [coder decodeObjectForKey:kCodingKeyErrorCount];
        self.syncDate = [coder decodeIntegerForKey:kCodingKeySyncDate];
        self.udid = [coder decodeIntegerForKey:kCodingKeyUDID];

    }
    return self;
}


@end
