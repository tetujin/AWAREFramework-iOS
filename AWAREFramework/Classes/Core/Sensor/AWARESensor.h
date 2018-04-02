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
#import "AWAREUtils.h"
#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "TCQMaker.h"
#import "AWAREStorage.h"
#import "JSONStorage.h"
#import "SQLiteStorage.h"
#import "CSVStorage.h"

extern double const MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND;
extern int    const MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND;

@protocol AWARESensorDelegate <NSObject>

- (void) setParameters:(NSArray *)parameters;
- (BOOL) startSensor;
- (BOOL) stopSensor;
- (void) startSyncDB;
- (void) stopSyncDB;
- (void) createTable;
- (BOOL) isDebug;
- (void) setDebug:(BOOL)state;

@end

@interface AWARESensor : NSObject <AWARESensorDelegate, UIAlertViewDelegate>

@property AWAREStorage * storage;

typedef void (^SensorEventHandler)(AWARESensor *sensor, NSDictionary *data);

- (instancetype) initWithDBType:(AwareDBType)dbType;
- (instancetype) initWithAwareStudy:(AWAREStudy *)study;
- (instancetype) initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType;
- (instancetype) initWithAwareStudy:(AWAREStudy *) study sensorName:(NSString *)name storage:(AWAREStorage *)localStorage;

- (void) setSensorEventHandler:(SensorEventHandler)handler;
- (SensorEventHandler)getSensorEventHandler;
- (NSString *) getSensorName;

- (void) setParameters:(NSArray *) parameters;

- (void) setLatestValue:(NSString *) valueStr;
- (NSString *) getLatestValue;
- (void) setLatestData:(NSDictionary *)dict;
- (NSDictionary *) getLatestData;

- (NSString *) getDeviceId;
- (double) getSensorSetting:(NSArray *)settings withKey:(NSString *)key;
- (NSString *)getSettingAsStringFromSttings:(NSArray *)settings withKey:(NSString *)key;

- (void) setStore:(BOOL)state;
- (BOOL) isStore;

// Utils
- (double) convertMotionSensorFrequecyFromAndroid:(double)intervalMicroSecond;

@end
