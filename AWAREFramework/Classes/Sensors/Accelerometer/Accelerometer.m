//
//  Accelerometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Accelerometer.h"
#import "AWAREUtils.h"
#import "EntityAccelerometer.h"
#import "EntityAccelerometer+CoreDataProperties.h"
#import "JSONStorage.h"
#import "SQLiteStorage.h"

NSString * const AWARE_PREFERENCES_STATUS_ACCELEROMETER    = @"status_accelerometer";
NSString * const AWARE_PREFERENCES_FREQUENCY_ACCELEROMETER = @"frequency_accelerometer";
NSString * const AWARE_PREFERENCES_FREQUENCY_HZ_ACCELEROMETER = @"frequency_hz_accelerometer";
NSString * const AWARE_PREFERENCES_THRESHOLD_ACCELEROMETER = @"threshold_accelerometer";

@implementation Accelerometer{
    CMMotionManager *manager;
    NSArray * lastValues;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"accelerometer"];
    } else if (dbType == AwareDBTypeCSV){
        NSArray * headerLabels = @[@"timestamp",@"device_id",@"double_values_0",@"double_values_1",@"double_values_2",@"accuracy",@"label"];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeInteger),@(CSVTypeText)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:@"accelerometer" headerLabels:headerLabels headerTypes:headerTypes];
    } else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:@"accelerometer" entityName:NSStringFromClass([EntityAccelerometer class]) insertCallBack:^(NSDictionary *dataDict, NSManagedObjectContext *childContext, NSString *entity) {
            EntityAccelerometer * entityAcc = (EntityAccelerometer *)[NSEntityDescription
                                                                      insertNewObjectForEntityForName:entity
                                                                      inManagedObjectContext:childContext];
            entityAcc.device_id = [self getDeviceId];
            entityAcc.timestamp = [dataDict objectForKey:@"timestamp"];
            entityAcc.double_values_0 = [dataDict objectForKey:@"double_values_0"];
            entityAcc.double_values_1 = [dataDict objectForKey:@"double_values_1"];
            entityAcc.double_values_2 = [dataDict objectForKey:@"double_values_2"];
            entityAcc.accuracy = [dataDict objectForKey:@"accuracy"];
            entityAcc.label = [dataDict objectForKey:@"label"];
        }];
    }
    self = [super initWithAwareStudy:study
                          sensorName:@"accelerometer"
                             storage:storage];
    if (self) {
        manager = [[CMMotionManager alloc] init];
        lastValues = [[NSArray alloc] init];
    }
    
    return self;
}

- (void) createTable {
    if ([self isDebug]){
        NSLog(@"[%@] Create Table", [self getSensorName]);
    }
    TCQMaker * queryMaker = [[TCQMaker alloc] init];
    [queryMaker addColumn:@"double_values_0" type:TCQTypeReal default:@"0"];
    [queryMaker addColumn:@"double_values_1" type:TCQTypeReal default:@"0"];
    [queryMaker addColumn:@"double_values_2" type:TCQTypeReal default:@"0"];
    [queryMaker addColumn:@"accuracy" type:TCQTypeInteger default:@"0"];
    [queryMaker addColumn:@"label" type:TCQTypeText default:@"''"];
    [self.storage createDBTableOnServerWithTCQMaker:queryMaker];
}



- (void)setParameters:(NSArray *)parameters{
    if(parameters != nil){
        double tempFrequency = [self getSensorSetting:parameters withKey:AWARE_PREFERENCES_FREQUENCY_ACCELEROMETER];
        if(tempFrequency != -1){
            [self setSensingIntervalWithSecond:[self convertMotionSensorFrequecyFromAndroid:tempFrequency]];
        }
        
        double tempHz = [self getSensorSetting:parameters withKey:AWARE_PREFERENCES_FREQUENCY_HZ_ACCELEROMETER];
        if(tempHz > 0){
            [self setSensingIntervalWithSecond:1.0f/tempHz];
        }
        
        double threshold = [self getSensorSetting:parameters withKey:@"threshold_accelerometer"];
        if (threshold > 0) {
            [self setThreshold:threshold];
        }
    }
}


- (BOOL) startSensorWithSensingInterval:(double)sensingInterval
                         savingInterval:(double)savingInterval{
    // Set and start a data uploader
    if ([self isDebug]) {
        NSLog(@"[%@] Start Sensor!", [self getSensorName]);
    }
    
    if (![manager isAccelerometerAvailable]) {
        if ([self isDebug]) { NSLog(@"[accelerometer] accelerometer sensor is not supported.");}
        return NO;
    }
    
    // Set buffer size for reducing file access
    [self.storage setBufferSize:savingInterval/sensingInterval];
    
    manager.accelerometerUpdateInterval = sensingInterval;
    
    // Set and start a motion sensor
    [manager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                  withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                      if( error ) {
                                          NSLog(@"[accelerometer] %@:%ld", [error domain], [error code] );
                                      } else {
                                          
                                          if (self.threshold > 0 && [self getLatestData] !=nil &&
                                             ![self isHigherThanThresholdWithTargetValue:accelerometerData.acceleration.x lastValueKey:@"double_values_0"] &&
                                             ![self isHigherThanThresholdWithTargetValue:accelerometerData.acceleration.y lastValueKey:@"double_values_1"] &&
                                             ![self isHigherThanThresholdWithTargetValue:accelerometerData.acceleration.z lastValueKey:@"double_values_2"]
                                            ) {
                                              return;
                                          }
                                          
                                          // SQLite
                                          NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                          [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
                                          [dict setObject:[self getDeviceId] forKey:@"device_id"];
                                          [dict setObject:@(accelerometerData.acceleration.x) forKey:@"double_values_0"];
                                          [dict setObject:@(accelerometerData.acceleration.y) forKey:@"double_values_1"];
                                          [dict setObject:@(accelerometerData.acceleration.z) forKey:@"double_values_2"];
                                          [dict setObject:@3 forKey:@"accuracy"];
                                          [dict setObject:@"" forKey:@"label"];
                                          [self setLatestValue:[NSString stringWithFormat:
                                                                @"%f, %f, %f",
                                                                accelerometerData.acceleration.x,
                                                                accelerometerData.acceleration.y,
                                                                accelerometerData.acceleration.z]];
                                          
                                          [self setLatestData:dict];
                                          
                                          NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                                                               forKey:EXTRA_DATA];
                                          [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_ACCELEROMETER
                                                                                              object:nil
                                                                                            userInfo:userInfo];
                                          
                                          SensorEventHandler handler = [self getSensorEventHandler];
                                          if (handler!=nil) {
                                              handler(self, dict);
                                          }
                                          
                                          [self.storage saveDataWithDictionary:dict buffer:YES saveInMainThread:NO];
                                      }
                                  }];

    return YES;
}



-(BOOL) stopSensor {
    [manager stopAccelerometerUpdates];
    return YES;
}


@end
