//
//  AWAREStudyManager.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const KEY_APNS_TOKEN;
extern NSString* const KEY_AWARE_STUDY;
extern NSString* const KEY_AWARE_DEVICE_NAME;
extern NSString* const KEY_AWARE_DEVICE_ID;
extern NSString* const KEY_APP_TERMINATED;

extern NSString* const KEY_MAX_DATA_SIZE;
extern NSString* const KEY_MAX_FETCH_SIZE_MOTION_SENSOR;
extern NSString* const KEY_MAX_FETCH_SIZE_NORMAL_SENSOR;
extern NSString* const KEY_UPLOAD_MARK;

extern NSString* const KEY_SENSORS;
extern NSString* const KEY_PLUGINS;
extern NSString* const KEY_PLUGIN;
extern NSString* const KEY_USER_SENSORS;
extern NSString* const KEY_USER_PLUGINS;

/**  Keys for contetns of a table view raw */
/// A key for a title in a raw
extern NSString* const KEY_CEL_TITLE;
/// A key for a description in a raw
extern NSString* const KEY_CEL_DESC;
/// A key for a image in a raw
extern NSString* const KEY_CEL_IMAGE;
/// A key for a status in a raw
extern NSString* const KEY_CEL_STATE;
/// A key for a sensor_name in a raw
extern NSString* const KEY_CEL_SENSOR_NAME;
/// A key for a sensor setting type
extern NSString* const KEY_CEL_SETTING_TYPE;
/// A key for a sensor current setting
extern NSString* const KEY_CEL_SETTING_VALUE;
extern NSString* const KEY_CEL_SETTING_TYPE_NUMBER;
extern NSString* const KEY_CEL_SETTING_TYPE_STRING;
extern NSString* const KEY_CEL_SETTING_TYPE_BOOL;


extern NSString* const KEY_AWARE_NOTIFICATION_DEFAULT_REQUEST_IDENTIFIER;

extern NSString* const KEY_STUDY_QR_CODE;

extern NSString* const KEY_MQTT_PASS;
extern NSString* const KEY_MQTT_USERNAME;
extern NSString* const KEY_MQTT_SERVER;
extern NSString* const KEY_MQTT_PORT;
extern NSString* const KEY_MQTT_KEEP_ALIVE;
extern NSString* const KEY_MQTT_QOS;
extern NSString* const KEY_STUDY_ID;
extern NSString* const KEY_API;
extern NSString* const KEY_WEBSERVICE_SERVER;

extern NSString* const SETTING_DEBUG_STATE;
extern NSString *const SETTING_SYNC_WIFI_ONLY;
extern NSString* const SETTING_SYNC_INT;
extern NSString* const SETTING_SYNC_BATTERY_CHARGING_ONLY;
extern NSString* const SETTING_FREQUENCY_CLEAN_OLD_DATA;
extern NSString* const SETTING_AUTO_SYNC_STATE;
extern NSString* const SETTING_CSV_EXPORT_STATE;
extern NSString* const SETTING_DB_TYPE;
extern NSString* const SETTING_UI_MODE;
extern NSString* const SETTING_AUTO_SYNC;
extern NSString* const SETTING_CPU_THESHOLD;

extern NSString* const TABLE_INSER;
extern NSString* const TABLE_LATEST;
extern NSString* const TABLE_CREATE;
extern NSString* const TABLE_CLEAR;

extern NSString* const SENSOR_ACCELEROMETER;//accelerometer
extern NSString* const SENSOR_BAROMETER;//barometer
extern NSString* const SENSOR_BATTERY;
extern NSString* const SENSOR_BLUETOOTH;
extern NSString* const SENSOR_MAGNETOMETER;
extern NSString* const SENSOR_ESMS;
extern NSString* const SENSOR_GYROSCOPE;//Gyroscope
extern NSString* const SENSOR_LOCATIONS;
extern NSString* const SENSOR_NETWORK;
extern NSString* const SENSOR_PROCESSOR;
extern NSString* const SENSOR_PROXIMITY;
extern NSString* const SENSOR_ROTATION;
extern NSString* const SENSOR_SCREEN;
extern NSString* const SENSOR_TELEPHONY;
extern NSString* const SENSOR_WIFI;
extern NSString* const SENSOR_GRAVITY;
extern NSString* const SENSOR_LINEAR_ACCELEROMETER;
extern NSString* const SENSOR_TIMEZONE;
extern NSString* const SENSOR_AMBIENT_NOISE;
extern NSString* const SENSOR_SCHEDULER;
extern NSString* const SENSOR_CALLS;
extern NSString* const SENSOR_LABELS;
extern NSString* const SENSOR_ORIENTATION;
extern NSString* const SENSOR_HEALTH_KIT;
extern NSString* const SENSOR_IOS_ESM;

