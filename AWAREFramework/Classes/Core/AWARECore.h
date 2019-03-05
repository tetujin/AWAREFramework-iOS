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
@property (strong, nonatomic) CLLocationManager *sharedLocationManager;

// Daily Update Timer
@property (strong, nonatomic) NSTimer * dailyUpdateTimer;

// Base compliance
@property (strong, nonatomic) NSTimer * complianceTimer;

@property BOOL isNeedBackgroundSensing;

+ (AWARECore * _Nonnull)sharedCore;

- (void) activate;
- (void) deactivate;
- (void) startBaseLocationSensor;

- (void) checkCompliance;
- (void) checkComplianceWithViewController:(UIViewController *)viewController;
- (void) checkComplianceWithViewController:(UIViewController *)viewController showDetail:(BOOL)detail;

- (bool) checkLocationSensorWithViewController:(UIViewController *)viewController showDetail:(BOOL)detail;
- (bool) checkBackgroundAppRefreshWithViewController:(UIViewController *)viewController showDetail:(BOOL)detail;
- (bool) checkStorageUsageWithViewController:(UIViewController *)viewController showDetail:(BOOL)detail;
- (bool) checkWifiStateWithViewController:(UIViewController *)viewController showDetail:(BOOL)detail;
- (bool) checkLowPowerModeWithViewController:(UIViewController *)viewController showDetail:(BOOL)detail;
- (bool) checkNotificationSettingWithViewController:(UIViewController *)viewController showDetail:(BOOL)detail;

//
- (void) requestPermissionForPushNotification;
- (void) requestPermissionForBackgroundSensing;


- (void) requestBackgroundSensing;
- (void) requestNotification:(UIApplication *) application;


@end
