//
//  AWARECoreManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARECore.h"
#import "Debug.h"
#import "AWAREDebugMessageLogger.h"
#import "AWAREStudy.h"
#import <ifaddrs.h>
#import <net/if.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <UserNotifications/UserNotifications.h>
#import <ESMSchedule.h>

static AWARECore * sharedCore;

@implementation AWARECore{
    LocationAPIAuthorizationCompletionHandler completionHandler;
}

+ (AWARECore * _Nonnull) sharedCore{
    @synchronized(self){
        if (!sharedCore){
            sharedCore = [[AWARECore alloc] init];
        }
    }
    return sharedCore;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedCore == nil) {
            sharedCore= [super allocWithZone:zone];
            return sharedCore;
        }
    }
    return nil;
}

- (instancetype)init{
    self = [super init];
    if(self != nil){
        // background sensing
        _isNeedBackgroundSensing = YES;
        
        /// Set defualt settings
        AWAREStudy * study = [AWAREStudy sharedStudy];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if (![userDefaults boolForKey:@"aware_inited"]) {
            [study setDebug:NO];
            [study setAutoDBSyncOnlyWifi:YES];
            [study setAutoDBSyncOnlyBatterChargning:YES];
            [study setAutoDBSyncIntervalWithMinutue:60];
            [study setAutoDBSync:YES];
            [study setMaximumByteSizeForDBSync:1000*100];
            [study setMaximumNumberOfRecordsForDBSync:1000];
            [study setCleanOldDataType:cleanOldDataTypeDaily];
            [study setUIMode:AwareUIModeNormal];
            [study setDBType:AwareDBTypeSQLite];
            [userDefaults setBool:YES forKey:@"aware_inited"];
        }
        
        _sharedLocationManager = [[CLLocationManager alloc] init];
        _sharedLocationManager.delegate = self;
    }
    return self;
}


- (void) activate {
    [self deactivate];
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    
    // Error Tacking
    NSSetUncaughtExceptionHandler(&exceptionHandler);
    
    /**
     * Start a location sensor for background sensing.
     * On the iOS, we have to turn on the location sensor
     * for using application in the background.
     */
    if (_isNeedBackgroundSensing) {
        [self startBaseLocationSensor];
    }
    
    AWAREStudy * study = [AWAREStudy sharedStudy];
    
    // start sensors
    AWARESensorManager * sensorManager = [AWARESensorManager sharedSensorManager];
    [sensorManager startAllSensors];
    if([study isAutoDBSync]){
        double uploadInterval = [study getAutoDBSyncIntervalSecond];
        [sensorManager startAutoSyncTimerWithIntervalSecond:uploadInterval];
    }
    
    // Compliance checker
    NSDate* dailyCheckComplianceTime = [AWAREUtils getTargetNSDate:[NSDate new] hour:0 minute:0 second:0 nextDay:YES];
    _complianceTimer = [[NSTimer alloc] initWithFireDate:dailyCheckComplianceTime
                                                interval:60*60*6 //1 hour
                                                  target:self
                                                selector:@selector(checkCompliance)
                                                userInfo:nil
                                                 repeats:YES];
    NSRunLoop *loop = [NSRunLoop currentRunLoop];
    [loop addTimer:_complianceTimer forMode:NSRunLoopCommonModes];

    // Battery Monitor
    if([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0){
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                  selector:@selector(checkCompliance)
                                                      name:NSProcessInfoPowerStateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector( checkCompliance)
                                                     name:UIApplicationBackgroundRefreshStatusDidChangeNotification
                                                   object:nil];
        
    }
    
    // battery state trigger
    // Set a battery state change event to a notification center
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changedBatteryState:)
                                                 name:UIDeviceBatteryStateDidChangeNotification object:nil];

    // register to observe notifications from the store
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector (ubiquitousDataDidChange:)
                                                 name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object: [NSUbiquitousKeyValueStore defaultStore]];
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];

}

- (void) changedBatteryState:(id) sender{
    if ([[AWAREStudy sharedStudy] isAutoDBSync]){
        NSInteger batteryState = [UIDevice currentDevice].batteryState;
        if (batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull) {
            Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
            [debugSensor saveDebugEventWithText:@"[Uploader] The battery is charging. AWARE iOS start to upload sensor data." type:DebugTypeInfo label:@""];
            [[AWARESensorManager sharedSensorManager] syncAllSensors];
            [[AWARESensorManager sharedSensorManager] runBatteryStateChangeEvents];
        }
    }
}

