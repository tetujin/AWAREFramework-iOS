//
//  AWARESensorManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
// This class manages AWARESensors' start and stop operation.
// And also, you can upload sensor data manually by using this class.
//
//

#import "AWARESensorManager.h"
#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "AWAREPlugin.h"

// AWARE Sensors
#import "Accelerometer.h"
#import "Gyroscope.h"
#import "Magnetometer.h"
#import "Rotation.h"
#import "Battery.h"
#import "Barometer.h"
#import "Locations.h"
#import "Network.h"
#import "Wifi.h"
#import "Processor.h"
#import "Gravity.h"
#import "LinearAccelerometer.h"
#import "Bluetooth.h"
// #import "AmbientNoise.h"
#import "Screen.h"
#import "NTPTime.h"
#import "Proximity.h"
#import "Timezone.h"
#import "Calls.h"
#import "ESM.h"
#import "PushNotification.h"

// AWARE Plugins
// #import "ActivityRecognition.h"
#import "IOSActivityRecognition.h"
#import "OpenWeather.h"
#import "DeviceUsage.h"
// #import "MSBand.h"
#import "GoogleCalPull.h"
#import "GoogleCalPush.h"
#import "GoogleLogin.h"
#import "BalacnedCampusESMScheduler.h"
#import "FusedLocations.h"
#import "Pedometer.h"
#import "BLEHeartRate.h"
#import "Memory.h"
// #import "AWAREHealthKit.h"
#import "WebESM.h"
// #import "IBeacon.h"
#import "IOSESM.h"

#import "Observer.h"
#import "Contacts.h"
#import "Fitbit.h"
// #import "Estimote.h"
#import "BasicSettings.h"

// #import "AWARE-Swift.h"


@implementation AWARESensorManager{
    /** upload timer */
    NSTimer * uploadTimer;
    /** sensor manager */
    NSMutableArray* awareSensors;
    /** aware study */
    AWAREStudy * awareStudy;
    /** lock state*/
    BOOL lock;
    /** progress of manual upload */
    int manualUploadProgress;
    int numberOfSensors;
    BOOL manualUploadResult;
    NSTimer * manualUploadMonitor;
    NSObject * observer;
    NSMutableDictionary * progresses;
    int manualUploadTime;
    BOOL alertState;
    NSDictionary * previousProgresses;
}

/**
 * Init a AWARESensorManager with an AWAREStudy
 * @param   AWAREStudy  An AWAREStudy content
 */
- (instancetype)initWithAWAREStudy:(AWAREStudy *) study {
    self = [super init];
    if (self) {
        awareSensors = [[NSMutableArray alloc] init];
        awareStudy = study;
        lock = false;

        manualUploadProgress = 0;
        numberOfSensors = 0;
        manualUploadTime = 0;
        alertState = NO;
        previousProgresses = [[NSDictionary alloc] init];
    }
    return self;
}


- (void)lock{
    lock = YES;
}

- (void)unlock{
    lock = NO;
}

- (BOOL)isLocked{
    return lock;
}

- (BOOL) startAllSensors{
    return [self startAllSensorsWithStudy:awareStudy];
}

- (BOOL)startAllSensorsWithStudy:(AWAREStudy *) study{
    //return [self startAllSensorsWithStudy:study dbType:AwareDBTypeCoreData];
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger dbType = [userDefaults integerForKey:SETTING_DB_TYPE];
    return [self startAllSensorsWithStudy:study dbType:dbType];
}

