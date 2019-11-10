//
//  AWARECoreManager.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "AWAREKeys.h"
#import "AWARESensorManager.h"
#import "ESMScheduleManager.h"


@interface AWARECore : NSObject <CLLocationManagerDelegate>

// Core Location Manager
@property (strong, nonatomic, nonnull) CLLocationManager * sharedLocationManager;

// Daily Update Timer
@property (strong, nonatomic) NSTimer * _Nullable dailyUpdateTimer;

// Base compliance
@property (strong, nonatomic) NSTimer * _Nullable complianceTimer;

@property BOOL isNeedBackgroundSensing;

+ (AWARECore * _Nonnull) sharedCore;

typedef void (^CoreLocationAuthCompletionHandler)(CLAuthorizationStatus status);
typedef void (^UNNotificationAuthCompletionHandler)(BOOL granted, NSError * _Nullable error);

- (void) activate;
- (void) deactivate;
- (void) reactivate;

- (void) startBaseLocationSensor;

- (void) checkCompliance;
- (void) checkComplianceWithViewController:(UIViewController * _Nullable)viewController;
- (void) checkComplianceWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail;
- (void) checkComplianceWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail showSummary:(BOOL)summary;

- (bool) checkLocationSensorWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail;
- (bool) checkBackgroundAppRefreshWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail;
- (bool) checkStorageUsageWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail;
- (bool) checkWifiStateWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail;
- (bool) checkLowPowerModeWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail;
- (void) checkNotificationSettingWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail completion:(void(^_Nullable)(BOOL))completion;

- (void) requestPermissionForBackgroundSensingWithCompletion:(CoreLocationAuthCompletionHandler _Nullable)completionHandler;
- (void) requestPermissionForPushNotificationWithCompletion:(UNNotificationAuthCompletionHandler _Nullable)completionHandler;

- (void) openSettingsApp:(UIViewController * _Nonnull)vc title:(NSString * _Nullable)title message:(NSString * _Nullable)message;
- (BOOL) isWiFiEnabled;
@end