extern NSString* const SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION;
extern NSString* const SENSOR_IOS_ACTIVITY_RECOGNITION;
extern NSString* const SENSOR_GOOGLE_FUSED_LOCATION;
extern NSString* const SENSOR_PLUGIN_OPEN_WEATHER;
extern NSString* const SENSOR_PLUGIN_MSBAND;
extern NSString* const SENSOR_PLUGIN_DEVICE_USAGE;
extern NSString* const SENSOR_PLUGIN_NTPTIME;
extern NSString* const SENSOR_PLUGIN_SCHEDULER;
extern NSString* const SENSOR_PLUGIN_GOOGLE_CAL_PULL;
extern NSString* const SENSOR_PLUGIN_GOOGLE_CAL_PUSH;
extern NSString* const SENSOR_PLUGIN_GOOGLE_LOGIN;
extern NSString* const SENSOR_PLUGIN_CAMPUS;
extern NSString* const SENSOR_PLUGIN_PEDOMETER;
extern NSString* const SENSOR_PLUGIN_WEB_ESM;
extern NSString* const SENSOR_PLUGIN_BLE_HR;
extern NSString* const SENSOR_AWARE_DEBUG;
extern NSString* const SENSOR_PLUGIN_IOS_ESM;
extern NSString* const SENSOR_PLUGIN_FITBIT;
extern NSString* const SENSOR_PLUGIN_CONTACTS;
extern NSString* const SENSOR_BASIC_SETTINGS;
extern NSString* const SENSOR_PLUGIN_CALENDAR;

extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_CALORIES;
extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_DEVICECONTACT;
extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_DISTANCE;
extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_HEARTRATE;
extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_PEDOMETER;
extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_SKINTEMP;
extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_UV;
extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_BATTERYGAUGE;
extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_GSR;
extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_ACC;
extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_GYRO;
extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_ALTIMETER;
extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_BAROMETER;
extern NSString* const SENSOR_PLUGIN_MSBAND_SENSORS_RRINTERVAL;

extern NSString* const SENSOR_PLUGIN_MSBAND_KEY_ACTIVE_TIME_INTERVAL_IN_MINUTE;
extern NSString* const SENSOR_PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE;




extern NSString* const SENSOR_APPLICATION_HISTORY;

extern NSString * const NotificationCategoryIdent;
extern NSString * const NotificationActionOneIdent;
extern NSString * const NotificationActionTwoIdent;

extern NSString* const SENSOR_LABELS_TYPE_TEXT;
extern NSString* const SENSOR_LABELS_TYPE_BOOLEAN;

extern NSString* const SENSOR_PLUGIN_CAMPUS_ESM_NOTIFICATION_BOOLEAN;
extern NSString* const SENSOR_PLUGIN_CAMPUS_ESM_NOTIFICATION_LABEL;

//////////////////////////// Actions
extern NSString* const EXTRA_DATA;
// acc actions
extern NSString* const ACTION_AWARE_ACCELEROMETER;
// barometer actions
extern NSString* const ACTION_AWARE_BAROMETER;
// battery actions
extern NSString * const ACTION_AWARE_BATTERY_CHANGED;
extern NSString * const ACTION_AWARE_BATTERY_CHARGING;
//extern NSString * const ACTION_AWARE_BATTERY_CHARGING_AC;
//extern NSString * const ACTION_AWARE_BATTERY_CHARGING_USB;
extern NSString * const ACTION_AWARE_BATTERY_DISCHARGING;
extern NSString * const ACTION_AWARE_BATTERY_FULL;
//extern NSString * const ACTION_AWARE_BATTERY_LOW;
//extern NSString * const ACTION_AWARE_PHONE_SHUTDOWN;
//extern NSString * const ACTION_AWARE_PHONE_REBOOT;

// bluetooth
extern NSString * const ACTION_AWARE_BLUETOOTH_NEW_DEVICE;
extern NSString * const ACTION_AWARE_BLUETOOTH_SCAN_STARTED;
extern NSString * const ACTION_AWARE_BLUETOOTH_SCAN_ENDED;
//extern NSString * const ACTION_AWARE_BLUETOOTH_REQUEST_SCAN;

// Communication (Phone Call Events)
extern NSString * const ACTION_AWARE_CALL_ACCEPTED;// broadcasted when the user accepts an incoming call.
extern NSString * const ACTION_AWARE_CALL_RINGING;//: broadcasted when the phone is ringing.
extern NSString * const ACTION_AWARE_CALL_MISSED;//: broadcasted when the user lost a call.
extern NSString * const ACTION_AWARE_CALL_MADE;//: broadcasted when the user is making a call.
extern NSString * const ACTION_AWARE_USER_IN_CALL;//: broadcasted when the user is currently in a call.
extern NSString * const ACTION_AWARE_USER_NOT_IN_CALL;//: broadcasted when the user is not in a call.

// Debug
extern NSString * const ACTION_AWARE_DEBUG;

// Gravity
extern NSString * const ACTION_AWARE_GRAVITY;

// Gyroscope
extern NSString * const ACTION_AWARE_GYROSCOPE; //:new data recorded in provider.

// Linear Accelerometer
extern NSString * const ACTION_AWARE_LINEAR_ACCELEROMETER;

