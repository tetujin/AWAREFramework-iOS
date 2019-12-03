//
//  AWARECoreManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARECore.h"
#import "AWAREStudy.h"
#import "AWAREEventLogger.h"
#import <ifaddrs.h>
#import <net/if.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <UserNotifications/UserNotifications.h>
#import <ESMSchedule.h>

static AWARECore * sharedCore;

@implementation AWARECore{
    CoreLocationAuthCompletionHandler coreLocationAuthCompletionHandler;
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
        
        // Set defualt settings
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


/// Activate a core module of AWARE framework.
- (void) activate {
    [self deactivate];
    
    [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",@"event":@"activate"}];
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    
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
//    NSDate* dailyCheckComplianceTime = [AWAREUtils getTargetNSDate:[NSDate new] hour:0 minute:0 second:0 nextDay:YES];
//    _complianceTimer = [[NSTimer alloc] initWithFireDate:dailyCheckComplianceTime
//                                                interval:60*60
//                                                  target:self
//                                                selector:@selector(checkCompliance)
//                                                userInfo:nil
//                                                 repeats:YES];
//    NSRunLoop *loop = [NSRunLoop currentRunLoop];
//    [loop addTimer:_complianceTimer forMode:NSRunLoopCommonModes];

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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void) changedBatteryState:(id) sender{
    if ([[AWAREStudy sharedStudy] isAutoDBSync]){
        NSInteger batteryState = [UIDevice currentDevice].batteryState;
        if (batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull) {
            [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                                @"event":@"start sync",
                                                @"reason":@"battery state is changed"}];
            [[AWARESensorManager sharedSensorManager] syncAllSensors];
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

- (void) applicationDidEnterBackground:(id)snder{
    [AWARECore.sharedCore reactivate];
}

- (void) deactivate{
    [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore", @"event":@"deactivate"}];
    [[AWARESensorManager sharedSensorManager] stopAllSensors];
    [[AWARESensorManager sharedSensorManager] stopAutoSyncTimer];
    [_sharedLocationManager stopUpdatingLocation];
    [_dailyUpdateTimer invalidate];
    [_complianceTimer invalidate];
    
    if([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0){
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSProcessInfoPowerStateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationBackgroundRefreshStatusDidChangeNotification object:nil];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object: [NSUbiquitousKeyValueStore defaultStore]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)reactivate{
    [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore", @"event":@"reactivate"}];
    if (_isNeedBackgroundSensing) {
        [_sharedLocationManager stopUpdatingLocation];
        [_sharedLocationManager startUpdatingLocation];
        [_sharedLocationManager requestLocation];
    }
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    if (error!=nil) {
        NSLog(@"%@",error);
        [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                            @"event":@"locationManager:didFailWithError:",
                                            @"reason":error.debugDescription}];
    }
}

/// This method is an initializers for a location sensor.
/// On the iOS, we have to turn on the location sensor
/// for using application in the background.
/// And also, this sensing interval is the most low level.
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
            _sharedLocationManager.allowsBackgroundLocationUpdates = YES;
        }
        [_sharedLocationManager startUpdatingLocation];
        // [_sharedLocationManager startMonitoringSignificantLocationChanges];
        [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                            @"event":@"base-location-sensor is started"}];
    }else{
        NSLog(@"[NOTE] Background location sensing is not allowed. Please call sendBackgroundSensingRequest first if you need to collect activities in the background.");
        [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                            @"event":@"base-location-sensor is not started",
                                            @"reason":@"not authronized"}];
    }
}


/// The method is called by location sensor when the device location is changed.
- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    
    // NSLog(@"[AWARECore|BaseLocationSensor]%@", locations.debugDescription);
    
    #ifdef LOG_BASE_LOCATION_EVENTS
    if (locations.count > 0) {
        CLLocation * location = [locations lastObject];

        [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                            @"event":@"didUpdateLocations",
                                            @"info":@{@"latitude":@(location.coordinate.latitude),
                                                      @"longitude":@(location.coordinate.longitude)}
                                            }];
    }
    #endif
    
    #ifdef SHOW_BASE_LOCATION_EVENTS
    if (locations.count > 0) {
        if (AWAREStudy.sharedStudy.isDebug) {
            CLLocation * location = [locations lastObject];
            NSLog(@"[AWARECore] didUpdateBaseLocation: %@",location.description);
            [AWAREUtils sendLocalPushNotificationWithTitle:nil body:location.description timeInterval:0.1 repeats:NO];
        }
    }
    #endif
    
}


- (void) requestPermissionForPushNotification {
    [self requestPermissionForPushNotificationWithCompletion:nil];
}