- (void)ubiquitousDataDidChange:(NSNotification *)notification
{
//     NSDictionary *dict = [notification userInfo];
//    NSLog(@"[iCloud] Update : %@", dict);
//    NSArray *keys = [dict objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
//    NSUbiquitousKeyValueStore *ukvs = [NSUbiquitousKeyValueStore defaultStore];
//    for (NSString *key in keys) {
//        NSUInteger index = [ukvs longLongForKey:key];
//        // NSLog(@"index:%d", index);
//    }
}

- (void) deactivate{
    [[AWARESensorManager sharedSensorManager] stopAllSensors];
    [_sharedLocationManager stopUpdatingLocation];
    [[AWARESensorManager sharedSensorManager] stopAutoSyncTimer];
    [_dailyUpdateTimer invalidate];
    [_complianceTimer invalidate];
    
    if([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0){
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSProcessInfoPowerStateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationBackgroundRefreshStatusDidChangeNotification object:nil];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object: [NSUbiquitousKeyValueStore defaultStore]];

}

///////////////////////////////////////////////////////////////////////////////////

void exceptionHandler(NSException *exception) {
    Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[[AWAREStudy alloc] initWithReachability:YES] dbType:AwareDBTypeJSON];
    [debugSensor saveDebugEventWithText:exception.debugDescription type:DebugTypeCrash label:exception.name];
    [debugSensor startSyncDB];
}


////////////////////////////////////////////////////////////////////////////////////

/**
 * This method is an initializers for a location sensor.
 * On the iOS, we have to turn on the location sensor
 * for using application in the background.
 * And also, this sensing interval is the most low level.
 */
- (void) startBaseLocationSensor {
    CLAuthorizationStatus state = [CLLocationManager authorizationStatus];
    if(state == kCLAuthorizationStatusAuthorizedAlways){
        if (_sharedLocationManager == nil) {
            _sharedLocationManager = [[CLLocationManager alloc] init];
            _sharedLocationManager.delegate = self;
        }
        _sharedLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        _sharedLocationManager.pausesLocationUpdatesAutomatically = NO;
        _sharedLocationManager.activityType = CLActivityTypeOther;
        
        if ([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0) {
            /// After iOS 9.0, we have to set "YES" for background sensing.
            _sharedLocationManager.allowsBackgroundLocationUpdates = YES;
        }
        [_sharedLocationManager startUpdatingLocation];
        [_sharedLocationManager startMonitoringSignificantLocationChanges];
    }else{
        NSLog(@"[NOTE] Background location sensing is not allowed. Please call sendBackgroundSensingRequest first if you need to collect activities in the background.");
    }
}

/**
 * The method is called by location sensor when the device location is changed.
 */
- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    bool appTerminated = [userDefaults boolForKey:KEY_APP_TERMINATED];
    if (appTerminated) {
        NSString * message = @"AWARE client iOS is rebooted";
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        bool debugMode = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        if(debugMode){
            // [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
        }
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
        [debugSensor saveDebugEventWithText:message type:DebugTypeInfo label:@""];
        [userDefaults setBool:NO forKey:KEY_APP_TERMINATED];
    }else{
        // [AWAREUtils sendLocalNotificationForMessage:@"" soundFlag:YES];
        //NSLog(@"Base Location Sensor.");
//        if ([userDefaults boolForKey: SETTING_DEBUG_STATE]) {
//            for (CLLocation * location in locations) {
//                NSLog(@"%@",location.description);
//                
//            }
//        }
    }
}

- (void) requestBackgroundSensing{
    NSLog(@"Please use -requestPermissionForBackgroundSensing instead of -requestBackgroundSensing");
    [self requestPermissionForBackgroundSensing];
}

- (void) requestNotification:(UIApplication *) application{
    NSLog(@"Please use -requestPermissionForPushNotification instead of requestNotification:");
    [self requestPermissionForPushNotification:application];
}

/////////////
- (void) requestPermissionForPushNotification {
    [self requestPermissionForPushNotification:[UIApplication sharedApplication]];
}

