//
//  RMVSecondViewController.m
//  RateMyView
//
//  Created by Daniel Anderton on 16/07/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import "RMVSubmitViewController.h"
#import "QuartzCore/QuartzCore.h"
#import "ServerController.h"
#import "RMVRatingControl.h"
#import "RMVMapViewObject.h"
#import "RMVInformationViewController.h"
#import "MBProgressHUD.h"
#import "RMVMapAnnotation.h"
#import "SyncController.h"
#define DEGREES_TO_RADIANS(angle) (((angle) / 180.0) * M_PI)

@interface RMVSubmitViewController () <UITextFieldDelegate,UITextViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,RMMapViewDelegate,UIAlertViewDelegate>

@property(nonatomic,strong) UILabel* lblRating;
@property(nonatomic,strong) UILabel* lblSyncNumber;
@property(nonatomic,strong) UISegmentedControl* segmentArea;
@property(nonatomic,strong) UISegmentedControl* segmentAge;
@property(nonatomic,strong) UITextView* txtPlaceHolder;
@property(nonatomic,strong) UIImagePickerController* imagePickerController;
@property(nonatomic,strong) UIImageView* imageView;
@property(nonatomic,getter = isKeyboardShown) BOOL keyboardShown;
@property(nonatomic,getter = isUploading) BOOL uploading;
@property(nonatomic,strong) RMVRatingControl *ratingControl;
@property(nonatomic,strong) RMMapView* mapView;
@property(nonatomic,strong) UIImageView* headingImage;
@property(nonatomic,strong) RMMapboxSource *tileSource;
@property(nonatomic,getter = isSetup) BOOL setup;
@property(nonatomic,strong) NSDate* postUDIDDate;
@end

