//
//  NTPTime.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "NTPTime.h"
#import "ios-ntp.h"
#import "EntityNTPTime.h"

NSString * const AWARE_PREFERENCES_STATUS_NTPTIME = @"status_plugin_ntptime";

@implementation NTPTime  {
    NSTimer * sensingTimer;
 }

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_NTPTIME];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_NTPTIME entityName:NSStringFromClass([EntityNTPTime class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            EntityNTPTime * entityNTP = (EntityNTPTime *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                                                       inManagedObjectContext:childContext];
                                            entityNTP.device_id = [data objectForKey:@"device_id"];
                                            entityNTP.timestamp = [data objectForKey:@"timestamp"];;
                                            entityNTP.drift     = [data objectForKey:@"drift"];
                                            entityNTP.ntp_time  = [data objectForKey:@"ntp_time"];
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_NTPTIME
                             storage:storage];
    if (self) {
        _intervalSec = 60*10; // 10 min
        
//        [self setCSVHeader:@[@"timestamp", @"device_id", @"drift", @"ntp_time"]];
//
//        [self setTypeAsPlugin];
//        [self addDefaultSettingWithBool:@NO key:AWARE_PREFERENCES_STATUS_NTPTIME desc:@"true or false to activate or deactivate accelerometer sensor."];
        
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
    "drift real default 0," //clocks drift from ntp time
    "ntp_time real default 0"; //actual ntp timestamp in milliseconds
    // "UNIQUE (timestamp,device_id)";
    // [[ ]][super createTable:query];
    [self.storage createDBTableOnServerWithQuery:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    if ([self isDebug]){
        NSLog(@"[%@] Start Device Usage Sensor", [self getSensorName]);
    }
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:_intervalSec
                                                    target:self
                                                  selector:@selector(getNTPTime)
                                                  userInfo:nil
                                                   repeats:YES];
    [self getNTPTime];
    
    return YES;
}



- (BOOL)stopSensor{
    [sensingTimer invalidate];
    return YES;
}


///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////

- (void) getNTPTime {
    NetworkClock * nc = [NetworkClock sharedNetworkClock];
    NSDate * nt = nc.networkTime;
    double offset = nc.networkOffset * 1000;
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSNumber * ntpUnixtime = [AWAREUtils getUnixTimestamp:nt];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:[NSNumber numberWithDouble:offset] forKey:@"drift"]; // real
    [dict setObject:ntpUnixtime forKey:@"ntp_time"]; // real

    [self setLatestValue:[NSString stringWithFormat:@"[%f] %@",offset, nt ]];
    
    //dispatch_async(dispatch_get_main_queue(), ^{
    [self setLatestData:dict];
    // [self saveData:dict];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
    //});
}


- (void)saveDummyData{
    [self getNTPTime];
}


@end