- (void) requestPermissionForPushNotification:(UIApplication*)application{
    [application registerForRemoteNotifications];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
                              // Enable or disable features based on authorization.
                              
                          }];
}


- (void) requestPermissionForBackgroundSensing{
    [self requestPermissionForBackgroundSensingWithCompletion:nil];
}
                                                              
- (void) requestPermissionForBackgroundSensingWithCompletion:(LocationAPIAuthorizationCompletionHandler)completionHandler{
    self->completionHandler = completionHandler;
    CLAuthorizationStatus state = [CLLocationManager authorizationStatus];
    if(state != kCLAuthorizationStatusAuthorizedAlways){
        if (_sharedLocationManager != nil){
            [_sharedLocationManager requestAlwaysAuthorization];
        }
    }
}



- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if(status == kCLAuthorizationStatusNotDetermined ){
        ////////////////// kCLAuthorizationStatusRestricted ///////////////////////
    }else if (status == kCLAuthorizationStatusRestricted ){
        ///////////////// kCLAuthorizationStatusDenied //////////////////////////////
    }else if (status == kCLAuthorizationStatusDenied ){
        //////////////////// kCLAuthorizationStatusAuthorized /////////////////////////
    }else if (status == kCLAuthorizationStatusAuthorizedAlways){
        /////////////////// kCLAuthorizationStatusAuthorizedWhenInUse ///////////////////
        if(_isNeedBackgroundSensing){
            // [self activate];
            [self startBaseLocationSensor];
        }
        if (self->completionHandler) {
            self->completionHandler();
        }
        
    }else if (status == kCLAuthorizationStatusAuthorizedWhenInUse){
        //////////////////// Unknown ///////////////////////////////
    }else {
        
    }
}





////////////////////////////////////////////////////////
////////////////////////////////////////////////////////



/**
 * Start data sync with all sensors in the background when the device is started a battery charging.
 */
//- (void) changedBatteryState:(id) sender {

//}



////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////

- (void) checkCompliance {
    [self checkComplianceWithViewController:nil];
}

- (void) checkComplianceWithViewController:(UIViewController *)viewController{
    [self checkComplianceWithViewController:viewController showDetail:NO];
}

- (void) checkComplianceWithViewController:(UIViewController *)viewController showDetail:(BOOL)detail{
    if(![self checkLocationSensorWithViewController:viewController showDetail:detail]) return;
    if(![self checkBackgroundAppRefreshWithViewController:viewController showDetail:detail]) return;
    if(![self checkStorageUsageWithViewController:viewController showDetail:detail]) return;
    if(![self checkWifiStateWithViewController:viewController showDetail:detail]) return;
    if(![self checkLowPowerModeWithViewController:viewController showDetail:detail]) return;
    if(![self checkNotificationSettingWithViewController:viewController showDetail:detail]) return;
    
    if (viewController!=nil && detail) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Your settings are correct"
                                                                       message:@"Thank you for your copperation."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Close"
                                                                style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  
                                                              }];
        [alert addAction:cancelAction];
        if (detail) {
            [viewController presentViewController:alert animated:YES completion:nil];
        }
    }
}

//////////////////////////////////////////////////////////////////

- (bool)checkLocationSensorWithViewController:(UIViewController *) viewController showDetail:(BOOL)detail{
    bool state = NO;
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        
        NSString *title;
        title = (status == kCLAuthorizationStatusDenied) ? @"Location services are off" : @"Background location is not enabled";
        NSString *message = @"To track your daily activity, you have to turn on 'Always' in the Location Services Settings.";

        
        if([AWAREUtils isForeground]  && viewController != nil ){
            // To track your daily activity, AWARE client iOS needs access to your location in the background.
            // To use background location you must turn on 'Always' in the Location Services Settings
            
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      // Send the user to the Settings for this app
                                                                      NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                                      // if([AWAREUtils getCurrentOSVersionAsFloat] < 10.0f ){
                                                                      //    settingsURL = [NSURL URLWithString:@"prefs:root=LOCATION_SERVICES"];
                                                                      // }
                                                                      // [[UIApplication sharedApplication] openURL:settingsURL];
                                                                      [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:^(BOOL success) {
                                                                          
                                                                      }];
                                                                  }];
            UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                    style:UIAlertActionStyleCancel
                                                                  handler:^(UIAlertAction * _Nonnull action) {
                                                                      
                                                                  }];
            [alert addAction:defaultAction];
            [alert addAction:cancelAction];
            if (detail) {
                [viewController presentViewController:alert animated:YES completion:nil];
            }
        }else{
            /*
            [AWAREUtils sendLocalNotificationForMessage:message
                                                  title:title
                                              soundFlag:NO
                                               category:nil
                                               fireDate:[NSDate new]
                                         repeatInterval:0
                                               userInfo:nil
                                        iconBadgeNumber:1];
             */
        }
        
