//
//  Magnetometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Magnetometer.h"
#import "EntityMagnetometer.h"

NSString* const AWARE_PREFERENCES_STATUS_MAGNETOMETER = @"status_magnetometer";
NSString* const AWARE_PREFERENCES_FREQUENCY_MAGNETOMETER = @"frequency_magnetometer";
NSString* const AWARE_PREFERENCES_FREQUENCY_HZ_MAGNETOMETER = @"frequency_hz_magnetometer";

@implementation Magnetometer{
    CMMotionManager* manager;
    double defaultInterval;
    int dbWriteInterval;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_MAGNETOMETER
                        dbEntityName:NSStringFromClass([EntityMagnetometer class])
                              dbType:dbType];
            // dbType:dbType];
    if (self) {
        manager = [[CMMotionManager alloc] init];
        defaultInterval = MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND;
        dbWriteInterval = MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND;
        [self setCSVHeader:@[@"timestamp",@"device_id", @"double_values_0", @"double_values_1",@"double_values_2", @"accuracy",@"label"]];
    
        [self addDefaultSettingWithBool:@NO       key:AWARE_PREFERENCES_STATUS_MAGNETOMETER        desc:@"e.g., True or False"];
        [self addDefaultSettingWithNumber:@200000 key:AWARE_PREFERENCES_FREQUENCY_MAGNETOMETER     desc:@"e.g., 200000 (normal), 60000 (UI), 20000 (game), 0 (fastest)."];
        [self addDefaultSettingWithNumber:@0      key:AWARE_PREFERENCES_FREQUENCY_HZ_MAGNETOMETER  desc:@"e.g., 1-100hz (default=0)"];

    }
    return self;
}


- (void) createTable{
    // Send a table craete query
    NSLog(@"[%@] Create table", [self getSensorName]);
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "double_values_0 real default 0,"
    "double_values_1 real default 0,"
    "double_values_2 real default 0,"
    "accuracy integer default 0,"
    "label text default ''";
    // "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    // Get and set a sensng frequency to CMMotionManager
    double frequency = [self getSensorSetting:settings withKey:@"frequency_magnetometer"];
    if(frequency != -1){
        NSLog(@"Accelerometer's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        frequency = iOSfrequency;
    }else{
        frequency = defaultInterval;
    }
    
    double tempHz = [self getSensorSetting:settings withKey:AWARE_PREFERENCES_FREQUENCY_HZ_MAGNETOMETER];
    if(tempHz > 0){
        frequency = 1.0f/tempHz;
    }
    
    int buffer = dbWriteInterval/frequency;
    return [self startSensorWithInterval:frequency bufferSize:buffer];
}

- (BOOL) startSensor{
    return [self startSensorWithInterval:defaultInterval];
}

- (BOOL) startSensorWithInterval:(double)interval{
    return [self startSensorWithInterval:interval bufferSize:[self getBufferSize]];
}

- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer{
    return [self startSensorWithInterval:interval bufferSize:buffer fetchLimit:[self getFetchLimit]];
}

- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer fetchLimit:(int)fetchLimit{
    
    // Set a buffer size for reducing file access
    [self setBufferSize:buffer];
    
    [self setFetchLimit:fetchLimit];
    
    // Set and start a sensor
    NSLog(@"[%@] Start Mag sensor", [self getSensorName]);
    
    manager.magnetometerUpdateInterval = interval;
    
    [manager startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                 withHandler:^(CMMagnetometerData * _Nullable magnetometerData,
                                               NSError * _Nullable error) {
                                     if( error ) {
                                         NSLog(@"%@:%ld", [error domain], [error code] );
                                     } else {
                                         
                                         // dispatch_async(dispatch_get_main_queue(),^{
                                             
                                             NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                             NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                             [dict setObject:unixtime forKey:@"timestamp"];
                                             [dict setObject:[self getDeviceId] forKey:@"device_id"];
                                             [dict setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.x] forKey:@"double_values_0"];
                                             [dict setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.y] forKey:@"double_values_1"];
                                             [dict setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.z] forKey:@"double_values_2"];
                                             [dict setObject:@3 forKey:@"accuracy"];
                                             [dict setObject:@"" forKey:@"label"];
                                             [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",magnetometerData.magneticField.x, magnetometerData.magneticField.y, magnetometerData.magneticField.z]];
                                             [self setLatestData:dict];
                                         
                                             NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                                                                  forKey:EXTRA_DATA];
                                             [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_MAGNETOMETER
                                                                                                 object:nil
                                                                                               userInfo:userInfo];

                                         if([self getDBType] == AwareDBTypeCoreData){
                                             [self saveData:dict];
                                         }else if ([self getDBType] == AwareDBTypeTextFile){
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [self saveData:dict];
                                             });
                                         }
                                         
                                         // });
                                     }
                                 }];

    return YES;
}


- (void)insertNewEntityWithData:(NSDictionary *)data managedObjectContext:(NSManagedObjectContext *)childContext entityName:(NSString *)entity{

    EntityMagnetometer* entityMag = (EntityMagnetometer *)[NSEntityDescription
                                                      insertNewObjectForEntityForName:entity
                                                      inManagedObjectContext:childContext];
    
    entityMag.device_id = [data objectForKey:@"device_id"];
    entityMag.timestamp = [data objectForKey:@"timestamp"];
    entityMag.double_values_0 = [data objectForKey:@"double_values_0"];
    entityMag.double_values_1 = [data objectForKey:@"double_values_1"];
    entityMag.double_values_2 = [data objectForKey:@"double_values_2"];
    entityMag.accuracy = [data objectForKey:@"accuracy"];
    entityMag.label =  [data objectForKey:@"label"];
    
}

- (BOOL)stopSensor{
    // Stop a motion sensor
    [manager stopMagnetometerUpdates];
    manager = nil;
    return YES;
}


@end
