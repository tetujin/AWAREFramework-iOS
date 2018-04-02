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
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_GRAVITY];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp",@"device_id", @"double_values_0", @"double_values_1",@"double_values_2", @"accuracy",@"label"];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_GRAVITY withHeader:header];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_GRAVITY entityName:NSStringFromClass([EntityGravity class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            EntityGravity* gravityData = (EntityGravity *)[NSEntityDescription
                                                                                           insertNewObjectForEntityForName:entity
                                                                                           inManagedObjectContext:childContext];
                                            
                                            gravityData.device_id = [data objectForKey:@"device_id"];
                                            gravityData.timestamp = [data objectForKey:@"timestamp"];
                                            gravityData.double_values_0 = [data objectForKey:@"double_values_0"];
                                            gravityData.double_values_1 = [data objectForKey:@"double_values_1"];
                                            gravityData.double_values_2 = [data objectForKey:@"double_values_2"];
                                            gravityData.label =  [data objectForKey:@"label"];
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_GRAVITY
                             storage:storage];
            //dbType:dbType];
    if (self) {
        motionManager = [[CMMotionManager alloc] init];
        super.sensingInterval = MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND;
        super.savingInterval = MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND;
        // [self setCSVHeader:];
    }
    return self;
}


- (void) createTable{
    if([self isDebug]){
        NSLog(@"[%@] Create Table", [self getSensorName]);
    }
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:@"double_values_0" type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:@"double_values_1" type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:@"double_values_2" type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:@"accuracy" type:TCQTypeInteger default:@"0"];
    [tcqMaker addColumn:@"label" type:TCQTypeText default:@"''"];
    [self.storage createDBTableOnServerWithTCQMaker:tcqMaker];
}

- (void)setParameters:(NSArray *)parameters{
    /// Get sensing frequency from settings
    // double interval = sensingInterval;
    double frequency = [self getSensorSetting:parameters withKey:@"frequency_gravity"];
    if(frequency != -1){
        NSLog(@"Gravity's frequency is %f !!", frequency);
        super.sensingInterval = [self convertMotionSensorFrequecyFromAndroid:frequency];
    }
    
    double tempHz = [self getSensorSetting:parameters withKey:AWARE_PREFERENCES_FREQUENCY_HZ_GRAVITY];
    if(tempHz > 0){
        super.sensingInterval = 1.0f/tempHz;
    }
}

- (BOOL)startSensorWithSensingInterval:(double)sensingInterval savingInterval:(double)savingInterval{
    // Set a buffer size for reducing file access
    if ([self isDebug]) {
        NSLog(@"[%@] Start Gravity Sensor", [self getSensorName]);
    }
 
    // [self setBufferSize:sensingInterval/savingInterval];
    [self.storage setBufferSize:savingInterval/sensingInterval];
    
    if( motionManager.deviceMotionAvailable ){
        motionManager.deviceMotionUpdateInterval = sensingInterval;
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
                                               [self.storage saveDataWithDictionary:dict buffer:YES saveInMainThread:NO];
                                               
                                               SensorEventCallBack callback = [self getSensorEventCallBack];
                                               if (callback != nil) {
                                                   callback(dict);
                                               }
                                               
//                                                   if([self getDBType] == AwareDBTypeSQLite){
//                                                       [self saveData:dict];
//                                                   }else if([self getDBType] == AwareDBTypeJSON){
//                                                       dispatch_async(dispatch_get_main_queue(), ^{
//                                                           [self saveData:dict];
//                                                       });
//                                                   }
                                               
                                               // });
                                           }];
    }

    return YES;
}


- (BOOL)stopSensor{
    [motionManager stopDeviceMotionUpdates];
    motionManager = nil;
    return YES;
}


/////////////// for TextFile based DB
//

@end
