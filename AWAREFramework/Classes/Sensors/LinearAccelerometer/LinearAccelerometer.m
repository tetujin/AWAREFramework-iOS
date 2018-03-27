//
//  linearAccelerometer.m
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

//    deviceMotion.magneticField.field.x; done
//    deviceMotion.magneticField.field.y; done
//    deviceMotion.magneticField.field.z; done
//    deviceMotion.magneticField.accuracy;

//    deviceMotion.gravity.x;
//    deviceMotion.gravity.y;
//    deviceMotion.gravity.z;
//    deviceMotion.attitude.pitch;
//    deviceMotion.attitude.roll;
//    deviceMotion.attitude.yaw;
//    deviceMotion.rotationRate.x;
//    deviceMotion.rotationRate.y;
//    deviceMotion.rotationRate.z;

//    deviceMotion.timestamp;
//    deviceMotion.userAcceleration.x;
//    deviceMotion.userAcceleration.y;
//    deviceMotion.userAcceleration.z;


#import "LinearAccelerometer.h"
#import "EntityLinearAccelerometer.h"

NSString* const AWARE_PREFERENCES_STATUS_LINEAR_ACCELEROMETER = @"status_linear_accelerometer";
NSString* const AWARE_PREFERENCES_FREQUENCY_LINEAR_ACCELEROMETER = @"frequency_linear_accelerometer";
NSString* const AWARE_PREFERENCES_FREQUENCY_HZ_LINEAR_ACCELEROMETER = @"frequency_hz_linear_accelerometer";

@implementation LinearAccelerometer {
    CMMotionManager* motionManager;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_LINEAR_ACCELEROMETER
                        dbEntityName:NSStringFromClass([EntityLinearAccelerometer class])
                              dbType:dbType];
        // dbType:dbType];
    if (self) {
        motionManager = [[CMMotionManager alloc] init];
        super.sensingInterval = MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND;
        super.savingInterval  = MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND;

        [self setCSVHeader:@[@"timestamp",@"device_id", @"double_values_0", @"double_values_1",@"double_values_2", @"accuracy",@"label"]];
    
        [self addDefaultSettingWithBool:@NO       key:AWARE_PREFERENCES_STATUS_LINEAR_ACCELEROMETER        desc:@"e.g., True or False"];
        [self addDefaultSettingWithNumber:@200000 key:AWARE_PREFERENCES_FREQUENCY_LINEAR_ACCELEROMETER     desc:@"e.g., 200000 (normal), 60000 (UI), 20000 (game), 0 (fastest)."];
        [self addDefaultSettingWithNumber:@0      key:AWARE_PREFERENCES_FREQUENCY_HZ_LINEAR_ACCELEROMETER desc:@"e.g., 1-100hz (default=0)"];
    }
    return self;
}

- (void) createTable{
    if([self isDebug]){
        NSLog(@"[%@] Create Table", [self getSensorName]);
    }
    NSString *query = @"_id integer primary key autoincrement,"
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


- (void)setParameters:(NSArray *)parameters{
    if (parameters != nil) {
        double frequency = [self getSensorSetting:parameters withKey:@"frequency_linear_accelerometer"];
        if(frequency != -1){
            super.sensingInterval = [self convertMotionSensorFrequecyFromAndroid:frequency];
        }
        double hz = [self getSensorSetting:parameters withKey:AWARE_PREFERENCES_FREQUENCY_HZ_LINEAR_ACCELEROMETER];
        if(hz > 0){
            super.sensingInterval = 1.0f/hz;
        }
    }
}

-(BOOL)startSensorWithSensingInterval:(double)sensingInterval savingInterval:(double)savingInterval{

    if ([self isDebug]) {
        NSLog(@"[%@] Start Linear Acc Sensor", [self getSensorName]);
    }
    
    // Set a buffer size for reducing file access
    [self setBufferSize:savingInterval/sensingInterval];

    if( motionManager.deviceMotionAvailable ){
        motionManager.deviceMotionUpdateInterval = sensingInterval;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                           withHandler:^(CMDeviceMotion *motion, NSError *error){
                                               // Save sensor data to the local database
                                               
                                               // dispatch_async(dispatch_get_main_queue(),^{
                                                   
                                                   //////////////////////////////////////////////////
                                                   NSNumber *unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                                   NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                                   [dict setObject:unixtime forKey:@"timestamp"];
                                                   [dict setObject:[self getDeviceId] forKey:@"device_id"];
                                                   [dict setObject:[NSNumber numberWithDouble:motion.userAcceleration.x] forKey:@"double_values_0"]; //double
                                                   [dict setObject:[NSNumber numberWithDouble:motion.userAcceleration.y]  forKey:@"double_values_1"]; //double
                                                   [dict setObject:[NSNumber numberWithDouble:motion.userAcceleration.z]  forKey:@"double_values_2"]; //double
                                                   [dict setObject:@3 forKey:@"accuracy"];//int
                                                   [dict setObject:@"" forKey:@"label"]; //text
                                                   [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",motion.userAcceleration.x, motion.userAcceleration.y,motion.userAcceleration.z]];
                                                   [self setLatestData:dict];
                                               
                                                   NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                                                                        forKey:EXTRA_DATA];
                                                   [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_LINEAR_ACCELEROMETER
                                                                                                       object:nil
                                                                                                     userInfo:userInfo];
                                                   
                                               if([self getDBType] == AwareDBTypeSQLite){
                                                   [self saveData:dict];
                                               }else if([self getDBType] == AwareDBTypeJSON){
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
    EntityLinearAccelerometer* entityLinearAcc = (EntityLinearAccelerometer *)[NSEntityDescription
                                                                    insertNewObjectForEntityForName:entity
                                                                    inManagedObjectContext:childContext];
    
    entityLinearAcc.device_id = [data objectForKey:@"device_id"];
    entityLinearAcc.timestamp = [data objectForKey:@"timestamp"];
    entityLinearAcc.double_values_0 = [data objectForKey:@"double_values_0"];
    entityLinearAcc.double_values_1 = [data objectForKey:@"double_values_1"];
    entityLinearAcc.double_values_2 = [data objectForKey:@"double_values_2"];
    entityLinearAcc.accuracy = [data objectForKey:@"accuracy"];
    entityLinearAcc.label =  [data objectForKey:@"label"];
}

- (BOOL)stopSensor{
    [motionManager stopDeviceMotionUpdates];
    motionManager = nil;
    return YES;
}




@end
