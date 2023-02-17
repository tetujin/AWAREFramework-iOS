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
#import "Calls.h"
#import "Gravity.h"
#import "Gravity.h"
#import "Gyroscope.h"
#import "LinearAccelerometer.h"
#import "Locations.h"
#import "LocationVisit.h"
#import "Magnetometer.h"
#import "Network.h"
#import "Orientation.h"
#import "Processor.h"
#import "Proximity.h"
#import "Rotation.h"
#import "Screen.h"
#import "Timezone.h"
#import "Wifi.h"
#import "ESM.h"
#import "AWAREDevice.h"
#import "DeviceUsage.h"
#import "FusedLocations.h"
#import "AWAREMemory.h"
#import "NTPTime.h"
#import "OpenWeather.h"
#import "PushNotification.h"
#import "IOSESM.h"
#import "Fitbit.h"
#import "BasicSettings.h"
#import "SignificantMotion.h"
#import "PushNotification.h"

/// Plugins

#ifdef IMPORT_MIC
#import "AmbientNoise.h"
#import "Conversation.h"
#endif

#ifdef IMPORT_MOTION_ACTIVITY
#import "Pedometer.h"
#import "IOSActivityRecognition.h"
#endif

#ifdef IMPORT_BLUETOOTH
#import "Bluetooth.h"
#import "BLEHeartRate.h"
#endif

#ifdef IMPORT_CONTACT
#import "Contacts.h"
#endif

#ifdef IMPORT_CALENDAR
#import "CalendarESMScheduler.h"
#import "Calendar.h"
#endif

#ifdef IMPORT_HEALTHKIT
#import "AWAREHealthKit.h"
#endif

@interface AWARESensors : NSObject

@end
