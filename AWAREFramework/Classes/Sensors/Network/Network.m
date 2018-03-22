//
//  Network.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Network.h"
#import "SCNetworkReachability.h"
#import "EntityNetwork.h"

NSString * const AWARE_PREFERENCES_STATUS_NETWORK_EVENTS = @"status_network";

@implementation Network{
    SCNetworkReachability *reachability;
    NSTimer* sensingTimer;
    bool networkState;
    NSNumber* networkType;
    NSString* networkSubtype;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_NETWORK
                        dbEntityName:NSStringFromClass([EntityNetwork class])
                              dbType:dbType];
    if (self) {
        networkState= YES;
        networkType = @0;
        networkSubtype = @"";
        [self setCSVHeader:@[@"timestamp",
                             @"device_id",
                             @"network_type",
                             @"network_subtype",
                             @"network_state"]];
        [self addDefaultSettingWithBool:@NO key:AWARE_PREFERENCES_STATUS_NETWORK_EVENTS desc:@"True or False"];
    }
    return self;
}


- (void) createTable{
    // Send a create table query
    NSLog(@"[%@] Cretate Table", [self getSensorName]);
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "network_type integer default 0,"
    "network_subtype text default '',"
    "network_state integer default 0";
    // "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}

- (BOOL)startSensor{
    return [self startSensorWithSettings:nil];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings {
    // Set and start a network reachability sensor
    NSLog(@"Start Network Sensing!");
    reachability = [[SCNetworkReachability alloc] initWithHost:@"https://github.com"];
    [reachability reachabilityStatus:^(SCNetworkStatus status) {
         switch (status) {
             case SCNetworkStatusReachableViaWiFi:
                 NSLog(@"Reachable via WiFi");
                 networkState= YES;
                 networkType = @1;
                 networkSubtype = @"WIFI";
                 [self getNetworkInfo];

                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_INTERNET_AVAILABLE object:nil];
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_ON object:nil];
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_MOBILE_OFF object:nil];
                 
                 break;
             case SCNetworkStatusReachableViaCellular:
                 NSLog(@"Reachable via Cellular");
                 networkState= YES;
                 networkType = @4;
                 networkSubtype = @"MOBILE";
                 [self getNetworkInfo];
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_INTERNET_AVAILABLE object:nil];
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_OFF object:nil];
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_MOBILE_ON object:nil];
                 
                 break;
             case SCNetworkStatusNotReachable:
                 NSLog(@"Not Reachable");
                 networkType = @0;
                 networkState= NO;
                 networkSubtype = @"";
                 [self getNetworkInfo];
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_INTERNET_UNAVAILABLE object:nil];
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_OFF object:nil];
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_MOBILE_OFF object:nil];
                 
                 break;
         }
     }];
    return YES;
}


- (BOOL)stopSensor{
    // stop a reachability timer
    reachability = nil;
    
    return YES;
}

- (void)saveDummyData{
    [self getNetworkInfo];
}


//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////

- (void) getNetworkInfo{

    [self setLatestValue:[NSString stringWithFormat:@"%@", networkSubtype]];
 
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:networkType forKey:@"network_type"];
    [dict setObject:networkSubtype forKey:@"network_subtype"];
    [dict setObject:[NSNumber numberWithInt:networkState] forKey:@"network_state"];
    
    [self saveData:dict];
    [self setLatestData:dict];
}

- (void)insertNewEntityWithData:(NSDictionary *)data managedObjectContext:(NSManagedObjectContext *)childContext entityName:(NSString *)entity{
    EntityNetwork* entityNetwork = (EntityNetwork *)[NSEntityDescription
                                            insertNewObjectForEntityForName:entity
                                                     inManagedObjectContext:childContext];
    
    entityNetwork.device_id = [data objectForKey:@"device_id"];
    entityNetwork.timestamp = [data objectForKey:@"timestamp"];
    entityNetwork.network_type =    [data objectForKey:@"network_type"];
    entityNetwork.network_state =   [data objectForKey:@"network_state"];
    entityNetwork.network_subtype = [data objectForKey:@"network_subtype"];

}

@end
