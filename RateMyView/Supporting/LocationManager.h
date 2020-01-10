//
//  LocationManager.h
//  YellForiPad
//
//  Created by Daniel Anderton on 01/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NSString* const locationDidUpdate;
NSString* const headingDidUpdate;
NSString* const locationDidFail;

@interface LocationManager : NSObject <CLLocationManagerDelegate>

+(id)sharedLocationManager;
-(void)startUpdatingCurrentLocation;
-(void)stopUpdatingCurrentLocation;
-(CLLocationCoordinate2D)locationAsCoordinates;
-(NSString*)stringForError:(NSError*)error;
-(BOOL)locationServicesAreEnabled;
-(BOOL)locationCoordiatesAreValid;

@property(nonatomic,retain) CLLocationManager* currentLocationManager;
@property(nonatomic,retain) CLLocation* currentLocation;
@property(nonatomic,retain) CLHeading* currentHeading;

@property(nonatomic,retain) NSError* currentError;

@end