@implementation RMVSubmitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"My View";

    //set up the scrollview
    self.scrollView = [[RMVScrollView alloc] initWithFrame:self.view.frame];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
    
    //set up the bar buttons
    UIBarButtonItem* btnReload = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(didTapReload:)];
    
    self.navigationItem.rightBarButtonItem = btnReload;
    
    //make sure we can get a loction
    [[LocationManager sharedLocationManager] startUpdatingCurrentLocation];

    //set iPad popover size
    self.preferredContentSize = CGSizeMake(320, 700);
    
    //update for non iOS7 devices
    if(!kIsiOS7)
    {
        [self.navigationController.navigationBar setTranslucent:YES];
        [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
    }
    
    //listen to changes
    [[NSNotificationCenter defaultCenter] addObserver:self
    										 selector:@selector(keyboardWasShown:)
    											 name:UIKeyboardWillShowNotification
    										   object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
    										 selector:@selector(keyboardWasHidden:)
    											 name:UIKeyboardWillHideNotification
    										   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
    										 selector:@selector(networkDown:)
    											 name:kNetworkIsDown
    										   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
    										 selector:@selector(headingUpdated:)
    											 name:headingDidUpdate
    										   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
    										 selector:@selector(updateUploadedQueueText:)
    											 name:kCachedSyncSucess
    										   object:nil];
  
    
    //
    
    //if we have network add the tile source. this is duw to an MapBox Bug
    if ([[RMVMapController sharedController] networkStatusUp]) {
    }
    
    NSError* error = nil;
    NSString *fullPath = [[NSBundle mainBundle] pathForResource:@"paperclipmonkey.map-zr7oe1u7" ofType:@"json"];
    NSString* tileJSON = [NSString stringWithContentsOfFile:fullPath encoding:NSASCIIStringEncoding error:&error];
    
    if(!error && [tileJSON length])
        self.tileSource = [[RMMapboxSource alloc] initWithTileJSON:tileJSON];
    
    self.mapView = [[RMMapView alloc] initWithFrame:CGRectMake(0, 0, 1, 1) andTilesource:self.tileSource]; //doesnt like being zero and we can draw it nicely later
    _mapView.delegate = self;
    
    if([[LocationManager sharedLocationManager] locationServicesAreEnabled])
    {
        _mapView.showsUserLocation = YES;
    }
    
    _mapView.userInteractionEnabled = NO;
    //_mapView.hideAttribution= YES;
    [_mapView zoomByFactor:0.30 near:self.mapView.center animated:YES];
   
    //create the imageview to hold the compass
    UIImage* compass = [UIImage imageNamed:@"compass"];
    self.headingImage = [[UIImageView alloc] initWithImage:compass];
    self.headingImage.frame = CGRectMake(self.view.frame.size.width - compass.size.width - 10, 0, compass.size.width, compass.size.height);
    self.headingImage.autoresizingMask = UIViewAutoresizingNone;
    self.headingImage.layer.anchorPoint = CGPointMake(0.5, 0.5);
    self.headingImage.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillDisappear:(BOOL)animated
{
    //just to clean up
    [self.tileSource cancelAllDownloads];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(!self.isSetup)
        [self setupView];

}

-(void)setupView
{
    //clean up and remove all views
    [self.scrollView cleanup];
    
    //lets add a header
    UIView* emptySpace = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.height,  kIsiOS7 ? 10 : 50)];
    [self.scrollView addSubview:emptySpace];
    
    const CGFloat padding = 10;
    const CGFloat width = self.view.frame.size.width - padding - padding;
    
    self.lblSyncNumber = [[UILabel alloc] initWithFrame:CGRectMake(padding, 0, width, 30)];
    self.lblSyncNumber.font = [RMVAssetManager italicFontOfSize:12];
    self.lblSyncNumber.textColor = [UIColor darkGrayColor];
    self.lblSyncNumber.textAlignment = NSTextAlignmentLeft;
    [self.scrollView addSubview:self.lblSyncNumber];
    [self updateUploadedQueueText:nil];
        
    UILabel* lblHeading = [[UILabel alloc] initWithFrame:CGRectMake(padding, 0, width, 30)];
    lblHeading.font = [RMVAssetManager headingFontOfSize:24];
    lblHeading.textColor = [UIColor blackColor];
    lblHeading.textAlignment = NSTextAlignmentLeft;
    lblHeading.text = NSLocalizedString(@"myviewheading", nil);
    [self.scrollView addSubview:lblHeading];
    
    //update the heading image
    self.headingImage.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0));
    self.headingImage.frame = CGRectMake(self.view.frame.size.width - self.headingImage.frame.size.width - 10, 0, self.headingImage.frame.size.width, self.headingImage.frame.size.height);
    
    //container for heading
    UIView* headingHolder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];
    [headingHolder addSubview:lblHeading];
    [headingHolder addSubview:self.headingImage];
    [self.scrollView addSubview:headingHolder];

    //info about RMV
    UITextView* txtSubtitle = [[UITextView alloc] initWithFrame:CGRectMake(padding, 0, width, 50)];
    txtSubtitle.font = [RMVAssetManager bodyFontOfSize:16];
    txtSubtitle.textColor = [UIColor blackColor];
    txtSubtitle.textAlignment = NSTextAlignmentLeft;
        txtSubtitle.userInteractionEnabled = NO;
    txtSubtitle.text = NSLocalizedString(@"myviewsubtitle", nil);
    [self.scrollView addSubview:txtSubtitle];
    
    
    UITextView* txtHint = [[UITextView alloc] initWithFrame:CGRectMake(padding, 0, width, 50)];
    txtHint.font = [RMVAssetManager bodyFontOfSize:16];
    txtHint.textColor = [UIColor blackColor];
        txtHint.userInteractionEnabled = NO;
    txtHint.textAlignment = NSTextAlignmentLeft;
    txtHint.text = NSLocalizedString(@"myviewtakephoto", nil);
    [self.scrollView addSubview:txtHint];
    
    //create a button and set it up
    UIButton* btnCamera = [RMVAssetManager greyButton];
    CGRect frameCamera = btnCamera.frame;
    frameCamera.origin.x = self.view.bounds.size.width/2.0 - frameCamera.size.width*0.5;
    btnCamera.frame = frameCamera;
    [btnCamera setTitle:NSLocalizedString(@"Camera",nil) forState:UIControlStateNormal];
    [btnCamera addTarget:self action:@selector(didTapCameraButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:btnCamera];
    
    //create a view to hold the imageview. hide it as we have no image
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, width, width)];
    self.imageView.hidden = YES;
    [self.scrollView addSubview:self.imageView];
    
    //add the mapview to the view
    self.mapView.frame = CGRectMake(padding, 0, width, 100);
    [self.scrollView addSubview:self.mapView];
    

    self.lblRating  = [[UILabel alloc] initWithFrame:CGRectMake(padding, 0, width, 30)];
    self.lblRating .font = [RMVAssetManager bodyFontOfSize:16];
    self.lblRating .textColor = [UIColor blackColor];
    self.lblRating .textAlignment = NSTextAlignmentLeft;
    self.lblRating .text = [NSString stringWithFormat:@"%@ %u",NSLocalizedString(@"myviewrating", nil),3];
    [self.scrollView addSubview:self.lblRating ];
    
    //create the custom rating control
    UIImage *dot = [UIImage imageNamed:@"dot.png"];
	UIImage *star = [UIImage imageNamed:@"star.png"];
	self.ratingControl = [[RMVRatingControl alloc] initWithLocation:CGPointMake(self.view.bounds.size.width* 0.5, 5)
                                                                      emptyImage:dot
                                                                      solidImage:star
                                                                    andMaxRating:5];
    //block to handle changes
    __block __weak RMVSubmitViewController* weakself = self;
    [self.ratingControl setEditingChangedBlock:^(NSUInteger rating){
        NSInteger result = (int)roundf(rating);
        weakself.lblRating.text = [NSString stringWithFormat:@"%@ %u",NSLocalizedString(@"myviewrating", nil),(int)result];
    }];
    
    // Customize the current rating if needed
    [self.ratingControl setRating:3];
    [self.ratingControl setStarSpacing:6];
    self.ratingControl.center = CGPointMake(self.view.bounds.size.width * 0.5, 0);
    [self.scrollView addSubview:self.ratingControl];
    
    /*
     create the words textfields. these are tagged to make it easier to find later
     
     */

    UILabel* lblDescribe = [[UILabel alloc] initWithFrame:CGRectMake(padding, 0, width, 40)];
    lblDescribe.font = [RMVAssetManager bodyFontOfSize:16];
    lblDescribe.textColor = [UIColor blackColor];
    lblDescribe.numberOfLines = 2;
    lblDescribe.textAlignment = NSTextAlignmentLeft;
    lblDescribe.text = NSLocalizedString(@"myviewdescribe", nil);
    [self.scrollView addSubview:lblDescribe];
    
    UILabel* lblPhase = [[UILabel alloc] initWithFrame:CGRectMake(padding, 0, width, 30)];
    lblPhase.font = [RMVAssetManager bodyFontOfSize:16];
    lblPhase.textColor = [UIColor blackColor];
    lblPhase.textAlignment = NSTextAlignmentLeft;
    lblPhase.text = NSLocalizedString(@"myviewphase1", nil);
    [self.scrollView addSubview:lblPhase];
    
    UITextField* txtPhaseOne = [[UITextField alloc] initWithFrame:CGRectMake(padding, 0, width, 40)];
    txtPhaseOne.tag = kTextFieldTagPhase1;
    txtPhaseOne.delegate = self;
    txtPhaseOne.borderStyle = UITextBorderStyleRoundedRect;
    txtPhaseOne.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    txtPhaseOne.returnKeyType = UIReturnKeyNext;
    [self.scrollView addSubview:txtPhaseOne];
    
    [self.scrollView addSubview:[self seperatedView]];
    
    //TEXTField 2
    
    UILabel* lblPhaseTwo = [[UILabel alloc] initWithFrame:CGRectMake(padding, 0, width, 30)];
    lblPhaseTwo.font = [RMVAssetManager bodyFontOfSize:16];
    lblPhaseTwo.textColor = [UIColor blackColor];
    lblPhaseTwo.textAlignment = NSTextAlignmentLeft;
    lblPhaseTwo.text = NSLocalizedString(@"myviewphase2", nil);
    [self.scrollView addSubview:lblPhaseTwo];
    
    UITextField* txtPhaseTwo = [[UITextField alloc] initWithFrame:CGRectMake(padding, 0, width, 40)];
    txtPhaseTwo.tag = kTextFieldTagPhase2;
    txtPhaseTwo.delegate = self;
    txtPhaseTwo.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    txtPhaseTwo.borderStyle = UITextBorderStyleRoundedRect;
    txtPhaseTwo.returnKeyType = UIReturnKeyNext;

    [self.scrollView addSubview:txtPhaseTwo];
    
    [self.scrollView addSubview:[self seperatedView]];
    
    //Textfield 3
    
    UILabel* lblPhaseThree = [[UILabel alloc] initWithFrame:CGRectMake(padding, 0, width, 30)];
    lblPhaseThree.font = [RMVAssetManager bodyFontOfSize:16];
    lblPhaseThree.textColor = [UIColor blackColor];
    lblPhaseThree.textAlignment = NSTextAlignmentLeft;
    lblPhaseThree.text = NSLocalizedString(@"myviewphase3", nil);

    [self.scrollView addSubview:lblPhaseThree];
    
    UITextField* txtPhaseThree = [[UITextField alloc] initWithFrame:CGRectMake(padding, 0, width, 40)];
    txtPhaseThree.tag = kTextFieldTagPhase3;
    txtPhaseThree.delegate = self;
    txtPhaseThree.borderStyle = UITextBorderStyleRoundedRect;
    txtPhaseThree.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    txtPhaseThree.returnKeyType = UIReturnKeyNext;

    [self.scrollView addSubview:txtPhaseThree];
    
    [self.scrollView addSubview:[self seperatedView]];

    
    //label to hint comments
    UILabel* lblDescribeMore = [[UILabel alloc] initWithFrame:CGRectMake(padding, 0, width, 40)];
    lblDescribeMore.font = [RMVAssetManager bodyFontOfSize:16];
    lblDescribeMore.textColor = [UIColor blackColor];
    lblDescribeMore.numberOfLines = 2;
    lblDescribeMore.textAlignment = NSTextAlignmentLeft;
    lblDescribeMore.text = NSLocalizedString(@"myviewdescribeMore", nil);
    [self.scrollView addSubview:lblDescribeMore];
    
    //due to the way we use our custom scrollview we need a content soze for the comments area
    self.txtPlaceHolder = [[UITextView alloc] initWithFrame:CGRectMake(padding, 0, width, 30)];
    self.txtPlaceHolder.font = [RMVAssetManager headingFontOfSize:16];
    self.txtPlaceHolder.textColor = [UIColor blackColor];
    self.txtPlaceHolder.textAlignment = NSTextAlignmentLeft;
    self.txtPlaceHolder.text = @"\n\n\n\n\n"; // The alignment will resize this too small else
    self.txtPlaceHolder.layer.borderColor = [UIColor grayColor].CGColor;
    self.txtPlaceHolder.layer.borderWidth = 2.0f;
    self.txtPlaceHolder.tag = kTextFieldTagComments;
    self.txtPlaceHolder.delegate = self;
    [self.scrollView addSubview:self.txtPlaceHolder];
    
    [self.scrollView addSubview:[self seperatedView]];
    
    //lets ask a bit about the user
    UILabel* lblKnowdlege = [[UILabel alloc] initWithFrame:CGRectMake(padding, 0, width, 40)];
    lblKnowdlege.font = [RMVAssetManager bodyFontOfSize:16];
    lblKnowdlege.textColor = [UIColor blackColor];
    lblKnowdlege.textAlignment = NSTextAlignmentLeft;
    lblKnowdlege.numberOfLines = 2;
    lblKnowdlege.text = NSLocalizedString(@"myviewdescribeknowledge", nil);
    [self.scrollView addSubview:lblKnowdlege];

    self.segmentArea = [[UISegmentedControl alloc] initWithItems:@[@"Not at all",@"Not very well",@"Very well"]];
    self.segmentArea.frame = CGRectMake(padding, 0, width, 30);
    [self.scrollView addSubview:self.segmentArea];
    [self.scrollView addSubview:[self seperatedView]];
    
    UILabel* lblAge = [[UILabel alloc] initWithFrame:CGRectMake(padding, 0, width, 30)];
    lblAge.font = [RMVAssetManager bodyFontOfSize:16];
    lblAge.textColor = [UIColor blackColor];
    lblAge.textAlignment = NSTextAlignmentLeft;
    lblAge.text = NSLocalizedString(@"myviewage", nil);
    [self.scrollView addSubview:lblAge];
    
    self.segmentAge = [[UISegmentedControl alloc] initWithItems:@[@"0-18",@"19-24",@"25-44",@"45-64",@"65+"]];
    self.segmentAge.frame = CGRectMake(padding, 0, width, 30);
    [self.scrollView addSubview:self.segmentAge];
    [self.scrollView addSubview:[self seperatedView]];
    
    UIButton* btnSend = [RMVAssetManager greyButton];
    [btnSend addTarget:self action:@selector(didTapSend:) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect frame = btnSend.frame;
    frame.origin.x = self.view.bounds.size.width * 0.5 - frame.size.width*0.5;
    btnSend.frame = frame;
    [btnSend setTitle:NSLocalizedString(@"Submit",nil) forState:UIControlStateNormal];
    [self.scrollView addSubview:btnSend];
    
    //force it to redraw and layout
    [self.scrollView layoutView];

    self.setup = YES;
}

