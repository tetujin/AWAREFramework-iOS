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

NSString * const AWARE_PREFERENCES_STATUS_BLUETOOTH    = @"status_bluetooth";
NSString * const AWARE_PREFERENCES_FREQUENCY_BLUETOOTH = @"frequency_bluetooth";

@implementation Bluetooth {
    NSTimer * scanTimer;
    NSDate * sessionTime;
    
    NSString * KEY_BLUETOOTH_TIMESTAMP;
    NSString * KEY_BLUETOOTH_DEVICE_ID;
    NSString * KEY_BLUETOOTH_ADDRESS;
    NSString * KEY_BLUETOOTH_NAME;
    NSString * KEY_BLUETOOTH_RSSI;
    NSString * KEY_BLUETOOTH_LABLE;
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
        NSArray * header = @[KEY_BLUETOOTH_TIMESTAMP, KEY_BLUETOOTH_DEVICE_ID, KEY_BLUETOOTH_ADDRESS, KEY_BLUETOOTH_NAME, KEY_BLUETOOTH_RSSI, KEY_BLUETOOTH_LABLE];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeText),@(CSVTypeText),@(CSVTypeInteger),@(CSVTypeText)];
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
    }
    return self;
}

- (void) createTable{
    // Send a table create query (for both BLE and classic Bluetooth)
    // NSLog(@"[%@] Create Table", [self getSensorName]);
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

- (BOOL) startSensor{
    return [self startSensorWithScanInterval:_scanInterval duration:_scanDuration];
}

- (BOOL) startSensorWithScanInterval:(int)interval duration:(int)duration{
    
    [super startSensor];
    
    _peripherals = [[NSMutableArray alloc] init];
    
    scanTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                 target:self
                                               selector:@selector(startToScanBluetooth:)
                                               userInfo:nil
                                                repeats:YES];
    [scanTimer fire];
    
    // Init a CBCentralManager for sensing BLE devices
    if ([self isDebug]) {
        NSLog(@"[%@] Start BLE Sensor", [self getSensorName]);
    }
    
    return YES;
}


- (BOOL) stopSensor {
    // Stop a scan ble devices by CBCentralManager
    [_myCentralManager stopScan];
    _myCentralManager = nil;
    
    // Stop the scan timer for the classic bluetooth
    [scanTimer invalidate];
    scanTimer = nil;
    [super stopSensor];
    
    return YES;
}

////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////


- (void) saveBluetoothDeviceWithAddress:(NSString *) address
                                   name:(NSString *) name
                                   rssi:(NSNumber *) rssi{
    if (name == nil) name = @"";
    if (address == nil ) address = @"";
    if (rssi == nil) rssi = @-1;
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:address forKey:@"bt_address"]; //varchar
    [dict setObject:name forKey:@"bt_name"]; //text
    [dict setObject:rssi  forKey:@"bt_rssi"]; //int
    [dict setObject:[[AWAREUtils getUnixTimestamp:sessionTime] stringValue] forKey:@"label"]; //text
    [self setLatestValue:[NSString stringWithFormat:@"%@(%@), %@", name, address,rssi]];
    // [self saveData:dict];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:NO];
    
    [self setLatestData:dict];
    
    // Boradcast events
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

/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
// For Classic Bluetooth


/**
 * @param   sender  A NSTimer sender
 * @discussion  Start to scan the claasic blueooth devices with private APIs. Also, the method is called by NSTimer class which is initialized at the startSensor method in Bluetooth sensor.
 */
-(void)startToScanBluetooth:(id)sender{
    
    // send scan notification
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BLUETOOTH_SCAN_STARTED
                                                        object:nil
                                                      userInfo:nil];
    _peripherals = [[NSMutableArray alloc] init];
    
    sessionTime = [NSDate new];

    if ([self isDebug]) {
        NSLog(@"[Bluetooth] startToScanBluetooth");
    }
    
    // start scanning ble devices.
    if ([AWAREUtils isBackground]) {
        [_myCentralManager retrievePeripheralsWithIdentifiers:[self getKnownPeripheralUUIDs]];
    }else{
        _myCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    [self performSelector:@selector(stopToScanBluetooth) withObject:nil afterDelay:_scanDuration];

}