//        DebugTypeUnknown = 0, DebugTypeInfo = 1, DebugTypeError = 2, DebugTypeWarn = 3, DebugTypeCrash = 4
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
        [debugSensor saveDebugEventWithText:@"[compliance] Location Services are OFF or Background Location is NOT enabled" type:DebugTypeWarn label:title];
        [debugSensor startSyncDB];
    }
    // The user has not enabled any location services. Request background authorization.
    else if (status == kCLAuthorizationStatusNotDetermined) {
        // [self startBaseLocationSensor];
    }else{
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
        [debugSensor saveDebugEventWithText:@"[compliance] Location Services is enabled" type:DebugTypeInfo label:@""];
        state = YES;
    }
    // status == kCLAuthorizationStatusAuthorizedAlways
    return state;
}

///////////////////////////////////////////////////////

- (bool) checkBackgroundAppRefreshWithViewController:(UIViewController *) viewController  showDetail:(BOOL)detail{
    bool state = NO;
    
    //    UIBackgroundRefreshStatusRestricted, //< unavailable on this system due to device configuration; the user cannot enable the feature
    //    UIBackgroundRefreshStatusDenied,     //< explicitly disabled by the user for this application
    //    UIBackgroundRefreshStatusAvailable   //< enabled for this application
    UIBackgroundRefreshStatus backgroundRefreshStatus = [UIApplication sharedApplication].backgroundRefreshStatus;
    if(backgroundRefreshStatus == UIBackgroundRefreshStatusDenied || backgroundRefreshStatus == UIBackgroundRefreshStatusRestricted){
        
        NSString *title = @"Background App Refresh service is Restricted or Denied"; // : @"Background location is not enabled";
        NSString *message = @"To track your daily activity, you have to allow the 'Background App Refresh' service in the General Settings.";
        if([AWAREUtils isForeground]  && viewController!=nil ){
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      // Send the user to the Settings for this app
                                                                      NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                                      // if([AWAREUtils getCurrentOSVersionAsFloat] < 10.0f ){
                                                                      //    settingsURL = [NSURL URLWithString:@"prefs:root=General&path=AUTO_CONTENT_DOWNLOAD"];
                                                                      // }
                                                                      [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:^(BOOL success) {
                                                                          
                                                                      }];
                                                                      // [[UIApplication sharedApplication] openURL:settingsURL];
                                                                  }];
            UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                    style:UIAlertActionStyleCancel
                                                                  handler:^(UIAlertAction * _Nonnull action) {
                
                                                                }];
                                            
            [alert addAction:cancelAction];
            [alert addAction:defaultAction];
            if(detail){
                 [viewController presentViewController:alert animated:YES completion:nil];
            }
        }else{
            // [AWAREUtils sendLocalNotificationForMessage:@"Please allow the 'Background App Refresh' service in the Settings->General." soundFlag:NO];
        }
        
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
        [debugSensor saveDebugEventWithText:@"[compliance] Background App Refresh service is Restricted or Denied" type:DebugTypeWarn label:@""];
//        [debugSensor.storage allowsDateUploadWithoutBatteryCharging];
//        [debugSensor.storage allowsCellularAccess];
        // [debugSensor syncAwareDBInBackground];
    } else if(backgroundRefreshStatus == UIBackgroundRefreshStatusAvailable){
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
        [debugSensor saveDebugEventWithText:@"[compliance] Background App Refresh service is Allowed" type:DebugTypeInfo label:@""];
        state = YES;
    }
    return state;
}