- (void)requestPermissionForPushNotificationWithCompletion:(UNNotificationAuthCompletionHandler)completionHandler{
    UIApplication * application = UIApplication.sharedApplication;
    [application registerForRemoteNotifications];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
                              // Enable or disable features based on authorization.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler != nil) {
                completionHandler(granted, error);
            }
        });
    }];
}

- (void)requestPermissionForBackgroundSensingWithCompletion:(CoreLocationAuthCompletionHandler)completionHandler{
    self->coreLocationAuthCompletionHandler = completionHandler;
    CLAuthorizationStatus state = [CLLocationManager authorizationStatus];
    if(state == kCLAuthorizationStatusNotDetermined){
        if (_sharedLocationManager != nil){
            [_sharedLocationManager requestAlwaysAuthorization];
        }
    }else{
        if (self->coreLocationAuthCompletionHandler != nil) {
            self->coreLocationAuthCompletionHandler(state);
        }
        self->coreLocationAuthCompletionHandler = nil;
    }
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",@"event":@"didChangeAuthorizationStatus",@"status":@(status)}];
    if(status == kCLAuthorizationStatusNotDetermined ){
        /// kCLAuthorizationStatusRestricted
        return;
    }else if (status == kCLAuthorizationStatusAuthorizedAlways){
        /// kCLAuthorizationStatusAuthorizedWhenInUse
        if(_isNeedBackgroundSensing){
            [self startBaseLocationSensor];
        }
    }else if (status == kCLAuthorizationStatusAuthorizedWhenInUse){
        /// kCLAuthorizationStatusAuthorizedWhenInUse
    }else if (status == kCLAuthorizationStatusRestricted ){
        /// kCLAuthorizationStatusDenied
    }else if (status == kCLAuthorizationStatusDenied ){
        /// kCLAuthorizationStatusAuthorized
    }
    
    if (self->coreLocationAuthCompletionHandler) {
        self->coreLocationAuthCompletionHandler(status);
        self->coreLocationAuthCompletionHandler = nil;
    }
}


- (void) checkCompliance {
    [self checkComplianceWithViewController:nil];
}

- (void) checkComplianceWithViewController:(UIViewController *)viewController{
    [self checkComplianceWithViewController:viewController showDetail:NO];
}

- (void) checkComplianceWithViewController:(UIViewController *)viewController showDetail:(BOOL)detail{
    [self checkComplianceWithViewController:viewController showDetail:detail showSummary:NO];
}

- (void) checkComplianceWithViewController:(UIViewController *)viewController showDetail:(BOOL)detail showSummary:(BOOL)summary{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(![self checkLocationSensorWithViewController:viewController showDetail:detail]) return;
        if(![self checkBackgroundAppRefreshWithViewController:viewController showDetail:detail]) return;
        if(![self checkStorageUsageWithViewController:viewController showDetail:detail]) return;
        if(![self checkWifiStateWithViewController:viewController showDetail:detail]) return;
        if(![self checkLowPowerModeWithViewController:viewController showDetail:detail]) return;
        [self checkNotificationSettingWithViewController:viewController showDetail:detail completion:^(BOOL status){
            if (status) {
                if (viewController!=nil && summary) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"AWARE is ready for data collection"
                                                                                       message:@"Thank you for your copperation.\nWiFi->On\nLow Power Mode->Off\nStorage Space->Enough\nNotification->On\nLocation->On\nBackground Refresh->On"
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Close"
                                                                                style:UIAlertActionStyleCancel
                                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                                  
                                                                              }];
                        [alert addAction:cancelAction];
                        [viewController presentViewController:alert animated:YES completion:nil];
                    });
                }
            }
        }];
    });
}

