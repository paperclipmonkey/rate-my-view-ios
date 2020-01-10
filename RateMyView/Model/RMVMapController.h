//
//  RMVMapController.h
//  RateMyView
//
//  Created by Daniel Anderton on 17/09/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapBox/MapBox.h>
#import "RMVMapViewObject.h"
#import "RMVMapAnnotation.h"
#define kMapUserDefaultsKey @"kMapUserDefaultsKey"
#define kMapIsReady @"kMapIsReady"
#define kNetworkIsUp @"kNetworkIsUp"
#define kNetworkIsDown @"kNetworkIsDown"

#define kAnnotationSelected @"kAnnotationSelected" 

@interface RMVMapController : NSObject 

+ (id)sharedController;
- (void)setup;

@property(nonatomic,strong) RMMapView* mapView;
@property(nonatomic,strong) UIViewController* containerController;

-(NSArray*)mapPinObjects;
-(void)fetchNearByPoints;
-(void)addMapViewObject:(RMVMapViewObject *)map;
-(void)changeMapToType:(NSInteger)type;
-(void)networkUp;
-(void)networkDown;
-(BOOL)networkStatusUp;
-(RMVMapAnnotation*)annoationForView:(RMVMapViewObject*)object;
@end
