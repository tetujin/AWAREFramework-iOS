//
//  Barometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Barometer.h"
#import "EntityBarometer.h"
#import "SQLiteStorage.h"
#import "JSONStorage.h"
#import "../../Core/Storage/SQLite/SQLiteSeparatedStorage.h"
#import "../../Core/Storage/SQLite/AWAREBatchDataOM+CoreDataClass.h"
#import "ObjectModels/AWAREBarometerOM+CoreDataClass.h"


NSString* const AWARE_PREFERENCES_STATUS_BAROMETER    = @"status_barometer";
NSString* const AWARE_PREFERENCES_FREQUENCY_BAROMETER = @"frequency_barometer";

@implementation Barometer{
    CMAltimeter* altitude;
    double timestamp;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_BAROMETER];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp",@"device_id", @"double_values_0",@"accuracy",@"label"];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeReal),@(CSVTypeInteger),@(CSVTypeText)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_BAROMETER headerLabels:header headerTypes:headerTypes];
    }else{
        SQLiteStorage * sqlite = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_BAROMETER
                                                           entityName:NSStringFromClass([EntityBarometer class])
                                                       insertCallBack:nil];
        NSError * error = nil;
        BOOL exist = [sqlite isExistUnsyncedDataWithError:error];
        if (!exist && error==nil) {
            storage = [[SQLiteSeparatedStorage alloc] initWithStudy:study sensorName:SENSOR_BAROMETER
                                                    objectModelName:NSStringFromClass([AWAREBarometerOM class])
                                                      syncModelName:NSStringFromClass([AWAREBatchDataOM class])
                                                          dbHandler:AWAREBarometerCoreDataHandler.shared];
        }else{
            if (error!=nil) {
                NSLog(@"[%@] Error: %@", [self getSensorName], error.debugDescription);
            }
            storage = sqlite;
        }
        
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_BAROMETER
                             storage:storage];
    if (self) {
        [self setSensingIntervalWithSecond:0.2f];
        [self setSavingIntervalWithSecond:30.0f]; // 30 sec
    }
    return self;
}


- (void) createTable{
    if ([self isDebug]){
        NSLog(@"[%@] Create Table", [self getSensorName]);
    }
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:@"double_values_0" type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:@"accuracy" type:TCQTypeInteger default:@"0"];
    [tcqMaker addColumn:@"label" type:TCQTypeText default:@"''"];
    [self.storage createDBTableOnServerWithTCQMaker:tcqMaker];
}

- (void)setParameters:(NSArray *)parameters{
    /// Get a sensing frequency
    double frequency = [self getSensorSetting:parameters withKey:@"frequency_barometer"];
    if(frequency > 0){
        /// NOTE: The frequency value is a microsecond
        [self setSensingIntervalWithSecond:frequency/1000000];
    }
}

- (BOOL)startSensor{
    return [self startSensorWithSensingInterval:self.sensingInterval savingInterval:self.savingInterval];
}

- (BOOL)startSensorWithSensingInterval:(double)sensingInterval savingInterval:(double)savingInterval{
    
    [self.storage setBufferSize:savingInterval/sensingInterval];
    
    timestamp = [[NSDate new] timeIntervalSince1970];
    
    /// Set and start a sensor
    if ([self isDebug]) {
        NSLog(@"[%@] Start Barometer Sensor", [self getSensorName]);
    }
    if (![CMAltimeter isRelativeAltitudeAvailable]) {
        NSLog(@"This device doesen't support CMAltimeter.");
    } else {
        altitude = [[CMAltimeter alloc] init];
        
        [altitude startRelativeAltitudeUpdatesToQueue:[NSOperationQueue currentQueue]
                                          withHandler:^(CMAltitudeData *altitudeData, NSError *error) {
                                              
                                              double currentTimestamp = [[NSDate new] timeIntervalSince1970];
                                              
                                              if( (currentTimestamp - self->timestamp) > super.sensingInterval ){
                                                  
                                                  self->timestamp = currentTimestamp;
                                                  
                                                 double pressureDouble = [altitudeData.pressure doubleValue];

                                                 NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                                 NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                                 [dict setObject:unixtime forKey:@"timestamp"];
                                                 [dict setObject:[self getDeviceId] forKey:@"device_id"];
                                                 [dict setObject:@(pressureDouble*10.0f) forKey:@"double_values_0"];
                                                 [dict setObject:@3 forKey:@"accuracy"];
                                                  if (self.label != nil) {
                                                      [dict setObject:self.label forKey:@"label"];
                                                  }else{
                                                      [dict setObject:@"" forKey:@"label"];
                                                  }
                                                 [self setLatestValue:[NSString stringWithFormat:@"%f", pressureDouble*10.0f]];
                                                  
                                                  [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:NO];
                                                  
                                                  
                                                  [self setLatestValue:[NSString stringWithFormat:@"%f", (pressureDouble * 10.0f)]];
                                                  
                                                  [self setLatestData:dict];
                                                  
                                                  NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                                                                       forKey:EXTRA_DATA];
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BAROMETER
                                                                                                      object:nil
                                                                                                    userInfo:userInfo];
                                                  SensorEventHandler handler = [self getSensorEventHandler];
                                                  if (handler!=nil) {
                                                      handler(self, dict);
                                                  }
                                              }
                                          }];
    }
    [self setSensingState:YES];
    return YES;
}


- (BOOL)stopSensor{
    /// Stop a altitude sensor
    [altitude stopRelativeAltitudeUpdates];
    altitude = nil;
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    [self setSensingState:NO];
    
    return YES;
}



@end


static AWAREBarometerCoreDataHandler * shared;
@implementation  AWAREBarometerCoreDataHandler
+ ( AWAREBarometerCoreDataHandler * _Nonnull)shared {
    @synchronized(self){
        if (!shared){
            shared =  (AWAREBarometerCoreDataHandler *)[[BaseCoreDataHandler alloc] initWithDBName:@"AWARE_Barometer"];
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
