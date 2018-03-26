//
//  AWARESensorViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//


/**
 * 2/16/2016 by Yuuki NISHIYAMA
 * 
 * The AWARESensor class is the super class of aware sensors, and wraps to access
 * local storages(LocalFileStorageHelper) and to upload sensor data to
 * an AWARE server(AWAREDataUploader).
 *
 * LocalFileStorageHelper:
 * LocalFileStoragehelper is a text file based local storage. And also, a developer can store 
 * a sensor data with a NSDictionary Object using -(bool)saveData:(NSDictionary *)data;.
 * [WIP] Now I'm making a CoreData based storage for more stable data management.
 *
 * AWAREDataUploader:
 * This class supports data upload in the background/foreground. You can upload data by using -(void)syncAwareDB; 
 * or -(BOOL)syncAwareDBInForeground;. AWAREDataUploader obtains uploading sensor data from LocalFileStorageHelper
 * by -(NSMutableString *)getSensorDataForPost;
 *
 */


#import "AWARESensor.h"
#import "AWAREKeys.h"
#import "AWAREStudy.h"
#import "AWARECoreDataManager.h"
#import "AWAREDataUploader.h"
#import "AWAREUploader.h"
#import "AWAREDebugMessageLogger.h"
#import "AWAREDelegate.h"

#import "SCNetworkReachability.h"
#import "LocalFileStorageHelper.h"

double const MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND = 0.2f;
int const MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND = 30;

@interface AWARESensor () {
    /** aware sensor name */
    NSString * awareSensorName;
    /** entity name */
    NSString * dbEntityName;
    /** latest Sensor Value */
    NSString * latestSensorValue;
    /** buffer size */

    /** debug state */
    bool debug;
    /** network state */
    NSInteger networkState;
    
    /** debug sensor*/
    AWAREDebugMessageLogger * dmLogger;
    /** aware study*/
    AWAREStudy * awareStudy;

    
    AwareDBType awareDBType;
    
    /// Base Uploader
    AWAREUploader * baseDataUploader;

    ///////////// text file based database ////////////////
    /** aware local storage (text) */
    LocalFileStorageHelper * localStorage;
    /** sensor data uploader */
    // AWAREDataUploader *uploader;
    
    ////////////// CoroData //////////////////////////////
//     AWARECoreDataManager * coreDataManager;

    BOOL sensorStatus;
    
    BOOL dataStoringState;
    
    BOOL isTypeSensor;
    
    NSDictionary * latestData;
    
    NSMutableArray * defaultSettings;
    
    NSString * sensorStatusKey;
}

@end

@implementation AWARESensor


- (instancetype) initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType pluginName:(NSString *) pluginName {
    
    NSLog(@"Please overwrite this method");
    
    return [self initWithAwareStudy:study sensorName:pluginName dbEntityName:@"---" dbType:dbType];
}

- (instancetype) initWithAwareStudy:(AWAREStudy *)study
                         sensorName:(NSString *)name
                       dbEntityName:(NSString *)entity {
    return [self initWithAwareStudy:study sensorName:name dbEntityName:entity dbType:AwareDBTypeSQLite];
}

- (instancetype) initWithAwareStudy:(AWAREStudy *)study
                         sensorName:(NSString *)name
                       dbEntityName:(NSString *)entity
                             dbType:(AwareDBType)dbType{
    return [self initWithAwareStudy:study sensorName:name dbEntityName:entity dbType:dbType bufferSize:0];
}

