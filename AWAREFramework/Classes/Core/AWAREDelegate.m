//
//  AWAREDelegate.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREDelegate.h"
#import "AWARECore.h"
#import "Debug.h"
#import "GoogleLogin.h"
#import "Fitbit.h"
#import "AWAREDebugMessageLogger.h"

@implementation AWAREDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // NSLog(@"Turn 'OFF' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [[AWARECore sharedCore] activate];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // NSLog(@"Turn 'ON' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    // NSLog(@"Turn 'OFF' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // NSLog(@"Turn 'OFF' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:-1];
}


////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////


/**
 This method is called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
 Saves changes in the application's managed object context before the application terminates.

 @param application UIApplication
 */
- (void)applicationWillTerminate:(UIApplication *)application {
    
    NSString * errorMsg = @"Application is stopped! Please reboot this app for logging your acitivties.";
    Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
    [debugSensor saveDebugEventWithText:errorMsg type:DebugTypeWarn label:@"stop"];
    [debugSensor startSyncDB];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:KEY_APP_TERMINATED];
    
    NSLog(@"Stop background task of AWARE....");
    NSLog(@"Turn 'ON' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {

    if([[url scheme] isEqualToString:@"fitbit"]){
        if([[url host] isEqualToString:@"logincallback"]){
            NSLog(@"Get a login call back");
            dispatch_async(dispatch_get_main_queue(), ^{
                // [Fitbit handleURL:url sourceApplication:sourceApplication annotation:annotation];
                Fitbit * fitbit = [[Fitbit alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
                [fitbit handleURL:url sourceApplication:sourceApplication annotation:annotation];
            });
            return YES;
        }else{
            NSLog(@"This is not a call back for fitbit login");
        }
        return YES;
    }else{
        return [[GIDSignIn sharedInstance] handleURL:url
                                   sourceApplication:sourceApplication
                                          annotation:annotation];
    }
    
}

@end
