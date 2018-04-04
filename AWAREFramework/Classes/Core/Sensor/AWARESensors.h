//
//  AWARESensors.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 10/10/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Sensors
#import "Accelerometer.h"
#import "Barometer.h"
#import "Battery.h"
#import "BatteryCharge.h"
#import "BatteryDischarge.h"
#import "Bluetooth.h"
#import "Calls.h"
#import "Gravity.h"
#import "Debug.h"
#import "Gravity.h"
#import "Gyroscope.h"
#import "LinearAccelerometer.h"
#import "Locations.h"
#import "VisitLocations.h"
#import "Magnetometer.h"
#import "Network.h"
#import "Orientation.h"
#import "Pedometer.h"
#import "Processor.h"
#import "Proximity.h"
#import "Rotation.h"
#import "Screen.h"
#import "Timezone.h"
#import "Wifi.h"
#import "ESM.h"

/// Plugins
#import "BLEHeartRate.h"
#import "DeviceUsage.h"
#import "FusedLocations.h"
#import "AWAREHealthKit.h"
#import "Memory.h"
#import "NTPTime.h"
#import "OpenWeather.h"
#import "PushNotification.h"
#import "IOSESM.h"
#import "IOSActivityRecognition.h"
#import "Contacts.h"
#import "Fitbit.h"
#import "BasicSettings.h"
#import "AmbientNoise.h"
#import "GoogleLogin.h"

@interface AWARESensors : NSObject

@end
