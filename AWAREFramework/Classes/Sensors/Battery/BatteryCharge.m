//
//  BatteryCharge.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "BatteryCharge.h"
#import "EntityBatteryCharge.h"

@implementation BatteryCharge

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"battery_charges"];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:@"battery_charges" entityName:NSStringFromClass([EntityBatteryCharge class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            EntityBatteryCharge* batteryChargeData = (EntityBatteryCharge *)[NSEntityDescription
                                                                                                             insertNewObjectForEntityForName:entity
                                                                                                             inManagedObjectContext:childContext];
                                            batteryChargeData.device_id = [data objectForKey:@"device_id"];
                                            batteryChargeData.timestamp = [data objectForKey:@"timestamp"];
                                            batteryChargeData.battery_start = [data objectForKey:@"battery_start"];
                                            batteryChargeData.battery_end = [data objectForKey:@"battery_end"];
                                            batteryChargeData.double_end_timestamp = [data objectForKey:@"double_end_timestamp"];
                                        }];
    }
    //////////////////////////////////////////
    self = [super initWithAwareStudy:study sensorName:@"battery_charges" storage:storage];
    if (self!=nil) {
        
    }
    return self;
    
}

- (void)createTable{
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
//    [self createTable:query];
}

- (void)saveBatteryChargeEventWithStartTimestamp:(NSNumber *)startTimestamp
                                    endTimestamp:(NSNumber *)endTimestamp
                               startBatteryLevel:(NSNumber *)startBatteryLevel
                                 endBatteryLevel:(NSNumber *)endBatteryLevel
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:startTimestamp forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:startBatteryLevel forKey:@"battery_start"];
    [dict setObject:endBatteryLevel forKey:@"battery_end"];
    [dict setObject:endTimestamp forKey:@"double_end_timestamp"];
    // Save battery charge event
    // [self saveData:dict];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:NO];
    
    [self setLatestData:dict];
    
    // Broadcast events
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                         forKey:EXTRA_DATA];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BATTERY_CHARGING
                                                        object:nil
                                                      userInfo:userInfo];

}



@end
