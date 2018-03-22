//
//  bluetooth.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/24/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
// Public Bluetooth API
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
// Private API (for Classic Bluetooth)
/**
 * This library(MDBluetoothManager) is made by @michaeldomer under the GPL(ver3) licence.
 * Also, you can access his original source code from GitHub(https://github.com/michaeldorner/BeeTee) .
 */
// #import "MDBluetoothManager.h"

extern NSString* const AWARE_PREFERENCES_STATUS_BLUETOOTH;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_BLUETOOTH;

//@interface Bluetooth : AWARESensor <AWARESensorDelegate, CBCentralManagerDelegate, CBPeripheralDelegate,MDBluetoothObserverProtocol>
@interface Bluetooth : AWARESensor <AWARESensorDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *myCentralManager;
//@property (nonatomic, strong) CBPeripheral *peripheralDevice;
@property (strong,nonatomic) NSMutableArray *peripherals;

@property (nonatomic) int scanInterval;
@property (nonatomic) int scanDuration;

- (BOOL) startSensor;

- (BOOL) startSensorWithScanInterval:(int)interval duration:(int)duration;

//https://developer.bluetooth.org/gatt/services/Pages/ServicesHome.aspx

//#define SENSORTAG_SERVICE_UUID @"AA80"


#define BATTERY_SERVICE @"180F"
#define BODY_COMPOSITION_SERIVCE @"181B"
#define CURRENT_TIME_SERVICE @"1805"
#define DEVICE_INFORMATION @"180A"
#define ENVIRONMENTAL_SENSING @"181A"
#define GENERIC_ACCESS @"1800"
#define GENERIC_ATTRIBUTE @"1801"
#define MEASUREMENT @"2A37"
#define BODY_LOCATION @"2A38"
#define MANUFACTURER_NAME @"2A29"
#define HEART_RATE_UUID @"180D"
#define HTTP_PROXY_UUID @"1823"
#define HUMAN_INTERFACE_DEVICE @"1812"
#define INDOOR_POSITIONING @"1820"
#define LOCATION_NAVIGATION @"1819"
#define PHONE_ALERT_STATUS @"180E"
#define REFERENCE_TIME @"1806"
#define SCAN_PARAMETERS @"1813"
#define TRANSPORT_DISCOVERY @"1824"
#define USER_DATA @"181C"



//Heart Rate	org.bluetooth.service.heart_rate	0x180D	Adopted
//HTTP Proxy	org.bluetooth.service.http_proxy	0x1823	Adopted
//Human Interface Device	org.bluetooth.service.human_interface_device	0x1812	Adopted
//Immediate Alert	org.bluetooth.service.immediate_alert	0x1802	Adopted
//Indoor Positioning	org.bluetooth.service.indoor_positioning	0x1821	Adopted
//Internet Protocol Support	org.bluetooth.service.internet_protocol_support	0x1820	Adopted
//Link Loss	org.bluetooth.service.link_loss	0x1803	Adopted
//Location and Navigation	org.bluetooth.service.location_and_navigation	0x1819	Adopted
//Next DST Change Service	org.bluetooth.service.next_dst_change	0x1807	Adopted
//Object Transfer	org.bluetooth.service.object_transfer	0x1825	Adopted
//Phone Alert Status Service	org.bluetooth.service.phone_alert_status	0x180E	Adopted
//Pulse Oximeter	org.bluetooth.service.pulse_oximeter	0x1822	Adopted
//Reference Time Update Service	org.bluetooth.service.reference_time_update	0x1806	Adopted
//Running Speed and Cadence	org.bluetooth.service.running_speed_and_cadence	0x1814	Adopted
//Scan Parameters	org.bluetooth.service.scan_parameters	0x1813	Adopted
//Transport Discovery	org.bluetooth.service.transport_discovery	0x1824	Adopted
//Tx Power	org.bluetooth.service.tx_power	0x1804	Adopted
//User Data	org.bluetooth.service.user_data	0x181C	Adopted
//Weight Scale	org.bluetooth.service.weight_scale	0x181D	Adopted


//Alert Notification Service	org.bluetooth.service.alert_notification	0x1811	Adopted
//Automation IO	org.bluetooth.service.automation_io	0x1815	Adopted
//Blood Pressure	org.bluetooth.service.blood_pressure	0x1810	Adopted
//Body Composition	org.bluetooth.service.body_composition	0x181B	Adopted
//Bond Management	org.bluetooth.service.bond_management	0x181E	Adopted
//Continuous Glucose Monitoring	org.bluetooth.service.continuous_glucose_monitoring	0x181F	Adopted
//Current Time Service	org.bluetooth.service.current_time	0x1805	Adopted
//Cycling Power	org.bluetooth.service.cycling_power	0x1818	Adopted
//Cycling Speed and Cadence	org.bluetooth.service.cycling_speed_and_cadence	0x1816	Adopted
//Device Information	org.bluetooth.service.device_information	0x180A	Adopted
//Environmental Sensing	org.bluetooth.service.environmental_sensing	0x181A	Adopted
//Generic Access	org.bluetooth.service.generic_access	0x1800	Adopted
//Generic Attribute	org.bluetooth.service.generic_attribute	0x1801	Adopted
//Glucose	org.bluetooth.service.glucose	0x1808	Adopted
//Health Thermometer	org.bluetooth.service.health_thermometer	0x1809	Adopted
//Heart Rate	org.bluetooth.service.heart_rate	0x180D	Adopted
//HTTP Proxy	org.bluetooth.service.http_proxy	0x1823	Adopted
//Human Interface Device	org.bluetooth.service.human_interface_device	0x1812	Adopted
//Immediate Alert	org.bluetooth.service.immediate_alert	0x1802	Adopted
//Indoor Positioning	org.bluetooth.service.indoor_positioning	0x1821	Adopted
//Internet Protocol Support	org.bluetooth.service.internet_protocol_support	0x1820	Adopted
//Link Loss	org.bluetooth.service.link_loss	0x1803	Adopted
//Location and Navigation	org.bluetooth.service.location_and_navigation	0x1819	Adopted
//Next DST Change Service	org.bluetooth.service.next_dst_change	0x1807	Adopted
//Object Transfer	org.bluetooth.service.object_transfer	0x1825	Adopted
//Phone Alert Status Service	org.bluetooth.service.phone_alert_status	0x180E	Adopted
//Pulse Oximeter	org.bluetooth.service.pulse_oximeter	0x1822	Adopted
//Reference Time Update Service	org.bluetooth.service.reference_time_update	0x1806	Adopted
//Running Speed and Cadence	org.bluetooth.service.running_speed_and_cadence	0x1814	Adopted
//Scan Parameters	org.bluetooth.service.scan_parameters	0x1813	Adopted
//Transport Discovery	org.bluetooth.service.transport_discovery	0x1824	Adopted
//Tx Power	org.bluetooth.service.tx_power	0x1804	Adopted
//User Data	org.bluetooth.service.user_data	0x181C	Adopted
//Weight Scale	org.bluetooth.service.weight_scale	0x181D	Adopted


@end
