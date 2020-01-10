//
//  RMVMapAnnotation.h
//  RateMyView
//
//  Created by Daniel Anderton on 22/09/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import <MapBox/MapBox.h>
#import "RMVMapViewObject.h"
@interface RMVMapAnnotation : RMAnnotation

@property(nonatomic,strong) RMVMapViewObject* viewObject;
@property(nonatomic) NSInteger viewIndex;

@end
