//
//  BatteryDischarge.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "BatteryDischarge.h"
#import "EntityBatteryDischarge.h"

@implementation BatteryDischarge

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"battery_discharges"];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:@"battery_discharges" entityName:NSStringFromClass([EntityBatteryDischarge class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            EntityBatteryDischarge* batteryDischargeData = (EntityBatteryDischarge *)[NSEntityDescription
                                                                                                                      insertNewObjectForEntityForName:entity
                                                                                                                      inManagedObjectContext:childContext];
                                            batteryDischargeData.device_id = [data objectForKey:@"device_id"];
                                            batteryDischargeData.timestamp = [data objectForKey:@"timestamp"];
                                            batteryDischargeData.battery_start = [data objectForKey:@"battery_start"];
                                            batteryDischargeData.battery_end = [data objectForKey:@"battery_end"];
                                            batteryDischargeData.double_end_timestamp = [data objectForKey:@"double_end_timestamp"];
        }];
    }
    
    //////////////////////////
    
    self = [super initWithAwareStudy:study sensorName:@"battery_discharges" storage:storage];
    if (self != nil) {
        
    }
    return self;
}

- (void) createTable {
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:@"battery_start" type:TCQTypeInteger default:@"0"];
    [maker addColumn:@"battery_end" type:TCQTypeInteger default:@"0"];
    [maker addColumn:@"double_end_timestamp" type:TCQTypeReal default:@"0"];
    [self.storage createDBTableOnServerWithTCQMaker:maker];
    
//    NSString *query = [[NSString alloc] init];
//    query = @"_id integer primary key autoincrement,"
//    "timestamp real default 0,"
//    "device_id text default '',"
//    "battery_start integer default 0,"
//    "battery_end integer default 0,"
//    "double_end_timestamp real default 0";
//    // "UNIQUE (timestamp,device_id)";
//    [super createTable:query];
}

- (void)saveBatteryDischargeEventWithStartTimestamp:(NSNumber *)startTimestamp
                                       endTimestamp:(NSNumber *)endTimestamp
                                  startBatteryLevel:(NSNumber *)startBatteryLevel
                                    endBatteryLevel:(NSNumber *)endBatteryLevel{
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:startTimestamp forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:startBatteryLevel forKey:@"battery_start"];
    [dict setObject:endBatteryLevel forKey:@"battery_end"];
    [dict setObject:endTimestamp forKey:@"double_end_timestamp"];
    // [self saveData:dict];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:NO];
    
    [self setLatestData:dict];
    
    // Broadcast the battery discharge event
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                         forKey:EXTRA_DATA];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BATTERY_DISCHARGING
                                                        object:nil
                                                      userInfo:userInfo];
}


@end