- (instancetype) initWithAwareStudy:(AWAREStudy *)study
                         sensorName:(NSString *)name
                       dbEntityName:(NSString *)entity
                             dbType:(AwareDBType)dbType
                         bufferSize:(int)buffer{
    self = [super initWithAwareStudy:study sensorName:name dbEntityName:entity];
    //self = [super init];
    if (self != nil) {
        
        sensorStatus = NO;
        
        isTypeSensor = YES;
        
        defaultSettings = [[NSMutableArray alloc] init];
        
        // Get debug state
        if(study == nil){
            // If the study object is nil(null), the initializer gnerates a new AWAREStudy object.
            awareStudy = [[AWAREStudy alloc] initWithReachability:NO];
        }else{
            awareStudy = study;
        }
        debug = [awareStudy getDebugState];
        
        // Save sensorName instance to awareSensorName
        awareSensorName = name;
        
        sensorStatusKey = [NSString stringWithFormat:@"status_%@",name];
        
        // Set db entity name
        dbEntityName = entity;
        
        // Initialize the latest sensor value with an empty object (@"").
        latestSensorValue = @"";
        
        // init buffer size
        [super setBufferSize:buffer];
        
        // AWARE DB setting
        awareDBType = dbType;
        
        dataStoringState = YES;
        
        latestData = [[NSDictionary alloc] init];
        
        switch (dbType) {
            case AwareDBTypeSQLite:
                if([self isDebug]) { NSLog(@"[%@] Initialize an AWARESensor (Type=CoreData,EntityName=%@,BufferSize=%d)", name, entity, buffer); }
                break;
            case AwareDBTypeJSON:
                if ([self isDebug]) { NSLog(@"[%@] Initialize an AWARESensor (Type=TextFile,DBName=%@,BufferSize=%d)", name, name, buffer); }
                localStorage     = [[LocalFileStorageHelper alloc] initWithStorageName:name];
                baseDataUploader = [[AWAREDataUploader alloc] initWithLocalStorage:localStorage withAwareStudy:awareStudy];
                break;
            default:
                break;
        }
    }
    return self;
}

- (void)setCSVHeader:(NSArray *)headers{
    [super setCSVHeader:headers];
    if (localStorage != nil) {
        [localStorage setCSVHeader:headers];
    }
    [super setCSVHeader:headers];
}

/////////////////////////////////////////////////

/**
 * DEFAULT:
 *
 */
- (BOOL)clearTable{
    return NO;
}

/**
 * DEFAULT:
 *
 */
- (void)setParameters:(NSArray *)parameters{
    NSLog(@"[%@] Please overwrite -setParameters: method", [self getSensorName]);
}

/**
 * DEFAULT:
 *
 */
//-(BOOL)startSensorWithSettings:(NSArray *)settings{
//    return [self startSensor];
//}

- (BOOL) startSensor {
    sensorStatus = YES;
    return NO;
}

/**
 * DEFAULT:
 */
- (BOOL)stopSensor{
    sensorStatus = NO;
    return NO;
}

- (BOOL)quitSensor{
    return NO;
}

////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////

- (void)setSensorStatusKey:(NSString *)key{
    sensorStatusKey = key;
}

- (NSString *)getSensorStatusKey{
    return sensorStatusKey;
}


/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

- (void) setTypeAsPlugin{
    isTypeSensor = NO;
}

- (void) setTypeAsSensor{
    isTypeSensor = YES;
}

- (bool) isPlugin{
    if (isTypeSensor == YES) {
        return NO;
    }else{
        return YES;
    }
}

- (bool) isSensor{
    return isTypeSensor;
}

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

- (NSArray * )getDefaultSettings{
    return defaultSettings;
}


- (void) addDefaultSettingWithBool:(NSNumber *)boolValue
                               key:(NSString *)key
                              desc:(NSString *)desc{
    NSString * boolString = @"false";
    if ([boolValue isEqualToNumber:@1]) {
        boolString = @"true";
    }
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] initWithObjects:@[boolString,
                                                                                KEY_CEL_SETTING_TYPE_BOOL,
                                                                                key,
                                                                                desc]
                                                                      forKeys:@[KEY_CEL_SETTING_VALUE,
                                                                                KEY_CEL_SETTING_TYPE,
                                                                                KEY_CEL_TITLE,
                                                                                KEY_CEL_DESC]];
    [defaultSettings addObject:dict];
}

- (void) addDefaultSettingWithString:(NSString *)strValue
                                 key:(NSString *)key
                                desc:(NSString *)desc{
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] initWithObjects:@[strValue,
                                                                                KEY_CEL_SETTING_TYPE_STRING,
                                                                                key,
                                                                                desc]
                                                                      forKeys:@[KEY_CEL_SETTING_VALUE,
                                                                                KEY_CEL_SETTING_TYPE,
                                                                                KEY_CEL_TITLE,
                                                                                KEY_CEL_DESC]];
    [defaultSettings addObject:dict];
    
}

- (void) addDefaultSettingWithNumber:(NSNumber *)numberValue
                                 key:(NSString *)key
                                desc:(NSString *)desc{
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] initWithObjects:@[[numberValue stringValue],
                                                                                KEY_CEL_SETTING_TYPE_NUMBER,
                                                                                key,
                                                                                desc]
                                                                      forKeys:@[KEY_CEL_SETTING_VALUE,
                                                                                KEY_CEL_SETTING_TYPE,
                                                                                KEY_CEL_TITLE,
                                                                                KEY_CEL_DESC]];
    [defaultSettings addObject:dict];
}

