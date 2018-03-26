//
//  Timezone.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Timezone.h"
#import "EntityTimezone.h"
#import "AWAREKeys.h"

NSString* const AWARE_PREFERENCES_STATUS_TIMEZONE = @"status_timezone";
NSString* const AWARE_PREFERENCES_FREQUENCY_TIMEZONE = @"frequency_timezone";

@implementation Timezone{
    NSTimer * sensingTimer;
    double updateInterval;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_TIMEZONE
                        dbEntityName:NSStringFromClass([EntityTimezone class])
                              dbType:dbType
                          bufferSize:0];
    if (self) {
        updateInterval = 60*60;// 3600 sec. = 1 hour
        [self setCSVHeader:@[@"timestamp",@"device_id",@"timezone"]];
        
        [self addDefaultSettingWithBool:@NO       key:AWARE_PREFERENCES_STATUS_TIMEZONE      desc:@"true or false to activate or deactivate sensor."];
        [self addDefaultSettingWithNumber:@3600   key:AWARE_PREFERENCES_FREQUENCY_TIMEZONE   desc:@"how frequently we check the device’s timezone, in seconds – default is 3600 seconds (i.e.,  1h)."];
        
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
    "timezone text default ''";
    //"UNIQUE (timestamp,device_id)";
    [super createTable:query];
}

- (void)setParameters:(NSArray *)parameters{
    // Get a frequency of data upload from settings
    double frequency = [self getSensorSetting:parameters withKey:@"frequency_timezone"];
    if (frequency > 0) {
        updateInterval = frequency ;//60*60;//3600 sec = 1 hour
    }
}

- (BOOL) startSensor{
    return [self startSensorWithInterval:updateInterval];
}

- (BOOL) startSensorWithInterval:(double)interval{
    
    // Set and start sensing timer
    if ([self isDebug]) {
        NSLog(@"[%@] Start Device Usage Sensor", [self getSensorName]);
    }
    [self getTimezone];
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                    target:self
                                                  selector:@selector(getTimezone)
                                                  userInfo:nil
                                                   repeats:YES];
    return YES;
}



- (BOOL)stopSensor{
    // Stop a sync timer
    [sensingTimer invalidate];
    sensingTimer = nil;
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    return YES;
}


- (void)saveDummyData{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:[[NSTimeZone localTimeZone] description] forKey:@"timezone"];
    [self saveData:dict];
}

/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////


- (void) getTimezone {
    [NSTimeZone localTimeZone];
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:[[NSTimeZone localTimeZone] description] forKey:@"timezone"];
    [self setLatestValue:[NSString stringWithFormat:@"%@", [[NSTimeZone localTimeZone] description]]];
    [self saveData:dict];
    [self setLatestData:dict];
    
    // Broadcast
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                         forKey:EXTRA_DATA];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_TIMEZONE
                                                        object:nil
                                                      userInfo:userInfo];

    
}

- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{
    EntityTimezone* entityTimezone = (EntityTimezone *)[NSEntityDescription
                                              insertNewObjectForEntityForName:entity
                                              inManagedObjectContext:childContext];
    
    entityTimezone.device_id = [data objectForKey:@"device_id"];
    entityTimezone.timestamp = [data objectForKey:@"timestamp"];
    entityTimezone.timezone = [[NSTimeZone localTimeZone] description];
}

@end

