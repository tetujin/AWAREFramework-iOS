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
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_LINEAR_ACCELEROMETER];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp",@"device_id", @"double_values_0", @"double_values_1",@"double_values_2", @"accuracy",@"label"];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_LINEAR_ACCELEROMETER withHeader:header];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_LINEAR_ACCELEROMETER entityName:NSStringFromClass([EntityLinearAccelerometer class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
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
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_LINEAR_ACCELEROMETER
                        storage:storage];
    if (self) {
        motionManager = [[CMMotionManager alloc] init];
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
    // [super createTable:query];
    [self.storage createDBTableOnServerWithQuery:query];
}


- (void)setParameters:(NSArray *)parameters{
    if (parameters != nil) {
        double frequency = [self getSensorSetting:parameters withKey:@"frequency_linear_accelerometer"];
        if(frequency != -1){
            [self setSensingIntervalWithSecond:[self convertMotionSensorFrequecyFromAndroid:frequency]];
        }
        double hz = [self getSensorSetting:parameters withKey:AWARE_PREFERENCES_FREQUENCY_HZ_LINEAR_ACCELEROMETER];
        if(hz > 0){
            [self setSensingIntervalWithSecond:1.0f/hz];
        }
    }
}

-(BOOL)startSensorWithSensingInterval:(double)sensingInterval savingInterval:(double)savingInterval{

    if ([self isDebug]) {
        NSLog(@"[%@] Start Linear Acc Sensor", [self getSensorName]);
    }
    
    // Set a buffer size for reducing file access
    // [self setBufferSize:savingInterval/sensingInterval];
    [self.storage setBufferSize:savingInterval/sensingInterval];
    
    if( motionManager.deviceMotionAvailable ){
        motionManager.deviceMotionUpdateInterval = sensingInterval;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                           withHandler:^(CMDeviceMotion *motion, NSError *error){
                                               // Save sensor data to the local database
                                               
                                               
                                                   if (self.threshold > 0 && [self getLatestData] !=nil &&
                                                       ![self isHigherThanThresholdWithTargetValue:motion.userAcceleration.x lastValueKey:@"double_values_0"] &&
                                                       ![self isHigherThanThresholdWithTargetValue:motion.userAcceleration.y lastValueKey:@"double_values_1"] &&
                                                       ![self isHigherThanThresholdWithTargetValue:motion.userAcceleration.z lastValueKey:@"double_values_2"]
                                                       ) {
                                                       return;
                                                   }
                                               
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
                                               
                                               [self.storage saveDataWithDictionary:dict buffer:YES saveInMainThread:NO];
                                               
                                               SensorEventHandler handler = [self getSensorEventHandler];
                                               if (handler!=nil) {
                                                   handler(self, dict);
                                               }
                                           }];
    }
    return YES;
}


- (BOOL)stopSensor{
    [motionManager stopDeviceMotionUpdates];
    motionManager = nil;
    return YES;
}




@end
