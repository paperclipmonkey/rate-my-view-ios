//
//  RMVInformationViewController.m
//  RateMyView
//
//  Created by Daniel Anderton on 22/09/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import "RMVInformationViewController.h"
#import "RMVScrollView.h"
#import "RMVMapController.h"
#import "RMVRatingControl.h"
#define DEGREES_TO_RADIANS(angle) (((angle) / 180.0) * M_PI)


@interface RMVInformationViewController ()<RMVScrollViewDelegate>
@property(nonatomic,strong) RMVScrollView* scrollView;
@end

@implementation RMVInformationViewController

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

    if(!kIsiOS7)
    {
        [self.navigationController.navigationBar setTranslucent:YES];
        [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
        [self.toolbar setTranslucent:YES];
        [self.toolbar setTintColor:[UIColor blackColor]];
    }

    if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
    {
         UIBarButtonItem* btnCancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didTapCancel:)];
        self.navigationItem.leftBarButtonItem = btnCancel;
    }
    
    self.scrollView = [[RMVScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    self.scrollView.layoutDelegate = self;
    [self.view insertSubview:self.scrollView belowSubview:self.toolbar];
    
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated
{
    [self setupView];
    [super viewWillAppear:animated];
    self.preferredContentSize = CGSizeMake(320, 600);

}

-(void)setupView
{
    
    //clean up
    [self.scrollView cleanup];

    if(!kIsiOS7)
    {
        //lets add a header
        
        UIView* emptySpace = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.height, 30)];
        [self.scrollView addSubview:emptySpace];
    }
    
    //this is where the image goes.
    UIView* imageHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width + 30)];
    
    UIImageView* imageHeading = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compass"]];
    
    imageHeading.frame = CGRectMake(self.view.frame.size.width - [UIImage imageNamed:@"compass"].size.width - 10, 0, [UIImage imageNamed:@"compass"].size.width, [UIImage imageNamed:@"compass"].size.height);
    imageHeading.autoresizingMask = UIViewAutoresizingNone;
    imageHeading.layer.anchorPoint = CGPointMake(0.5, 0.5);
    imageHeading.contentMode = UIViewContentModeScaleAspectFit;
    imageHeading.tag = 99;
    
    __weak __block RMVInformationViewController* weakself = self;
    
    __block UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.width)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;

    [self downloadImageWithURL:[NSURL URLWithString:self.selectedObject.photoURL] completionBlock:^(BOOL succeeded, UIImage *image) {
        if (succeeded) {
            imageView.image = image;
            [weakself.scrollView layoutView];
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Error fetching image",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil]show];
        }
    }];
    
    //holder for the imagevierw
    UIView* holderView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, self.view.frame.size.width, 30)];
    holderView.backgroundColor = [UIColor colorWithWhite:0.899 alpha:1.000];
    holderView.clipsToBounds = NO;
    holderView.layer.shadowColor = [[UIColor blackColor] CGColor];
    holderView.layer.shadowOffset = CGSizeMake(0,1);
    holderView.layer.shadowOpacity = 1.0;
    [imageHolderView addSubview:holderView];
    [imageHolderView addSubview:imageView];

    //when were we uploaded
    UILabel* lblUpload = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width - 60, 30)];
    lblUpload.text = [NSString stringWithFormat:@"Uploaded: %@",self.selectedObject.date];
    lblUpload.font = [RMVAssetManager italicFontOfSize:12];
    lblUpload.shadowColor = [UIColor whiteColor];
    lblUpload.shadowOffset = CGSizeMake(0, 1);
    lblUpload.backgroundColor = [UIColor clearColor];
    [holderView addSubview:lblUpload];
    [self.scrollView addSubview:imageHolderView];

    //rating
	UIImage *dot = [UIImage imageNamed:@"dot.png"];
	UIImage *star = [UIImage imageNamed:@"star.png"];
	RMVRatingControl *ratingControl = [[RMVRatingControl alloc] initWithLocation:CGPointMake(self.view.frame.size.width*0.5 + 20, 5)
                                                                          emptyImage:dot
                                                                      solidImage:star
                                                                    andMaxRating:5];
    

    
    // Customize the current rating if needed
    [ratingControl setRating:self.selectedObject.rating.integerValue];
    [ratingControl setStarSpacing:6];
    ratingControl.center = CGPointMake(holderView.frame.size.width - 10 - ratingControl.frame.size.width*0.5, 15);
    [ratingControl setUserInteractionEnabled:NO];
    [holderView addSubview:ratingControl];
    

    //create a view that shows all the words
    UIView* wordsHolder = [[UIView alloc] initWithFrame:CGRectZero];
    
    CGFloat y = 0;
    
    for(NSString* word in self.selectedObject.words)
    {
        
        UIImageView* dot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dot.png"]];
        [dot sizeToFit];
        dot.frame = CGRectMake(5, y, dot.frame.size.width, dot.frame.size.height);
        
        UILabel* lblWords = [[UILabel alloc] initWithFrame:CGRectMake(10 + dot.frame.size.height, y, 200, dot.frame.size.height)];
        lblWords.text = word;
        lblWords.font = [RMVAssetManager bodyFontOfSize:14];
        
        y+=dot.frame.size.height + 5.0f;
        [wordsHolder addSubview:lblWords];
        [wordsHolder addSubview:dot];
    }
    
    wordsHolder.frame = CGRectMake(0, 0, 320, y + 15);
    [wordsHolder addSubview:imageHeading];
    [self.scrollView addSubview:wordsHolder];
   
    UITextView* txtComments = [[UITextView alloc] initWithFrame:CGRectMake(5, 0, 310, 100)];
    txtComments.text = self.selectedObject.comments;
    txtComments.textColor = [UIColor blackColor];
    txtComments.font = [RMVAssetManager bodyFontOfSize:14];
    txtComments.userInteractionEnabled = NO;
    [self.scrollView addSubview:txtComments];

    [self.scrollView layoutView];
    
    self.btnBack.enabled = [self canGoLeft];
    self.btnForward.enabled = [self canGoRight];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)didTapCancel:(id)sender
{
    //hide
    [self dismissViewControllerAnimated:YES completion:^{
        //center to where we was last looking
        [[[RMVMapController sharedController] mapView] setCenterCoordinate:self.selectedObject.location.coordinate animated:YES];
    }];
}

