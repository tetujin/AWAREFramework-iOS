//
//  AWARESensorViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
#import "AWAREStudy.h"
#import "AWAREDebugMessageLogger.h"
#import "AWAREDelegate.h"
#import "SCNetworkReachability.h"
#import "AWAREStorage.h"

double const MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND  = 0.2f;
int    const MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND = 30;

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
    
    SensorEventHandler eventHandler;
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
            /**
             * @todo How should we initialize the awareStudy variable?
             */
            awareStudy = [AWAREStudy sharedStudy];
        }else{
            awareStudy = study;
        }
        debug = study.isDebug;
        sensorName = name;
        latestSensorValue = @"";
        // latestData = [[NSDictionary alloc] init];
        _storage = localStorage;
        [_storage setDebug:debug];
    }
    return self;
}

- (void)setSensorEventHandler:(SensorEventHandler)handler{
    eventHandler = handler;
}

- (SensorEventHandler)getSensorEventHandler{
    return eventHandler;
}

- (NSString *) getSensorName{
    return sensorName;
}

- (BOOL) isDebug{
    return debug;
}

/**
 Set debug status by boolean. If status "true", this library shows some debug messages on console log.

 @param state A status of debug mode
 */
- (void) setDebug:(BOOL)state{
    debug = state;
}


/**
 Create a database table for this sensor on an AWARE server. All of the subclasses should overwrite this method for creating the table.
 
 TCQMaker supports to make the query. Finally, you need to give to the instance to -createDBTableOnServer method on AWAREStorage.
 */
- (void) createTable {
    NSLog(@"[%@] Please overwrite -creatTable method", [self getSensorName]);
}

/**
 Set settings by parameters which are composed by NSDictionary.
 The supported parameters of sensors are described in each sensor.
 
 @param parameters A parameters for sensor
 */
- (void)setParameters:(NSArray *)parameters{
    NSLog(@"[%@] Please overwrite -setParameters: method", [self getSensorName]);
}


/**
 Start AWARESensor

 @discussion All of sub-classes of AWARESensor should overwride this method
 @discussion If the sensor is activated collectory, this method should return true, but if not, return false.
 
 @return AWARESensor is started or not
 */
- (BOOL) startSensor {
    return NO;
}


/**
 Stop AWARESensor

 @return AWARESensor is stopped or not
 */
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
 * @return The device ID of this app
 */
- (NSString *) getDeviceId {
    return [awareStudy getDeviceId];
}



/**
 Set the latest sensor to AWARESensor.

 @param dict The latest sensor data which is a NSDictionary object
 */
- (void) setLatestData:(NSDictionary *)dict{
    if(dict != nil){
        latestData = dict;
    }
}


/**
 Get the keeped latest sensor data

 @return The keeped latest sensor data which is a NSDictionary object
 */
- (NSDictionary *) getLatestData{
    return latestData;
}

/**
 Start synchronizing with a remote database
 */
- (void) startSyncDB {
    if(_storage != nil){
        [_storage startSyncStorage];
    }
}

/**
 Stop synchronizing with a remote database
 */
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
