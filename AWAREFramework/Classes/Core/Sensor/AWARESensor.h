//
//  AWARESensorViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <Foundation/Foundation.h>
#import <math.h>
#import "AWAREUtils.h"
#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "TCQMaker.h"
#import "AWAREStorage.h"
#import "JSONStorage.h"
#import "SQLiteStorage.h"
#import "CSVStorage.h"
#import "BaseCoreDataHandler.h"
#import "AWAREBatchDataOM+CoreDataClass.h"
#import "SQLiteSeparatedStorage.h"

extern double const MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND;
extern int    const MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND;

@protocol AWARESensorDelegate <NSObject>

@property (readonly) BOOL isSensing;
@property (nullable) NSString * label;

- (void) setSensingState:(BOOL)state;

- (void) setParameters:(NSArray * _Nonnull)parameters;
- (BOOL) startSensor;
- (BOOL) stopSensor;
- (void) startSyncDB;
- (void) stopSyncDB;
- (void) createTable;
- (BOOL) isDebug;
- (void) setDebug:(BOOL)state;
- (void) setLabel:(NSString * _Nullable)label;
- (void) resetSensor;

@end

NS_ASSUME_NONNULL_BEGIN

@interface AWARESensor : NSObject <AWARESensorDelegate, UIAlertViewDelegate>

@property AWAREStorage * _Nullable storage;

typedef void (^SensorEventHandler)(AWARESensor * _Nonnull sensor, NSDictionary<NSString *, id> * _Nullable data);

- (instancetype) initWithDBType:(AwareDBType)dbType;
- (instancetype) initWithAwareStudy:(AWAREStudy * _Nullable) study;
- (instancetype) initWithAwareStudy:(AWAREStudy * _Nullable) study dbType:(AwareDBType)dbType;
- (instancetype) initWithAwareStudy:(AWAREStudy * _Nullable) study sensorName:(NSString * _Nullable)name storage:(AWAREStorage * _Nullable)localStorage;

- (void) setSensorEventHandler:(SensorEventHandler _Nonnull)handler;
- (SensorEventHandler _Nullable )getSensorEventHandler;
- (NSString * _Nullable) getSensorName;

- (void) setParameters:(NSArray * _Nonnull) parameters;

- (void) setLatestValue:(NSString * _Nonnull) valueStr;
- (NSString * _Nullable) getLatestValue;
- (void) setLatestData:(NSDictionary * _Nonnull)dict;
- (NSDictionary * _Nullable) getLatestData;

- (NSString * _Nullable) getDeviceId;
- (double) getSensorSetting:(NSArray * _Nonnull)settings withKey:(NSString * _Nonnull)key;
- (NSString *)getSettingAsStringFromSttings:(NSArray * _Nonnull)settings withKey:(NSString * _Nonnull)key;

- (void) setStore:(BOOL)state;
- (BOOL) isStore;

// Utils
- (double) convertMotionSensorFrequecyFromAndroid:(double)intervalMicroSecond;

- (void) setNotificationNames:(NSArray <NSNotification *> *) names;
- (NSArray <NSNotification *> *) getNotificationNames;

NS_ASSUME_NONNULL_END

@end