//helps
-(UIView*)seperatedView
{
    UIView* viewSeperator = [[UIView alloc] initWithFrame:CGRectMake(10, 0, self.view.bounds.size.width - 20, 1)];
    viewSeperator.backgroundColor = [UIColor lightGrayColor];
    viewSeperator.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    return viewSeperator;
}

#pragma mark actions

-(void)didTapCameraButton:(id)sender
{
    //create it now. this is quite expensive and takes a while
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        self.imagePickerController = [[UIImagePickerController alloc] init];
        self.imagePickerController.sourceType=UIImagePickerControllerSourceTypeCamera;
        self.imagePickerController.delegate=self;
        self.imagePickerController.allowsEditing=NO;
    }
    
    if(!self.imagePickerController)
    {
        [self showAlertViewTitle:@"Error" body:NSLocalizedString(@"nocamera", nil) cancelButtonTitle:@"Cancel" buttonTitles:nil];
        return;
    }
    
    [self presentViewController:self.imagePickerController animated:YES completion:NULL];
}

#pragma mark - When finish shoot

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //got an image lets set it and relayout
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.imageView.image = image;
    self.imageView.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        [self.scrollView layoutView];
    }];
    
    self.postUDIDDate = [NSDate date];
    
    //save to the device
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark texfiels

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    
    id viewWithTag = (UIView*)[self.scrollView viewWithTag:textField.tag+1];
    
    if([viewWithTag isKindOfClass:[UITextField class]])
    {
        UITextField* nextField = (UITextField*)viewWithTag;
        [nextField becomeFirstResponder];
    }
    else if([viewWithTag isKindOfClass:[UITextView class]]){
        UITextView* nextField = (UITextView*)viewWithTag;
        [nextField becomeFirstResponder];
    }else
    {
        [textField resignFirstResponder];
    }
        
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    //scroll to the point we are visible
    CGRect frame = [textField convertRect:textField.frame toView:textField.superview];
    frame.origin.y -= 20;
    [self.scrollView scrollRectToVisible:frame animated:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    if(![textView.text length])
        textView.text = @"\n\n\n\n\n";
    [textView resignFirstResponder];
}

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    if([textView.text isEqualToString:@"\n\n\n\n\n"])
        textView.text = @"";
    
    CGRect frame = [textView convertRect:textView.frame toView:textView.superview];
    frame.origin.y -= 30; // keybaord hieght - height;
    [self.scrollView scrollRectToVisible:frame animated:YES];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if([self.txtPlaceHolder isFirstResponder])
    {
        [self.view endEditing:YES];
    }
}