- (BOOL)startAllSensorsWithStudy:(AWAREStudy *) study dbType:(AwareDBType)dbType{
    
    [self stopAndRemoveAllSensors];
    
    if (study != nil){
        awareStudy = study;
    }else{
        return NO;
    }

//    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
//    if ([[awareStudy getStudyId] isEqualToString:@""]) {
//        NSLog( @"ERROR: You did not have a StudyID. Please check your study configuration.");
//        return NO;
//    }

    // sensors settings
    NSArray *sensors = [awareStudy getSensors];
    
    // plugins settings
    NSArray *plugins = [awareStudy  getPlugins];
    
    AWARESensor* awareSensor = nil;
    
    /// start and make a sensor instance
    if(sensors != nil){

        for (int i=0; i<sensors.count; i++) {
            
            awareSensor = nil;
            
            NSString * setting = [[sensors objectAtIndex:i] objectForKey:@"setting"];
            NSString * value = [[sensors objectAtIndex:i] objectForKey:@"value"];
            
            if ([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_ACCELEROMETER]]) {
                awareSensor= [[Accelerometer alloc] initWithAwareStudy:awareStudy dbType:dbType ];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_BAROMETER]]){
                awareSensor = [[Barometer alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_GYROSCOPE]]){
                awareSensor = [[Gyroscope alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_MAGNETOMETER]]){
                awareSensor = [[Magnetometer alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_BATTERY]]){
                awareSensor = [[Battery alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_LOCATIONS]]){
                awareSensor = [[Locations alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_NETWORK]] ||
                     [setting isEqualToString:@"status_network_events"]){
                awareSensor = [[Network alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_WIFI]]){
                awareSensor = [[Wifi alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if ([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PROCESSOR]]){
                awareSensor = [[Processor alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if ([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_GRAVITY]]){
                awareSensor = [[Gravity alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_LINEAR_ACCELEROMETER]]){
                awareSensor = [[LinearAccelerometer alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_BLUETOOTH]]){
                awareSensor = [[Bluetooth alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_SCREEN]]){
                awareSensor = [[Screen alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PROXIMITY]]){
                awareSensor = [[Proximity alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_TIMEZONE]]){
                awareSensor = [[Timezone alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_ESMS]]){
                /** ESM and WebESM plugin are replaced to iOS ESM ( = IOSESM class) plugin */
                // awareSensor = [[ESM alloc] initWithAwareStudy:awareStudy dbType:dbType];
                // awareSensor = [[WebESM alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_CALLS]]){
                awareSensor = [[Calls alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_ROTATION]]){
                awareSensor = [[Rotation alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_IOS_ESM]]){
                awareSensor = [[IOSESM alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }
            
            if (awareSensor != nil) {
                // Start the sensor
                if ([value isEqualToString:@"true"]) {
                    [awareSensor startSensorWithSettings:sensors];
                }
                [awareSensor trackDebugEvents];
                // Add the sensor to the sensor manager
                [self addNewSensor:awareSensor];
            }
        }
    }
    
    if(plugins != nil){
        // Start and make a plugin instance
        for (int i=0; i<plugins.count; i++) {
            NSDictionary *plugin = [plugins objectAtIndex:i];
            NSArray *pluginSettings = [plugin objectForKey:@"settings"];
            for (NSDictionary* pluginSetting in pluginSettings) {
                
                awareSensor = nil;
                NSString *pluginName = [pluginSetting objectForKey:@"setting"];
                NSLog(@"%@", pluginName);
                if ([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION]]){
                    // NOTE: This sensor is not longer supported. The sensor will move to iOS activity recognition plugin.
                    // awareSensor = [[ActivityRecognition alloc] initWithAwareStudy:awareStudy dbType:dbType];
                    
                    // iOS Activity Recognition API
                    NSString * pluginState = [pluginSetting objectForKey:@"value"];
                    if ([pluginState isEqualToString:@"true"]) {
                        AWARESensor * iosActivityRecognition = [[IOSActivityRecognition alloc] initWithAwareStudy:awareStudy dbType:dbType];
                        [iosActivityRecognition startSensorWithSettings:pluginSettings];
                        [iosActivityRecognition trackDebugEvents];
                        [self addNewSensor:iosActivityRecognition];
                    }
                    
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_IOS_ACTIVITY_RECOGNITION ]] ) {
                    awareSensor = [[IOSActivityRecognition alloc] initWithAwareStudy:awareStudy dbType:dbType];
                } else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_OPEN_WEATHER]]){
                    awareSensor = [[OpenWeather alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_DEVICE_USAGE]]){
                    awareSensor = [[DeviceUsage alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_NTPTIME]]){
                    awareSensor = [[NTPTime alloc] initWithAwareStudy:awareStudy dbType:dbType];
//                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_MSBAND]]){
//                    awareSensor = [[MSBand alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_GOOGLE_CAL_PULL]]){
                    awareSensor = [[GoogleCalPull alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_GOOGLE_CAL_PUSH]]){
                    awareSensor = [[GoogleCalPush alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_GOOGLE_LOGIN]]){
                    awareSensor = [[GoogleLogin alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_CAMPUS]]){
                    awareSensor = [[BalacnedCampusESMScheduler alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_GOOGLE_FUSED_LOCATION]]){
                    awareSensor = [[FusedLocations alloc] initWithAwareStudy:awareStudy dbType:dbType];
//                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_AMBIENT_NOISE]]){
//                    awareSensor = [[AmbientNoise alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_BLE_HR]]){
                    awareSensor = [[BLEHeartRate alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_IOS_ESM]]){
                    awareSensor = [[IOSESM alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@", SENSOR_PLUGIN_FITBIT]]){
                    awareSensor = [[Fitbit alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@", SENSOR_PLUGIN_CONTACTS]]){
                    awareSensor = [[Contacts alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@", SENSOR_PLUGIN_PEDOMETER]]){
                    awareSensor = [[Pedometer alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@", SENSOR_BASIC_SETTINGS]]){
                    awareSensor = [[BasicSettings alloc] initWithAwareStudy:awareStudy dbType:dbType];
//                }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@", @"calendar"]]){
//                    awareSensor = [[Calendar alloc] initWithAwareStudy:awareStudy dbType:dbType];
                }
                
                if(awareSensor != nil){
                    NSString * pluginState = [pluginSetting objectForKey:@"value"];
                    if ([pluginState isEqualToString:@"true"]) {
                        [awareSensor startSensorWithSettings:pluginSettings];
                    }
                    [awareSensor trackDebugEvents];
                    [self addNewSensor:awareSensor];
                }
            }
        }
    }
    
    /**
     * [Additional hidden sensors]
     * You can add your own AWARESensor to AWARESensorManager directly using following source code.
     * The "-addNewSensor" method is versy userful for testing and debuging a AWARESensor without registlating a study.
     */
    
    // Memory
//    AWARESensor *memory = [[Memory alloc] initWithSensorName:@"memory" withAwareStudy:awareStudy];
//    [memory startSensor:uploadInterval withSettings:nil];
//    [self addNewSensor:memory];
    
//    AWARESensor * calSensor = [[Calendar alloc] initWithAwareStudy:awareStudy dbType:dbType];
//    [calSensor startSensorWithSettings:nil];
//    [self addNewSensor:calSensor];
    
    // Observer
     AWARESensor *observerSensor = [[Observer alloc] initWithAwareStudy:awareStudy dbType:dbType];
     [observerSensor startSensorWithSettings:nil];
     [self addNewSensor:observerSensor];

    // Push Notification
    AWARESensor * pushNotification = [[PushNotification alloc] initWithAwareStudy:awareStudy dbType:dbType];
    [pushNotification startSensorWithSettings:nil];
    [self addNewSensor:pushNotification];
    
    // Fitbit
//    AWARESensor * fitbit = [[Fitbit alloc] initWithAwareStudy:awareStudy dbType:dbType];
//    [fitbit startSensorWithSettings:nil];
//    [self addNewSensor:fitbit];
    
//    IBeacon * iBeacon = [[IBeacon alloc] initWithAwareStudy:awareStudy];
//    [iBeacon startSensorWithSettings:nil];
//    [self addNewSensor:iBeacon];
    
    
//    Estimote * estimote = [[Estimote alloc] initWithAwareStudy:awareStudy dbType:dbType];
//    [estimote startSensorWithSettings:nil];
//    [self addNewSensor:estimote];
    
    /**
     * Debug Sensor
     * NOTE: don't remove this sensor. This sensor collects debug messages.
     */
    AWARESensor * debug = [[Debug alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    [debug startSensorWithSettings:nil];
    [self addNewSensor:debug];
    
    
    AWARESensor * iOSESM = [[IOSESM alloc] initWithAwareStudy:study dbType:dbType];
    bool stateIOSESM = [self isExist:SENSOR_PLUGIN_IOS_ESM];
    if( stateIOSESM == NO){
        [iOSESM quitSensor];
    }
    
    return YES;
}


- (BOOL)createAllTables{
    for(AWARESensor * sensor in awareSensors){
        [sensor createTable];
    }
    return YES;
}


/**
 * Check an existance of a sensor by a sensor name
 * You can find and edit the keys on AWAREKeys.h and AWAREKeys.m
 *
 * @param   key A NSString key for a sensor
 * @return  An existance of the target sensor as a boolean value
 */
- (BOOL) isExist :(NSString *) key {
    if([key isEqualToString:@"location_gps"] || [key isEqualToString:@"location_network"]){
        key = @"locations";
    }
    
    if([key isEqualToString:@"esm"]){
        key = @"esms";
    }
    
    for (AWARESensor* sensor in awareSensors) {
        if([[sensor getSensorName] isEqualToString:key]){
            return YES;
        }
    }
    return NO;
}


/**
 * Add a new sensor to a aware sensor manager
 *
 * @param sensor An AWARESensor object (A null value is not an acceptable)
 */
- (void) addNewSensor : (AWARESensor *) sensor {
    if (sensor == nil) return;
    for(AWARESensor* storedSensor in awareSensors){
        if([storedSensor.getSensorName isEqualToString:sensor.getSensorName]){
            return;
        }
    }
    [awareSensors addObject:sensor];
}

/**
 * Remove all sensors from the manager after stop the sensors
 */
- (void) stopAndRemoveAllSensors {
    [self lock];
    NSString * message = nil;
    @autoreleasepool {
        for (AWARESensor* sensor in awareSensors) {
            message = [NSString stringWithFormat:@"[%@] Stop %@ sensor",[sensor getSensorName], [sensor getSensorName]];
            NSLog(@"%@", message);
            [sensor saveDebugEventWithText:message type:DebugTypeInfo label:@"stop"];
            [sensor stopSensor];
            [sensor cancelSyncProcess];
        }
        [awareSensors removeAllObjects];
    }
    [self unlock];
}

- (AWARESensor *) getSensorWithKey:(NSString *)sensorName {
    for (AWARESensor* sensor in awareSensors) {
        if([[sensor getSensorName] isEqualToString:sensorName]){
            return sensor;
        }
    }
    return nil;
}

- (void)quitAllSensor{
    // TODO
    for (AWARESensor* sensor in awareSensors) {
        [sensor quitSensor];
    }
}

/**
 * Stop a sensor with the sensor name.
 * You can find the sensor name (key) on AWAREKeys.h and .m.
 * 
 * @param sensorName A NSString sensor name (key)
 */
- (void) stopASensor:(NSString *)sensorName{
    for (AWARESensor* sensor in awareSensors) {
        if ([sensor.getSensorName isEqualToString:sensorName]) {
            [sensor stopSensor];
        }
        [sensor stopSensor];
    }
}


/**
 * Stop all sensors
 *
 */
- (void) stopAllSensors{
    if(awareSensors == nil) return;
    for (AWARESensor* sensor in awareSensors) {
        [sensor stopSensor];
    }
}


/**
 * Provide latest sensor data by each sensor as NSString value.
 * You can access the data by using sensor names (keys) on AWAREKeys.h and .m.
 *
 * @param sensorName A NSString sensor name (key)
 * @return A latest sensor value as
 */
- (NSString*) getLatestSensorValue:(NSString *) sensorName {
    if ([self isLocked]) return @"";
    
    if([sensorName isEqualToString:@"location_gps"] || [sensorName isEqualToString:@"location_network"]){
        sensorName = @"locations";
    }
    
    
    for (AWARESensor* sensor in awareSensors) {
        if (sensor.getSensorName != nil) {
            if ([sensor.getSensorName isEqualToString:sensorName]) {
                NSString *sensorValue = [sensor getLatestValue];
                return sensorValue;
            }
        }
    }
    return @"";
}


- (NSDictionary * ) getLatestSensorData:(NSString *) sensorName {
    if ([self isLocked])
        return [[NSDictionary alloc] init];
    
    if([sensorName isEqualToString:@"location_gps"] || [sensorName isEqualToString:@"location_network"]){
        sensorName = @"locations";
    }
    
    for (AWARESensor* sensor in awareSensors) {
        if (sensor.getSensorName != nil) {
            if ([sensor.getSensorName isEqualToString:sensorName]) {
                return [sensor getLatestData];
            }
        }
    }
    return [[NSDictionary alloc] init];
}


/**
 *
 */
- (NSArray *) getAllSensors {
    return awareSensors;
}



/**
 * Upload sensor data manually in the foreground
 *
 * NOTE: 
 * This method works in the foreground only, and lock the uploading file.
 * During an uploading process, an AWARE can not access to the file.
 *
 */
- (bool) syncAllSensorsWithDBInForeground {
    
    if(manualUploadMonitor != nil){
        [manualUploadMonitor invalidate];
        manualUploadMonitor = nil;
    }
    
    // [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD showWithStatus:@"Start manual upload"];
    
//    [self stopAndRemoveAllSensors];
//    [self startAllSensors];
    
    manualUploadMonitor = [NSTimer scheduledTimerWithTimeInterval:1
                                                           target:self
                                                         selector:@selector(checkAllSensorsUploadStatus:)
                                                         userInfo:nil
                                                          repeats:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        
        // show progress view
        numberOfSensors = (int)awareSensors.count;
        progresses = [[NSMutableDictionary alloc] init];
        for (AWARESensor * sensor in awareSensors) {
            [progresses setObject:@0 forKey:[sensor getSensorName]];
        }
        
        observer = [[NSNotificationCenter defaultCenter]
                               addObserverForName:ACTION_AWARE_DATA_UPLOAD_PROGRESS
                               object:nil
                               queue:nil
                               usingBlock:^(NSNotification *notif) {
                                   NSDictionary * userInfo = notif.userInfo;
                                   if(userInfo != nil){
                                       // call main thread for UI update
                                       dispatch_sync(dispatch_get_main_queue(), ^{
                                           NSNumber* progressStr = [userInfo objectForKey:KEY_UPLOAD_PROGRESS_STR];
                                           BOOL isFinish =  [[userInfo objectForKey:KEY_UPLOAD_FIN] boolValue];
                                           BOOL isSuccess = [[userInfo objectForKey:KEY_UPLOAD_SUCCESS] boolValue];
                                           NSString* progressName = [userInfo objectForKey:KEY_UPLOAD_SENSOR_NAME];
                                           [progresses setObject:progressStr forKey:progressName];

                                           // update progress
                                           @try {
                                               NSMutableString * result = [[NSMutableString alloc] init];
                                               for (id key in [progresses keyEnumerator]) {
                                                   double progress = [[progresses objectForKey:key] doubleValue];
                                                   [result appendFormat:@"%@ (%.2f %%)\n", key, progress];
                                               }
                                               [SVProgressHUD showWithStatus:result];
                                           } @catch (NSException *exception) {
                                               NSLog(@"%@", exception.debugDescription);
                                           } @finally {
                                               
                                           }
                                           
                                           // stop
                                           if(isFinish == YES && isSuccess == NO){
                                               
                                               AudioServicesPlayAlertSound(1010);
                                               if([AWAREUtils isBackground]){
                                                   [AWAREUtils sendLocalNotificationForMessage:@"[Manual Upload] Failed to upload sensor data. Please try uploading again." soundFlag:YES];
                                               }else{
                                                   UIAlertView *alert = [ [UIAlertView alloc]
                                                                         initWithTitle:@""
                                                                         message:@"[Manual Upload] Failed to upload sensor data. Please try upload again."
                                                                         delegate:nil
                                                                         cancelButtonTitle:@"OK"
                                                                         otherButtonTitles:nil];
                                                   [alert show];
                                               }
                                           }
                                       });
                                   }
                               }];
        
        for ( AWARESensor * sensor in awareSensors ) {
            // NSLog(sensor.getSensorName);
            // [sensor resetMark]; // <- [TEST]
            [sensor syncAwareDBInForeground];
        }
        
        
//        for ( int i=0; i < awareSensors.count; i++) {
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i * 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//                NSLog(@"%d", [NSThread isMainThread]);
//                @try {
//                    if (i < awareSensors.count ) {
//                        AWARESensor* sensor = [awareSensors objectAtIndex:i];
//                        [sensor  syncAwareDBInForeground];
//                    }else{
//                        NSLog(@"error");
//                    }
//                } @catch (NSException *e) {
//                    NSLog(@"An exception was appeared: %@",e.name);
//                    NSLog(@"The reason: %@",e.reason);
//                }
//            });
//        }

    });
    return YES;
}


- (void) checkAllSensorsUploadStatus:(id)sensder{
    
    BOOL finish = YES;
    for (AWARESensor * sensor in awareSensors) {
        // NSLog(@"[%@] %d", [sensor getSensorName], [sensor isUploading]);
        if([sensor isUploading]){
            finish = NO;
        }
    }
    
    if(finish){
        // stop NSTimer
        [manualUploadMonitor invalidate];
        manualUploadMonitor = nil;
        // remove observer from DefaultCenter
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
       
        // check progress of all sensors
        BOOL completion = YES;
        
        @try {
            for (id key in [progresses keyEnumerator]) {
                double progress = [[progresses objectForKey:key] doubleValue];
                // NSLog(@"[%@] %f", key ,progress);
                if(progress < 100){
                    completion = NO;
                    break;
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"%@", exception.debugDescription);
        } @finally {
            
        }
        
        
//        [SVProgressHUD performSelector:@selector(dismiss) withObject:nil afterDelay:1.0f];
        [SVProgressHUD dismiss];
        
        if ( completion ){
//            [SVProgressHUD showSuccessWithStatus:@"Success to upload all sensor data!"];
            AudioServicesPlayAlertSound(1000);
            if([AWAREUtils isBackground]){
                [AWAREUtils sendLocalNotificationForMessage:@"[Manual Upload] Succeed to upload all sensors data." soundFlag:YES];
            }else{
                UIAlertView *alert = [ [UIAlertView alloc]
                                      initWithTitle:@""
                                      message:@"[Manual Upload] sensors data are uploaded !!"
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
                [alert show];
            }
        } else {
//            [SVProgressHUD showErrorWithStatus:@"Failed to upload sensor data. Please try upload again."];
            // AudioServicesPlayAlertSound(1324);
            AudioServicesPlayAlertSound(1010);
            if([AWAREUtils isBackground]){
                [AWAREUtils sendLocalNotificationForMessage:@"[Manual Upload] Failed to upload sensor data. Please try uploading again." soundFlag:YES];
            }else{
                UIAlertView *alert = [ [UIAlertView alloc]
                                      initWithTitle:@""
                                      message:@"[Manual Upload] Failed to upload sensor data. Please try uploading again."
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
                [alert show];
            }
            
        }
    }
    
    /** ========= Freeze Check ======== */
    @try {
        manualUploadTime ++;
        // NSLog(@"%d", manualUploadTime);
        if(manualUploadTime > 60 ){
            manualUploadTime = 0;
            for (id key in [progresses keyEnumerator]) {
                double progress = [[progresses objectForKey:key] doubleValue];
                if(progress == 0 && alertState == NO ){
                    alertState = YES;
                    UIAlertView *alert = [ [UIAlertView alloc]
                                          initWithTitle:@"Manual Upload"
                                          message:@"The manual upload process might have encountered an error. Do you want to continue uploading sensor data? Please try manually uploading again."
                                          delegate:self
                                          cancelButtonTitle:@"NO"
                                          otherButtonTitles:@"YES",nil];
                    [alert show];
                    break;
                }
            }
            previousProgresses = progresses;
        }
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.debugDescription);
    } @finally {
        
    }
    
    
    /** =======  WiFi network ======= */
//    if(![awareStudy isWifiReachable]){
//        // stop NSTimer
//        [manualUploadMonitor invalidate];
//        manualUploadMonitor = nil;
//        
//        // remove observer from DefaultCenter
//        [[NSNotificationCenter defaultCenter] removeObserver:observer];
//        [SVProgressHUD performSelector:@selector(dismiss) withObject:nil afterDelay:3.0f];
//        AudioServicesPlayAlertSound(1324);
//        
//        if([AWAREUtils isBackground]){
//            [AWAREUtils sendLocalNotificationForMessage:@"[Manual Upload] WiFi connection is closed. Please try upload again with WiFi." soundFlag:YES];
//        }else{
//            UIAlertView *alert = [ [UIAlertView alloc]
//                                  initWithTitle:@""
//                                  message:@"[Manual Upload] WiFi connection is closed. Please try upload again with WiFi."
//                                  delegate:nil
//                                  cancelButtonTitle:@"OK"
//                                  otherButtonTitles:nil];
//            [alert show];
//        }
//    }
    
    /** =========  Battery Charging  ====== */
//    if( [UIDevice currentDevice].batteryState == UIDeviceBatteryStateUnplugged ){
//        [manualUploadMonitor invalidate];
//        manualUploadMonitor = nil;
//        
//        // remove observer from DefaultCenter
//        [[NSNotificationCenter defaultCenter] removeObserver:observer];
//        [SVProgressHUD performSelector:@selector(dismiss) withObject:nil afterDelay:3.0f];
//        AudioServicesPlayAlertSound(1324);
//        
//        if([AWAREUtils isBackground]){
//            [AWAREUtils sendLocalNotificationForMessage:@"[Manual Upload] The battery is not charged. Please try upload again with battery charging." soundFlag:YES];
//        }else{
//            UIAlertView *alert = [ [UIAlertView alloc]
//                                  initWithTitle:@""
//                                  message:@"[Manual Upload] The battery is not charged. Please try upload again with battery charging."
//                                  delegate:nil
//                                  cancelButtonTitle:@"OK"
//                                  otherButtonTitles:nil];
//            [alert show];
//        }
//    }
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        // stop NSTimer
        [manualUploadMonitor invalidate];
        manualUploadMonitor = nil;
        // remove observer from DefaultCenter
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        [SVProgressHUD showErrorWithStatus:@"Failed to upload data to the server."];
        AudioServicesPlayAlertSound(1324);
        [SVProgressHUD performSelector:@selector(dismiss) withObject:nil afterDelay:3.0f];
    }
    alertState = NO;
}


//- (bool) syncOldSensorsDataInTextFileWithDBInForeground {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
//        @autoreleasepool{
//            // Show progress bar
//            bool sucessOfUpload = true;
//            dispatch_sync(dispatch_get_main_queue(), ^{
//                [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
//            });
//            // Sync local stored data with aware server.
//            for ( int i=0; i<awareSensors.count; i++) {
//                
//                AWARESensor* sensor = [awareSensors objectAtIndex:i];
//                NSString *message = [NSString stringWithFormat:@"Uploading %@ data %@",
//                                     [sensor getSensorName],
//                                     [sensor getSyncProgressAsText]];
//                [SVProgressHUD setStatus:message];
//                
//                [sensor lockDB];
//                if (![sensor syncAwareDBInForeground]) {
//                    sucessOfUpload = NO;
//                }
//                [sensor unlockDB];
//            }
//            // Update UI in the main thread.
//            dispatch_sync(dispatch_get_main_queue(), ^{
//                if (sucessOfUpload) {
//                    [SVProgressHUD showSuccessWithStatus:@"Success to upload your data to the server!"];
//                    AudioServicesPlayAlertSound(1000);
//                }else{
//                    [SVProgressHUD showErrorWithStatus:@"Failed to upload data to the server."];
//                    AudioServicesPlayAlertSound(1324);
//                }
//                [SVProgressHUD performSelector:@selector(dismiss) withObject:nil afterDelay:3.0f];
//                
//            });
//        }
//    });
//    return YES;
//}


/**
 * Sync All Sensors with DB in the bacground
 *
 */
- (bool) syncAllSensorsWithDBInBackground {
    
    if([[awareStudy getStudyURL] isEqualToString:@""]){
        return NO;
    }
    
    // Sync local stored data with aware server.
    if(awareSensors == nil){
        return NO;
    }
    for ( int i=0; i < awareSensors.count; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i * 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            @try {
                if (i < awareSensors.count ) {
                    AWARESensor* sensor = [awareSensors objectAtIndex:i];
                    [sensor syncAwareDB];
                }else{
                    NSLog(@"error");
                }
            } @catch (NSException *e) {
                NSLog(@"An exception was appeared: %@",e.name);
                NSLog(@"The reason: %@",e.reason);
            }
        });
    }
    return YES;
}



- (void) startUploadTimerWithInterval:(double) interval {
    if (uploadTimer != nil) {
        [uploadTimer invalidate];
        uploadTimer = nil;
    }
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                   target:self
                                                 selector:@selector(syncAllSensorsWithDBInBackground)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void) stopUploadTimer{
    [uploadTimer invalidate];
    uploadTimer = nil;
}

- (void)runBatteryStateChangeEvents{
    if(awareSensors == nil) return;
    for (AWARESensor * sensor in awareSensors) {
        [sensor changedBatteryState];
    }
}


//////////////////////////////////////////////////////
//////////////////////////////////////////////////////


- (void) testSensing{
    [self testSensingWithCase:1];
}

/**
 *
 */
- (void) testSensingWithCase:(NSInteger)caseId{
    /**
     * 0 => text file (normal)
     * 1 => core data (normal)
     * 2 => text file -> core data
     * 3 => core data -> text file
     */

    // remove all sensor data in all cases
    NSLog(@"==============Stop and remove all sensors ================");
    [self stopAndRemoveAllSensors];
    [self removeAllFilesFromDocumentRoot];
    
    // get a start timestamp
    NSNumber * timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
    
    // NSLog(@"============== Set a study for a test ====================");
    [awareStudy setStudyInformationWithURL:@"https://api.awareframework.com/index.php/webservice/index/876/Dtw61qkZ7Sc4"];
    
    switch (caseId) {
        case 0:
            [self startAllSensorsWithStudy:awareStudy dbType:AwareDBTypeTextFile];
            [self performSelector:@selector(saveAllDummyDate) withObject:nil afterDelay:10];
            [self performSelector:@selector(stopAllSensors) withObject:nil afterDelay:40];
            [self performSelector:@selector(checkLocalDBs) withObject:nil afterDelay:41];
            [self performSelector:@selector(syncAllSensorsWithDBInForeground) withObject:nil afterDelay:45];
            [self performSelector:@selector(showAllLatestSensorDataFromServer:) withObject:timestamp afterDelay:90];
            break;
        case 1:
            [self startAllSensorsWithStudy:awareStudy dbType:AwareDBTypeCoreData];
            [self performSelector:@selector(saveAllDummyDate) withObject:nil afterDelay:10];
            [self performSelector:@selector(stopAllSensors) withObject:nil afterDelay:40];
            [self performSelector:@selector(checkLocalDBs) withObject:nil afterDelay:41];
            [self performSelector:@selector(syncAllSensorsWithDBInForeground) withObject:nil afterDelay:45];
            [self performSelector:@selector(showAllLatestSensorDataFromServer:) withObject:timestamp afterDelay:90];
            break;
        case 2:
            [self startAllSensorsWithStudy:awareStudy dbType:AwareDBTypeTextFile];
            [self performSelector:@selector(saveAllDummyDate) withObject:nil afterDelay:10];
            [self performSelector:@selector(stopAllSensors) withObject:nil afterDelay:40];
            [self performSelector:@selector(checkLocalDBs) withObject:nil afterDelay:41];
            [self performSelector:@selector(syncAllSensorsWithDBInForeground) withObject:nil afterDelay:45];
            [self performSelector:@selector(showAllLatestSensorDataFromServer:) withObject:timestamp afterDelay:90];
            
            timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
            [self performSelector:@selector(stopAndRemoveAllSensors) withObject:nil afterDelay:120];
            [self performSelector:@selector(startAllSensors) withObject:nil afterDelay:125];
            [self performSelector:@selector(saveAllDummyDate) withObject:nil afterDelay:135];
            [self performSelector:@selector(stopAllSensors) withObject:nil afterDelay:180];
            [self performSelector:@selector(checkLocalDBs) withObject:nil afterDelay:181];
            [self performSelector:@selector(syncAllSensorsWithDBInForeground) withObject:nil afterDelay:185];
            [self performSelector:@selector(showAllLatestSensorDataFromServer:) withObject:timestamp afterDelay:210];
            
        default:
            
            break;
    }
}


- (void) saveAllDummyDate {
    for (AWARESensor * sensor in awareSensors) {
        [sensor saveDummyData];
    }
}

- (void) showAllLatestSensorDataFromServer:(NSNumber *) startTimestamp {
    for (AWARESensor * sensor in [self getAllSensors]) {
        NSData * data = [sensor getLatestData];
        if(data != nil){
            // NSLog(@"[%@] sucess: %@", [sensor getSensorName], [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] );
            NSError *error = nil;
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &error];
            if(error != nil){
                NSLog(@"error: %@", error.debugDescription);
            }
            if(jsonArray != nil){
                for (NSDictionary * dict in jsonArray) {
                    NSNumber * timestamp = [dict objectForKey:@"timestamp"];
                    if(startTimestamp.longLongValue < timestamp.longLongValue){
                        NSLog(@"[Exist] %@ (%@ <---> %@)",[sensor getSensorName], timestamp, startTimestamp);
                    }else{
                        NSLog(@"[ None] %@ (%@ <---> %@)",[sensor getSensorName], timestamp, startTimestamp);
                    }
                }
            }else{
                NSLog(@"[Error] %@", [sensor getSensorName]);
            }
        }else{
            NSLog(@"[Error] %@'s data is null...", [sensor getSensorName]);
        }
    }
}

- (void) checkLocalDBs {
    for (AWARESensor * sensor in awareSensors) {
        NSFileManager   *fileManager    = [NSFileManager defaultManager];
        NSArray         *ducumentDir    =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString        *docRoot        = [ducumentDir objectAtIndex:0];
        NSError * error = nil;
        bool result = false;
        for ( NSString *dirName  in [fileManager contentsOfDirectoryAtPath:docRoot error:&error] ){
            // NSLog(@"%@", dirName);
            if([dirName isEqualToString:[NSString stringWithFormat:@"%@.dat",[sensor getSensorName]]]){
                NSLog(@"[Exist] %@", [sensor getSensorName]);
                result = true;
                break;
            }
        }
        if(!result){
            NSLog(@"[ None] %@", [sensor getSensorName]);
        }
    }
}

- (void) resetAllMarkerPositionsInDB {
    NSLog(@"------- Start to reset marker Position in DB -------");
    for (AWARESensor * sensor in awareSensors) {
        int preMark = [sensor getMarkerPosition];
        [sensor resetMarkerPosition];
        int currentMark = [sensor getMarkerPosition];
        NSLog(@"[%@] %d -> %d", [sensor getSensorName], preMark, currentMark);
    }
    NSLog(@"------- Finish to reset marker Position in DB -------");
}

- (void)removeAllFilesFromDocumentRoot{
    NSFileManager   *fileManager    = [NSFileManager defaultManager];
    NSArray         *ducumentDir    =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString        *docRoot        = [ducumentDir objectAtIndex:0];
    NSError * error = nil;
    for ( NSString *dirName  in [fileManager contentsOfDirectoryAtPath:docRoot error:&error] ){
        if([dirName isEqualToString:@"AWARE.sqlite"] ||
           [dirName isEqualToString:@"AWARE.sqlite-shm"] ||
           [dirName isEqualToString:@"AWARE.sqlite-wal"] ||
           [dirName isEqualToString:@"BandSDK"]){
            
        }else{
            [self removeFilePath:[NSString stringWithFormat:@"%@/%@",docRoot, dirName]];
        }
    }
}

- (BOOL)removeFilePath:(NSString*)path {
    NSLog(@"Remove => %@", path);
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    return [fileManager removeItemAtPath:path error:NULL];
}


///////////////////////////////////////////////////////////////////
-  (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
  completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                              NSURLCredential * _Nullable credential)) completionHandler{
    // http://stackoverflow.com/questions/19507207/how-do-i-accept-a-self-signed-ssl-certificate-using-ios-7s-nsurlsession-and-its
    
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        
        NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
        SecTrustRef trust = [protectionSpace serverTrust];
        NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
        
        // NSArray *certs = [[NSArray alloc] initWithObjects:(id)[[self class] sslCertificate], nil];
        // int err = SecTrustSetAnchorCertificates(trust, (CFArrayRef)certs);
        // SecTrustResultType trustResult = 0;
        // if (err == noErr) {
        //    err = SecTrustEvaluate(trust, &trustResult);
        // }
        
        // if ([challenge.protectionSpace.host isEqualToString:@"aware.ht.sfc.keio.ac.jp"]) {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // } else if ([challenge.protectionSpace.host isEqualToString:@"r2d2.hcii.cs.cmu.edu"]) {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // } else if ([challenge.protectionSpace.host isEqualToString:@"api.awareframework.com"]) {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // } else {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // }
        
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    }
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

- (BOOL) checkFileExistance:(NSString *)name {
    /**
     * NOTE: Switch to CoreData to TextFile DB if this device is using TextFile DB
     */
    BOOL textFileExistance = NO;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",name]];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        textFileExistance = YES;
    }else{
        textFileExistance = NO;
    }
    return textFileExistance;
}


@end
