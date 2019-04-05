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

- (void) addSensor:(AWARESensor *  _Nonnull) sensor;
- (void) addSensors:(NSArray<AWARESensor *> * _Nonnull)sensors;
- (BOOL) addSensorsWithStudy:(AWAREStudy * _Nonnull) study;
- (BOOL) addSensorsWithStudy:(AWAREStudy * _Nonnull) study dbType:(AwareDBType)dbType;
- (BOOL) isExist :(NSString * _Nonnull) sensorName;
- (NSArray<AWARESensor *> * _Nonnull) getAllSensors;
- (AWARESensor * _Nullable ) getSensor:(NSString * _Nonnull) sensorName;

///////////////////////////////////
- (void) setSensorEventHandlerToAllSensors:(SensorEventHandler _Nonnull)handler;
- (void) setSyncProcessCallbackToAllSensorStorages:(SyncProcessCallBack _Nonnull)callback;
- (void) setDebugToAllSensors:(bool)state;
- (void) setDebugToAllStorage:(bool)state;

////////////////////////////////////////
- (BOOL) createDBTablesOnAwareServer;
- (BOOL) startAllSensors;
- (void) runBatteryStateChangeEvents;
- (void) stopAndRemoveAllSensors;
- (void) stopAllSensors;
- (void) stopSensor:(NSString *) sensorName;

//////////////////
- (void) syncAllSensors;
- (void) syncAllSensorsForcefully;

////////////////////////
- (void) startAutoSyncTimerWithIntervalSecond:(double) second;
- (void) startAutoSyncTimer;
- (void) stopAutoSyncTimer;

////////////////////////////

// get latest sensor data with sensor name
- (NSString * _Nullable) getLatestSensorValue:(NSString * _Nonnull) sensorName;
- (NSDictionary * _Nullable) getLatestSensorData:(NSString * _Nonnull) sensorName;

- (void) resetAllMarkerPositionsInDB;
- (void) removeAllFilesFromDocumentRoot;

NS_ASSUME_NONNULL_END

@end