#pragma mark keyboard

- (void)keyboardWasShown:(NSNotification *)aNotification {
    if (self.keyboardShown)
        return;
    
    //the popover will resize for us
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return;
    
    self.keyboardShown = YES;    
    NSDictionary *info = [aNotification userInfo];
    NSValue *aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [aValue CGRectValue].size;
    
    CGRect scrollRect = self.scrollView.frame;
    scrollRect.size.height -= keyboardSize.height - 44.0f;
    [UIView animateWithDuration:0.15 animations:^{
        self.scrollView.frame = scrollRect;
    }];

}
- (void)keyboardWasHidden:(NSNotification *)aNotification {
    if (!self.keyboardShown)
        return;
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return;
    
    self.keyboardShown = NO;

    CGRect scrollRect = self.scrollView.frame;
    scrollRect.size.height = self.view.frame.size.height;
    self.scrollView.frame = scrollRect;

}

#pragma mark MKMapView

-(void)mapView:(RMMapView *)mapView didUpdateUserLocation:(RMUserLocation *)userLocation
{
    //do we have a valid location. if so center it
    if(CLLocationCoordinate2DIsValid(userLocation.location.coordinate))
    {
        mapView.centerCoordinate = userLocation.location.coordinate;
    }
    
    //animate the heading change
    /*[UIView animateWithDuration:0.2 animations:^{
        self.headingImage.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(userLocation.heading.trueHeading));
    }];*/
}

