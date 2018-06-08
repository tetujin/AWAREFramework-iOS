//
//  AWAREFrameworkAppDelegate.m
//  AWAREFramework
//
//  Created by tetujin on 03/22/2018.
//  Copyright (c) 2018 tetujin. All rights reserved.
//

#import "AWAREFrameworkAppDelegate.h"

@implementation AWAREFrameworkAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    NSURL *fileURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.aware.ios"];
//    fileURL = [fileURL URLByAppendingPathComponent:@"aware.sqlite"];
//    self.sqliteFileURL = fileURL;
    
//    AWARECore * core = [AWARECore sharedCore];
//    core.isNeedBackgroundSensing = NO;
    
    // Override point for customization after application launch.
    
    [AWAREStudy.sharedStudy joinStudyWithURL:@"https://api.awareframework.com/index.php/webservice/index/1839/XHHyAIM4aUga" completion:^(NSArray *result, AwareStudyState state, NSError * _Nullable error) {
        [AWARESensorManager.sharedSensorManager addSensorsWithStudy:AWAREStudy.sharedStudy];
        [AWARESensorManager.sharedSensorManager setDebugToAllSensors:YES];
        [AWARESensorManager.sharedSensorManager startAllSensors];
    }];
    
    AWAREStudy * study = AWAREStudy.sharedStudy;
    [study setSetting:AWARE_PREFERENCES_STATUS_WIFI value:@"true"];
    
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [super applicationWillResignActive:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [super applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [super applicationWillEnterForeground:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [super applicationDidBecomeActive:application];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [super applicationWillResignActive:application];
}

@end
