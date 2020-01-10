//
//  RMVMapViewObject.h
//  RateMyView
//
//  Created by Daniel Anderton on 17/09/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
@interface RMVMapViewObject : NSObject

-(id)initWithDictionary:(NSDictionary*)dict;

@property(nonatomic,strong) NSString* comments;
@property(nonatomic) float heading;
@property(nonatomic,strong) NSString *viewID;
@property(nonatomic,strong) CLLocation* location;
@property(nonatomic) float latitude;
@property(nonatomic) float longitude;
@property(nonatomic,strong) NSString* photoURL;
@property(nonatomic,strong) NSNumber* rating;
@property(nonatomic,strong) NSString* time;
@property(nonatomic,strong) NSString* date;
@property(nonatomic,strong) NSString* tsVague;
@property(nonatomic,strong) NSArray* words;

@end
