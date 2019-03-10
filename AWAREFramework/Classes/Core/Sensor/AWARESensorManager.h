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

- (void) addSensor:(AWARESensor *  _Nonnull) sensor;
- (void) addSensors:(NSArray<AWARESensor *> * _Nonnull)sensors;
- (BOOL) addSensorsWithStudy:(AWAREStudy * _Nonnull) study;
- (BOOL) addSensorsWithStudy:(AWAREStudy * _Nonnull) study dbType:(AwareDBType)dbType;
- (BOOL) isExist :(NSString *) sensorName;
- (NSArray<AWARESensor *> * _Nonnull) getAllSensors;
- ( AWARESensor * _Nullable ) getSensor:(NSString * _Nonnull) sensorName;

///////////////////////////////////
- (void) setSensorEventHandlerToAllSensors:(SensorEventHandler)handler;
- (void) setSyncProcessCallbackToAllSensorStorages:(SyncProcessCallBack)callback;
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
- (NSString *) getLatestSensorValue:(NSString * _Nonnull) sensorName;
- (NSDictionary *) getLatestSensorData:(NSString * _Nonnull) sensorName;

- (void) resetAllMarkerPositionsInDB;
- (void) removeAllFilesFromDocumentRoot;

@end
