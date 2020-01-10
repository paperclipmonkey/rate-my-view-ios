//
//  RMVInformationViewController.h
//  RateMyView
//
//  Created by Daniel Anderton on 22/09/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMVMapViewObject.h"
#import "RMVViewController.h"

@interface RMVInformationViewController : RMVViewController

@property(nonatomic,strong) RMVMapViewObject* selectedObject;
@property(nonatomic) NSInteger selectedObjectIndex;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnBack;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnForward;

- (IBAction)didTapButtonRight:(id)sender;
- (IBAction)didTapButtonBack:(id)sender;
@end