- (bool) checkNotificationSettingWithViewController:(UIViewController *) viewController  showDetail:(BOOL)detail{
    bool state = NO;
    // authorizationStatus;
    // soundSetting __TVOS_PROHIBITED;
    // badgeSetting __WATCHOS_PROHIBITED;
    // alertSetting __TVOS_PROHIBITED;
    // notificationCenterSetting __TVOS_PROHIBITED;
    // lockScreenSetting __TVOS_PROHIBITED __WATCHOS_PROHIBITED;
    // carPlaySetting __TVOS_PROHIBITED __WATCHOS_PROHIBITED;
    // alertStyle __TVOS_PROHIBITED __WATCHOS_PROHIBITED;
    // showPreviewsSetting  __IOS_AVAILABLE(11.0)
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        switch (settings.authorizationStatus) {
            case UNAuthorizationStatusAuthorized:
                break;
            case UNAuthorizationStatusDenied:
            case UNAuthorizationStatusNotDetermined:{
                NSString * title = @"Notification service is not permitted.";
                NSString * message = @"To send important notifications, please allow the 'Notification' service in the General Settings.";
                
                if([AWAREUtils isForeground]  && viewController!=nil ){
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                                   message:message
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault
                                                                          handler:^(UIAlertAction * action) {
                                                                              // Send the user to the Settings for this app
                                                                              NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                                              // if([AWAREUtils getCurrentOSVersionAsFloat] < 10.0f ){
                                                                              //    settingsURL = [NSURL URLWithString:@"prefs:root=Notifications"];
                                                                              // }
                                                                              [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:^(BOOL success) {
                                                                                  
                                                                              }];
                                                                              
                                                                              // [[UIApplication sharedApplication] openURL:settingsURL];
                                                                          }];
                    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                            style:UIAlertActionStyleCancel
                                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                                              
                                                                          }];
                    [alert addAction:defaultAction];
                    [alert addAction:cancelAction];
                    if(detail){
                        [viewController presentViewController:alert animated:YES completion:nil];
                    }
                }else{
                    // [AWAREUtils sendLocalNotificationForMessage:@"Please allow the 'Notification' service in the Settings.app->Notification->Allow Notifications." soundFlag:NO];
                }
                Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
                [debugSensor saveDebugEventWithText:@"[compliance] Notification Service is NOT permitted" type:DebugTypeWarn label:@""];
                [debugSensor startSyncDB];
                break;
            }
            case UNAuthorizationStatusProvisional:
                
                break;
        }
//        switch (settings.lockScreenSetting) {
//            case UNNotificationSettingEnabled:
//                break;
//            case UNNotificationSettingDisabled:
//                break;
//            case UNNotificationSettingNotSupported:
//                break;
//            default:
//                break;
//        }
    }];
    return state;
}

///////////////////////////////////////////////////////////////

- (bool) checkStorageUsageWithViewController:(UIViewController *) viewController  showDetail:(BOOL)detail{
    bool state = YES;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:nil];
    if (dictionary) {
        int GiB = 1024*1024*1024;
        float free = [[dictionary objectForKey: NSFileSystemFreeSize] floatValue]/GiB;
        float total = [[dictionary objectForKey: NSFileSystemSize] floatValue]/GiB;
//        NSLog(@"Used: %.3f", total-free);
//        NSLog(@"Space: %.3f", free);
//        NSLog(@"Total: %.3f", total);
        float percentage = free/total * 100.0f;
        NSString * event = [NSString stringWithFormat:@"[compliance] TOTAL:%.3fGB, USED:%.3fGB, FREE:%.3fGB", total, total-free, free];
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
        [debugSensor saveDebugEventWithText:event type:DebugTypeInfo label:@""];
        // [debugSensor syncAwareDBInBackground];
        if(percentage < 5 && detail){ // %
            state = NO;
            NSString * title = @"Please sync your local database manually!";
            NSString * message = [NSString stringWithFormat:@"You are using  %.3f GB ", free];
            if([AWAREUtils isForeground]){
                UIAlertController * alertContoller = [UIAlertController alertControllerWithTitle:title
                                                                                         message:message preferredStyle:UIAlertControllerStyleAlert];
                [alertContoller addAction:[UIAlertAction actionWithTitle:@"start manual sync" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [[AWARESensorManager sharedSensorManager] syncAllSensors];
                }]];
                [alertContoller addAction:[UIAlertAction actionWithTitle:@"close" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                }]];
            }else{
                // [AWAREUtils sendLocalNotificationForMessage:message soundFlag:NO];
            }
        }
    }
    return state;
}


