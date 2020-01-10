//
//  RMVMapController.m
//  RateMyView
//
//  Created by Daniel Anderton on 17/09/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import "RMVMapController.h"
#import "ServerController.h"
#import "RMVMapAnnotation.h"
#import "RMVInformationViewController.h"
#define kMapSatelliteKey @"paperclipmonkey.map-asryj7mr"
#define kMapNormalKey @"paperclipmonkey.map-zr7oe1u7"

#define kMapKey [[NSUserDefaults standardUserDefaults] boolForKey:kMapUserDefaultsKey] ? kMapSatelliteKey : kMapNormalKey
#define kTilesURL @"tiles.ratemyview.co.uk/v2/aonbs"
@interface RMVMapController()<RMMapViewDelegate>

@property(nonatomic,strong) NSMutableArray* nearbyPoints;
@property(nonatomic) BOOL centeredAroundMe;
@property(nonatomic,strong) RMMapboxSource *tileSource;
@property(nonatomic,strong) RMGenericMapSource *rmvTileSource;
@property(nonatomic) BOOL isNetworkUp;
@property(nonatomic,strong) NSString* mapKey;
@end

@implementation RMVMapController

+ (id)sharedController
{
    static dispatch_once_t once;
    static RMVMapController *sharedController;
    dispatch_once(&once, ^ { sharedController = [[self alloc] init]; });
    return sharedController;
}

-(void)setup
{
    self.nearbyPoints = [NSMutableArray array];
    [ServerController sharedController];
    self.mapKey = kMapKey;
    self.isNetworkUp = YES;
    
    [self.mapView setTileSource:nil];
    self.tileSource = nil;
    self.rmvTileSource = nil;
    self.rmvTileSource = [[RMGenericMapSource alloc] initWithHost:kTilesURL tileCacheKey:@"RMVCustomCacheKey" minZoom:0 maxZoom:15];

    NSError* error = nil;
    NSString *fullPath = [[NSBundle mainBundle] pathForResource:self.mapKey ofType:@"json"];
    NSString* tileJSON = [NSString stringWithContentsOfFile:fullPath encoding:NSASCIIStringEncoding error:&error];
    
    if(!error && [tileJSON length])
    {
        //set up the til source
        self.tileSource = [[RMMapboxSource alloc] initWithTileJSON:tileJSON];
        _tileSource.cacheable = NO;
        self.rmvTileSource.cacheable = NO;
        if(!self.mapView)
        {
            self.mapView = [[RMMapView alloc] initWithFrame:CGRectMake(0, 0, 1, 1) andTilesource:self.tileSource]; //doesnt like being zero
            _mapView.delegate = self;
            _mapView.showsUserLocation = YES;
            _mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        }
        
        [self.mapView setTileSources:@[self.tileSource,self.rmvTileSource]];
        
        //tell people the map is ready and network is up
        [[NSNotificationCenter defaultCenter] postNotificationName:kMapIsReady object:nil];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:@"Error Creating Map" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
    
}

-(void)networkUp
{
    self.isNetworkUp = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetworkIsUp object:nil];
    });
    
    //allows for a location to be found and centered before fetching points
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self fetchBoundingAreas];
        [self fetchNearByPoints];
    });
    
}

-(void)networkDown
{
    //this fixes a location issue where mapbox would crash
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if([self networkStatusUp])
             [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network Down",nil) message:NSLocalizedString(@"Your network connection is down", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil]show];
        
        [self.tileSource cancelAllDownloads];
        
        self.isNetworkUp = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetworkIsDown object:nil];
       
    });
}

