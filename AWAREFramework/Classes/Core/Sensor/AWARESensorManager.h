//
//  AWARESensorManager.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioServices.h>

#import "AWARESensor.h"
#import "AWAREStudy.h"

@interface AWARESensorManager : NSObject <UIAlertViewDelegate>

+ (AWARESensorManager * _Nonnull) sharedSensorManager;

/** Initializer */
NS_ASSUME_NONNULL_BEGIN

#pragma mark - Sensor In/Out Operations
- (void) addSensor:(AWARESensor *  _Nonnull) sensor;
- (void) addSensors:(NSArray<AWARESensor *> * _Nonnull)sensors;
- (BOOL) addSensorsWithStudy:(AWAREStudy * _Nonnull) study;
- (BOOL) addSensorsWithStudy:(AWAREStudy * _Nonnull) study dbType:(AwareDBType)dbType;
- (BOOL) isExist :(NSString * _Nonnull) sensorName;
- (NSArray<AWARESensor *> * _Nonnull) getAllSensors;
- (AWARESensor * _Nullable ) getSensor:(NSString * _Nonnull) sensorName;

#pragma mark - Event Handls
- (void) setSensorEventHandlerToAllSensors:(SensorEventHandler _Nonnull)handler;
- (void) setSyncProcessCallbackToAllSensorStorages:(SyncProcessCallback _Nonnull)callback;

#pragma mark - Debug
- (void) setDebugToAllSensors:(bool)state;
- (void) setDebugToAllStorage:(bool)state;

#pragma mark - Sensor Start/Stop Operations
- (BOOL) startAllSensors;
- (void) stopSensor:(NSString *) sensorName;
- (void) stopAllSensors;
- (void) stopAndRemoveAllSensors;

#pragma mark - Sensor Sync Operations
- (BOOL) createDBTablesOnAwareServer;
- (BOOL) createTablesOnRemoteServer;
- (void) syncAllSensors;
- (void) syncAllSensorsForcefully;

#pragma mark - Auto Sync Timer
- (void) startAutoSyncTimerWithIntervalSecond:(double) second;
- (void) startAutoSyncTimer;
- (void) stopAutoSyncTimer;

#pragma mark - Lastest Data Interface
- (NSDictionary * _Nullable) getLatestSensorData:(NSString * _Nonnull)  sensorName;
- (NSString * _Nullable)     getLatestSensorValue:(NSString * _Nonnull) sensorName;

#pragma mark - Others
- (void) resetAllMarkerPositionsInDB;
- (void) removeAllFilesFromDocumentRoot;

NS_ASSUME_NONNULL_END

@end
