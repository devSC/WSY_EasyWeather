//
//  AppDelegate.m
//  SimpleWeather
//
//  Created by Ryan Nystrom on 11/11/13.
//  Copyright (c) 2013 Ryan Nystrom. All rights reserved.
//

#import "AppDelegate.h"
#import "WXController.h"
#import <TSMessage.h>
@import CoreLocation;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[WXController alloc] init];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [TSMessage setDefaultViewController: self.window.rootViewController];

    
    /**
     *  
     */
    if (![CLLocationManager locationServicesEnabled]) {
        // location services is disabled, alert user
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DisabledTitle", @"DisabledTitle")
                                                                        message:NSLocalizedString(@"DisabledMessage", @"DisabledMessage")
                                                                       delegate:nil
                                                              cancelButtonTitle:NSLocalizedString(@"OKButtonTitle", @"OKButtonTitle")
                                                              otherButtonTitles:nil];
        [servicesDisabledAlert show];
    }
    
    return YES;
}

@end
