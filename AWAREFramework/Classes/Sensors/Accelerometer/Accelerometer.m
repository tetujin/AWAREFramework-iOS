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

NSString * const AWARE_PREFERENCES_STATUS_ACCELEROMETER    = @"status_accelerometer";
NSString * const AWARE_PREFERENCES_FREQUENCY_ACCELEROMETER = @"frequency_accelerometer";
NSString * const AWARE_PREFERENCES_FREQUENCY_HZ_ACCELEROMETER = @"frequency_hz_accelerometer";

@implementation Accelerometer{
    CMMotionManager *manager;
    double sensingInterval;
    int dbWriteInterval; //second
    int currentBufferSize;
    NSMutableArray * bufferArray;
    NSDictionary * defaultSettings;
    double hzMonitor;
    double hz;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:@"accelerometer"
                        dbEntityName:NSStringFromClass([EntityAccelerometer class])
                              dbType:dbType];
    if (self) {
        manager = [[CMMotionManager alloc] init];
        sensingInterval = MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND;
        dbWriteInterval = MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND;
        bufferArray = [[NSMutableArray alloc] init];
        currentBufferSize = 0;
        hz = 0;
        hzMonitor = 0;
        [self setCSVHeader:@[@"timestamp",@"device_id",@"double_values_0",@"double_values_1",@"double_values_2",@"accuracy",@"label"]];
        
        [self addDefaultSettingWithBool:@NO       key:AWARE_PREFERENCES_STATUS_ACCELEROMETER        desc:@"true or false to activate or deactivate accelerometer sensor."];
        [self addDefaultSettingWithNumber:@200000 key:AWARE_PREFERENCES_FREQUENCY_ACCELEROMETER     desc:@"non-deterministic frequency in microseconds (dependent of the hardware sensor capabilities and resources), e.g., 200000 (normal), 60000 (UI), 20000 (game), 0 (fastest)."];
        [self addDefaultSettingWithNumber:@0    key:AWARE_PREFERENCES_FREQUENCY_HZ_ACCELEROMETER desc:@"100-1Hz (defualt=0)"];
    }
    
    return self;
}

- (void) createTable {
    NSLog(@"[%@] Create Table", [self getSensorName]);
    TCQMaker * queryMaker = [[TCQMaker alloc] init];
    [queryMaker addColumn:@"double_values_0" type:TCQTypeReal default:@"0"];
    [queryMaker addColumn:@"double_values_1" type:TCQTypeReal default:@"0"];
    [queryMaker addColumn:@"double_values_2" type:TCQTypeReal default:@"0"];
    [queryMaker addColumn:@"accuracy" type:TCQTypeInteger default:@"0"];
    [queryMaker addColumn:@"label" type:TCQTypeText default:@"''"];
    NSString * query = [queryMaker getDefaudltTableCreateQuery];
    [super createTable:query];
}

/**
 *
 */
- (BOOL) startSensorWithSettings:(NSArray *)settings{

    double frequency = sensingInterval;
    if(settings != nil){
        double tempFrequency = [self getSensorSetting:settings withKey:AWARE_PREFERENCES_FREQUENCY_ACCELEROMETER];
        if(tempFrequency != -1){
            frequency = [self convertMotionSensorFrequecyFromAndroid:tempFrequency];
        }
    }
    
    double tempHz = [self getSensorSetting:settings withKey:AWARE_PREFERENCES_FREQUENCY_HZ_ACCELEROMETER];
    if(tempHz > 0){
        frequency = 1.0f/tempHz;
    }
    
    int buffer = dbWriteInterval/frequency;
    
    return [self startSensorWithInterval:frequency bufferSize:buffer];
}


- (BOOL) startSensor {
    // NSDictionary * defaultSettings = [self getDefaultSettings];
    // double frequency = [[defaultSettings objectForKey:AWARE_PREFERENCES_FREQUENCY_ACCELEROMETER] doubleValue];
    return [self startSensorWithInterval:sensingInterval];
}

- (BOOL) startSensorWithInterval:(double)interval{
    return [self startSensorWithInterval:interval bufferSize:[self getBufferSize]];
}

- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer{
    return [self startSensorWithInterval:interval bufferSize:buffer fetchLimit:[self getFetchLimit]];
}
            
/**
 * Start sensor with interval and buffer, fetchLimit
 */
- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer fetchLimit:(int)fetchLimit{
    
    [super startSensor];
    
    // Set and start a data uploader
    NSLog(@"[%@] Start Sensor!", [self getSensorName]);
    
    // Set buffer size for reducing file access
    [self setBufferSize:buffer];
    
    [self setFetchLimit:fetchLimit];
    
    manager.accelerometerUpdateInterval = interval;
    
    // Set and start a motion sensor
    [manager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                  withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                      if( error ) {
                                          NSLog(@"%@:%ld", [error domain], [error code] );
                                      } else {
                                          
                                          // SQLite
                                          NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                          [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
                                          [dict setObject:[self getDeviceId] forKey:@"device_id"];
                                          [dict setObject:@(accelerometerData.acceleration.x) forKey:@"double_values_0"];
                                          [dict setObject:@(accelerometerData.acceleration.y) forKey:@"double_values_1"];
                                          [dict setObject:@(accelerometerData.acceleration.z) forKey:@"double_values_2"];
                                          [dict setObject:@3 forKey:@"accuracy"];
                                          [dict setObject:@"" forKey:@"label"];
                                          // NSLog(@"%f", accelerometerData.acceleration.x);
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
                                          
                                          
                                          ////// SQLite DB ////////
                                          if([self getDBType] == AwareDBTypeCoreData) {
                                              [self saveData:dict];
                                         //////////// Text File based DB ///////////////////////////////////
                                          } else if ([self getDBType] == AwareDBTypeTextFile){
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                     [self saveData:dict];
                                                });
                                          }
                                          
                                          ////////////////////////////////
//                                          if ( hzMonitor == 0 ) {
//                                              hzMonitor = [[NSDate date] timeIntervalSince1970];
//                                          } else {
//                                              double gap = ([[NSDate new] timeIntervalSince1970] - hzMonitor);
//                                              if (gap > 1) {
//                                                  NSLog(@"Hz:%f(hz)",hz);
//                                                  hzMonitor = [[NSDate date] timeIntervalSince1970];
//                                                  hz=0;
//                                              }
//                                          }
//                                          hz++;
                                      }
                                  }];

    return YES;
}

- (void)insertNewEntityWithData:(NSDictionary *)data managedObjectContext:(NSManagedObjectContext *)childContext entityName:(NSString *)entity{
    EntityAccelerometer * entityAcc = (EntityAccelerometer *)[NSEntityDescription
                                                           insertNewObjectForEntityForName:entity
                                                           inManagedObjectContext:childContext];
    entityAcc.device_id = [self getDeviceId];
    entityAcc.timestamp = [data objectForKey:@"timestamp"];
    entityAcc.double_values_0 = [data objectForKey:@"double_values_0"];
    entityAcc.double_values_1 = [data objectForKey:@"double_values_1"];
    entityAcc.double_values_2 = [data objectForKey:@"double_values_2"];
    entityAcc.accuracy = [data objectForKey:@"accuracy"];
    entityAcc.label = [data objectForKey:@"label"];
    
    // NSLog(@"%@",entityAcc.debugDescription);
    
}


-(BOOL) stopSensor {
    [super stopSensor];
    [manager stopAccelerometerUpdates];
    return YES;
}



///////////////////////////////////////////////////
///////////////////////////////////////////////////

- (BOOL) setInterval:(double)interval{
    // [self setDefaultSettingWithNumber:@(interval) key:AWARE_PREFERENCES_FREQUENCY_ACCELEROMETER];
    sensingInterval = interval;
    return YES;
}

- (double) getInterval{
    // NSDictionary * settings = [self getDefaultSettings];
    // return [[settings objectForKey:AWARE_PREFERENCES_FREQUENCY_ACCELEROMETER] doubleValue];
    return sensingInterval;
}

@end
