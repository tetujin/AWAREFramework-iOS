//
//  Gravity.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/21/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

/**
 * [CoreMotion API]
 * https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/motion_event_basics/motion_event_basics.html
 *
 * [CMDeviceMotion API]
 * https://developer.apple.com/library/ios/documentation/CoreMotion/Reference/CMDeviceMotion_Class/index.html#//apple_ref/occ/cl/CMDeviceMotion
 */

#import "Gravity.h"
#import "EntityGravity.h"

NSString* const AWARE_PREFERENCES_STATUS_GRAVITY = @"status_gravity";
NSString* const AWARE_PREFERENCES_FREQUENCY_GRAVITY = @"frequency_gravity";
NSString* const AWARE_PREFERENCES_FREQUENCY_HZ_GRAVITY = @"frequency_hz_gravity";;

@implementation Gravity {
    CMMotionManager* motionManager;
    double sensingInterval;
    int dbWriteInterval;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_GRAVITY
                        dbEntityName:NSStringFromClass([EntityGravity class])
                              dbType:dbType];
            //dbType:dbType];
    if (self) {
        motionManager = [[CMMotionManager alloc] init];
        sensingInterval = MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND;
        dbWriteInterval = MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND;
        [self setCSVHeader:@[@"timestamp",@"device_id", @"double_values_0", @"double_values_1",@"double_values_2", @"accuracy",@"label"]];
        [self addDefaultSettingWithBool:@NO       key:AWARE_PREFERENCES_STATUS_GRAVITY        desc:@"e.g., true or false"];
        [self addDefaultSettingWithNumber:@200000 key:AWARE_PREFERENCES_FREQUENCY_GRAVITY     desc:@"e.g., 200000 (normal), 60000 (UI), 20000 (game), 0 (fastest)."];
        [self addDefaultSettingWithNumber:@0      key:AWARE_PREFERENCES_FREQUENCY_HZ_GRAVITY  desc:@"e.g., 100-1Hz(default=0)"];

    }
    return self;
}


- (void) createTable{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:@"double_values_0" type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:@"double_values_1" type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:@"double_values_2" type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:@"accuracy" type:TCQTypeInteger default:@"0"];
    [tcqMaker addColumn:@"label" type:TCQTypeText default:@"''"];
    NSString *query = [tcqMaker getDefaudltTableCreateQuery];
    [super createTable:query];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    /// Get sensing frequency from settings
    double interval = sensingInterval;
    double frequency = [self getSensorSetting:settings withKey:@"frequency_gravity"];
    if(frequency != -1){
        NSLog(@"Gravity's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        interval = iOSfrequency;
    }
    
    double tempHz = [self getSensorSetting:settings withKey:AWARE_PREFERENCES_FREQUENCY_HZ_GRAVITY];
    if(tempHz > 0){
       interval = 1.0f/tempHz;
    }

    
    int buffer = dbWriteInterval/interval;
    
    return [self startSensorWithInterval:interval bufferSize:buffer];
}

- (BOOL) startSensor{
    return [self startSensorWithInterval:sensingInterval];
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
    
    // Set and start motion sensor
    NSLog(@"[%@] Start Gravity Sensor", [self getSensorName]);
    if( motionManager.deviceMotionAvailable ){
        motionManager.deviceMotionUpdateInterval = interval;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                           withHandler:^(CMDeviceMotion *motion, NSError *error){
                                               // Save sensor data to the local database.
                                               
                                               // dispatch_async(dispatch_get_main_queue(),^{
                                                   
                                                  NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                                  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                                  [dict setObject:unixtime forKey:@"timestamp"];
                                                  [dict setObject:[self getDeviceId] forKey:@"device_id"];
                                                  [dict setObject:[NSNumber numberWithDouble:motion.gravity.x] forKey:@"double_values_0"]; //double
                                                  [dict setObject:[NSNumber numberWithDouble:motion.gravity.y]  forKey:@"double_values_1"]; //double
                                                  [dict setObject:[NSNumber numberWithDouble:motion.gravity.z]  forKey:@"double_values_2"]; //double
                                                  [dict setObject:@3 forKey:@"accuracy"];//int
                                                  [dict setObject:@"" forKey:@"label"]; //text
                                                  [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",motion.attitude.pitch, motion.attitude.roll,motion.attitude.yaw]];
                                                  
                                                  [self setLatestData:dict];
                                               
                                                   NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                                                                        forKey:EXTRA_DATA];
                                                   [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_GRAVITY
                                                                                                       object:nil
                                                                                                     userInfo:userInfo];
                                                   
                                                   if([self getDBType] == AwareDBTypeCoreData){
                                                       [self saveData:dict];
                                                   }else if([self getDBType] == AwareDBTypeTextFile){
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           [self saveData:dict];
                                                       });
                                                   }
                                                
                                               // });
                                           }];
    }

    return YES;
}

- (void)insertNewEntityWithData:(NSDictionary *)data managedObjectContext:(NSManagedObjectContext *)childContext entityName:(NSString *)entity{
    EntityGravity* gravityData = (EntityGravity *)[NSEntityDescription
                                                   insertNewObjectForEntityForName:entity
                                                   inManagedObjectContext:childContext];
    
    gravityData.device_id = [data objectForKey:@"device_id"];
    gravityData.timestamp = [data objectForKey:@"timestamp"];
    gravityData.double_values_0 = [data objectForKey:@"double_values_0"];
    gravityData.double_values_1 = [data objectForKey:@"double_values_1"];
    gravityData.double_values_2 = [data objectForKey:@"double_values_2"];
    gravityData.label =  [data objectForKey:@"label"];

}

- (BOOL)stopSensor{
    [motionManager stopDeviceMotionUpdates];
    motionManager = nil;
    return YES;
}


/////////////// for TextFile based DB
//

@end
