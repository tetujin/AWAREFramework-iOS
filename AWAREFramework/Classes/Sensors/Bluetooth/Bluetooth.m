//
//  bluetooth.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/24/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
//  NOTE: This sensor can scan BLE devices' UUID. Those UUIDs not unique.
//

#import "Bluetooth.h"
#import "EntityBluetooth.h"
#import "BLEScanner.h"

NSString * const AWARE_PREFERENCES_STATUS_BLUETOOTH    = @"status_bluetooth";
NSString * const AWARE_PREFERENCES_FREQUENCY_BLUETOOTH = @"frequency_bluetooth";

@implementation Bluetooth {
    NSDate * sessionTime;
    
    NSString * KEY_BLUETOOTH_TIMESTAMP;
    NSString * KEY_BLUETOOTH_DEVICE_ID;
    NSString * KEY_BLUETOOTH_ADDRESS;
    NSString * KEY_BLUETOOTH_NAME;
    NSString * KEY_BLUETOOTH_RSSI;
    NSString * KEY_BLUETOOTH_LABLE;
    BLEScanner * scanner;
    
    NSTimer * mainTimer;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    KEY_BLUETOOTH_TIMESTAMP = @"timestamp";
    KEY_BLUETOOTH_DEVICE_ID = @"device_id";
    KEY_BLUETOOTH_ADDRESS = @"bt_address";
    KEY_BLUETOOTH_NAME = @"bt_name";
    KEY_BLUETOOTH_RSSI = @"bt_rssi";
    KEY_BLUETOOTH_LABLE = @"label";
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_BLUETOOTH];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header       = @[KEY_BLUETOOTH_TIMESTAMP,KEY_BLUETOOTH_DEVICE_ID,
                                   KEY_BLUETOOTH_ADDRESS,  KEY_BLUETOOTH_NAME,
                                   KEY_BLUETOOTH_RSSI,     KEY_BLUETOOTH_LABLE];
        NSArray * headerTypes  = @[@(CSVTypeReal),    @(CSVTypeText),
                                   @(CSVTypeText),    @(CSVTypeText),
                                   @(CSVTypeInteger), @(CSVTypeText)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_BLUETOOTH headerLabels:header headerTypes:headerTypes];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_BLUETOOTH entityName:NSStringFromClass([EntityBluetooth class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            EntityBluetooth* bluetoothData = (EntityBluetooth *)[NSEntityDescription
                                                                                                 insertNewObjectForEntityForName:entity
                                                                                                 inManagedObjectContext:childContext];
                                            bluetoothData.device_id = [data objectForKey:@"device_id"];
                                            bluetoothData.timestamp = [data objectForKey:@"timestamp"];
                                            bluetoothData.bt_address = [data objectForKey:@"bt_address"];
                                            bluetoothData.bt_name = [data objectForKey:@"bt_name"];
                                            bluetoothData.bt_rssi = [data objectForKey:@"bt_rssi"];
                                            bluetoothData.label = [data objectForKey:@"label"];
                                        }];
    }
    
    self = [super initWithAwareStudy:study sensorName:SENSOR_BLUETOOTH storage:storage];
    if (self) {
        _scanDuration = 30; // 30 second
        _scanInterval = 60*5; // 5 min
        sessionTime = [NSDate new];
        scanner = [BLEScanner sharedBLEScanner];
        [scanner setWellKnownTargetServiceUUIDs];
    }
    return self;
}

- (void) createTable{
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:KEY_BLUETOOTH_ADDRESS type:TCQTypeText    default:@"''"];
    [maker addColumn:KEY_BLUETOOTH_NAME    type:TCQTypeText    default:@"''"];
    [maker addColumn:KEY_BLUETOOTH_RSSI    type:TCQTypeInteger default:@"0"];
    [maker addColumn:KEY_BLUETOOTH_LABLE   type:TCQTypeText    default:@"''"];
    [self.storage createDBTableOnServerWithTCQMaker:maker];
}