- (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if ( !error )
                                   {
                                       UIImage *image = [[UIImage alloc] initWithData:data];
                                       completionBlock(YES,image);
                                   } else{
                                       completionBlock(NO,nil);
                                   }
                                   
                               });
                           }];
}

-(BOOL)canGoLeft
{
    NSArray* views = [[RMVMapController sharedController] mapPinObjects];
    if(self.selectedObjectIndex !=0 && self.selectedObjectIndex < [views count])
        return YES;
    
    return NO;
}

-(BOOL)canGoRight
{
    NSArray* views = [[RMVMapController sharedController] mapPinObjects];
    if(self.selectedObjectIndex < ([views count] -1))
        return YES;
    
    return NO;
}

- (IBAction)didTapButtonRight:(id)sender {
    
    if([self canGoRight])
    {
        NSArray* views = [[RMVMapController sharedController] mapPinObjects];
        if(self.selectedObjectIndex < ([views count] -1))
        {
            self.selectedObjectIndex++;
            self.selectedObject = [views objectAtIndex:self.selectedObjectIndex];
            [self setupView];
            
            //this is for the iPad to then move itself on the map
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DidSwapToObject" object:self.selectedObject];
        }
    }
}

- (IBAction)didTapButtonBack:(id)sender {
    if([self canGoLeft])
    {
        NSArray* views = [[RMVMapController sharedController] mapPinObjects];
        if(self.selectedObjectIndex !=0 && self.selectedObjectIndex < [views count])
        {
            self.selectedObjectIndex--;
            self.selectedObject = [views objectAtIndex:self.selectedObjectIndex];
            [self setupView];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DidSwapToObject" object:self.selectedObject];
        }
    }
}

-(void)didLayoutView:(RMVScrollView*)scroll
{
    //once layed out lets make sure showing the right heading.
    //wait for the view to be layed out else we get weird resulst
    double delayInSeconds = 0.25;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        UIImageView* imageView = (UIImageView*)[scroll viewWithTag:99];
        [UIView animateWithDuration:0.2 animations:^{
            imageView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(self.selectedObject.heading));
        }];
        
    });
   
}
@end
