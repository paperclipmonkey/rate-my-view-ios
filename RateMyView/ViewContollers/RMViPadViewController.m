//
//  RMViPadViewController.m
//  RateMyView
//
//  Created by Daniel Anderton on 28/09/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import "RMViPadViewController.h"
#import "RMVSubmitViewController.h"
#import "RMVPopOverController.h"
#import "RMVMapAnnotation.h"
#import "RMVInformationViewController.h"
#import "RMVAboutViewController.h"
@interface RMViPadViewController () <UIPopoverControllerDelegate>

@property(nonatomic,getter = isSetup) BOOL setup;
@property(nonatomic,strong) RMVPopOverController* popOver;
@property(nonatomic,strong) RMVPopOverController* submitPopOver;

@end


@implementation RMViPadViewController

- (void)viewDidLoad
{
    
    self.title = @"Around Me";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupMap) name:kMapIsReady object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapAnnotationSelected:) name:kAnnotationSelected object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hidePopover:) name:@"HidePopover" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didTapNewPoint:) name:@"DidSwapToObject" object:nil];
    
    
    [[LocationManager sharedLocationManager] startUpdatingCurrentLocation];
    
    UIBarButtonItem * btnLocation =  btnLocation = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"location-white.png"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapLocation:)];
    
    if(!kIsiOS7)
    {
        [self.navigationController.navigationBar setTranslucent:YES];
        [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
        [self.toolbar setBarStyle:UIBarStyleBlack];

    }
    
    UIBarButtonItem* btnReload = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(didTapReload:)];
    
    self.navigationItem.leftBarButtonItem = btnLocation;
    self.navigationItem.rightBarButtonItem = btnReload;
    
    [[RMVMapController sharedController] setup];
    [[RMVMapController sharedController] setContainerController:self];
    
    [self.mapSegment setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] boolForKey:kMapUserDefaultsKey] ? 1 : 0];
    [self.mapSegment addTarget:self action:@selector(didChangeMapType:) forControlEvents:UIControlEventValueChanged];
   
    [super viewDidLoad];

	// Do any additional setup after loading the view, typically from a nib.
}

-(void)setupMap
{
    RMMapView* map = [[RMVMapController sharedController] mapView];
    if(map)
    {
        [map removeFromSuperview];
        map.frame = self.view.bounds;
        [self.view insertSubview:map atIndex:0];
    }
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (![[LocationManager sharedLocationManager]locationServicesAreEnabled]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Please authorise access to your location through the Location Services options in Settings.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil] show];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark user actions
-(void)didTapLocation:(id)sender
{
    //no network map is hidden so cant center
    if(![[RMVMapController sharedController] networkStatusUp])
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network Error", nil) message:NSLocalizedString(@"No internet connection", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil] show];
        return;
    }
    
    if([[LocationManager sharedLocationManager] currentLocation] && CLLocationCoordinate2DIsValid([[[LocationManager sharedLocationManager] currentLocation] coordinate]))
    {
        [[[RMVMapController sharedController] mapView] setCenterCoordinate:[[[LocationManager sharedLocationManager] currentLocation] coordinate] animated:YES];
    }
    else{
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Invalid Location, Please check location services are enabled or move to an open area", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil] show];
    }
}

-(void)didTapReload:(id)sender
{
    [[RMVMapController sharedController] fetchNearByPoints];
}

-(void)didChangeMapType:(id)sender
{
    UISegmentedControl* segment = (UISegmentedControl*)sender;
    [[RMVMapController sharedController] changeMapToType:segment.selectedSegmentIndex];
}

