//
//  RMVAboutViewController.m
//  RateMyView
//
//  Created by Daniel Anderton on 16/07/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import "RMVAboutViewController.h"
#import "RMVScrollView.h"
@interface RMVAboutViewController ()
@property(nonatomic,strong) RMVScrollView* scrollView;
@end

@implementation RMVAboutViewController

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
    self.preferredContentSize = CGSizeMake(320, 600);
    

    
   self.title = @"About";
    
    self.scrollView = [[RMVScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.scrollView];
    
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated
{
    [self setupView];
    self.preferredContentSize = CGSizeMake(320, 600);
    [super viewWillAppear:animated];
}

-(void)setupView
{
    
    //clean up the view
    [self.scrollView cleanup];
    const CGFloat xPadding = 10;
    const CGFloat width = self.view.frame.size.width - 2*xPadding;
   
    //header
    UIView* emptySpace = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.height, 30)];
    [self.scrollView addSubview:emptySpace];
    
    
    UIImageView* headerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ratemy-logo-small"]];
    [headerImage sizeToFit];
    headerImage.frame = CGRectMake(xPadding, 0, width, headerImage.frame.size.height);
    headerImage.contentMode = UIViewContentModeCenter;
    [self.scrollView addSubview:headerImage];
    
    
    UILabel* headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(xPadding, 0, width, 40)];
    headerLabel.shadowColor = [UIColor whiteColor];
    headerLabel.shadowOffset = CGSizeMake(0, 1);
    headerLabel.font = [RMVAssetManager boldFontOfSize:16];
    headerLabel.text = NSLocalizedString(@"View it - Capture it - Rate it - Share it!",nil);
    [self.scrollView addSubview:headerLabel];
    
    UITextView* textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    textView.scrollEnabled = NO;
    textView.text = NSLocalizedString(@"Rate my View is an exciting new way to capture and share what you really feel about the local landscape! It is part of a project to discover new ways of exploring landscapes, better understand how we all see them and to discover what we particularly value.\n\nTo do this we need to burrow beneath “that’s a nice view” and delve a little deeper to find out what we really think about our coast, estuaries, countryside and villages. By taking part and rating your view, you will be adding your valuable piece of the jigsaw. This will help us complete the giant puzzle which makes up a picture of our landscape.\n\nYou can add and rate pictures whenever you want. They will be shared onto a map where you can see what everyone else thought too, as well as sent to us to enter onto our project.\nIt’s easy, quick and good fun – have a go!",nil);
    [textView sizeToFit];
    textView.editable = NO;
    textView.font = [RMVAssetManager bodyFontOfSize:14];
    [self.scrollView addSubview:textView];
    
    UITextView* textViewLink = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    textViewLink.text = NSLocalizedString(@"View your results online at ratemyview.co.uk",nil);
    textViewLink.dataDetectorTypes = UIDataDetectorTypeLink;
    [textViewLink sizeToFit];
    textViewLink.font = [RMVAssetManager bodyFontOfSize:12];
    textViewLink.editable = NO;
    [self.scrollView addSubview:textViewLink];
    
    UILabel* lblTerms = [[UILabel alloc] initWithFrame:CGRectMake(xPadding, 0, width, 30)];
    lblTerms.text = NSLocalizedString(@"Terms of Service", nil);
    lblTerms.font = [RMVAssetManager boldFontOfSize:16];
    [self.scrollView addSubview:lblTerms];
    
    UILabel* lblTermDetails = [[UILabel alloc] initWithFrame:CGRectMake(xPadding, 0, width, 80)];
    lblTermDetails.text = NSLocalizedString(@"Terms of Service", nil);
    lblTermDetails.numberOfLines = 0;
    lblTermDetails.font = [RMVAssetManager bodyFontOfSize:12];
    lblTermDetails.text = NSLocalizedString(@"Once submitted, photos taken and submitted by Rate my View users are owned by the South Devon AONB and may be used for related website or project work in addition to Rate my View.",nil);
    [self.scrollView addSubview:lblTermDetails];
    
    UIImageView* sponsor = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sponsors"]];
    
    [sponsor sizeToFit];
    [self.scrollView addSubview:sponsor];
    [self.scrollView layoutView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
