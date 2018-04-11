//
//  proximity.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Proximity.h"
#import "EntityProximity.h"

NSString* const AWARE_PREFERENCES_STATUS_PROXIMITY = @"status_proximity";
NSString* const AWARE_PREFERENCES_FREQUENCY_PROXIMITY = @"frequency_proximity";

@implementation Proximity

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_PROXIMITY];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp",@"device_id",@"double_proximity",@"accuracy",@"label"];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeReal),@(CSVTypeInteger),@(CSVTypeText)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_PROXIMITY headerLabels:header headerTypes:headerTypes];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_PROXIMITY entityName:NSStringFromClass([EntityProximity class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            EntityProximity* entityProximity = (EntityProximity *)[NSEntityDescription
                                                                                                   insertNewObjectForEntityForName:entity
                                                                                                   inManagedObjectContext:childContext];
                                            
                                            entityProximity.device_id = [data objectForKey:@"device_id"];
                                            entityProximity.timestamp = [data objectForKey:@"timestamp"];
                                            entityProximity.double_proximity = [data objectForKey:@"double_proximity"];
                                            entityProximity.accuracy = [data objectForKey:@"accuracy"];
                                            entityProximity.label = [data objectForKey:@"label"];
                                            
                                        }];
    }
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PROXIMITY
                             storage:storage];
    if (self) {
        
    }
    return self;
}

- (void) createTable{
    if([self isDebug]){
        NSLog(@"[%@] Create Table", [self getSensorName]);
    }
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "double_proximity real default 0,"
    "accuracy integer default 0,"
    "label text default ''";
    //"UNIQUE (timestamp,device_id)";
    [self.storage createDBTableOnServerWithQuery:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    if([self isDebug]){
        NSLog(@"[%@] Start Device Usage Sensor", [self getSensorName]);
    }
    // Set and start proximity sensor
    // NOTE: This sensor is not working in the background
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(proximitySensorStateDidChange:)
                                                 name:UIDeviceProximityStateDidChangeNotification
                                               object:nil];

    return YES;
}


- (BOOL)stopSensor{
    // Stop a sync timer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceProximityStateDidChangeNotification
                                                  object:nil];
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    return YES;
}


/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////


- (void)proximitySensorStateDidChange:(NSNotification *)notification {
    int state = [UIDevice currentDevice].proximityState;
    // NSLog(@"Proximity: %d", state );
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:[NSNumber numberWithInt:state] forKey:@"double_proximity"];
    [dict setObject:@0 forKey:@"accuracy"];
    [dict setObject:@"" forKey:@"label"];
    [self setLatestValue:[NSString stringWithFormat:@"[%d]", state ]];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
    [self setLatestData:dict];
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, dict);
    }
}



@end
