//
//  RMVMapViewObject.m
//  RateMyView
//
//  Created by Daniel Anderton on 17/09/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import "RMVMapViewObject.h"
#import "NSString+Helper.h"
@implementation RMVMapViewObject
#define kBaseURL @"http://static.ratemyview.co.uk/uploads"

-(id)initWithDictionary:(NSDictionary*)dict
{
    if(!(self = [super init])){
        return nil;
    }
    
    self.comments = [NSString nonNullString:[dict valueForKey:@"comments"]];
    self.heading = [[dict valueForKey:@"heading"]floatValue];
    self.viewID = [NSString nonNullString:[dict valueForKey:@"id"]];
    NSArray* loc = [dict objectForKey:@"loc"];
    
    //we have a lat and a lon
    if([loc count]==2)
    {
        //these will need to be changed
        float lat = [[loc objectAtIndex:1] floatValue];
        float lon = [[loc objectAtIndex:0] floatValue];
        
        if(CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(lat, lon)))
        {
            self.location = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
            self.latitude = lat;
            self.longitude = lon;
        }else
        {
            //rubbish coordinates lets just ignore.
            return nil;
        }
        
    }
    
    NSString* url = [NSString nonNullString:[dict valueForKey:@"photo"]];
    if([url length])
        self.photoURL = [NSString stringWithFormat:@"%@/%@",kBaseURL,url];
    
    self.rating = [dict objectForKey:@"rating"];
    self.time = [NSString nonNullString:[dict objectForKey:@"time"]];
    self.date = [NSString nonNullString:[dict objectForKey:@"ts"]];
    self.tsVague = [NSString nonNullString:[dict objectForKey:@"tsVague"]];
    
    id words = [dict objectForKey:@"words"];
    
    //lets make sure we have an array and an array of strings
    if([words isKindOfClass:[NSArray class]])
    {
        BOOL strings = YES;
        for (id object in (NSArray*)words){
            if(![object isKindOfClass:[NSString class]])
            {
                strings = NO;
            }
        }
        
        if(strings)
        {
            self.words = words;
        }
        
    }
    
    
    return self;
}

/*
 @property(nonatomic,strong) NSString* comments;
 @property(nonatomic) float heading;
 @property(nonatomic,strong) NSNumber *viewID;
 @property(nonatomic,strong) CLLocation* location;
 @property(nonatomic) float latitude;
 @property(nonatomic) float longitude;
 @property(nonatomic,strong) NSString* photoURL;
 @property(nonatomic,strong) NSNumber* rating;
 @property(nonatomic,strong) NSString* time;
 @property(nonatomic,strong) NSString* date;
 @property(nonatomic,strong) NSString* tsVague;
 @property(nonatomic,strong) NSArray* words;*/

@end
