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
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_BAROMETER
                                            entityName:NSStringFromClass([EntityBarometer class]) insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                                EntityBarometer * pressureData = (EntityBarometer *)[NSEntityDescription
                                                                                                     insertNewObjectForEntityForName:entity
                                                                                                     inManagedObjectContext:childContext];
                                                
                                                pressureData.device_id = [data objectForKey:@"device_id"];
                                                pressureData.timestamp = [data objectForKey:@"timestamp"];
                                                pressureData.double_values_0 = [data objectForKey:@"double_values_0"];
                                                pressureData.accuracy = @0;
                                                pressureData.label = @"";
                                            }];
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
    // NSString * query = [tcqMaker getDefaudltTableCreateQuery];
    [self.storage createDBTableOnServerWithTCQMaker:tcqMaker];
}

- (void)setParameters:(NSArray *)parameters{
    // Get a sensing frequency
    double frequency = [self getSensorSetting:parameters withKey:@"frequency_barometer"];
    if(frequency > 0){
        // NOTE: The frequency value is a microsecond
        [self setSensingIntervalWithSecond:frequency/1000000];
    }
}


- (BOOL)startSensorWithSensingInterval:(double)sensingInterval savingInterval:(double)savingInterval{
    
    // [self setBufferSize:savingInterval/sensingInterval];
    [self.storage setBufferSize:savingInterval/sensingInterval];
    
    timestamp = [[NSDate new] timeIntervalSince1970];
    
    // Set and start a sensor
    if ([self isDebug]) {
        NSLog(@"[%@] Start Barometer Sensor", [self getSensorName]);
    }
    if (![CMAltimeter isRelativeAltitudeAvailable]) {
        NSLog(@"This device doesen't support CMAltimeter.");
    } else {
        altitude = [[CMAltimeter alloc] init];
        
        [altitude startRelativeAltitudeUpdatesToQueue:[NSOperationQueue mainQueue]
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
                                                 [dict setObject:@"" forKey:@"label"];
                                                 [self setLatestValue:[NSString stringWithFormat:@"%f", pressureDouble*10.0f]];
                                                  
                                                  [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
                                                  
                                                  
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
    return YES;
}


- (BOOL)stopSensor{
    // Stop a altitude sensor
    [altitude stopRelativeAltitudeUpdates];
    altitude = nil;
    
    [super stopSensor];
    
    return YES;
}



@end
