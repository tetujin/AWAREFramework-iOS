//
//  AWARESensorViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//


/**
 * 2/16/2016 by Yuuki NISHIYAMA
 * 
 * The AWARESensor class is the super class of aware sensors, and wraps to access
 * local storages(LocalFileStorageHelper) and to upload sensor data to
 * an AWARE server(AWAREDataUploader).
 *
 * LocalFileStorageHelper:
 * LocalFileStoragehelper is a text file based local storage. And also, a developer can store 
 * a sensor data with a NSDictionary Object using -(bool)saveData:(NSDictionary *)data;.
 * [WIP] Now I'm making a CoreData based storage for more stable data management.
 *
 * AWAREDataUploader:
 * This class supports data upload in the background/foreground. You can upload data by using -(void)syncAwareDB; 
 * or -(BOOL)syncAwareDBInForeground;. AWAREDataUploader obtains uploading sensor data from LocalFileStorageHelper
 * by -(NSMutableString *)getSensorDataForPost;
 *
 */


#import "AWARESensor.h"
#import "AWAREKeys.h"
#import "AWAREStudy.h"
#import "AWAREDebugMessageLogger.h"
#import "AWAREDelegate.h"
#import "SCNetworkReachability.h"
#import "AWAREStorage.h"

double const MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND = 0.2f;
int const MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND = 30;

@interface AWARESensor () {
    /** aware sensor name */
    NSString * sensorName;
    /** latest Sensor Value */
    NSString * latestSensorValue;
    /** debug state */
    bool debug;
    /** network state */
    NSInteger networkState;
    /** debug sensor*/
    AWAREDebugMessageLogger * dmLogger;
    /** aware study*/
    AWAREStudy * awareStudy;
    NSDictionary * latestData;
    
    SensorEventCallBack sensorEventCallBack;
}

@end

@implementation AWARESensor


- (instancetype) init{
    return [self initWithAwareStudy:nil dbType:AwareDBTypeSQLite];
}

- (instancetype) initWithDBType:(AwareDBType)dbType{
    return [self initWithAwareStudy:nil dbType:dbType];
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    return [self initWithAwareStudy:study dbType:AwareDBTypeSQLite];
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    NSLog(@"Please orverwrite this method -iniWithAwareStudy:dbType");
    return self;
}

- (instancetype) initWithAwareStudy:(AWAREStudy *) study
                         sensorName:(NSString *)name
                            storage:(AWAREStorage *)localStorage{
    self = [super init];
    if (self != nil) {
        if(study == nil){
            awareStudy = [[AWAREStudy alloc] initWithReachability:NO];
        }else{
            awareStudy = study;
        }
        debug = study.getDebugState;
        sensorName = name;
        latestSensorValue = @"";
        latestData = [[NSDictionary alloc] init];
        _storage = localStorage;
        [_storage setDebug:debug];
    }
    return self;
}

- (void)setSensorEventCallBack:(SensorEventCallBack)callback{
    sensorEventCallBack = callback;
}

- (SensorEventCallBack)getSensorEventCallBack{
    return sensorEventCallBack;
}

- (NSString *) getSensorName{
    return sensorName;
}

- (BOOL) isDebug{
    return debug;
}

- (void) setDebug:(BOOL)state{
    debug = state;
}


/**
 * DEFAULT:
 *
 */
- (void)setParameters:(NSArray *)parameters{
    NSLog(@"[%@] Please overwrite -setParameters: method", [self getSensorName]);
}

- (BOOL) startSensor {
    return NO;
}

- (BOOL)stopSensor{
    return NO;
}

/**
 * Set the latest sensor data
 *
 * @param   valueStr  NSString  The latest sensor value as a NSString value
 */

- (void) setLatestValue:(NSString *)valueStr{
    latestSensorValue = valueStr;
}

/**
 * Get the latest sensor value as a NSString
 *
 * @return The latest sensor data as a NSString
 */
- (NSString *)getLatestValue{
    return latestSensorValue;
}

/**
 * Get a device_id
 * @return A device_id
 */
- (NSString *) getDeviceId {
    return [awareStudy getDeviceId];
}

/**
 * Get a sensor name of this sensor
 * @return A sensor name of this AWARESensor
 */
//- (NSString *) getSensorName{
//    return sensorName;
//}


- (void) setLatestData:(NSDictionary *)dict{
    if(dict != nil){
        latestData = dict;
    }
}

- (NSDictionary *) getLatestData{
    if (latestData != nil) {
        return latestData;
    }else{
        return [[NSDictionary alloc] init];
    }
}

//////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

- (void) createTable {
    
}

- (void) startSyncDB {
    if(_storage != nil){
        [_storage startSyncStorage];
    }
}

- (void) stopSyncDB {
    if(_storage != nil){
        [_storage cancelSyncStorage];
    }
}

//////////////////// Utils ////////////////////

/**
 Get a sensor setting(such as a sensing frequency) from settings with Key

 @param settings for the target setting
 @param key for the target setting
 @return a double value of the setting
 */
- (double)getSensorSetting:(NSArray *)settings withKey:(NSString *)key{
    if (settings != nil) {
        for (NSDictionary * setting in settings) {
            if ([[setting objectForKey:@"setting"] isEqualToString:key]) {
                double value = [[setting objectForKey:@"value"] doubleValue];
                return value;
            }
        }
    }
    return -1;
}



- (NSString *)getSettingAsStringFromSttings:(NSArray *)settings withKey:(NSString *)key{
    if (settings != nil) {
        for (NSDictionary * setting in settings) {
            if ([[setting objectForKey:@"setting"] isEqualToString:key]) {
                NSString * value = [setting objectForKey:@"value"];
                return value;
            }
        }
    }
    return @"";
}


/**
 Converts a sensing frequency which format is Android (microsecond) to an iOS sensing frequency (second).

 @param intervalMicroSecond is a sensing frequency in Andrind (frequency microsecond)
 @return a sensing frequency for iOS (second)
 */
- (double) convertMotionSensorFrequecyFromAndroid:(double)intervalMicroSecond{
    //  Android: Non-deterministic frequency in microseconds
    // (dependent of the hardware sensor capabilities and resources),
    // e.g., 200000 (normal), 60000 (UI), 20000 (game), 0 (fastest).
    double intervalSecond = intervalMicroSecond/(double)1000000;
    if ([self isDebug]) {
        NSLog(@"Sensing Interval: %f (second)",intervalSecond);
        NSLog(@"Hz: %f (Hz)", (double)1/intervalSecond);
    }
    return intervalSecond;
}


- (void) setStore:(BOOL)state{
    if (_storage != nil) {
        [_storage setStore:state];
    }
}

- (BOOL) isStore{
    if (_storage != nil) {
        return [_storage isStore];
    }else{
        NSLog(@"[%@] local-storage is null", sensorName);
        return NO;
    }
}

@end
