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
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_NETWORK];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp", @"device_id",@"network_type",@"network_subtype",@"network_state"];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_NETWORK withHeader:header];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_NETWORK entityName:NSStringFromClass([EntityNetwork class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            EntityNetwork* entityNetwork = (EntityNetwork *)[NSEntityDescription
                                                                                             insertNewObjectForEntityForName:entity
                                                                                             inManagedObjectContext:childContext];
                                            
                                            entityNetwork.device_id = [data objectForKey:@"device_id"];
                                            entityNetwork.timestamp = [data objectForKey:@"timestamp"];
                                            entityNetwork.network_type =    [data objectForKey:@"network_type"];
                                            entityNetwork.network_state =   [data objectForKey:@"network_state"];
                                            entityNetwork.network_subtype = [data objectForKey:@"network_subtype"];
                                        }];
    }
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_NETWORK
                             storage:storage];
    if (self) {
        networkState= YES;
        networkType = @0;
        networkSubtype = @"";
    }
    return self;
}


- (void) createTable{
    // Send a create table query
    if ([self isDebug]) {
        NSLog(@"[%@] Cretate Table", [self getSensorName]);
    }
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "network_type integer default 0,"
    "network_subtype text default '',"
    "network_state integer default 0";
    // "UNIQUE (timestamp,device_id)";
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void)setParameters:(NSArray *)parameters{
    
}

- (BOOL)startSensor{
    // Set and start a network reachability sensor
    if ([self isDebug]) {
        NSLog(@"Start Network Sensing!");
    }
    reachability = [[SCNetworkReachability alloc] initWithHost:@"https://github.com"];
    [reachability reachabilityStatus:^(SCNetworkStatus status) {
        switch (status) {
            case SCNetworkStatusReachableViaWiFi:
                NSLog(@"Reachable via WiFi");
                self->networkState= YES;
                self->networkType = @1;
                self->networkSubtype = @"WIFI";
                [self getNetworkInfo];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_INTERNET_AVAILABLE object:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_ON object:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_MOBILE_OFF object:nil];
                
                break;
            case SCNetworkStatusReachableViaCellular:
                NSLog(@"Reachable via Cellular");
                self->networkState= YES;
                self->networkType = @4;
                self->networkSubtype = @"MOBILE";
                [self getNetworkInfo];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_INTERNET_AVAILABLE object:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_OFF object:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_MOBILE_ON object:nil];
                
                break;
            case SCNetworkStatusNotReachable:
                NSLog(@"Not Reachable");
                self->networkType = @0;
                self->networkState= NO;
                self->networkSubtype = @"";
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
    
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
    [self setLatestData:dict];
    
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, dict);
    }
}


@end