- (bool)checkLocationSensorWithViewController:(UIViewController *) viewController showDetail:(BOOL)detail{
    bool state = NO;
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        
        if([AWAREUtils isForeground]  && viewController != nil ){
            // To track your daily activity, AWARE client iOS needs access to your location in the background.
            // To use background location you must turn on 'Always' in the Location Services Settings
            NSString *title = (status == kCLAuthorizationStatusDenied) ? @"Location services are off" : @"Background location sensing is not allowed";
            NSString *message = @"To track your daily activity, you have to turn on 'Always' in the Location Services Settings.";
            if (detail) [self openSettingsApp:viewController title:title message:message];
        }
        
        [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                            @"event":@"compliance check",
                                            @"state":@"error",
                                            @"reason":@"kCLAuthorizationStatusAuthorizedWhenInUse,kCLAuthorizationStatusDenied, or kCLAuthorizationStatusRestricted"}];
    }
    // The user has not enabled any location services. Request background authorization.
    else if (status == kCLAuthorizationStatusNotDetermined) {
        [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                            @"event":@"compliance check",
                                            @"state":@"error",
                                            @"reason":@"kCLAuthorizationStatusNotDetermined"}];
        NSString * url = [AWAREStudy.sharedStudy getStudyURL];
        if ( url != nil && ![url isEqualToString:@""]) {
            if([AWAREUtils isForeground]  && viewController != nil ){
                NSString *title = @"Location service is not permitted";
                NSString *message = @"To track your daily activity, the application needs to access your location `Always`. Please permit the location sensor from Settings.";
                if (detail) [self openSettingsApp:viewController title:title message:message];
            }
        }
    }else{
        [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                            @"event":@"compliance check",
                                            @"state":@"pass",
                                            @"reason":@"kCLAuthorizationStatusAuthorizedAlways"}];
        state = YES;
    }
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
            [self openSettingsApp:viewController title:title message:message];
        }else{
            // [AWAREUtils sendLocalNotificationForMessage:@"Please allow the 'Background App Refresh' service in the Settings->General." soundFlag:NO];
        }
        
        [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                            @"event":@"compliance check",
                                            @"state":@"error",
                                            @"reason":@"background app refresh service is restricted or denied"}];
    } else if(backgroundRefreshStatus == UIBackgroundRefreshStatusAvailable){
        [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                            @"event":@"compliance check",
                                            @"state":@"pass",
                                            @"reason":@"UIBackgroundRefreshStatusAvailable"}];
        state = YES;
    }
    return state;
}

- (void) checkNotificationSettingWithViewController:(UIViewController *) viewController  showDetail:(BOOL)detail completion:(void(^)(BOOL))completion{
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        NSString * reason = @"unknown";
        switch (settings.authorizationStatus) {
            case UNAuthorizationStatusAuthorized:
                [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                                    @"event":@"compliance check",
                                                    @"state":@"pass",
                                                    @"reason":@"UNAuthorizationStatusAuthorized"}];
                if (completion!=nil) {completion(true);}
                break;
            case UNAuthorizationStatusNotDetermined:
                reason = @"UNAuthorizationStatusNotDetermined";
            case UNAuthorizationStatusProvisional:
                reason = @"UNAuthorizationStatusProvisional";
            case UNAuthorizationStatusDenied:
                reason = @"UNAuthorizationStatusDenied";
                dispatch_async(dispatch_get_main_queue(), ^{
                   if([AWAREUtils isForeground]  && viewController!=nil ){
                       NSString * title = @"Notification service is not permitted.";
                       NSString * message = @"To send important notifications, please allow the `Notification` service in the General Settings.";
                       [self openSettingsApp:viewController title:title message:message];
                   }else{
                       // [AWAREUtils sendLocalNotificationForMessage:@"Please allow the 'Notification' service in the Settings.app->Notification->Allow Notifications." soundFlag:NO];
                   }
                    if (completion!=nil) { completion(false); }
                    [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                                        @"event":@"compliance check",
                                                        @"state":@"error",
                                                        @"reason":reason}];
            });
            break;
        }
    }];
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
        float percentage = free/total * 100.0f;
        
        [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                            @"event":@"compliance check",
                                            @"total":@(total), @"free":@(free),
                                            @"used":@(total-free), @"percentage":@(percentage)}];
        
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
                [viewController presentViewController:alertContoller animated:YES completion:nil];
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
            if([AWAREUtils isForeground]){
                [self openSettingsApp:viewController title:title message:message];
            }else{
                // [AWAREUtils sendLocalNotificationForMessage:title soundFlag:NO];
            }
            
            [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                                @"event":@"compliance check",
                                                @"state":@"error",
                                                @"reason":@"low-power-mode is enabled"}];
        }else{
            [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                                @"event":@"compliance check",
                                                @"state":@"pass",
                                                @"reason":@"low-power-mode is disabled"}];
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
            [self openSettingsApp:viewController title:title message:message];
        }else{
            // [AWAREUtils sendLocalNotificationForMessage:@"Please turn on WiFi! AWARE client needs WiFi for data uploading." soundFlag:NO];
        }
        [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                            @"event":@"compliance check",
                                            @"state":@"error",
                                            @"reason":@"wifi-module is off"}];
    }else{
        [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                            @"event":@"compliance check",
                                            @"state":@"pass",
                                            @"reason":@"wifi-module is on"}];
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


- (void) openSettingsApp:(UIViewController * _Nonnull)vc title:(NSString * _Nullable)title message:(NSString * _Nullable)message{ //} completion:(void(^)(void))completion{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                              [[UIApplication sharedApplication] openURL:settingsURL
                                                                                                 options:@{}
                                                                                       completionHandler:^(BOOL success) {
                                                                  
                                                              }];
                                                          }];
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              
                                                          }];
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [vc presentViewController:alert animated:YES completion:nil];
}

@end
