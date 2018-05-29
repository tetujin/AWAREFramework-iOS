//
//  AWARESensorManager.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <AudioToolbox/AudioServices.h>

#import "AWARESensor.h"
#import "AWAREStudy.h"

@interface AWARESensorManager : NSObject <UIAlertViewDelegate>

+ (AWARESensorManager *) sharedSensorManager;

/** Initializer */
- (instancetype)initWithAWAREStudy:(AWAREStudy *) study;

- (void) addSensor:(AWARESensor *) sensor;
- (void) addSensors:(NSArray *)sensors;
- (BOOL) addSensorsWithStudy:(AWAREStudy *) study;
- (BOOL) addSensorsWithStudy:(AWAREStudy *) study dbType:(AwareDBType)dbType;
- (BOOL) isExist :(NSString *) key;
- (NSArray *) getAllSensors;

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
- (NSString *) getLatestSensorValue:(NSString *)sensorName;
- (NSDictionary *) getLatestSensorData:(NSString *) sensorName;

- (void) resetAllMarkerPositionsInDB;
- (void) removeAllFilesFromDocumentRoot;


@end