-(IBAction)didTapAddView:(id)sender
{

    if(self.popOver && [self.popOver isPopoverVisible])
       [self.popOver dismiss];
    
    self.popOver = nil;
    
    [self.submitPopOver dismiss];
    
    
    //lets keep this around incase they tap away, we dont want them to loose there stuff;
    if(!self.submitPopOver){
        UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
        RMVSubmitViewController* inform = [storyBoard instantiateViewControllerWithIdentifier:@"SubmitView"];
        inform.title = NSLocalizedString(@"Add My View",nil);
        UINavigationController* navcontroller = [[UINavigationController alloc] initWithRootViewController:inform];
        
        self.submitPopOver = [[RMVPopOverController alloc] initWithContentViewController:navcontroller];
    }
    
    self.submitPopOver.presentionBarItem = (UIBarButtonItem*)sender;
    self.submitPopOver.presentionArrow = UIPopoverArrowDirectionDown;
    self.submitPopOver.delegate = nil;
    self.submitPopOver.presentationView = self;
    self.submitPopOver.autoRotate = YES;
    if(self.view.window)
        [self.submitPopOver presentPopoverFromBarButtonItem:(UIBarButtonItem*)sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    
    
}

-(IBAction)didTapAbout:(id)sender
{
    //AboutView
    if(self.popOver && [self.popOver isPopoverVisible])
        [self.popOver dismiss];
    
    self.popOver = nil;
    [self.submitPopOver dismiss];
    
    UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
    RMVAboutViewController* inform = [storyBoard instantiateViewControllerWithIdentifier:@"AboutView"];
    UINavigationController* navcontroller = [[UINavigationController alloc] initWithRootViewController:inform];
    
    self.popOver = [[RMVPopOverController alloc] initWithContentViewController:navcontroller];
    self.popOver.presentionBarItem = (UIBarButtonItem*)sender;
    self.popOver.presentionArrow = UIPopoverArrowDirectionDown;
    self.popOver.delegate = nil;
    self.popOver.presentationView = self;
    self.popOver.autoRotate = YES;
    if(self.view.window)
        [self.popOver presentPopoverFromBarButtonItem:(UIBarButtonItem*)sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    [self.popOver dismiss];
    self.popOver = nil;
    [self.submitPopOver dismiss];
}


-(void)mapAnnotationSelected:(NSNotification*)note
{
    if(note && [note object])
    {
        if([[note object] isKindOfClass:[RMVMapAnnotation class]])
        {
            
            RMVMapAnnotation* selectedAnnotation = (RMVMapAnnotation*)[note object];
            CGPoint point = [[[RMVMapController sharedController] mapView] coordinateToPixel:selectedAnnotation.viewObject.location.coordinate];

            //this offsets it on the map to look good
            point.y += 14;
            
            UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
            RMVInformationViewController* inform = [storyBoard instantiateViewControllerWithIdentifier:@"InfoSB"];
            inform.selectedObject = selectedAnnotation.viewObject;
            inform.selectedObjectIndex = selectedAnnotation.viewIndex;
            
            
            if(self.popOver)
                [self.popOver dismiss];
            
            self.popOver = nil;
            
            [self.submitPopOver dismiss];
            
            self.popOver = [[RMVPopOverController alloc] initWithContentViewController:inform];
            self.popOver.presentationRect = CGRectMake(point.x, point.y, 1, 1);
            self.popOver.presentionArrow = UIPopoverArrowDirectionDown;
            self.popOver.delegate = nil;
            self.popOver.presentationView = self;
            self.popOver.autoRotate = YES;
            if(self.view.window)
                [self.popOver presentPopoverFromRect:self.popOver.presentationRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
        }
        
    }
    
}

-(void)hidePopover:(id)sender
{
    if(self.popOver)
        [self.popOver dismiss];
    
    self.popOver = nil;
    [self.submitPopOver dismiss];

}

-(void)didTapNewPoint:(NSNotification*)note
{
    if(note && [note object])
    {
        if([[note object] isKindOfClass:[RMVMapViewObject class]])
        {
            if(self.popOver)
                [self.popOver dismiss];
            
            
            [self.submitPopOver dismiss];
            
            RMVMapViewObject* selectedView = (RMVMapViewObject*)[note object];
            
            [[[RMVMapController sharedController] mapView] setCenterCoordinate:selectedView.location.coordinate animated:NO];
            
            CGPoint point = [[[RMVMapController sharedController] mapView] coordinateToPixel:selectedView.location.coordinate];
            
            //this offsets it on the map to look good
            point.y += 14;
            
            self.popOver.presentationRect = CGRectMake(point.x, point.y, 1, 1);

            if(self.view.window)
                [self.popOver presentPopoverFromRect:self.popOver.presentationRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            

        }
        
    }

}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    
}


@end