- (void) stopToScanBluetooth {
    if ([self isDebug]) {
        NSLog(@"[Bluetooth] stopToScanBluetooth");
    }
    
    [_myCentralManager stopScan];
    
    if (_peripherals != nil) {
        for (CBPeripheral * peripheral in _peripherals) {
            [_myCentralManager cancelPeripheralConnection:peripheral];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BLUETOOTH_SCAN_ENDED
                                                        object:nil
                                                      userInfo:nil];
}

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
// For BLE

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch ([central state]) {
        case CBManagerStateUnknown:
            if ([self isDebug]) NSLog(@"[%@] CBManagerStateUnknown", [self getSensorName]);
            break;
        case CBManagerStatePoweredOn:
            if ([self isDebug]) { NSLog(@"[%@] CBManagerStatePoweredOn", [self getSensorName]);}
            // [central scanForPeripheralsWithServices:services options:nil];
            /// for foreground sensing
            [_myCentralManager scanForPeripheralsWithServices:nil options:nil];
//            [_myCentralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"10B697A7-3600-4F55-85E5-16915BD23602"]]
//                                                      options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@(NO)}];
            break;
        case CBManagerStateResetting:
            if ([self isDebug]) NSLog(@"[%@] CBManagerStateResetting", [self getSensorName]);
            break;
        case CBManagerStatePoweredOff:
            if ([self isDebug]) NSLog(@"[%@] CBManagerStatePoweredOff", [self getSensorName]);
            break;
        case CBManagerStateUnsupported:
            if ([self isDebug]) NSLog(@"[%@] CBManagerStateUnsupported", [self getSensorName]);
            break;
        case CBManagerStateUnauthorized:
            if ([self isDebug]) NSLog(@"[%@] CBManagerStateUnauthorized", [self getSensorName]);
            break;
        default:
            break;
    }
    
//    NSLog(@"centralManagerDidUpdateState");
//    if([central state] == CBCentralManagerStatePoweredOff){
//        NSLog(@"CoreBluetooth BLE hardware is powered off");
//        [self saveDebugEventWithText:@"Bluetooth module is powered off" type:DebugTypeWarn label:@""];
//    }else if([central state] == CBCentralManagerStatePoweredOn){
//        NSLog(@"CoreBluetooth BLE hardware is powered on");
//        [self saveDebugEventWithText:@"Bluetooth module is powered on" type:DebugTypeWarn label:@""];
//        NSArray *services = @[
//                            [CBUUID UUIDWithString:BATTERY_SERVICE],
//                            [CBUUID UUIDWithString:BODY_COMPOSITION_SERIVCE],
//                            [CBUUID UUIDWithString:CURRENT_TIME_SERVICE],
//                            [CBUUID UUIDWithString:DEVICE_INFORMATION],
//                            [CBUUID UUIDWithString:ENVIRONMENTAL_SENSING],
//                            [CBUUID UUIDWithString:GENERIC_ACCESS],
//                            [CBUUID UUIDWithString:GENERIC_ATTRIBUTE],
//                            [CBUUID UUIDWithString:MEASUREMENT],
//                            [CBUUID UUIDWithString:BODY_LOCATION],
//                            [CBUUID UUIDWithString:MANUFACTURER_NAME],
//                            [CBUUID UUIDWithString:HEART_RATE_UUID],
//                            [CBUUID UUIDWithString:HTTP_PROXY_UUID],
//                            [CBUUID UUIDWithString:HUMAN_INTERFACE_DEVICE],
//                            [CBUUID UUIDWithString:INDOOR_POSITIONING],
//                            [CBUUID UUIDWithString:LOCATION_NAVIGATION ],
//                            // [CBUUID UUIDWithString:PHONE_ALERT_STATUS],
//                            [CBUUID UUIDWithString:REFERENCE_TIME],
//                            [CBUUID UUIDWithString:SCAN_PARAMETERS],
//                            [CBUUID UUIDWithString:TRANSPORT_DISCOVERY],
//                            [CBUUID UUIDWithString:USER_DATA],
//                            [CBUUID UUIDWithString:@"AA80"]
//                              ];
//        // [central scanForPeripheralsWithServices:services options:nil];
//        [_myCentralManager scanForPeripheralsWithServices:services options:nil];
//    }else if([central state] == CBCentralManagerStateUnauthorized){
//        NSLog(@"CoreBluetooth BLE hardware is unauthorized");
//        [self saveDebugEventWithText:@"Bluetooth module is unauthorized" type:DebugTypeWarn label:@""];
//    }else if([central state] == CBCentralManagerStateUnknown){
//        NSLog(@"CoreBluetooth BLE hardware is unknown");
//        [self saveDebugEventWithText:@"Bluetooth module is unknown" type:DebugTypeWarn label:@""];
//    }else if([central state] == CBCentralManagerStateUnsupported){
//        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
//        [self saveDebugEventWithText:@"Bluetooth module is unsupported on this platform" type:DebugTypeWarn label:@""];
//    }
}


- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if([self isDebug]){
        NSLog(@"[Bluetooth] Name:%@, UUID: %@, RSSI: %@", peripheral.name, peripheral.identifier, RSSI);
    }
    
    [self savePeripheralUUID:peripheral.identifier];
    
    NSString *name = peripheral.name;
    NSString *uuid = peripheral.identifier.UUIDString;
    
    [self saveBluetoothDeviceWithAddress:uuid name:name rssi:RSSI];
    
    [_myCentralManager connectPeripheral:peripheral options:nil];
}