/**
 * Set the latest sensor data
 *
 * @param   valueStr  NSString  The latest sensor value as a NSString value
 */

- (void) setLatestValue:(NSString *)valueStr{
    latestSensorValue = valueStr;
    [NSString stringWithFormat:@""];
}


/**
 * Set buffer size of sensor data
 * NOTE: If you use high sampling rate sensor (such as an accelerometer, gyroscope, and magnetic-field),
 * you shold use to set buffer value.
 * @param size (int) A buffer size
 */
- (void) setBufferSize:(int) size{
    if (localStorage != nil) {
        [localStorage setBufferSize:size];
    }
    if (baseDataUploader != nil){
        [baseDataUploader setBufferSize:size];
    }
    [super setBufferSize:size];
}


- (void)setFetchLimit:(int)limit{
    if(baseDataUploader!=nil)[baseDataUploader setFetchLimit:limit];
    [super setFetchLimit:limit];
}

- (void)setFetchBatchSize:(int)size{
    if(baseDataUploader!=nil)[baseDataUploader setFetchBatchSize:size];
    [super setFetchBatchSize:size];
}


- (int) getBufferSize{
    if(baseDataUploader != nil){
        return [baseDataUploader getBufferSize];
    }
    return [super getBufferSize];
}

- (int) getFetchLimit{
    if(baseDataUploader != nil){
        return [baseDataUploader getFetchLimit];
    }else{
        return [super getFetchLimit];
    }
}

- (int) getFetchBatchSize{
    if(baseDataUploader != nil){
        return [baseDataUploader getFetchBatchSize];
    }else{
        return [super getFetchBatchSize];
    }
}

- (void) resetMarkerPosition{
    if(localStorage != nil){
        [localStorage resetMark];
    }
}

- (int) getMarkerPosition{
    if(localStorage != nil){
        return [localStorage getMarker];
    }
    return 0;
}

//////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

/**
 * Get the latest sensor value as a NSString
 *
 * @return The latest sensor data as a NSString
 */
- (NSString *)getLatestValue{
    return latestSensorValue;
}

/**
 * Get a device_id
 * @return A device_id
 */
- (NSString *) getDeviceId {
    return [awareStudy getDeviceId];
}

/**
 * Get a sensor name of this sensor
 * @return A sensor name of this AWARESensor
 */
- (NSString *) getSensorName{
    return awareSensorName;
}

- (NSString *)getEntityName{
    return dbEntityName;
}


- (NSInteger) getDBType{
    return awareDBType;
}


- (void) setLatestData:(NSDictionary *)dict{
    if(dict != nil){
        latestData = dict;
    }
}

- (NSDictionary *) getLatestData{
    if (latestData != nil) {
        return latestData;
    }else{
        return [[NSDictionary alloc] init];
    }
}

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

- (void) changedBatteryState{
    
}

- (void) calledBackgroundFetch{
    
}


//////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

- (void) createTable {
    
}

/**
 * Send a query for creating a table of this sensor on an AWARE Server (MySQL).
 * @param   NSString    A query for creating a database table
 */
- (void) createTable:(NSString *) query {
    if(baseDataUploader != nil){
        [baseDataUploader createTable:query];
    }else{
        [super createTable:query];
    }
}

/**
 * Send a query for creating a table of this sensor on an AWARE Server (MySQL) with a sensor name.
 * @param   NSString    A query for creating a database table
 */
- (void) createTable:(NSString *)query withTableName:(NSString *)tableName{
    if(baseDataUploader != nil){
        [baseDataUploader createTable:query withTableName:tableName];
    }else{
        [super createTable:query withTableName:tableName];
    }
}



//////////////////////////////////////////
////////////////////////////////////////

//// save data
- (bool) saveDataWithArray:(NSArray*) array {
    if(dataStoringState){
        if(localStorage != nil){
            return [localStorage saveDataWithArray:array];
        }else{
            return [super saveDataWithArray:array];
        }
    }
    return NO;
}

// save data
- (bool) saveData:(NSDictionary *)data{
    if(dataStoringState){
        if(localStorage != nil){
            return [localStorage saveData:data];
        }else{
            return [super saveData:data];
        }
    }
    return NO;
}


// save data with local file
- (bool) saveData:(NSDictionary *)data toLocalFile:(NSString *)fileName{
    if(dataStoringState){
        if(localStorage != nil){
            return [localStorage saveData:data toLocalFile:fileName];
        }else{
            NSLog(@"[%@] Please use -saveData: method", awareSensorName);
            return [super saveData:data];
        }
    }
    return NO;
}