- (bool) checkLowPowerModeWithViewController:(UIViewController *) viewController showDetail:(BOOL)detail{
    
    bool state = NO;
    
    if([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0){
        
        NSString * title = @"Please turn off the **Low Power Mode** for tracking your daily activites.";
        NSString * message = @"";
        if ([NSProcessInfo processInfo].lowPowerModeEnabled ) {
            
            // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=BATTERY_USAGE"]];
            if([AWAREUtils isForeground]){
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                          NSURL * settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                                          NSLog(@"%@", UIApplicationOpenSettingsURLString);
                                                                          // settingsURL = [NSURL URLWithString:@"prefs:"];
                                                                          
                                                                          // if([AWAREUtils getCurrentOSVersionAsFloat] < 10.0f ){
                                                                          //    settingsURL = [NSURL URLWithString:@"prefs:root=BATTERY_USAGE"];
                                                                          // }
                                                                          [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:^(BOOL success) {
                                                                              
                                                                          }];

                                                                          // [[UIApplication sharedApplication] openURL:settingsURL];
                                                                          
                                                                      }];
                UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                        style:UIAlertActionStyleCancel
                                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                                          
                                                                      }];
                [alert addAction:defaultAction];
                [alert addAction:cancelAction];
                if(detail){
                    [viewController presentViewController:alert animated:YES completion:nil];
                }
            }else{
                // [AWAREUtils sendLocalNotificationForMessage:title soundFlag:NO];

            }
            
        
            Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
            [debugSensor saveDebugEventWithText:@"[compliance] Low Power Mode is ON" type:DebugTypeWarn label:@""];
            [debugSensor startSyncDB];
        }else{
            Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
            [debugSensor saveDebugEventWithText:@"[compliance] Low Power Mode is OFF" type:DebugTypeInfo label:@""];
            state = YES;
        }
    }
    return state;
}

///////////////////////////////////////////////////////////////

- (bool) checkWifiStateWithViewController:(UIViewController *) viewController  showDetail:(BOOL)detail{
    if(![self isWiFiEnabled]){
        
        NSString * title = @"Please turn on WiFi!";
        NSString * message = @"WiFi is turned off now. AWARE needs the wifi network for data uploading. Please keep turn on the WiFi during your study.";
        
        if ([AWAREUtils isForeground] && viewController!=nil) {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
//                                                                       Send the user to the Settings for this app
                                                                      NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                                      // if([AWAREUtils getCurrentOSVersionAsFloat] < 10.0f ){
                                                                      //    settingsURL = [NSURL URLWithString:@"prefs:root=WIFI"];
                                                                      // }
                                                                      [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:^(BOOL success) {
                                                                          
                                                                      }];
                                                                      // [[UIApplication sharedApplication] openURL:settingsURL];
                                                                      
                                                                  }];
            UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                    style:UIAlertActionStyleCancel
                                                                  handler:^(UIAlertAction * _Nonnull action) {
                                                                      
                                                                  }];
            [alert addAction:defaultAction];
            [alert addAction:cancelAction];
            if(detail){
                [viewController presentViewController:alert animated:YES completion:nil];
            }
        }else{
            // [AWAREUtils sendLocalNotificationForMessage:@"Please turn on WiFi! AWARE client needs WiFi for data uploading." soundFlag:NO];
        }
        
        
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
        [debugSensor saveDebugEventWithText:@"[compliance] WiFi is OFF" type:DebugTypeWarn label:@""];
        [debugSensor startSyncDB];
    }else{
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeJSON];
        [debugSensor saveDebugEventWithText:@"[compliance] WiFi is On" type:DebugTypeInfo label:@""];
    }
    
    return [self isWiFiEnabled];
}


- (BOOL) isWiFiEnabled {
    
    NSCountedSet * cset = [NSCountedSet new];
    
    struct ifaddrs *interfaces;
    
    if( ! getifaddrs(&interfaces) ) {
        for( struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
            if ( (interface->ifa_flags & IFF_UP) == IFF_UP ) {
                [cset addObject:[NSString stringWithUTF8String:interface->ifa_name]];
            }
        }
    }
    
    return [cset countForObject:@"awdl0"] > 1 ? YES : NO;
}

- (NSDictionary *) wifiDetails {
    return (__bridge NSDictionary *) CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex( CNCopySupportedInterfaces(), 0));
}

@end