- (void)setParameters:(NSArray *)parameters{
    double interval = [self getSensorSetting:parameters withKey:@"frequency_bluetooth"];
    if (interval > 0) {
        _scanInterval = interval;
    }
}


- (BOOL) startSensor {
    return [self startSensorWithScanInterval:_scanInterval duration:_scanDuration];
}


- (BOOL) startSensorWithScanInterval:(int)interval duration:(int)duration{
    [self startToScanBLEDevices];
    mainTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                 target:self
                                               selector:@selector(startToScanBLEDevices)
                                               userInfo:nil
                                                repeats:YES];
    
    [self setSensingState:YES];
    return YES;
}


- (BOOL) stopSensor {
    [self stopToScanBLEDevices];
    if (mainTimer!=nil) {
        [mainTimer invalidate];
        mainTimer = nil;
    }
    [self setSensingState:NO];
    return YES;
}


/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////

-(void)startToScanBLEDevices{
    if ([self isDebug]) NSLog(@"[Bluetooth] startToScanBluetooth");
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BLUETOOTH_SCAN_STARTED
                                                        object:nil
                                                      userInfo:nil];
    sessionTime = [NSDate new];

    [scanner startScanningWithHandler:^(NSString *uuid,
                                        NSString *name,
                                        NSNumber *rssi,
                                        NSDictionary<NSString *,id> *advertisementData) {
        [self saveBLEDeviceWithAddress:uuid name:name rssi:rssi];
        NSLog(@"name: %@", name);
    }];
    [self performSelector:@selector(stopToScanBLEDevices) withObject:nil afterDelay:_scanDuration];
}


- (void) stopToScanBLEDevices{
    if ([self isDebug]) NSLog(@"[Bluetooth] stopToScanBluetooth");
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BLUETOOTH_SCAN_ENDED
                                                        object:nil
                                                      userInfo:nil];
    [scanner stopScannning];
}

////////////////////////////////////////////////////////////
- (void) saveBLEDeviceWithAddress:(NSString *) address
                                       name:(NSString *) name
                                       rssi:(NSNumber *) rssi{
    if (name == nil)     name    = @"";
    if (address == nil)  address = @"";
    if (rssi == nil)     rssi    = @-1;
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSString * deviceId = [self getDeviceId];
    NSString * sTime = [[AWAREUtils getUnixTimestamp:sessionTime] stringValue];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:deviceId forKey:@"device_id"];
    [dict setObject:address  forKey:@"bt_address"];
    [dict setObject:name     forKey:@"bt_name"];
    [dict setObject:rssi     forKey:@"bt_rssi"];
    [dict setObject:sTime    forKey:@"label"];
    [self setLatestValue:[NSString stringWithFormat:@"%@(%@), %@", name, address,rssi]];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:NO];
    
    [self setLatestData:dict];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                         forKey:EXTRA_DATA];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BLUETOOTH_NEW_DEVICE
                                                        object:nil
                                                      userInfo:userInfo];
    
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, dict);
    }
}


- (void) remoteAllTargetServiceUUIDs{
    [scanner remoteAllTargetServiceUUIDs];
}

- (NSArray <CBUUID *> *) getTargetServiceUUIDs{
    return [scanner getTargetServiceUUIDs];
}

- (void) addTargetServiceUUIDs:(NSArray <CBUUID *>*) uuids{
    [scanner addTargetServiceUUIDs:uuids];
}

- (void) setTargetServiceUUIDs:(NSArray <CBUUID *>*) uuids{
    [scanner setTargetServiceUUIDs:uuids];
}

- (void) addTargetServiceUUID: (CBUUID *)uuid{
    [scanner addTargetServiceUUID:uuid];
}

- (void) setTargetServiceUUID: (CBUUID *)uuid{
    [scanner setTargetServiceUUID:uuid];
}

- (void) setWellKnownTargetServiceUUIDs{
    [scanner setWellKnownTargetServiceUUIDs];
}

@end
