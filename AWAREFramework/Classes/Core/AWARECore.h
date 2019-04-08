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

typedef void (^LocationAPIAuthorizationCompletionHandler)(void);

- (void) activate;
- (void) deactivate;
- (void) startBaseLocationSensor;

- (void) checkCompliance;
- (void) checkComplianceWithViewController:(UIViewController * _Nullable)viewController;
- (void) checkComplianceWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail;

- (bool) checkLocationSensorWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail;
- (bool) checkBackgroundAppRefreshWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail;
- (bool) checkStorageUsageWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail;
- (bool) checkWifiStateWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail;
- (bool) checkLowPowerModeWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail;
- (bool) checkNotificationSettingWithViewController:(UIViewController * _Nullable)viewController showDetail:(BOOL)detail;

- (void) requestPermissionForPushNotification;
- (void) requestPermissionForBackgroundSensing;
- (void) requestPermissionForBackgroundSensingWithCompletion:(LocationAPIAuthorizationCompletionHandler _Nullable)completionHandler;

- (void) requestBackgroundSensing;


@end
