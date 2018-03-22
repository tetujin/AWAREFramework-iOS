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

/** Initializer */
- (instancetype)initWithAWAREStudy:(AWAREStudy *) study;

// lock and unlock the sensor manager
- (void) lock;
- (void) unlock;
- (BOOL) isLocked;

// add a new sensor
- (void) addNewSensor:(AWARESensor *) sensor;
- (BOOL) isExist :(NSString *) key;

// sensor manager (start and stop)
- (BOOL) startAllSensors;
- (BOOL) startAllSensorsWithStudy:(AWAREStudy *) study;
- (BOOL) startAllSensorsWithStudy:(AWAREStudy *) study dbType:(AwareDBType)dbType;
- (BOOL) createAllTables;

// - (BOOL) clearDataFromLocalDB;
- (void)removeAllFilesFromDocumentRoot;

- (void) stopAndRemoveAllSensors;
- (void) stopASensor:(NSString *) sensorName;

- (void) quitAllSensor;

- (void) resetAllMarkerPositionsInDB;

// uploader in the foreground and background
- (bool) syncAllSensorsWithDBInForeground;
- (bool) syncAllSensorsWithDBInBackground;

- (void) runBatteryStateChangeEvents;


// upload timer
- (void) startUploadTimerWithInterval:(double) interval;
- (void) stopUploadTimer;

// get latest sensor data with sensor name
- (NSString *) getLatestSensorValue:(NSString *)sensorName;
- (NSDictionary *) getLatestSensorData:(NSString *) sensorName;
- (NSArray *) getAllSensors;

- (void) testSensing;

@end
