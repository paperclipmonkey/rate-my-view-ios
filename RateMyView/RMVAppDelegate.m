//
//  RMVAppDelegate.m
//  RateMyView
//
//  Created by Daniel Anderton on 16/07/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import "RMVAppDelegate.h"
#import "SyncController.h"
@implementation RMVAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.iphoneStoryBoard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
    
    //ios 7 only
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        self.window.tintColor = [UIColor colorWithRed:0.000 green:0.502 blue:0.251 alpha:1.000];
    }
    
    [[SyncController sharedController] configure];
    
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[LocationManager sharedLocationManager] stopUpdatingCurrentLocation];
    [[SyncController sharedController] forceSave];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[LocationManager sharedLocationManager] startUpdatingCurrentLocation];
    [[SyncController sharedController] forceSave];

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
