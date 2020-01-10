//
//  RMVViewController.h
//  RateMyView
//
//  Created by Daniel Anderton on 16/07/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RMVViewController : UIViewController

-(BOOL)isIpad;
-(void)showAlertViewTitle:(NSString*)title body:(NSString*)body cancelButtonTitle:(NSString*)cancelTitle buttonTitles:(NSArray*)buttons;
@end
