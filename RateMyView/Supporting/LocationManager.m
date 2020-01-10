//
//  LocationManager.m
//  YellForiPad
//
//  Created by Daniel Anderton on 01/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LocationManager.h"

NSString* const locationDidUpdate =  @"LocationUpdated";
NSString* const locationDidFail = @"locationFailed";
NSString* const headingDidUpdate = @"headingDidUpdate";
@implementation LocationManager
@synthesize currentLocationManager,currentLocation,currentError;

#pragma mark - Lifecycle
   
+ (id)sharedLocationManager {
        static dispatch_once_t token;
        static id instance = nil;	
        dispatch_once(&token, ^{ instance = [[self alloc] init]; });
        return instance;		
}

- (id)init {
	if(!(self = [super init])) {
		return nil;
	}
	
	self.currentLocationManager = [[CLLocationManager alloc] init];
	if(!currentLocationManager) {
        self = nil;
		return nil;
	}    
    currentLocationManager.delegate = self;
    currentLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if ([self.currentLocationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.currentLocationManager requestWhenInUseAuthorization];
    }
    return self;
}

-(void)startUpdatingCurrentLocation{
    
    if ([self.currentLocationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.currentLocationManager requestWhenInUseAuthorization];
    }
    
    self.currentError = nil;
    self.currentLocation = nil;
    
    [self.currentLocationManager startUpdatingLocation];
    [self.currentLocationManager startUpdatingHeading];

}

-(void)stopUpdatingCurrentLocation{
   
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.currentLocationManager stopUpdatingLocation];
        [self.currentLocationManager stopUpdatingHeading];
        self.currentError = nil;
        self.currentLocation = nil;
        self.currentHeading = nil;
    });
   
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    
    if(!CLLocationCoordinate2DIsValid(newLocation.coordinate)){
        return;
    }

    self.currentLocation = newLocation;
    self.currentError = nil;
    dispatch_async(dispatch_get_main_queue(), ^{

    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:locationDidUpdate object:currentLocation]];
        
    });
}

-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentHeading = newHeading;
        self.currentError = nil;
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:headingDidUpdate object:self.currentHeading]];

    });
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    if([error code] != kCLErrorLocationUnknown){
        self.currentError= error;
        self.currentLocation = nil;
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:locationDidFail object:currentError]];
    }
}

-(CLLocationCoordinate2D)locationAsCoordinates{
       
    return self.currentLocation.coordinate;

}

-(BOOL)locationCoordiatesAreValid{
    if(CLLocationCoordinate2DIsValid(currentLocation.coordinate)){
        return YES;
    }
    
    return NO;
    
}

-(void)dealloc{
    [self.currentLocationManager stopUpdatingHeading];
    [self.currentLocationManager stopUpdatingLocation];
    self.currentLocationManager = nil;
}


-(NSString*)stringForError:(NSError*)error{
    
    NSInteger errorCode = [error code];
    switch (errorCode) {
        case kCLErrorLocationUnknown:
            return @"Unable to find your location - Please try an open area or authorise access to your location through the Location Services options in Settings";
            break;
        case kCLErrorDenied:
            return @"Please authorise access to your location through the Location Services options in Settings.";
            break;
        case kCLErrorNetwork:
            return @"An Network error has occured";
            break;
            
        default:
            return @"Please authorise access to your location through the Location Services options in Settings.";
            break;
    }
    
}

-(BOOL)locationServicesAreEnabled{
    BOOL locationServicesPermitted = YES;
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];

    locationServicesPermitted = status == kCLAuthorizationStatusNotDetermined || status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse;

    return locationServicesPermitted;
}

@end
