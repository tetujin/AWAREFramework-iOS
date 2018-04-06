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
    //MDBluetoothManager * mdBluetoothManager;
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
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_BLUETOOTH withHeader:header];
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
        // mdBluetoothManager = [MDBluetoothManager sharedInstance];
        _scanDuration = 30; // 30 second
        _scanInterval = 60*5; // 5 min
        sessionTime = [NSDate new];
    }
    return self;
}

- (void) createTable{
    // Send a table create query (for both BLE and classic Bluetooth)
    NSLog(@"[%@] Create Table", [self getSensorName]);
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:KEY_BLUETOOTH_ADDRESS type:TCQTypeText    default:@"''"];
    [maker addColumn:KEY_BLUETOOTH_NAME    type:TCQTypeText    default:@"''"];
    [maker addColumn:KEY_BLUETOOTH_RSSI    type:TCQTypeInteger default:@"0"];
    [maker addColumn:KEY_BLUETOOTH_LABLE   type:TCQTypeText    default:@"''"];
    //[super createTable:query];
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
    
    // Set notification events for scanning classic bluetooth devices
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDeviceDiscoveredNotification:) name:@"BluetoothDeviceDiscoveredNotification" object:nil];
    
    return YES;
}


- (BOOL) stopSensor {
    // Stop a scan ble devices by CBCentralManager
    [_myCentralManager stopScan];
    _myCentralManager = nil;
    
    // Stop the scan timer for the classic bluetooth
    [scanTimer invalidate];
    scanTimer = nil;
    // Stop scanning classic bluetooth
    // [mdBluetoothManager endScan];
    // remove notification observer from notification center
    // [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BluetoothDeviceDiscoveredNotification" object:nil];
    
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
    [self.storage saveDataWithDictionary:dict buffer:YES saveInMainThread:YES];
    
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
    
//    if ([self isDebug]) {
//        [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"Find a new Blueooth device! %@ (%@)", name, address] soundFlag:NO];
//    }
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
    
    // Set up for a classic bluetooth
//    if (![mdBluetoothManager bluetoothIsPowered]) {
//        [mdBluetoothManager turnBluetoothOn];
//    }
    
    _peripherals = [[NSMutableArray alloc] init];
    sessionTime = [NSDate new];
    
    // start scanning classic bluetooth devices.
//    if (![mdBluetoothManager isScanning]) {
//        NSString *scanStartMessage = [NSString stringWithFormat:@"Start scanning Bluetooth devices during %d second!", _scanDuration];
//        if([self isDebug]) NSLog(@"...Start scanning Bluetooth devices.");
//        if ([self isDebug]){
//           [AWAREUtils sendLocalNotificationForMessage:scanStartMessage soundFlag:NO];
//        }
//        // start to scan Bluetooth devices
//        [mdBluetoothManager startScan];
//        // stop to scan Bluetooth devies after "scanDuration" second.
//        [self performSelector:@selector(stopToScanBluetooth) withObject:0 afterDelay:_scanDuration];
//        if([self isDebug]) NSLog(@"...After %d second, the Blueooth scan will be end.", _scanDuration);
//    }
    
    
    // start scanning ble devices.
    _myCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    [_myCentralManager performSelector:@selector(stopScan) withObject:nil afterDelay:_scanDuration];
}


- (void) stopToScanBluetooth {
    if ([self isDebug]){
        // [AWAREUtils sendLocalNotificationForMessage:@"Stop scanning Bluetooth devices!" soundFlag:NO];
    }
    
    // [mdBluetoothManager endScan];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BLUETOOTH_SCAN_ENDED
                                                        object:nil
                                                      userInfo:nil];
}

//- (void)receivedBluetoothNotification:(MDBluetoothNotification)bluetoothNotification{
//    switch (bluetoothNotification) {
//        case MDBluetoothPowerChangedNotification:
//            if([self isDebug]) NSLog(@"changed");
//            break;
//        case MDBluetoothDeviceUpdatedNotification:
//            if([self isDebug]) NSLog(@"update");
//            break;
//        case MDBluetoothDeviceRemovedNotification:
//            if([self isDebug]) NSLog(@"remove");
//            break;
//        case MDBluetoothDeviceDiscoveredNotification:
//            if([self isDebug]) NSLog(@"discoverd");
//            break;
//        default:
//            break;
//    }
//}