-(void)fetchBoundingAreas
{
    //this is no longer needed? just undo the return if needed
    return;
    //fetch the local areas
    [[ServerController sharedController] fetchBoundingAreasWithCompletion:^(NSError *error, id jsonResponse) {
        
        //if an array, we expect it to be an array
        if([jsonResponse isKindOfClass:[NSArray class]])
        {
            //for each obkect in the array
            for(id object in (NSArray*)jsonResponse)
            {
                //if thats as we spect
                if([object isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary* options = [object objectForKey:@"loc"];
                    NSArray* coordinates = [options objectForKey:@"coordinates"];

                    //lets be safe
                    if([coordinates count])
                    {
                        NSArray* coordiantesDrilled = [coordinates objectAtIndex:0];
                        NSMutableArray* boundingBox = [NSMutableArray array];
                        
                        for(id location in coordiantesDrilled){
                            
                            if([location isKindOfClass:[NSArray class]])
                            {
                                NSArray* locations = location;
                                //if we have a vaild coordinates
                                if([locations count] ==2)
                                {
                                    //swap these around if needed
                                    float lat = [[locations objectAtIndex:0]floatValue];
                                    float lon = [[locations objectAtIndex:1]floatValue];
                                    if(CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(lat, lon)))
                                    {
                                        CLLocation* newLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
                                        [boundingBox addObject:newLocation];
                                    }
                                    
                                }
                            }
                            
                        }
                        
                        //with those points lets make an annotaion area
                        if([boundingBox count])
                        {
                            RMAnnotation *annotation = [[RMAnnotation alloc] initWithMapView:self.mapView
                                                                                  coordinate:((CLLocation *)[boundingBox objectAtIndex:0]).coordinate
                                                                                andTitle:nil];
                            
                            //these are used to draw the links between points
                            annotation.userInfo = boundingBox;
                            [annotation setBoundingBoxFromLocations:boundingBox];
                            [self.mapView addAnnotation:annotation];
                        }
                    }
                    
                }
            }
        }
        
        
    }];
}

-(void)fetchNearByPoints
{
    
    [[ServerController sharedController] fetchViewsFromArea:[self mapArea] withCompletion:^(NSError *error, id jsonResponse) {
        
        //check we are an array
        if([jsonResponse isKindOfClass:[NSArray class]])
        {
            //check we are as expcted
            for(id object in (NSArray*)jsonResponse)
            {
                if([object isKindOfClass:[NSDictionary class]])
                {
                    RMVMapViewObject* map = [[RMVMapViewObject alloc] initWithDictionary:object];
                    [self addMapViewObject:map];
                }
            }
            
        }
        
    }];
}

-(void)addMapViewObject:(RMVMapViewObject *)map
{
    //the map is nil dont add it
    // this could be if we dont have an image or rubbish co ords
    if(map && ![self alreadyKnown:map.viewID])
    {
        RMVMapAnnotation *annotation = [[RMVMapAnnotation alloc] initWithMapView:self.mapView coordinate:map.location.coordinate andTitle:nil];
        annotation.viewObject = map;
        annotation.viewIndex = [[self nearbyPoints] count];
        [self.nearbyPoints addObject:map];
        [self.mapView addAnnotation:annotation];
    }
}

-(BOOL)alreadyKnown:(NSString*)view
{
    //double check we are not on the map
    for(RMVMapViewObject* object in self.nearbyPoints)
    {
        if([[object.viewID lowercaseString] isEqualToString:[view lowercaseString]])
            return YES;
    }
    
    return NO;

}

#pragma mark map

-(void)mapView:(RMMapView *)mapView didUpdateUserLocation:(RMUserLocation *)userLocation
{
    //centre the map based on current location
    if(CLLocationCoordinate2DIsValid(userLocation.location.coordinate) && !self.centeredAroundMe)
    {
        mapView.centerCoordinate = userLocation.location.coordinate;
        self.centeredAroundMe = YES;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(fetchNearByPoints) withObject:nil afterDelay:2.0];

}