- (void) centralManager:(CBCentralManager *) central didConnectPeripheral:(CBPeripheral *)peripheral {
    if([self isDebug]){ NSLog(@"Peripheral connected"); }
    
    [_peripherals addObject:peripheral];
    peripheral.delegate = self;
    [peripheral readRSSI];
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if(self.isDebug) { NSLog(@"[bluetooth] didDisconnectPeripheral: %@ (%@) %@", peripheral.name, peripheral.identifier.UUIDString, error.debugDescription); }
}

//- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict{
//    if (self.isDebug) {
//        NSLog(@"%@",dict.debugDescription);
//    }
//}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if (self.isDebug) {
        if(self.isDebug) { NSLog(@"[bluetooth] didFailPeripheral: %@ (%@) %@", peripheral.name, peripheral.identifier.UUIDString, error.debugDescription); }
    }
}

//////////////////////////////////////////////

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        // NSLog(@"[bluetooth] service: %@ -> %@", peripheral.name, service.UUID.UUIDString);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"180A"]]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}


- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic *characteristic in service.characteristics ) {
//        NSLog(@"Discovered characteristic: %@(%@)",characteristic.UUID,characteristic.UUID.UUIDString);
//        Manufacturer Name String(2A29)
//        Model Number String(2A24)
//        Serial Number String(2A25)
//        Hardware Revision String(2A27)
//        Firmware Revision String(2A26)
//        Software Revision String(2A28)
//        System ID(2A23)
       if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A25"]]) {
//            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
}



- (CBCharacteristic *) getCharateristicWithUUID:(NSString *)uuid from:(CBService *) cbService
{
    for (CBCharacteristic *characteristic in cbService.characteristics) {
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:uuid]]){
            return characteristic;
        }
    }
    return nil;
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString * serialNumber = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSString *name = [NSString stringWithFormat:@"%@ (%@)", peripheral.name, serialNumber];
    NSString *uuid = peripheral.identifier.UUIDString;
    if([self isDebug]){
        NSLog(@"[Bleutooth] %@", name);
    }
    [self saveBluetoothDeviceWithAddress:uuid name:name rssi:nil];
}


- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error{
//    NSString *name = [NSString stringWithFormat:@"%@", peripheral.name];
//    NSString *uuid = peripheral.identifier.UUIDString;
//    if([self isDebug]){
//        NSLog(@"[Bluetooth]%@:, RSSI:%@",name,RSSI);
//    }
//    [self saveBluetoothDeviceWithAddress:uuid name:name rssi:RSSI];
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices{
    if (invalidatedServices!=nil) {
        for (CBService * service in invalidatedServices) {
            NSLog(@"[bluetooth] peripheral: %@ (%@), didModifyServices: %@",peripheral.name, peripheral.identifier.UUIDString, service.UUID.UUIDString);
        }
    }
}



/**
 Save a peripheral UUID for recovering connection in the background

 @param uuid An UUID of a perihperal
 */
- (void) savePeripheralUUID:(NSUUID *) uuid {
    NSUserDefaults * defualts = [NSUserDefaults standardUserDefaults];
    NSMutableArray * knownUUIDs = [[NSMutableArray alloc] initWithArray:[self getKnownPeripheralUUIDs]];
    if (knownUUIDs == nil) {
        knownUUIDs = [[NSMutableArray alloc] init];
    }
    if (uuid != nil) {
        bool unknownUUID = true;
        for (NSUUID * knownUUID in knownUUIDs) {
            if ([knownUUID.UUIDString isEqualToString:uuid.UUIDString]) {
                unknownUUID = false;
                break;
            }
        }
        if (unknownUUID) {
            [knownUUIDs addObject:uuid];
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:knownUUIDs];
            [defualts setObject:data forKey:@"key.aware.known.ble.peripheral.uuids"];
            [defualts synchronize];
        }else{
            if(self.isDebug){ NSLog(@"Known UUID"); }
        }
    }
}


/**
 get a list of known peripheral UUIDs

 @return A list of known peripheral UUIDs
 */
- (NSArray *) getKnownPeripheralUUIDs {
    NSUserDefaults * defualts = [NSUserDefaults standardUserDefaults];
    NSData * knownUUIDsData = [defualts objectForKey:@"key.aware.known.ble.peripheral.uuids"];
    if (knownUUIDsData == nil) {
        return @[];
    }else{
        NSArray *knownUUIDs = [NSKeyedUnarchiver unarchiveObjectWithData:knownUUIDsData];
        return knownUUIDs;
    }
}




@end