- (bool) saveDataToDB {
    if(dataStoringState){
        if(baseDataUploader != nil){
            return [baseDataUploader saveDataToDB];
        }else{
            return [super saveDataToDB];
        }
    }
    return NO;
}

- (void) saveDummyData {
    NSLog(@"*** Please overwrite -saveDummyData method. ***");
}

/////////////////////////////
////////////////////////////

- (void) setDataStoring:(BOOL)state{
    dataStoringState = state;
}

- (void) startDataStoring{
    dataStoringState = YES;
}

- (void) stopDataStoring{
    dataStoringState = NO;
}

- (bool) isDataStoring{
    return dataStoringState;
}



//////////////////////////////////////////
////////////////////////////////////////s

- (void) syncAwareDB {
    if(baseDataUploader != nil){
        [baseDataUploader syncAwareDBInBackground];
    }else{
        [super syncAwareDBInBackground];
    }
}

- (void) syncAwareDBWithSensorName:(NSString *)name{
    if(baseDataUploader != nil){
        return [baseDataUploader syncAwareDBInBackgroundWithSensorName:name];
    }else{
        return [super syncAwareDBInBackgroundWithSensorName:name];
    }
}


- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary{
    if(baseDataUploader != nil){
        return [baseDataUploader syncAwareDBWithData:dictionary];
    }else{
        return [super syncAwareDBWithData:dictionary];
    }
    // return NO;
}

////////////////////////////////////////
///////////////////////////////////////

- (NSData *) getCSVData {
    if(baseDataUploader != nil){
        return [baseDataUploader getCSVData];
    }else{
        return nil;//[super syncAwareDBWithData:dictionary];
    }
}

//////////////////////////////////////////
////////////////////////////////////////
/**
 * Fourground sync method
 */
- (BOOL) syncAwareDBInForeground{
    if(baseDataUploader != nil){
        return [baseDataUploader syncAwareDBInForeground];
    }else{
        return [super syncAwareDBInForeground];
    }
}

- (void) lockDB{
    
    if(baseDataUploader != nil){
        [baseDataUploader lockDB];
    }else{
        [super lockDB];
    }
}

- (void) unlockDB{
    if(baseDataUploader != nil){
        [baseDataUploader unlockDB];
    }else{
        [super unlockDB];
    }
}

- (BOOL) isDBLock {
    if(baseDataUploader != nil){
        return [baseDataUploader isDBLock];
    }else{
        return [super isDBLock];
    }
}

/////////////////////////////////////////////
/////////////////////////////////////////////
/**
 * Sync options
 */
- (void)allowsCellularAccess{
    if(baseDataUploader != nil){
        [baseDataUploader allowsCellularAccess];
    }else{
        [super allowsCellularAccess];
    }
}

- (void)forbidCellularAccess{
    if(baseDataUploader != nil){
        [baseDataUploader forbidCellularAccess];
    }else{
        [super forbidCellularAccess];
    }
}

- (void) allowsDateUploadWithoutBatteryCharging{
    if(baseDataUploader != nil){
        [baseDataUploader allowsDateUploadWithoutBatteryCharging];
    }else{
        [super allowsDateUploadWithoutBatteryCharging];
    }
}


- (void) forbidDatauploadWithoutBatteryCharging{
    if(baseDataUploader != nil){
        [baseDataUploader forbidDatauploadWithoutBatteryCharging];
    }else{
        [super forbidDatauploadWithoutBatteryCharging];
    }
}


//////////////////////////////////////////
////////////////////////////////////////

- (NSString *)getSyncProgressAsText{
    if(baseDataUploader != nil){
        return [baseDataUploader getSyncProgressAsText];
    }else{
        return [super getSyncProgressAsText];
    }
}

- (NSString *) getSyncProgressAsText:(NSString *)sensorName{
    if(baseDataUploader != nil){
        return [baseDataUploader getSyncProgressAsText:sensorName];
    }else{
        return [super getSyncProgressAsText:sensorName];
    }
}

- (NSString *) getNetworkReachabilityAsText{
    if(baseDataUploader != nil){
        return [baseDataUploader getNetworkReachabilityAsText];
    }else{
        return [super getNetworkReachabilityAsText];
    }
}

- (bool)isUploading{
    
    if(baseDataUploader != nil){
        return [baseDataUploader isUploading];
    }else{
        // NSLog(@"%d %@", [super isUploading], awareSensorName);
        return [super isUploading];
    }
}


