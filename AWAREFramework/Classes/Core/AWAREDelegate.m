//
//  AWAREDelegate.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREDelegate.h"
#import "AWAREKeys.h"
#import "AWARECore.h"

// Sensors
#import "Debug.h"
#import "PushNotification.h"
#import "IOSESM.h"
#import "GoogleLogin.h"
#import <UserNotifications/UserNotifications.h>

#import "Fitbit.h"

@implementation AWAREDelegate
/////////////////////////////////////////////////////

@synthesize sharedAWARECore = _sharedAWARECore;
- (AWARECore *) sharedAWARECoreManager {
    if(_sharedAWARECore == nil){
        _sharedAWARECore = [[AWARECore alloc] init];
    }
    return _sharedAWARECore;
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
    
    //[ESM setAppearedState:NO];
    [IOSESM setAppearedState:NO];
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


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    //    [self saveContext];
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification){
        notification.repeatInterval = 0;
        notification.alertBody = @"Application is stopped! Please reboot this app for logging your acitivties.";
        notification.alertAction = @"Reboot";
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.applicationIconBadgeNumber = 1;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        
//        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeJSON];
//        [debugSensor saveDebugEventWithText:notification.alertBody type:DebugTypeWarn label:@"stop"];
//        [debugSensor syncAwareDB];
    }
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

- (void)application:(UIApplication *)application
performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
  completionHandler:(void (^)(BOOL))completionHandler{
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
            NSString *formattedDateString = [dateFormatter stringFromDate:[NSDate new]];
            
            completionHandler(UIBackgroundFetchResultNewData);

            NSLog(@"... Finish a background fetch");
        });
    });
}




- (void)application:(UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)())completionHandler {
    NSLog(@"Background OK");
    completionHandler();
    /*
     Store the completion handler. The completion handler is invoked by the view
     controller's checkForAllDownloadsHavingCompleted method (if all the download tasks have been
     completed).
     */
    //    self.backgroundSessionCompletionHandler = completionHandler;
}


///////////////////////////////////////
//  For Push Notification
///////////////////////////////////////

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSString *token = deviceToken.description;
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_DEBUG_STATE]){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"deviceToken: %@", token);
            [AWAREUtils sendLocalNotificationForMessage:token soundFlag:YES];
        });
    }
    
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
        
    PushNotification * pushNotification = [[PushNotification alloc] initWithAwareStudy:_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeSQLite];
    [pushNotification savePushNotificationDeviceToken:token];
    [pushNotification performSelector:@selector(startSyncDB) withObject:nil afterDelay:3];
    
    // NSLog(@"deviceToken: %@", token);
}

// Faile to get a DeviceToken
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"deviceToken error: %@", [error description]);
    
}


////////////////////////////
///////////////////////////

/**
 * Location Notification Event
 * If you receive local push notification, every time this method is called.
 * Also, each notification has their category ID. You can do some operation after get the notification.
 */
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    // Calendar and ESM plugin use this method
    
}


/**
 * Actions of LocalNotification.
 * After using the button on a notification in the lock or notifications screen, this method is called.
 */
- (void)application:(UIApplication *)application
handleActionWithIdentifier:(NSString *)identifier
forLocalNotification:(UILocalNotification *)notification
   withResponseInfo:(NSDictionary *)responseInfo
  completionHandler:(void (^)())completionHandler{
    // Calendar and ESM plugin use this method
  
    completionHandler();
}


/////////////////////////////////////////////////////////////////////////////
///// remote push notification

// This method is called then iOS receieved data by BackgroundFetch
- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"pushInfo in Background: %@", [userInfo description]);
    
    completionHandler(UIBackgroundFetchResultNoData);
}


/**
 * Notification handler for remote push notification
 */
- (void)application:(UIApplication *)application
handleActionWithIdentifier:(NSString *)identifier
forRemoteNotification:(NSDictionary *)userInfo
  completionHandler:(void (^)())completionHandler {
    
    // Get notification information from a userInfo variable
    
    if ([identifier isEqualToString:NotificationActionOneIdent]) {
        //        NSLog(@"You chose action 1.");
    }
    else if ([identifier isEqualToString:NotificationActionTwoIdent]) {
        //        NSLog(@"You chose action 2.");
    }
    if (completionHandler) {
        completionHandler();
    }
}


////////////////////////////////////////////
////////////////////////////////////////////

void exceptionHandler(NSException *exception) {
    // http://www.yoheim.net/blog.php?q=20130113
    NSLog(@"%@", exception.name);
    NSLog(@"%@", exception.reason);
    NSLog(@"%@", exception.callStackSymbols);
//    NSString * error = [NSString stringWithFormat:@"[%@] %@ , %@" , exception.name, exception.reason, exception.callStackSymbols];
    
//    Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[[AWAREStudy alloc] initWithReachability:YES] dbType:AwareDBTypeJSON];
//    [debugSensor saveDebugEventWithText:exception.debugDescription type:DebugTypeCrash label:exception.name];
//    [debugSensor syncAwareDB];
}



////////////////////////////////////////////////////////////////////////////////
//// For Google Login
///////////////////////////////////////////////////////////////////////////////


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {

    if([[url scheme] isEqualToString:@"aware-client"] || [[url scheme] isEqualToString:@"aware"]){
        if([[url host] isEqualToString:@"com.aware.ios.study.settings"]){
            NSDictionary *dict = [AWAREUtils getDictionaryFromURLParameter:url];
            if (dict != nil) {
                NSString * studyURL = [dict objectForKey:@"study_url"];
                if(studyURL != nil){
                    [_sharedAWARECore.sharedAwareStudy setStudyInformationWithURL:studyURL];
                }
            }
        }else if([[url host] isEqualToString:@"com.aware.ios.oauth2"]){
            
            // return [Fitbit handleURL:url sourceApplication:sourceApplication annotation:annotation];
            
        }
        return YES;
    }else if([[url scheme] isEqualToString:@"fitbit"]){
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

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations on signed in user here.
    NSString *userId = user.userID;                  // For client-side use only!
    // NSString *idToken = user.authentication.idToken; // Safe to send to the server
    NSString *name = user.profile.name;
    NSString *email = user.profile.email;
    
    if (name != nil ) {
        GoogleLogin * googleLogin = [[GoogleLogin alloc] initWithAwareStudy:_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeSQLite];
        [googleLogin setGoogleAccountWithUserId:userId name:name email:email];
    }
}


- (void)signIn:(GIDSignIn *)signIn
didDisconnectWithUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations when the user disconnects from app here.
    // ...
    NSLog(@"Google login error..");
}


//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
///////////////////////////////////////////
////////////////////////////////////////////


#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // NSLog(@"%@",[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory  inDomains:NSUserDomainMask] lastObject]);
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    if (_sqliteModelURL == nil) {
        _sqliteModelURL = [[NSBundle mainBundle] URLForResource:@"AWARE" withExtension:@"momd"];
    }
    // NSURL *modelURL = _sqliteModelURL; // [[NSBundle mainBundle] URLForResource:@"AWARE" withExtension:@"momd"];
//    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:_sqliteModelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    // NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    
    /*********** options  ***********/
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];
    if (_sqliteFileURL == nil) {
        _sqliteFileURL  = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
    }
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:_sqliteFileURL options:options error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            // abort();
        }
    }
}

@end
