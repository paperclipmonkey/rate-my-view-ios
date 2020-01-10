//
//  RMVFirstViewController.m
//  RateMyView
//
//  Created by Daniel Anderton on 16/07/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import "RMBMapViewController.h"
#import "RMVMapController.h"
#import "RMVInformationViewController.h"
#import "RMVMapAnnotation.h"
@interface RMBMapViewController () 
@property(nonatomic,getter = isSetup) BOOL setup;
@property(nonatomic,strong) UISegmentedControl* mapSegment;
@end

@implementation RMBMapViewController

- (void)viewDidLoad
{
    
    self.title = @"Around Me";
    
    //listen to notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupMap) name:kMapIsReady object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapAnnotationSelected:) name:kAnnotationSelected object:nil];

    
    //force start a second location manager
    [[LocationManager sharedLocationManager] startUpdatingCurrentLocation];

    //add the start location field
    UIBarButtonItem * btnLocation =  btnLocation = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"location-white.png"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapLocation:)];

    //if we are not ios 7
    if(!kIsiOS7)
    {
        [self.navigationController.navigationBar setTranslucent:YES];
        [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
    }
    
    UIBarButtonItem* btnReload = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(didTapReload:)];
    
    self.navigationItem.leftBarButtonItem = btnLocation;
    self.navigationItem.rightBarButtonItem = btnReload;
    
    //setup the map controller
    [[RMVMapController sharedController] setup];
    [[RMVMapController sharedController] setContainerController:self];

    //setup map type segment
   
    
    
    //
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

-(UISegmentedControl*)mapSegment
{
    if(!_mapSegment)
    {
        self.mapSegment = [[UISegmentedControl alloc] initWithItems:@[@"Terrain",@"Satellite"]];
        [self.mapSegment setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] boolForKey:kMapUserDefaultsKey] ? 1 : 0];
        [self.mapSegment addTarget:self action:@selector(didChangeMapType:) forControlEvents:UIControlEventValueChanged];
        [self.mapSegment sizeToFit];
        self.mapSegment.frame = CGRectMake(self.view.frame.size.width - 5 - self.mapSegment.frame.size.width, kIsiOS7 ? 70 : 50, self.mapSegment.frame.size.width, self.mapSegment.frame.size.height);
        
        self.mapSegment.tintColor = [[NSUserDefaults standardUserDefaults] boolForKey:kMapUserDefaultsKey] ? (kIsiOS7 ? [UIColor whiteColor] : [UIColor colorWithRed:0.000 green:0.502 blue:0.251 alpha:1.000]) : [UIColor colorWithRed:0.000 green:0.502 blue:0.251 alpha:1.000];
        
        //hide it as no point changing them if no map
        self.mapSegment.hidden = YES;
        [self.view addSubview:self.mapSegment];
    }
    
    return _mapSegment;
}

-(void)setupMap
{
    //recieved from the map notification
    RMMapView* map = [[RMVMapController sharedController] mapView];
    
    if(map)
    {
        self.mapSegment.hidden = NO;
        [map removeFromSuperview];
        map.frame = self.view.bounds;
        [self.view insertSubview:map atIndex:0];
    }

}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //we are not enabled tell the user
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
    //network is not up, iOS handles locations oddly when not using the locations
    if(![[RMVMapController sharedController] networkStatusUp])
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network Error", nil) message:NSLocalizedString(@"No internet connection", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil] show];
        return;
    }
    
    //if we have a valid location center the co ords
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
    //force reload the area
    [[RMVMapController sharedController] fetchNearByPoints];
}

-(void)didChangeMapType:(id)sender
{
    //tell the map controller we want a differnet type of map
    UISegmentedControl* segment = (UISegmentedControl*)sender;
    [[RMVMapController sharedController] changeMapToType:segment.selectedSegmentIndex];
    segment.tintColor = [[NSUserDefaults standardUserDefaults] boolForKey:kMapUserDefaultsKey] ? (kIsiOS7 ? [UIColor whiteColor] : [UIColor colorWithRed:0.000 green:0.502 blue:0.251 alpha:1.000]) : [UIColor colorWithRed:0.000 green:0.502 blue:0.251 alpha:1.000];
    
}

-(void)mapAnnotationSelected:(NSNotification*)note
{
    if(note && [note object])
    {
        //are we as expected
        if([[note object] isKindOfClass:[RMVMapAnnotation class]])
        {
            
            RMVMapAnnotation* selectedAnnotation = (RMVMapAnnotation*)[note object];
            
            UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
            RMVInformationViewController* inform = [storyBoard instantiateViewControllerWithIdentifier:@"InfoSB"];
            inform.selectedObject = selectedAnnotation.viewObject;
            inform.selectedObjectIndex = selectedAnnotation.viewIndex;
            UINavigationController* navcontroller = [[UINavigationController alloc] initWithRootViewController:inform];
            
            [self presentViewController:navcontroller animated:YES completion:NULL];
        }

    }
    
    

}

@end
