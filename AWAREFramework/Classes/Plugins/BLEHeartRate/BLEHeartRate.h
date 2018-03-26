//
//  BLEHeartRate.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 3/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <CoreBluetooth/CoreBluetooth.h>


#define POLARH7_HRM_DEVICE_INFO_SERVICE_UUID @"180A"
#define POLARH7_HRM_HEART_RATE_SERVICE_UUID @"180D"
#define POLARH7_HRM_MEASUREMENT_CHARACTERISTIC_UUID @"2A37"
#define POLARH7_HRM_BODY_LOCATION_CHARACTERISTIC_UUID @"2A38"
#define POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID @"2A29"

extern NSString* const AWARE_PREFERENCES_STATUS_BLE_HR;

/** (default = 5) in minutes */
extern NSString * const AWARE_PREFERENCES_PLUGIN_BLE_HR_INTERVAL_TIME_MIN;

/** (default = 30) in seconds */
extern NSString * const AWARE_PREFERENCES_PLUGIN_BLE_HR_ACTIVE_TIME_SEC;


@interface BLEHeartRate : AWARESensor <AWARESensorDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>



@property double intervalSec;
@property double activeTimeSec;
@property bool always;

@property (nonatomic, strong) CBCentralManager *myCentralManager;
@property (nonatomic, strong) CBPeripheral *peripheralDevice;
@property (nonatomic, strong) NSString *bodyData;
@property (nonatomic, strong) NSString *manufacturer;
@property (assign) uint16_t heartRate;
@property (nonatomic, strong) NSNumber *bodyLocation;
@property (nonatomic, strong) NSNumber *deviceRssi;

- (BOOL) startSensor;

@end
