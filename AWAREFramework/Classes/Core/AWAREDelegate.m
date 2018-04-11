//
//  AWAREDelegate.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>

#import "AWAREDelegate.h"
#import "AWAREKeys.h"
#import "AWARECore.h"
#import "Debug.h"
#import "PushNotification.h"
#import "IOSESM.h"
#import "GoogleLogin.h"
#import "Fitbit.h"
#import "AWAREDebugMessageLogger.h"

@implementation AWAREDelegate


/**
 A singleton instance of AWARECore
 */
@synthesize sharedAWARECore = _sharedAWARECore;
- (AWARECore *) sharedAWARECoreManager {
    if(_sharedAWARECore == nil){
        _sharedAWARECore = [[AWARECore alloc] init];
    }
    return _sharedAWARECore;
}

/**
 A singleton instance of CoreData (SQLite) handler
 */
@synthesize sharedCoreDataHandler = _sharedCoreDataHandler;
- (CoreDataHandler *) sharedCoreDataHandler{
    if (_sharedCoreDataHandler == nil) {
        _sharedCoreDataHandler = [[CoreDataHandler alloc] init];
    }
    return _sharedCoreDataHandler;
}

///////////////////////////////////////////////////////////////////////

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Set background fetch for updating debug information
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    [GIDSignIn sharedInstance].clientID = GOOGLE_LOGIN_CLIENT_ID;
    [GIDSignIn sharedInstance].delegate = self;
    
    // NSLog(@"Turn 'OFF' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    // Error Tacking
    NSSetUncaughtExceptionHandler(&exceptionHandler);
    
    
    _sharedAWARECore = [[AWARECore alloc] init];
    [_sharedAWARECore activate];

    
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
    
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Application is stopped! Please reboot this app for logging your acitivties.";
    content.body = @"Reboot";
    content.sound = [UNNotificationSound defaultSound];
    content.badge = @1;
    UNTimeIntervalNotificationTrigger * trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:@"ApplicationWillTerminate" content:content trigger:trigger];
    UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"%@",error.localizedDescription);
        }
    }];
    
    Debug * debugSensor = [[Debug alloc] initWithAwareStudy:_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeJSON];
    [debugSensor saveDebugEventWithText:content.title type:DebugTypeWarn label:@"stop"];
    [debugSensor startSyncDB];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:KEY_APP_TERMINATED];
    
    NSLog(@"Stop background task of AWARE....");
    NSLog(@"Turn 'ON' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
// https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIApplicationShortcutIcon_Class/#//apple_ref/c/tdef/UIApplicationShortcutIconType
// https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/iPhoneOSKeys.html#//apple_ref/doc/uid/TP40009252-SW36
// https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/Adopting3DTouchOniPhone/

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler{
    if([shortcutItem.type isEqualToString:@"com.awareframework.aware-client-ios.shortcut.manualupload"]){
        [_sharedAWARECore.sharedSensorManager syncAllSensorsForcefully];
    }
}



//////////////////////////////////////////////////////////////////////////
///   Backgroud Fetch
/// https://mobiforge.com/design-development/using-background-fetch-ios
///////////////////////////////////////////////////////////////////////////
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    /// NOTE: A background fetch method can work for 30 second. Also, the method is called randomly by OS.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Start a background fetch ...");
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
            // NSString *formattedDateString = [dateFormatter stringFromDate:[NSDate new]];
            
            completionHandler(UIBackgroundFetchResultNewData);

            NSLog(@"... Finish a background fetch");
        });
    });
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSString *token = deviceToken.description;
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_DEBUG_STATE]){
        dispatch_async(dispatch_get_main_queue(), ^{
            // NSLog(@"deviceToken: %@", token);
            // [AWAREUtils sendLocalNotificationForMessage:token soundFlag:YES];
        });
    }
    
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
        
    PushNotification * pushNotification = [[PushNotification alloc] initWithAwareStudy:_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeJSON];
    [pushNotification savePushNotificationDeviceToken:token];
}

// Faile to get a DeviceToken
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"deviceToken error: %@", [error description]);
    
}

// This method is called then iOS receieved data by BackgroundFetch
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"pushInfo in Background: %@", [userInfo description]);
    completionHandler(UIBackgroundFetchResultNoData);
}


void exceptionHandler(NSException *exception) {
    Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[[AWAREStudy alloc] initWithReachability:YES] dbType:AwareDBTypeJSON];
    [debugSensor saveDebugEventWithText:exception.debugDescription type:DebugTypeCrash label:exception.name];
    [debugSensor startSyncDB];
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
                Fitbit * fitbit = [[Fitbit alloc] initWithAwareStudy:self->_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeJSON];
                [fitbit handleURL:url sourceApplication:sourceApplication annotation:annotation];
            });
            return YES;
        }else{
            NSLog(@"This is not a Get a login call back");
        }
        return YES;
    }else{
        return [[GIDSignIn sharedInstance] handleURL:url
                                   sourceApplication:sourceApplication
                                          annotation:annotation];
    }
    
}

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    NSString *userId = user.userID;                  // For client-side use only!
    // NSString *idToken = user.authentication.idToken; // Safe to send to the server
    NSString *name = user.profile.name;
    NSString *email = user.profile.email;
    
    if (name != nil ) {
        GoogleLogin * googleLogin = [[GoogleLogin alloc] initWithAwareStudy:_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeSQLite];
        [googleLogin setGoogleAccountWithUserId:userId name:name email:email];
    }
}


- (void)signIn:(GIDSignIn *)signIn didDisconnectWithUser:(GIDGoogleUser *)user withError:(NSError *)error {
    // Perform any operations when the user disconnects from app here.
    NSLog(@"Google login error..");
}

@end