- (void)mapViewRegionDidChange:(RMMapView *)mapView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(fetchNearByPoints) withObject:nil afterDelay:0.5];
}

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    if (annotation.isUserLocationAnnotation)
        return nil;
    
    
    if([annotation isKindOfClass:[RMVMapAnnotation class]])
    {
        RMMarker* marker = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"pin.png"]];
        return marker;
    }
    
    RMShape *shape = [[RMShape alloc] initWithView:mapView];
    
    //change this is you want a differnt line color or size
    shape.lineColor = [UIColor orangeColor];
    shape.lineWidth = 5.0;
    
    for (CLLocation *location in (NSArray *)annotation.userInfo)
        [shape addLineToCoordinate:location.coordinate];
    
    return shape;
}

-(void)mapView:(RMMapView *)mapView didSelectAnnotation:(RMAnnotation *)annotation
{
    //deselect map pin and tell the views we are ready
    [mapView deselectAnnotation:annotation animated:YES];
    
    if([annotation isKindOfClass:[RMVMapAnnotation class]])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            RMVMapAnnotation* selectedAnnotation = (RMVMapAnnotation*)annotation;
            [[NSNotificationCenter defaultCenter] postNotificationName:kAnnotationSelected object:selectedAnnotation];
            
        });
    }
    
}

#pragma mark helpers
-(RMVMapAnnotation*)annoationForView:(RMVMapViewObject*)object
{
    for(id annoation in self.mapView.annotations)
    {
        if([annoation isKindOfClass:[RMVMapAnnotation class]])
        {
            RMVMapAnnotation* mapPin = (RMVMapAnnotation*)annoation;
            if(mapPin.viewObject == object)
            {
                return mapPin;
            }
        }
    }
    return nil;
}

-(NSArray*)mapPinObjects
{
    return self.nearbyPoints;
}

-(NSArray*)mapArea
{
    NSMutableArray* mapArea = [NSMutableArray array];
    
    //take the screen coords and use them
    //these are from the screen coordis
    [mapArea addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:[self.mapView pixelToCoordinate:CGPointMake(0, 0)].longitude],[NSNumber numberWithFloat:[self.mapView pixelToCoordinate:CGPointMake(0, 0)].latitude], nil]];
   
    [mapArea addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:[self.mapView pixelToCoordinate:CGPointMake(self.mapView.frame.size.width, 0)].longitude],[NSNumber numberWithFloat:[self.mapView pixelToCoordinate:CGPointMake(self.mapView.frame.size.width, 0)].latitude], nil]];
   
    [mapArea addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:[self.mapView pixelToCoordinate:CGPointMake(self.mapView.frame.size.width, self.mapView.frame.size.height)].longitude],[NSNumber numberWithFloat:[self.mapView pixelToCoordinate:CGPointMake(self.mapView.frame.size.width, self.mapView.frame.size.height)].latitude], nil]];
   
    [mapArea addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:[self.mapView pixelToCoordinate:CGPointMake(0, self.mapView.frame.size.height)].longitude],[NSNumber numberWithFloat:[self.mapView pixelToCoordinate:CGPointMake(0, self.mapView.frame.size.height)].latitude], nil]];
    
    return mapArea;
}

-(void)changeMapToType:(NSInteger)type
{
    
    [[NSUserDefaults standardUserDefaults] setBool:(type == 1) forKey:kMapUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.mapKey = (type == 1) ? kMapSatelliteKey : kMapNormalKey;
    
    [self.tileSource cancelAllDownloads];
    [self.mapView setTileCache:nil];
    self.tileSource = nil;
    
    NSError* error = nil;
    NSString *fullPath = [[NSBundle mainBundle] pathForResource:self.mapKey ofType:@"json"];
    NSString* tileJSON = [NSString stringWithContentsOfFile:fullPath encoding:NSASCIIStringEncoding error:&error];
    
    if(!error && [tileJSON length])
    {
        self.tileSource = [[RMMapboxSource alloc] initWithTileJSON:tileJSON];
        self.tileSource.cacheable = NO;
        [self.mapView setTileSources:@[self.tileSource,self.rmvTileSource]];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:@"Error Creating Map" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
    
   
    
}

-(BOOL)networkStatusUp
{
   return self.isNetworkUp;
}

@end