//////////////////////////////////////////
/////////////////////////////////////////

/**
 * A wrapper method for saving debug message
 */

- (bool)saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *)label{
    if (dmLogger != nil) {
        [dmLogger saveDebugEventWithText:eventText type:type label:label];
        return  YES;
    }
    return NO;
}


///////////////////////////////////
///////////////////////////////////

/// Utils

/**
 * Get a sensor setting(such as a sensing frequency) from settings with Key
 *
 * @param NSArray   Settings
 * @param NSString  A key for the target setting
 * @return A double value of the setting.
 */
- (double)getSensorSetting:(NSArray *)settings withKey:(NSString *)key{
    if (settings != nil) {
        for (NSDictionary * setting in settings) {
            if ([[setting objectForKey:@"setting"] isEqualToString:key]) {
                double value = [[setting objectForKey:@"value"] doubleValue];
                return value;
            }
        }
    }
    return -1;
}



- (NSString *)getSettingAsStringFromSttings:(NSArray *)settings withKey:(NSString *)key{
    if (settings != nil) {
        for (NSDictionary * setting in settings) {
            if ([[setting objectForKey:@"setting"] isEqualToString:key]) {
                NSString * value = [setting objectForKey:@"value"];
                return value;
            }
        }
    }
    return @"";
}


/**
 * Convert an iOS motion sensor frequency from an Androind frequency.
 *
 * @param   double  A sensing frequency for Andrind (frequency microsecond)
 * @return  double  A sensing frequency for iOS (second)
 */
- (double) convertMotionSensorFrequecyFromAndroid:(double)intervalMicroSecond{
    //  Android: Non-deterministic frequency in microseconds
    // (dependent of the hardware sensor capabilities and resources),
    // e.g., 200000 (normal), 60000 (UI), 20000 (game), 0 (fastest).
    double intervalSecond = intervalMicroSecond/(double)1000000;
    NSLog(@"Sensing Interval: %f (second)",intervalSecond);
    NSLog(@"Hz: %f (Hz)", (double)1/intervalSecond);
    return intervalSecond;
}


///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

/// For debug
/**
 Local push notification method
 @param message text message for notification
 @param sound type of sound for notification
 */
- (void)sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag {
    [AWAREUtils sendLocalNotificationForMessage:message soundFlag:soundFlag];
}


/**
 * Start a debug event tracker
 */
- (void) trackDebugEvents {
    if(awareStudy != nil){
        dmLogger = [[AWAREDebugMessageLogger alloc] initWithAwareStudy:awareStudy];
        [localStorage trackDebugEventsWithDMLogger:dmLogger];
    }else{
        NSLog(@"AWAREStudy variable is nil");
    }
//    debugSensor = [[Debug alloc] initWithAwareStudy:awareStudy];
//    [localStorage trackDebugEventsWithDebugSensor:debugSensor];
//    [baseDataUploader trackDebugEventsWithDebugSensor:debugSensor];
}

/**
 * Get a debug sensor state
 */
- (bool) isDebug{
    return debug;
}

- (void) setDebugState:(bool)state{
    debug = state;
}

- (NSString *) getWebserviceUrl{
    if(baseDataUploader != nil){
        return [baseDataUploader getWebserviceUrl];
    }else{
        return [super getWebserviceUrl];
    }
}

- (NSString *) getInsertUrl:(NSString *)sensorName{
    if(baseDataUploader != nil){
        return [baseDataUploader getInsertUrl:sensorName];
    }else{
        return [super getInsertUrl:sensorName];
    }
}

- (NSString *) getLatestDataUrl:(NSString *)sensorName{
    if(baseDataUploader != nil){
        return [baseDataUploader getLatestDataUrl:sensorName];
    }else{
        return [super getLatestDataUrl:sensorName];
    }
}

- (NSString *) getCreateTableUrl:(NSString *)sensorName{
    if(baseDataUploader != nil){
        return [baseDataUploader getCreateTableUrl:sensorName];
    }else{
        return [super getCreateTableUrl:sensorName];
    }
}

- (NSString *) getClearTableUrl:(NSString *)sensorName{
    if(baseDataUploader != nil){
        return [baseDataUploader getCreateTableUrl:sensorName];
    }else{
        return [super getClearTableUrl:sensorName];
    }
}

- (NSManagedObjectContext *)getSensorManagedObjectContext{
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    return delegate.managedObjectContext;
}

@end