-(void)headingUpdated:(id)sender
{
    //animate the heading change
    if([[LocationManager sharedLocationManager] currentHeading])
    {
        [UIView animateWithDuration:0.2 animations:^{
            self.headingImage.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS([[LocationManager sharedLocationManager] currentHeading].trueHeading));
        }];
    }
}

#pragma mark submitting

-(BOOL)canSend
{
    if(!self.imageView.image)
        return NO;
    if(self.segmentAge.selectedSegmentIndex == UISegmentedControlNoSegment)
        return NO;
    if(self.segmentArea.selectedSegmentIndex == UISegmentedControlNoSegment)
        return NO;
   
    for(NSInteger i =0; i < 3; i++)
    {
        UITextField* txtField = (UITextField*)[self.scrollView viewWithTag:100+i];
        [txtField resignFirstResponder];
        if(![txtField.text length])
            return NO;
    }
    
    CLLocation* userLocation = [[LocationManager sharedLocationManager] currentLocation];
    
    CLLocation* otherLocation = nil;
    
    if ([[SyncController sharedController] isNetworkUp]) {
        otherLocation = [[[[RMVMapController sharedController] mapView] userLocation] location];
    }
    
    if(!userLocation && !otherLocation)
        return NO;
    
    return YES;
}

-(void)didTapSend:(id)sender
{
    //prevent uploading twice
    if(self.isUploading)
        return;
    
    [self.view endEditing:YES];
    
    
    if (![[LocationManager sharedLocationManager]locationServicesAreEnabled]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Please authorise access to your location through the Location Services options in Settings.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil] show];
        return;
    }
    
    CLLocation* userLocation = [[LocationManager sharedLocationManager] currentLocation];
    
    CLLocation* otherLocation = nil;
    
    if ([[SyncController sharedController] isNetworkUp]) {
        otherLocation = [[[[RMVMapController sharedController] mapView] userLocation] location];
    }
    
    //we have no idea where you are. lets tell you it is a gps issue not generic
    if(!userLocation && !otherLocation)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"We dont have a valid location, please move to an open area and check you GPS settings", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil] show];
        return;
    }
    
    if(![self canSend])
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"A valid photo, your age, knowledge of the area and phrases to describe your view are required", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil]show];
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    self.uploading = YES;
    
    //lets send to the server
    __weak __block RMVSubmitViewController* weakself = self;
    
    NSTimeInterval udid = [(self.postUDIDDate ? self.postUDIDDate : [NSDate date]) timeIntervalSince1970];
    
    [[ServerController sharedController] postViewWithParameters:[self postParameters] andWords:[self postWords] udid:udid withCompletion:^(NSError *error, id jsonResponse) {
        
        [MBProgressHUD hideAllHUDsForView:weakself.view animated:YES];
        weakself.uploading = NO;
        
        if(error)
        {
            //this is due to no network - our error
            if([[error domain] isEqualToString:@"com.ratemyview"])
            {
                NSString* sync = NSLocalizedString(@"Rate My View will auto upload this view once it has good network coverage. Please reopen Rate My View once reconnected.", nil);
                
                 [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Network found",nil) message:sync delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles: nil]show];
                
                [MBProgressHUD hideAllHUDsForView:weakself.view animated:NO];
                weakself.setup = NO;
                [weakself setupView];

                
                return;
            }
            
    
           UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:[NSString stringWithFormat:@"%@\nWould you like Rate My View to upload later?",[error localizedDescription]] delegate:self cancelButtonTitle:NSLocalizedString(@"No",nil) otherButtonTitles:NSLocalizedString(@"Yes",nil), nil];
            alert.tag = 99;
            [alert show];
        }
        else{
            if([jsonResponse isKindOfClass:[NSDictionary class]])
            {
                NSDictionary* object = (NSDictionary*)jsonResponse;
                
                NSString* error = [jsonResponse objectForKey:@"err"];
                error =  [error length] ? error : [jsonResponse objectForKey:@"error"];
                
                if([error length]){
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:error delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles: nil]show];
                    return;
                }
                
                RMVMapViewObject* map = [[RMVMapViewObject alloc] initWithDictionary:object];
                
                if(map)
                {
                    [[RMVMapController sharedController] addMapViewObject:map];

                    
                    RMMapView* mapView = [[RMVMapController sharedController] mapView];
                    [mapView setCenterCoordinate:map.location.coordinate animated:YES];

                    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"HidePopover" object:nil];
                        
                       RMVMapAnnotation* annotation = [[RMVMapController sharedController] annoationForView:map];
                        
                        if(annotation)
                        {
                           [[NSNotificationCenter defaultCenter] postNotificationName:kAnnotationSelected object:annotation];
                        }
                        
                        return;
                    }
                        
                    

                    UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
                    RMVInformationViewController* inform = [storyBoard instantiateViewControllerWithIdentifier:@"InfoSB"];
                    inform.selectedObject = map;
                    inform.selectedObjectIndex = NSNotFound; //so that you cant go forward or back
                    inform.title = NSLocalizedString(@"Success",nil);
                    UINavigationController* navcontroller = [[UINavigationController alloc] initWithRootViewController:inform];
                    
                    [weakself presentViewController:navcontroller animated:YES completion:^{
                        [MBProgressHUD hideAllHUDsForView:weakself.view animated:NO];
                        weakself.setup = NO;
                        [weakself setupView];
                    }];
                }
                else{
                     [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"Something went wrong, Please try again later",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles: nil]show];
                }
            }
            
        }
       
    }];
    
}

