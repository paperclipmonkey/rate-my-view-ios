//
//  RMViPadViewController.h
//  RateMyView
//
//  Created by Daniel Anderton on 28/09/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RMViPadViewController : UIViewController

@property(nonatomic,weak) IBOutlet UIToolbar* toolbar;
@property(nonatomic,strong) IBOutlet UISegmentedControl* mapSegment;

-(IBAction)didTapAddView:(id)sender;
-(IBAction)didTapAbout:(id)sender;

@end
