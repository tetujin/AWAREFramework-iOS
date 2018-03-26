//
//  Rotation.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
/**
 * [CoreMotion API]
 * https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/motion_event_basics/motion_event_basics.html
 *
 * [CMDeviceMotion API]
 * https://developer.apple.com/library/ios/documentation/CoreMotion/Reference/CMDeviceMotion_Class/index.html#//apple_ref/occ/cl/CMDeviceMotion
 */


#import "Rotation.h"
#import "EntityRotation.h"

NSString* const AWARE_PREFERENCES_STATUS_ROTATION = @"status_rotation";
NSString* const AWARE_PREFERENCES_FREQUENCY_ROTATION = @"frequency_rotation";
NSString* const AWARE_PREFERENCES_FREQUENCY_HZ_ROTATION = @"frequency_hz_rotation";

@implementation Rotation {
    CMMotionManager* motionManager;
    double sensingInterval;
    int dbWriteInterval;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_ROTATION
                        dbEntityName:NSStringFromClass([EntityRotation class])
                              dbType:dbType];
            // dbType:dbType];
    if (self) {
        motionManager = [[CMMotionManager alloc] init];
        sensingInterval = MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND;
        dbWriteInterval = MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND;
        // [self setCSVHeader:@[@"timestamp",@"device_id"]];
        [self setCSVHeader:@[@"timestamp",@"device_id", @"double_values_0", @"double_values_1",@"double_values_2", @"double_values_3", @"accuracy",@"label"]];

        [self addDefaultSettingWithBool:@NO       key:AWARE_PREFERENCES_STATUS_ROTATION        desc:@"e.g., True or False"];
        [self addDefaultSettingWithNumber:@200000 key:AWARE_PREFERENCES_FREQUENCY_ROTATION     desc:@"e.g., 200000 (normal), 60000 (UI), 20000 (game), 0 (fastest)."];
        [self addDefaultSettingWithNumber:@0      key:AWARE_PREFERENCES_FREQUENCY_HZ_ROTATION  desc:@"e.g., 1-100hz (default=0)"];

    }
    return self;
}

- (void) createTable{
    if ([self isDebug]) {
        NSLog(@"[%@] Create Table", [self getSensorName]);
    }
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "double_values_0 real default 0,"
    "double_values_1 real default 0,"
    "double_values_2 real default 0,"
    "double_values_3 real default 0,"
    "accuracy integer default 0,"
    "label text default ''";
    // "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}

- (void)setParameters:(NSArray *)parameters{
    // Get a sensing frequency
    double frequency = [self getSensorSetting:parameters withKey:@"frequency_rotation"];
    if(frequency != -1){
        sensingInterval = [self convertMotionSensorFrequecyFromAndroid:frequency];
    }
    
    double hz = [self getSensorSetting:parameters withKey:AWARE_PREFERENCES_FREQUENCY_HZ_ROTATION];
    if(hz > 0){
        sensingInterval = 1.0f/hz;
    }
    
    int buffer = (double)dbWriteInterval/sensingInterval;
    [self setBufferSize:buffer];
    
    // return [self startSensorWithInterval:interval bufferSize:buffer];
}

- (BOOL)startSensor{
    return [self startSensorWithInterval:sensingInterval];
}

- (BOOL)startSensorWithInterval:(double)interval{
    return [self startSensorWithInterval:interval bufferSize:[self getBufferSize]];
}

- (BOOL)startSensorWithInterval:(double)interval bufferSize:(int)buffer{
    return [self startSensorWithInterval:interval bufferSize:buffer fetchLimit:[self getFetchLimit]];
}


- (BOOL)startSensorWithInterval:(double)interval bufferSize:(int)buffer fetchLimit:(int)fetchLimit{
    
    if ([self isDebug]) {
        NSLog(@"[%@] Start Rotation Sensor", [self getSensorName]);
    }
    
    [self setBufferSize:buffer];
    
    [self setFetchLimit:fetchLimit];
    
    // Set and start motion sensor
    if( motionManager.deviceMotionAvailable ){
        motionManager.deviceMotionUpdateInterval = interval;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue new]
                                           withHandler:^(CMDeviceMotion *motion, NSError *error){
                                               // Save sensor data to the local database.
                                               NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                           
                                              NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                              [dict setObject:unixtime forKey:@"timestamp"];
                                              [dict setObject:[self getDeviceId] forKey:@"device_id"];
                                              [dict setObject:@(motion.attitude.pitch) forKey:@"double_values_0"]; //double
                                              [dict setObject:@(motion.attitude.roll)  forKey:@"double_values_1"]; //double
                                              [dict setObject:@(motion.attitude.yaw)  forKey:@"double_values_2"]; //double
                                              [dict setObject:@0 forKey:@"double_values_3"]; //double
                                              [dict setObject:@3 forKey:@"accuracy"];//int
                                              [dict setObject:@"" forKey:@"label"]; //text
                                               
                                               if([self getDBType] == AwareDBTypeSQLite){
                                                   [self saveData:dict];
                                               }else if([self getDBType] == AwareDBTypeJSON){
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       [self saveData:dict];
                                                   });
                                               }
                                               
                                               [self setLatestData:dict];
                                               [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",motion.attitude.pitch, motion.attitude.roll,motion.attitude.yaw]];

                                               NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                                                                    forKey:EXTRA_DATA];
                                               [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_ROTATION
                                                                                                   object:nil
                                                                                                 userInfo:userInfo];
                                               
                                               
                                           }];
    }
    return YES;
}

- (BOOL)stopSensor{
    // Stop a sync timer
    [motionManager stopDeviceMotionUpdates];
    motionManager = nil;
    return YES;
}


- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{
    EntityRotation* entityRotation = (EntityRotation *)[NSEntityDescription
                                              insertNewObjectForEntityForName:entity
                                              inManagedObjectContext:childContext];
    
    entityRotation.device_id = [data objectForKey:@"device_id"];
    entityRotation.timestamp = [data objectForKey:@"timestamp"];
    entityRotation.double_values_0 = [data objectForKey:@"double_values_0"];
    entityRotation.double_values_1 = [data objectForKey:@"double_values_1"];
    entityRotation.double_values_2 = [data objectForKey:@"double_values_2"];
    entityRotation.double_values_3 = [data objectForKey:@"double_values_3"];
    entityRotation.accuracy = [data objectForKey:@"accuracy"];
    entityRotation.label = [data objectForKey:@"label"];
    
}


@end