-(void)networkDown:(id)sender
{
    [self.tileSource cancelAllDownloads];
}

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    //we have asked to add it to the cache contreoller
    if(alertView.tag == 99 && (alertView.cancelButtonIndex != buttonIndex))
    {
        [[ServerController sharedController] savePostRequestWithParameters:[self postParameters] andWords:[self postWords]];
        [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
        self.setup = NO;
        [self setupView];

    }
}

-(NSDictionary*)postParameters
{
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    
    [options setObject:[NSString stringWithFormat:@"%u",(int)self.ratingControl.rating] forKey:@"rating"];
    
    if([self.txtPlaceHolder.text length] && ![self.txtPlaceHolder.text isEqualToString:@"\n\n\n\n\n"])
        [options setObject:self.txtPlaceHolder.text forKey:@"comments"];
    
    [options setObject:[@[@"0-18",@"19-24",@"25-44",@"45-64",@"65+"] objectAtIndex:self.segmentAge.selectedSegmentIndex]  forKey:@"age"];
    [options setObject:[@[@"Not at all",@"Not very well",@"Very well"] objectAtIndex:self.segmentArea.selectedSegmentIndex]  forKey:@"knowarea"];
    
    if(self.imageView.image)
    {
        NSData *imageData = UIImageJPEGRepresentation(self.imageView.image, 1.0);
        NSString *encodedString = [imageData base64Encoding];
        [options setObject:encodedString forKey:@"photo"];
    }
    
    
    CLLocation* userLocation = [[LocationManager sharedLocationManager] currentLocation];
    CLLocation* otherLocation = nil;
    
    if ([[SyncController sharedController] isNetworkUp]) {
        otherLocation = [[[[RMVMapController sharedController] mapView] userLocation] location];

    }
    
    
    
    CLHeading* heading = [[LocationManager sharedLocationManager] currentHeading] ? [[LocationManager sharedLocationManager] currentHeading] : [[[[RMVMapController sharedController] mapView]userLocation] heading];
    
    if(userLocation)
    {
        [options setObject:[NSString stringWithFormat:@"%f",userLocation.coordinate.latitude] forKey:@"lat"];
        [options setObject:[NSString stringWithFormat:@"%f",userLocation.coordinate.longitude] forKey:@"lng"];
        [options setObject:[NSString stringWithFormat:@"%f",heading ? heading.trueHeading : 0] forKey:@"heading"];
    }
    else if(otherLocation)
    {
        [options setObject:[NSString stringWithFormat:@"%f",otherLocation.coordinate.latitude] forKey:@"lat"];
        [options setObject:[NSString stringWithFormat:@"%f",otherLocation.coordinate.longitude] forKey:@"lng"];
        [options setObject:[NSString stringWithFormat:@"%f",heading ? heading.trueHeading : 0] forKey:@"heading"];
    }
    

    
    return options;
}

