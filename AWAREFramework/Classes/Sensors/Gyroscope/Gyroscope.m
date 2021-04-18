//
//  Gyroscope.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Gyroscope.h"
#import "AWAREUtils.h"
#import "EntityGyroscope.h"
#import "../../Core/Storage/SQLite/AWAREBatchDataOM+CoreDataClass.h"
#import "../../Core/Storage/SQLite/SQLiteSeparatedStorage.h"
#import "ObjectModels/AWAREGyroscopeOM+CoreDataClass.h"

NSString* const AWARE_PREFERENCES_STATUS_GYROSCOPE = @"status_gyroscope";
NSString* const AWARE_PREFERENCES_FREQUENCY_GYROSCOPE = @"frequency_gyroscope";
NSString* const AWARE_PREFERENCES_FREQUENCY_HZ_GYROSCOPE = @"frequency_hz_gyroscope";

@implementation Gyroscope{
    CMMotionManager* gyroManager;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_GYROSCOPE];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp",@"device_id", @"double_values_0", @"double_values_1",@"double_values_2", @"accuracy",@"label"];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeInteger),@(CSVTypeText)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_GYROSCOPE headerLabels:header headerTypes:headerTypes];
    }else{
        SQLiteStorage * sqlite = [[SQLiteStorage alloc] initWithStudy:study
                                            sensorName:SENSOR_GYROSCOPE
                                            entityName:NSStringFromClass([EntityGyroscope class])
                                        insertCallBack:nil];
        /// use the separated database if the existing database is empty
        NSError * error = nil;
        BOOL exist = [sqlite isExistUnsyncedDataWithError:error];
        if (!exist && error==nil) {
            storage = [[SQLiteSeparatedStorage alloc] initWithStudy:study sensorName:SENSOR_GYROSCOPE
                                                    objectModelName:NSStringFromClass([AWAREGyroscopeOM class])
                                                      syncModelName:NSStringFromClass([AWAREBatchDataOM class])
                                                          dbHandler:AWAREGyroscopeCoreDataHandler.shared];
        }else{
            if (error!=nil) {
                NSLog(@"[%@] Error: %@", [self getSensorName], error.debugDescription);
            }
            storage = sqlite;
        }
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_GYROSCOPE
                             storage:storage];
    if (self) {
        gyroManager = [[CMMotionManager alloc] init];
    }
    return self;
}

- (void) createTable{
    // Send a table create query
    if ([self isDebug]) {
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
//    [super createTable:query];
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void)setParameters:(NSArray *)parameters{
    // Get a sensing frequency from settings
    if(parameters != nil){
        double frequency = [self getSensorSetting:parameters withKey:@"frequency_gyroscope"];
        if(frequency != -1){
            [self setSensingIntervalWithSecond:[self convertMotionSensorFrequecyFromAndroid:frequency]];
        }

        double tempHz = [self getSensorSetting:parameters withKey:AWARE_PREFERENCES_FREQUENCY_HZ_GYROSCOPE];
        if(tempHz > 0){
            [self setSensingIntervalWithSecond:1.0f/tempHz];
        }
    }
}

- (BOOL)startSensorWithSensingInterval:(double)sensingInterval savingInterval:(double)savingInterval{
    
    // Set and start a data uploader
    if([self isDebug]){
        NSLog(@"[%@] Start Gyro Sensor", [self getSensorName]);
    }
    
//    [self setBufferSize:savingInterval/sensingInterval];
    [self.storage setBufferSize:savingInterval/sensingInterval];

    gyroManager.gyroUpdateInterval = sensingInterval;
    
    // Start a sensor
    [gyroManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                             withHandler:^(CMGyroData * _Nullable gyroData,
                                           NSError * _Nullable error) {
                                 
                                     if( error ) {
                                         NSLog(@"%@:%zd", [error domain], [error code] );
                                     } else {
                                         
                                         if (self.threshold > 0 && [self getLatestData] !=nil &&
                                             ![self isHigherThanThresholdWithTargetValue:gyroData.rotationRate.x lastValueKey:@"double_values_0"] &&
                                             ![self isHigherThanThresholdWithTargetValue:gyroData.rotationRate.y lastValueKey:@"double_values_1"] &&
                                             ![self isHigherThanThresholdWithTargetValue:gyroData.rotationRate.z lastValueKey:@"double_values_2"]
                                             ) {
                                             return;
                                         }
                                         
                                         NSNumber *unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                         NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                         [dict setObject:unixtime forKey:@"timestamp"];
                                         [dict setObject:[self getDeviceId] forKey:@"device_id"];
                                         [dict setObject:@(gyroData.rotationRate.x) forKey:@"double_values_0"];
                                         [dict setObject:@(gyroData.rotationRate.y) forKey:@"double_values_1"];
                                         [dict setObject:@(gyroData.rotationRate.z) forKey:@"double_values_2"];
                                         [dict setObject:@3 forKey:@"accuracy"];
                                         if (self.label != nil) {
                                             [dict setObject:self.label forKey:@"label"];
                                         }else{
                                             [dict setObject:@"" forKey:@"label"];
                                         }
                                         [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",gyroData.rotationRate.x,gyroData.rotationRate.y,gyroData.rotationRate.z]];
                                         
                                         [self setLatestData:dict];
                                         
                                         [self.storage saveDataWithDictionary:dict buffer:YES saveInMainThread:NO];
                                         
                                         NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                                                              forKey:EXTRA_DATA];
                                         [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_GYROSCOPE
                                                                                             object:nil
                                                                                           userInfo:userInfo];
                                         SensorEventHandler handler = [self getSensorEventHandler];
                                         if (handler!=nil) {
                                             handler(self, dict);
                                         }
                                    }
                             }];
    [self setSensingState:YES];
    return YES;
}


- (BOOL)stopSensor{
    [gyroManager stopGyroUpdates];
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    [self setSensingState:NO];
    return YES;
}


@end


static AWAREGyroscopeCoreDataHandler * shared;
@implementation AWAREGyroscopeCoreDataHandler
+ (AWAREGyroscopeCoreDataHandler * _Nonnull)shared {
    @synchronized(self){
        if (!shared){
            shared =  (AWAREGyroscopeCoreDataHandler *)[[BaseCoreDataHandler alloc] initWithDBName:@"AWARE_Gyroscope"];
        }
    }
    return shared;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (shared == nil) {
            shared= [super allocWithZone:zone];
            return shared;
        }
    }
    return nil;
}

@end
