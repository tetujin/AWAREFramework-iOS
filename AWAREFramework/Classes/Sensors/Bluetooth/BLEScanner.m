//
//  BLEScanner.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/06/16.
//

#import "BLEScanner.h"

@implementation BLEScanner{
    BLEScanEventHandler scanEventHandler;
}

+ (id)sharedBLEScanner {
    static id instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        [instance initInstance];
    });
    
    return instance;
}

- (void)initInstance {
    if (self) {
        _serviceUUIDs = [[NSMutableArray alloc] init];
    }
}


/**
 start scanning BLE devices

 @param handler for BLE scan
 */
- (void)startScanningWithHandler:(BLEScanEventHandler)handler{
    scanEventHandler = handler;
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}



/**
  stop scanning BLE devices
 */
- (void) stopScannning {
    if (_centralManager) {
        [_centralManager stopScan];
    }
}



- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    NSArray * uuids = _serviceUUIDs;
    if ( uuids != nil ) {
        if (uuids.count == 0) {
            uuids = nil;
        }
    }
    
    switch ([central state]) {
        case CBManagerStateUnknown:
            // NSLog(@"[BLEScanner] CBManagerStateUnknown");
            break;
        case CBManagerStatePoweredOn:
            // NSLog(@"[BLEScanner] CBManagerStatePoweredOn");
            [self.centralManager scanForPeripheralsWithServices:uuids options:nil];
            break;
        case CBManagerStateResetting:
            // NSLog(@"[BLEScanner] CBManagerStateResetting");
            break;
        case CBManagerStatePoweredOff:
            // NSLog(@"[BLEScanner] CBManagerStatePoweredOff");
            break;
        case CBManagerStateUnsupported:
            // NSLog(@"[BLEScanner] CBManagerStateUnsupported");
            break;
        case CBManagerStateUnauthorized:
            // NSLog(@"[BLEScanner] CBManagerStateUnauthorized");
            break;
        default:
            break;
    }
}


- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI{
    
//    NSMutableString *string = [NSMutableString stringWithString:@"\n\n"];
//    [string appendFormat:@"NAME: %@\n"            , peripheral.name];
//    [string appendFormat:@"UUID(identifier): %@\n", peripheral.identifier];
//    [string appendFormat:@"RSSI: %@\n"            , RSSI];
//    [string appendFormat:@"Adverisement:%@\n"     , advertisementData];
//    NSLog(@"[BLEScanner] Peripheral Info:\n %@", string);
    
    if (scanEventHandler) {
        scanEventHandler(peripheral.identifier.UUIDString, peripheral.name, RSSI, advertisementData);
    }    
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral {
    
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error{
    
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error{
    
}



//////////////////////////////////////////////////////////////
- (CBCharacteristic *) getCharateristicWithUUID:(NSString *)uuid
                                           from:(CBService *) cbService
{
    for (CBCharacteristic *characteristic in cbService.characteristics) {
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:uuid]]){
            return characteristic;
        }
    }
    return nil;
}

/**
 Save a peripheral UUID for recovering connection in the background
 
 @param uuid An UUID of a perihperal
 */
- (BOOL) isKnownPeripheralUUID:(NSUUID *) uuid {
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
            
        }else{
            return YES;
        }
    }
    return NO;
}

- (void) saveUnknownPeripheralUUID:(NSUUID *)uuid{
    NSUserDefaults * defualts = [NSUserDefaults standardUserDefaults];
    NSMutableArray * knownUUIDs = [[NSMutableArray alloc] initWithArray:[self getKnownPeripheralUUIDs]];
    if (knownUUIDs == nil) {
        knownUUIDs = [[NSMutableArray alloc] init];
    }
    if (uuid == nil) return;
    
    [knownUUIDs addObject:uuid];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:knownUUIDs];
    [defualts setObject:data forKey:@"key.aware.known.ble.peripheral.uuids"];
    [defualts synchronize];
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

///////////////////////////////////////////////////////

/**
 remote all target service UUIDs
 @note please call this method before using startScanningWithHandler: method
 */
- (void) remoteAllTargetServiceUUIDs{
    [_serviceUUIDs removeAllObjects];
}


- (NSArray <CBUUID *> *) getTargetServiceUUIDs{
    return _serviceUUIDs;
}


- (void) addTargetServiceUUIDs:(NSArray <CBUUID *>*) uuids{
    if (uuids != nil) {
        [_serviceUUIDs addObjectsFromArray:uuids];
    }
}


- (void) setTargetServiceUUIDs:(NSArray <CBUUID *>*) uuids{
    if (uuids != nil) {
        [_serviceUUIDs removeAllObjects];
        [_serviceUUIDs addObjectsFromArray:uuids];
    }
}

/**
 add a target service UUID
 @note please call this method before using startScanningWithHandler: method

 @param uuid a scan target UUID
 */
- (void) addTargetServiceUUID: (CBUUID *) uuid{
    [_serviceUUIDs  addObject:uuid];
}

/**
 remote all target service UUIDs
 @note please call this method before using startScanningWithHandler: method
 */
- (void) setTargetServiceUUID: (CBUUID *) uuid{
    [_serviceUUIDs removeAllObjects];
    [_serviceUUIDs addObject:uuid];
}

- (void) setWellKnownTargetServiceUUIDs{
    [_serviceUUIDs setArray:@[[CBUUID UUIDWithString:BATTERY_SERVICE],
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
                          [CBUUID UUIDWithString:REFERENCE_TIME],
                          [CBUUID UUIDWithString:SCAN_PARAMETERS],
                          [CBUUID UUIDWithString:TRANSPORT_DISCOVERY],
                          [CBUUID UUIDWithString:USER_DATA],
                          [CBUUID UUIDWithString:@"AA80"]]];
}

@end