// Locations
extern NSString * const ACTION_AWARE_LOCATIONS; //: new location available.
//extern NSString * const ACTION_AWARE_GPS_LOCATION_ENABLED;//: GPS location is active.
//extern NSString * const ACTION_AWARE_NETWORK_LOCATION_ENABLED;//: network location is active.
//extern NSString * const ACTION_AWARE_GPS_LOCATION_DISABLED;//: GPS location disabled.
//extern NSString * const ACTION_AWARE_NETWORK_LOCATION_DISABLED;//: network location disabled.


// Magnetometer
extern NSString * const ACTION_AWARE_MAGNETOMETER;

// Network
//extern NSString * const ACTION_AWARE_AIRPLANE_ON;// broadcasted when airplane mode is activated.
//extern NSString * const ACTION_AWARE_AIRPLANE_OFF;// broadcasted when airplane mode is deactivated.
extern NSString * const ACTION_AWARE_WIFI_ON;// broadcasted when Wi-Fi is activated.
extern NSString * const ACTION_AWARE_WIFI_OFF;// broadcasted when Wi-Fi is deactivated.
extern NSString * const ACTION_AWARE_MOBILE_ON;// broadcasted when mobile network is activated.
extern NSString * const ACTION_AWARE_MOBILE_OFF;// broadcasted when mobile network is deactivated.
//extern NSString * const ACTION_AWARE_WIMAX_ON;// broadcasted when WIMAX is activated.
//extern NSString * const ACTION_AWARE_WIMAX_OFF;// broadcasted when WIMAX is deactivated.
//extern NSString * const ACTION_AWARE_BLUETOOTH_ON;// broadcasted when Bluetooth is activated.
//extern NSString * const ACTION_AWARE_BLUETOOTH_OFF;// broadcasted when Bluetooth is deactivated.
//extern NSString * const ACTION_AWARE_GPS_ON;// broadcasted when GPS is activated.
//extern NSString * const ACTION_AWARE_GPS_OFF;// broadcasted when GPS is deactivated.
extern NSString * const ACTION_AWARE_INTERNET_AVAILABLE;// broadcasted when the device is connected to the internet. One extra is included to provide the active internet access network:
//extern NSString * const EXTRA_ACCESS;// an integer with one of the following constants: 1=Wi-Fi, 2= Bluetooth, 4= Mobile, 5= WIMAX
extern NSString * const ACTION_AWARE_INTERNET_UNAVAILABLE;// broadcasted when the device is not connected to the internet.
//extern NSString * const ACTION_AWARE_NETWORK_TRAFFIC;// broadcasted when new traffic information is available for both Wi-Fi and mobile data.


extern NSString * const ACTION_AWARE_ROTATION;

extern NSString * const ACTION_AWARE_SCREEN_ON;// = @"ACTION_AWARE_SCREEN_ON";
extern NSString * const ACTION_AWARE_SCREEN_OFF;// = @"ACTION_AWARE_SCREEN_OFF";
extern NSString * const ACTION_AWARE_SCREEN_LOCKED;// = @"ACTION_AWARE_SCREEN_LOCKED";
extern NSString * const ACTION_AWARE_SCREEN_UNLOCKED;// = @"ACTION_AWARE_SCREEN_UNLOCKED";

// Timezone
extern NSString * const ACTION_AWARE_TIMEZONE;

// Wifi
extern NSString * const ACTION_AWARE_WIFI_NEW_DEVICE; //: new Wi-Fi device detected.
extern NSString * const ACTION_AWARE_WIFI_SCAN_STARTED; //: scan session has started.
extern NSString * const ACTION_AWARE_WIFI_SCAN_ENDED; //: scan session has ended.
extern NSString * const ACTION_AWARE_WIFI_REQUEST_SCAN; //: request a Wi-Fi scan as soon as possible.

// Activity Recognition
extern NSString * const ACTION_AWARE_GOOGLE_ACTIVITY_RECOGNITION;
extern NSString * const ACTION_AWARE_IOS_ACTIVITY_RECOGNITION;

// upload progress
extern NSString * const KEY_UPLOAD_PROGRESS_STR;
extern NSString * const KEY_UPLOAD_FIN;
extern NSString * const KEY_UPLOAD_SENSOR_NAME;
extern NSString * const KEY_UPLOAD_SUCCESS;
extern NSString * const ACTION_AWARE_DATA_UPLOAD_PROGRESS;
extern NSString * const ACTION_AWARE_PUSHED_QUICK_ANSWER_BUTTON;


extern NSString * const ACTION_AWARE_PEDOMETER;

extern NSString * const ACTION_AWARE_GOOGLE_LOGIN_REQUEST;
extern NSString * const ACTION_AWARE_GOOGLE_LOGIN_SUCCESS;

extern NSString * const ACTION_AWARE_CONTACT_REQUEST;

extern NSString * const ACTION_AWARE_SETTING_UI_UPDATE_REQUEST;

extern NSString * const ACTION_AWARE_FITBIT_LOGIN_REQUEST;

extern NSString * const ACTION_AWARE_UPDATE_STUDY_CONFIG;

extern NSString * const PLUGIN_CALENDAR_ESM_SCHEDULER_NOTIFICATION_CATEGORY;

extern NSString * const PLUGIN_CALENDAR_ESM_SCHEDULER_NOTIFICATION_ID;

@interface AWAREKeys: NSObject

@end
