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
#import "AWARESensors.h"
#import "AWAREEventLogger.h"
#import "AWAREStatusMonitor.h"

static AWARESensorManager * sharedSensorManager;

@implementation AWARESensorManager{
    /** upload timer */
    NSTimer * syncTimer;
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

+ (AWARESensorManager * _Nonnull) sharedSensorManager {
    @synchronized(self){
        if (!sharedSensorManager){
            sharedSensorManager = [[AWARESensorManager alloc] init];
        }
    }
    return sharedSensorManager;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedSensorManager == nil) {
            sharedSensorManager= [super allocWithZone:zone];
            return sharedSensorManager;
        }
    }
    return nil;
}


/**
 * Init a AWARESensorManager with an AWAREStudy
 */
- (instancetype)init{
    self = [super init];
    if (self) {
        awareSensors = [[NSMutableArray alloc] init];
        awareStudy = [AWAREStudy sharedStudy];
        lock = false;
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

- (void)setDebugToAllSensors:(bool)state{
    for (AWARESensor * sensor in awareSensors) {
        [sensor setDebug:state];
    }
}

- (void)setDebugToAllStorage:(bool)state{
    for (AWARESensor * sensor in awareSensors) {
        [sensor.storage setDebug:YES];
    }
}

- (BOOL) startAllSensors {
    if (![NSThread isMainThread]) {
        NSLog(@"[NOTE] Please call `-startAllSensors` in the main thread.");
    }
    if(awareSensors != nil){
        for (AWARESensor * sensor in awareSensors) {
            bool state = [sensor startSensor];
            [AWAREEventLogger.shared logEvent:@{@"AWARESensorManager":@"start sensor",
                                                @"sensor":sensor.getSensorName,
                                                @"state":@(state)}];
        }
    }
    return YES;
}

- (BOOL) addSensorsWithStudy:(AWAREStudy * _Nonnull) study{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger dbType = [userDefaults integerForKey:SETTING_DB_TYPE];
    return [self addSensorsWithStudy:study dbType:dbType];
}

- (BOOL) addSensorsWithStudy:(AWAREStudy * _Nonnull)study dbType:(AwareDBType)dbType{

    if (study != nil){
        awareStudy = study;
    }else{
        return NO;
    }

    NSArray * settings = [study getSensorSettings];
    
    AWARESensor* awareSensor = nil;
    
    /// start and make a sensor instance
    if(settings != nil){

        for (int i=0; i<settings.count; i++) {
            
            awareSensor = nil;
            
            NSString * setting = [[settings objectAtIndex:i] objectForKey:@"setting"];
            NSString * value = [[settings objectAtIndex:i] objectForKey:@"value"];
            
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
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_SCREEN]]){
                awareSensor = [[Screen alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PROXIMITY]]){
                awareSensor = [[Proximity alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_TIMEZONE]]){
                awareSensor = [[Timezone alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_CALLS]]){
                awareSensor = [[Calls alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_ROTATION]]){
                awareSensor = [[Rotation alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_IOS_ESM]]){
                awareSensor = [[IOSESM alloc] initWithAwareStudy:awareStudy dbType:dbType];
            } else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_OPEN_WEATHER]]){
                awareSensor = [[OpenWeather alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_DEVICE_USAGE]]){
                awareSensor = [[DeviceUsage alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_NTPTIME]]){
                awareSensor = [[NTPTime alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_GOOGLE_LOGIN]]){
//                awareSensor = [[GoogleLogin alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_GOOGLE_FUSED_LOCATION]]){
                awareSensor = [[FusedLocations alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_IOS_ESM]]){
                awareSensor = [[IOSESM alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@", SENSOR_PLUGIN_FITBIT]]){
                awareSensor = [[Fitbit alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@", SENSOR_BASIC_SETTINGS]]){
                awareSensor = [[BasicSettings alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if ([setting isEqualToString:AWARE_PREFERENCES_STATUS_SIGNIFICANT_MOTION]){
                awareSensor = [[SignificantMotion alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if ([setting isEqualToString:AWARE_PREFERENCES_STATUS_PUSH_NOTIFICATION]){
                awareSensor = [[PushNotification alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if ([setting isEqualToString:AWARE_PREFERENCES_STATUS_IOS_LOCATION_VISIT]){
                awareSensor = [[LocationVisit alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }
            #ifdef IMPORT_MIC
            else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_AMBIENT_NOISE]]){
                awareSensor = [[AmbientNoise alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:AWARE_PREFERENCES_STATUS_CONVERSATION]){
                awareSensor = [[Conversation alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }
            #endif
            #ifdef IMPORT_BLUETOOTH
            else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_BLUETOOTH]]){
                awareSensor = [[Bluetooth alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_BLE_HR]]){
                awareSensor = [[BLEHeartRate alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }
            #endif
            #ifdef IMPORT_MOTION_ACTIVITY
            else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@", SENSOR_PLUGIN_PEDOMETER]]){
                awareSensor = [[Pedometer alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if ([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION]]){
                awareSensor = [[IOSActivityRecognition alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_IOS_ACTIVITY_RECOGNITION ]] ) {
                awareSensor = [[IOSActivityRecognition alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_HEADPHONE_MOTION ]] ) {
                awareSensor = [[HeadphoneMotion alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }
            #endif
            #ifdef IMPORT_CONTACT
            else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@", SENSOR_PLUGIN_CONTACTS]]){
                awareSensor = [[Contacts alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }
            #endif
            #ifdef IMPORT_CALENDAR
            else if ([setting isEqualToString:AWARE_PREFERENCES_STATUS_CALENDAR_ESM]){
                awareSensor = [[CalendarESMScheduler alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }else if ([setting isEqualToString:AWARE_PREFERENCES_STATUS_CALENDAR]){
                awareSensor = [[Calendar alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }
            #endif
            #ifdef IMPORT_HEALTHKIT
            else if ([setting isEqualToString:AWARE_PREFERENCES_STATUS_HEALTHKIT]){
                awareSensor = [[AWAREHealthKit alloc] initWithAwareStudy:awareStudy dbType:dbType];
            }
            #endif

            if (awareSensor != nil) {
                // Start the sensor
                if ([value isEqualToString:@"true"]) {
                    [awareSensor setParameters:settings];
                    
                    // Add the sensor to the sensor manager
                    [self addSensor:awareSensor];
                }
            }
        }
    }
    
    return YES;
}


- (BOOL)createDBTablesOnAwareServer{
    return [self createTablesOnRemoteServer];
}

- (BOOL)createTablesOnRemoteServer{
    if (![NSThread isMainThread]) {
        NSLog(@"[NOTE] Please call `-createTablesOnRemoteServer` in the main thread.");
    }
    for(AWARESensor * sensor in awareSensors){
        [sensor createTable];
    }
    return YES;
}

/**
 * Check an existance of a sensor by a sensor name
 * You can find and edit the keys on AWAREKeys.h and AWAREKeys.m
 *
 * @param   sensorName A NSString key for a sensor
 * @return  An existance of the target sensor as a boolean value
 */
- (BOOL) isExist :(NSString * _Nonnull) sensorName {
    if([sensorName isEqualToString:@"location_gps"] || [sensorName isEqualToString:@"location_network"]){
        sensorName = @"locations";
    }
    
    if([sensorName isEqualToString:@"esm"]){
        sensorName = @"esms";
    }
    
    for (AWARESensor* sensor in awareSensors) {
        if ([sensor getSensorName] != nil ) {
            if([[sensor getSensorName] isEqualToString:sensorName]){
                return YES;
            }
        }
    }
    return NO;
}

- (void)addSensors:(NSArray<AWARESensor *> * _Nonnull)sensors{
    if (sensors != nil) {
        for (AWARESensor * sensor in sensors){
            [self addSensor:sensor];
        }
    }
}

/**
 * Add a new sensor to a aware sensor manager
 *
 * @param sensor An AWARESensor object (A null value is not an acceptable)
 */
- (void)addSensor:( AWARESensor * _Nonnull)sensor{
    if (sensor == nil) return;
    for(AWARESensor* storedSensor in awareSensors){
        if([storedSensor.getSensorName isEqualToString:sensor.getSensorName]){
            return;
        }
    }
    [awareSensors addObject:sensor];
}


- (AWARESensor * _Nullable )getSensor:(NSString *)sensorName{
    if (awareSensors != nil) {
        for (AWARESensor * sensor in awareSensors){
            if([sensor getSensorName] != nil){
                if([[sensor getSensorName] isEqualToString:sensorName]){
                    return sensor;
                }
            }
        }
    }
    return nil;
}


/**
 * Remove all sensors from the manager after stop the sensors
 */
- (void) stopAndRemoveAllSensors {
    // [self lock];
    if (![NSThread isMainThread]) {
        NSLog(@"[NOTE] Please call `-stopAndRemoveAllSensors` in the main thread.");
    }
    @autoreleasepool {
        for (AWARESensor* sensor in awareSensors) {
            // message = [NSString stringWithFormat:@"[%@] Stop %@ sensor",[sensor getSensorName], [sensor getSensorName]];
            // NSLog(@"%@", message);
            bool state = [sensor stopSensor];
            // [sensor.storage cancelSyncStorage];
            [sensor stopSyncDB];
            [AWAREEventLogger.shared logEvent:@{@"class":@"AWARESensorManager",
                                                @"event":@"stop and remove sensor",
                                                @"sensor":sensor.getSensorName,
                                                @"state":@(state)}];
        }
        [awareSensors removeAllObjects];
    }
    // [self unlock];
}

- (AWARESensor * _Nullable) getSensorWithKey:(NSString * _Nonnull)sensorName {
    for (AWARESensor* sensor in awareSensors) {
        if([[sensor getSensorName] isEqualToString:sensorName]){
            return sensor;
        }
    }
    return nil;
}

/**
 * Stop a sensor with the sensor name.
 * You can find the sensor name (key) on AWAREKeys.h and .m.
 * 
 * @param sensorName A NSString sensor name (key)
 */
- (void) stopSensor:(NSString * _Nonnull)sensorName{
    for (AWARESensor* sensor in awareSensors) {
        if ([sensor.getSensorName isEqualToString:sensorName]) {
            [sensor stopSensor];
            [AWAREEventLogger.shared logEvent:@{@"class":@"AWARESensorManager",
                                                @"event":@"stop sensor",
                                                @"sensor":sensorName}];
        }
    }
}


/**
 * Stop all sensors
 *
 */
- (void) stopAllSensors {
    if(awareSensors == nil) return;
    for (AWARESensor* sensor in awareSensors) {
        [sensor stopSensor];
        [sensor.storage cancelSyncStorage];
        if(sensor.getSensorName != nil){
            [AWAREEventLogger.shared logEvent:@{@"class":@"AWARESensorManager",
                                                @"event":@"stop sensor",
                                                @"sensor":sensor.getSensorName}];
        }
    }
}


/**
 * Provide latest sensor data by each sensor as NSString value.
 * You can access the data by using sensor names (keys) on AWAREKeys.h and .m.
 *
 * @param sensorName A NSString sensor name (key)
 * @return A latest sensor value as
 */
- (NSString*) getLatestSensorValue:(NSString * _Nonnull) sensorName {
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


- (NSDictionary *) getLatestSensorData:(NSString * _Nonnull) sensorName {
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


- (void)syncAllSensors {
    
    [AWAREEventLogger.shared logEvent:@{@"class":@"AWARESensorManager",@"event":@"sync: start syncAllSensor"}];
    
    if ([awareStudy isAutoDBSyncOnlyWifi]) {
        if (![awareStudy isWifiReachable]) {
            [AWAREEventLogger.shared logEvent:@{@"class":@"AWARESensorManager",@"event":@"sync: No Wifi Reachable"}];
            if(awareStudy.isDebug) NSLog(@"[AWARESensorManager] No Wifi Reachable");
            return;
        }else{
            [AWAREEventLogger.shared logEvent:@{@"class":@"AWARESensorManager",@"event":@"sync: Wifi Reachable"}];
            if(awareStudy.isDebug) NSLog(@"[AWARESensorManager] Wifi Reachable");
        }
    }
    
    if ([awareStudy isAutoDBSyncOnlyBatterChargning]) {
        switch ([UIDevice currentDevice].batteryState) {
            case UIDeviceBatteryStateFull:
            case UIDeviceBatteryStateCharging:
                [AWAREEventLogger.shared logEvent:@{@"class":@"AWARESensorManager",@"event":@"sync: Battery Charging Condition"}];
                if(awareStudy.isDebug) NSLog(@"[AWARESensorManager] Battery Charging Condition");
                break;
            case UIDeviceBatteryStateUnknown:
            case UIDeviceBatteryStateUnplugged:
                [AWAREEventLogger.shared logEvent:@{@"class":@"AWARESensorManager",@"event":@"sync: Not Battery Charging Condition"}];
                if(awareStudy.isDebug) NSLog(@"[AWARESensorManager] Not Battery Charging Condition");
                return;
        }
    }
    
    if (![awareStudy isNetworkReachable]) {
        [AWAREEventLogger.shared logEvent:@{@"class":@"AWARESensorManager",@"event":@"sync: No Network Connection"}];
        if(awareStudy.isDebug) NSLog(@"[AWARESensorManager] No Network Connection");
        return;
    }
    
    [AWAREEventLogger.shared logEvent:@{@"class":@"AWARESensorManager",@"event":@"sync: pass all flags"}];
    if(awareStudy.isDebug) NSLog(@"[AWARESensorManager] Start SyncDB");

    for (AWARESensor * sensor in awareSensors ) {
        [sensor startSyncDB];
    }
}

- (void)syncAllSensorsForcefully{
    
    [AWAREEventLogger.shared logEvent:@{@"class":@"AWARESensorManager",@"event":@"sync: syncAllSensorsForcefully"}];
    if (awareStudy.isDebug) NSLog(@"[AWARESensorManager] Start SyncDB forcefully");
    
    for (AWARESensor * sensor in awareSensors ) {
        NSString * name = sensor.getSensorName;
        if (name != nil){
            [AWAREEventLogger.shared logEvent:@{@"class":@"AWARESensorManager", @"event":@"sync", @"sensor":name}];
        }
        // sensor.storage.syncMode = AwareSyncModeQuick;
        [sensor startSyncDB];
    }
}


- (void) startAutoSyncTimer {
    if(awareStudy != nil){
        [self startAutoSyncTimerWithIntervalSecond:[awareStudy getAutoDBSyncIntervalSecond]];
    }else{
        double interval = [[AWAREStudy sharedStudy] getAutoDBSyncIntervalSecond];
        [self startAutoSyncTimerWithIntervalSecond:interval];
    }
}

/**
 Start a timer for synchronizing local storage with remote storage automatically in the background

 @param second An interval of the synchronization event trigger
 */
- (void) startAutoSyncTimerWithIntervalSecond:(double) second {
    if (syncTimer != nil) {
        [self stopAutoSyncTimer];
    }
    if (![NSThread isMainThread]) {
        NSLog(@"[NOTE] Please call `-startAutoSyncTimer` in the main thread.");
    }
    syncTimer = [NSTimer scheduledTimerWithTimeInterval:second
                                                   target:self
                                                 selector:@selector(syncAllSensors)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void) stopAutoSyncTimer{
    if (syncTimer != nil) {
        [syncTimer invalidate];
        syncTimer = nil;
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
            if([dirName isEqualToString:[NSString stringWithFormat:@"%@.json",[sensor getSensorName]]]){
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

- (void)resetAllSensors {
    for (AWARESensor * sensor in self->awareSensors) {
        [sensor resetSensor];
    }
}

- (void) resetAllMarkerPositionsInDB {
    for (AWARESensor * sensor in self->awareSensors) {
        [sensor.storage resetMark];
    }    
}

- (void)removeAllFilesFromDocumentRoot{
    NSFileManager   * fileManager    = [NSFileManager defaultManager];
    NSArray         * ducumentDir    =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString        * docRoot        = [ducumentDir objectAtIndex:0];
    NSError * error = nil;
    for ( NSString * dirName  in [fileManager contentsOfDirectoryAtPath:docRoot error:&error] ){
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


- (BOOL) checkFileExistance:(NSString *)name {
    /**
     * NOTE: Switch to CoreData to TextFile DB if this device is using TextFile DB
     */
    BOOL textFileExistance = NO;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json",name]];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        textFileExistance = YES;
    }else{
        textFileExistance = NO;
    }
    return textFileExistance;
}


- (void)setSensorEventHandlerToAllSensors:(SensorEventHandler)handler{
    for (AWARESensor * sensor in awareSensors) {
        [sensor setSensorEventHandler:handler];
    }
}

- (void)setSyncProcessCallbackToAllSensorStorages:(SyncProcessCallback)callback{
    for (AWARESensor * sensor in awareSensors) {
        [sensor.storage setSyncProcessCallback:callback];
    }
}

@end
