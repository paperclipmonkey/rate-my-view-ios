//
//  InveniasPopOverController.m
//  Invenias
//
//  Created by Daniel Anderton on 27/08/2013.
//  Copyright (c) 2013 Invenias Ltd. All rights reserved.
//

#import "RMVPopOverController.h"
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation RMVPopOverController

-(void)dismiss
{
    if(self.isPopoverVisible)
    {
        [self dismissPopoverAnimated:NO];
    }
}

-(id)initWithContentViewController:(UIViewController *)viewController
{
    if(!(self=[super initWithContentViewController:viewController])){
        return nil;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismiss) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
   
    self.contentViewController = viewController;

    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)didRotate: (NSNotification *) note
{
   
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
        return;
        
    //prevent it being called multiple times
    UIInterfaceOrientation current = [[UIApplication sharedApplication] statusBarOrientation];
    UIInterfaceOrientation orientation = [[[note userInfo] objectForKey: UIApplicationStatusBarOrientationUserInfoKey] integerValue];
    
    if ( current == orientation )
        return;
    
    if(!self.autoRotate)
        return;
    
    
    if(!self.isPopoverVisible)
        return;
    
    [self dismiss];

  
    if (self.presentionBarItem) {
        if(self.presentationView.view.window)
            [self presentPopoverFromBarButtonItem:self.presentionBarItem permittedArrowDirections:self.presentionArrow animated:YES];
        
        return;
    }
        
    if(self.presentationView.view.window)
        [self presentPopoverFromRect:self.presentationRect inView:self.presentationView.view permittedArrowDirections:self.presentionArrow animated:YES];
    
    
}


@end