-(NSArray*)postWords
{
    NSMutableArray* words = [NSMutableArray array];
    
    for(NSInteger i =0; i < 3; i++)
    {
        UITextField* txtField = (UITextField*)[self.scrollView viewWithTag:100+i];
        if([txtField.text length])
        {
            [words addObject:txtField.text];
        }
    }
    
    return words;
}


-(void)didTapReload:(id)sender
{
    [self setupView];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
   
}

-(void)updateUploadedQueueText:(NSNotification*)note
{
    //have we been told of changes. if so get the number from that
    if(note && [note object])
    {
        if([[note object] isKindOfClass:[NSNumber class]])
        {
            NSInteger items = [(NSNumber*)[note object] integerValue];
            if(items >0)
            {
                self.lblSyncNumber.hidden = NO;
                self.lblSyncNumber.text = [NSString stringWithFormat:@"%u view(s) waiting to upload",(int)items];
            }
            else
                self.lblSyncNumber.hidden = YES;
            
            [self.scrollView layoutView];
            return;
        }
    }
    
    //else this prob our first load.
    //lets find it out oursleds
    if([[SyncController sharedController] numberOfItemsToSync] > 0)
    {
        self.lblSyncNumber.text = [NSString stringWithFormat:@"%u view(s) waiting to upload",(int)[[SyncController sharedController] numberOfItemsToSync]];
        self.lblSyncNumber.hidden = NO;
        return;
    }
    
    self.lblSyncNumber.hidden = YES;
    [self.scrollView layoutView];

}

@end
