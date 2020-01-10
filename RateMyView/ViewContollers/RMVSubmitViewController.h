//
//  RMVSecondViewController.h
//  RateMyView
//
//  Created by Daniel Anderton on 16/07/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMVScrollView.h"
#import <MapBox/MapBox.h>

typedef enum {
    kTextFieldTagPhase1 = 100,
    kTextFieldTagPhase2 = 101,
    kTextFieldTagPhase3 = 102,
    kTextFieldTagComments = 103,
} kTextFieldsTag;

@interface RMVSubmitViewController : RMVViewController

@property (strong, nonatomic) RMVScrollView *scrollView;

@end
