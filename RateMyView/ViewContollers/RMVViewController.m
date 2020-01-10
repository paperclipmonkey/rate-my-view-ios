//
//  RMVViewController.m
//  RateMyView
//
//  Created by Daniel Anderton on 16/07/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import "RMVViewController.h"

@interface RMVViewController ()

@end

@implementation RMVViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)isIpad
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

-(void)showAlertViewTitle:(NSString*)title body:(NSString*)body cancelButtonTitle:(NSString*)cancelTitle buttonTitles:(NSArray*)buttons

{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:body delegate:nil cancelButtonTitle:cancelTitle otherButtonTitles:nil];
    
    for(NSString* btnTitle in buttons)
    {
        [alert addButtonWithTitle:btnTitle];
    }
    
    [alert show];
    
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
