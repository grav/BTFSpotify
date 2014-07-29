//
//  BTFAppDelegate.m
//  BTFSpotify
//
//  Created by CocoaPods on 07/29/2014.
//  Copyright (c) 2014 Mikkel Gravgaard. All rights reserved.
//

#import "BTFAppDelegate.h"
#import "BTFViewController.h"

@implementation BTFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    UIViewController *vc = [[BTFViewController alloc] init];
    self.window.rootViewController = vc;
    vc.view.frame = [[UIScreen mainScreen] applicationFrame];
    return YES;
}

@end