//- (void)bluetoothDeviceDiscoveredNotification:(NSNotification *)notification{
//    if([self isDebug]){
//        NSLog(@"%@", notification.description);
//    }
//    // save a bluetooth device information
//    BluetoothDevice * bluetoothDevice = notification.object;
//    NSString* address = bluetoothDevice.address;
//    NSString* name = bluetoothDevice.name;
//    if (address == nil) address = @"";
//    if (name == nil) name = @"";
//    
//    [self saveBluetoothDeviceWithAddress:address name:name rssi:@-1];
//}

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
// For BLE

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSArray *services = @[
                          [CBUUID UUIDWithString:BATTERY_SERVICE],
                          [CBUUID UUIDWithString:BODY_COMPOSITION_SERIVCE],
                          [CBUUID UUIDWithString:CURRENT_TIME_SERVICE],
                          [CBUUID UUIDWithString:DEVICE_INFORMATION],
                          [CBUUID UUIDWithString:ENVIRONMENTAL_SENSING],
                          [CBUUID UUIDWithString:GENERIC_ACCESS],
                          [CBUUID UUIDWithString:GENERIC_ATTRIBUTE],
                          [CBUUID UUIDWithString:MEASUREMENT],
                          [CBUUID UUIDWithString:BODY_LOCATION],
                          [CBUUID UUIDWithString:MANUFACTURER_NAME],
                          [CBUUID UUIDWithString:HEART_RATE_UUID],
                          [CBUUID UUIDWithString:HTTP_PROXY_UUID],
                          [CBUUID UUIDWithString:HUMAN_INTERFACE_DEVICE],
                          [CBUUID UUIDWithString:INDOOR_POSITIONING],
                          [CBUUID UUIDWithString:LOCATION_NAVIGATION ],
                          // [CBUUID UUIDWithString:PHONE_ALERT_STATUS],
                          [CBUUID UUIDWithString:REFERENCE_TIME],
                          [CBUUID UUIDWithString:SCAN_PARAMETERS],
                          [CBUUID UUIDWithString:TRANSPORT_DISCOVERY],
                          [CBUUID UUIDWithString:USER_DATA],
                          [CBUUID UUIDWithString:@"AA80"]
                          ];
    
    switch ([central state]) {
        case CBManagerStateUnknown:
            if ([self isDebug]) NSLog(@"[%@] CBManagerStateUnknown", [self getSensorName]);
            break;
        case CBManagerStatePoweredOn:
            if ([self isDebug]) { NSLog(@"[%@] CBManagerStatePoweredOn", [self getSensorName]);}
            [central scanForPeripheralsWithServices:services options:nil];
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




- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData
                   RSSI:(NSNumber *)RSSI {
    if([self isDebug]){
        NSLog(@"Discovered %@", peripheral.name);
        NSLog(@"UUID %@", peripheral.identifier);
        NSLog(@"%@", peripheral);
    }
    NSString *name = peripheral.name;
    NSString *uuid = peripheral.identifier.UUIDString;
    
    [self saveBluetoothDeviceWithAddress:uuid name:name rssi:RSSI];
    
    [_peripherals addObject:peripheral];
    [_myCentralManager connectPeripheral:peripheral options:nil];
    
}


- (void) centralManager:(CBCentralManager *) central
   didConnectPeripheral:(CBPeripheral *)peripheral
{
    if([self isDebug]){
        NSLog(@"Peripheral connected");
    }
    peripheral.delegate = self;
    [peripheral readRSSI];
    [peripheral discoverServices:nil];
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
//        NSLog(@"Discoverd serive %@", service.UUID);
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


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    NSString * serialNumber = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSString *name = [NSString stringWithFormat:@"%@ (%@)", peripheral.name, serialNumber];
    NSString *uuid = peripheral.identifier.UUIDString;
    NSNumber *rssi = peripheral.RSSI;
    if([self isDebug]){
        NSLog(@"%@", name);
    }
    [self saveBluetoothDeviceWithAddress:uuid name:name rssi:rssi];
    
}


- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error{

}



@end
