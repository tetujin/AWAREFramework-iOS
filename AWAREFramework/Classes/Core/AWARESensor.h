//
//  AWARESensorViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <Foundation/Foundation.h>
#import "AWAREUtils.h"
#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "AWARECoreDataManager.h"
#import "TCQMaker.h"


typedef enum: NSInteger {
    AwareSettingTypeBool   = 0,
    AwareSettingTypeString = 1,
    AwareSettingTypeNumber = 2
} AwareSettingType;

extern double const MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND;
extern int    const MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND;

@protocol AWARESensorDelegate <NSObject>

- (void) setParameters:(NSArray *)parameters;
// - (BOOL) startSensorWithSettings:(NSArray *)settings;
- (BOOL) startSensor;
- (BOOL) stopSensor;
- (BOOL) quitSensor;
- (void) syncAwareDB;
- (void) createTable;
- (void) changedBatteryState;
- (void) calledBackgroundFetch;
- (void) saveDummyData;

- (NSString *) getSensorName;
- (NSString *) getEntityName;
- (NSInteger) getDBType;

@end


@interface AWARESensor : AWARECoreDataManager <AWARESensorDelegate, UIAlertViewDelegate>

// - (instancetype) initWithAwareStudy:(AWAREStudy *) study;
- (instancetype) initWithAwareStudy:(AWAREStudy *) study dbType:(AwareDBType)dbType;
- (instancetype) initWithAwareStudy:(AWAREStudy *) study sensorName:(NSString *)name dbEntityName:(NSString *)entity;
- (instancetype) initWithAwareStudy:(AWAREStudy *) study sensorName:(NSString *)name dbEntityName:(NSString *)entity dbType:(AwareDBType)dbType;
- (instancetype) initWithAwareStudy:(AWAREStudy *) study sensorName:(NSString *)name dbEntityName:(NSString *)entity dbType:(AwareDBType)dbType bufferSize:(int)buffer;

- (NSArray *) getDefaultSettings;

- (void) addDefaultSettingWithBool:(NSNumber *)boolValue   key:(NSString *)key desc:(NSString *)desc;
- (void) addDefaultSettingWithString:(NSString *)strValue key:(NSString *)key desc:(NSString *)desc;
- (void) addDefaultSettingWithNumber:(NSNumber *)numberValue key:(NSString *)key desc:(NSString *)desc;

- (void) setParameters:(NSArray *) parameters;

// set & get settings
//- (void) setDefaultSettingWithString:(NSString *) value key:(NSString *) key;
//- (void) setDefaultSettingWithNumber:(NSNumber *) value key:(NSString *) key;
//- (void) setDefaultSettings:(NSDictionary *) dict;
//- (NSDictionary *) getDefaultSettings;
//- (NSString *) getKeyForDefaultSettings;

- (void) setSensorStatusKey:(NSString *)key;
- (NSString *) getSensorStatusKey;

- (void) setTypeAsPlugin;
- (void) setTypeAsSensor;
- (bool) isPlugin;
- (bool) isSensor;

//+ (NSString *) sensorTitle;
//+ (NSString *) sensorDescription;
//+ (NSString *) sensorKey;
//+ (NSString *) sensorIconName;
//+ (NSString *) sensorDeveloper;
//+ (NSString *) sensorDeveloperURL;

// save debug events
- (void) trackDebugEvents;
- (bool) saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *)label;

// get condition
- (NSString *) getNetworkReachabilityAsText;

- (void) setLatestValue:(NSString *) valueStr;
- (NSString *) getLatestValue;

- (void) setLatestData:(NSDictionary *)dict;
- (NSDictionary *) getLatestData;

- (NSString *) getDeviceId;
- (double) getSensorSetting:(NSArray *)settings withKey:(NSString *)key;
- (NSString *)getSettingAsStringFromSttings:(NSArray *)settings withKey:(NSString *)key;
- (bool) isUploading;

// create table
- (void) createTable:(NSString *)query withTableName:(NSString*) tableName;
- (void) createTable:(NSString *)query;

// clear table
- (BOOL) clearTable;

// store data
- (void) setBufferSize:(int)size;
- (void) setFetchLimit:(int)limit;
- (void) setFetchBatchSize:(int)size;

- (int) getFetchLimit;
- (int) getFetchBatchSize;
- (int) getBufferSize;

- (void) resetMarkerPosition;
- (int)  getMarkerPosition;

- (void) setDataStoring:(BOOL)state;
- (void) startDataStoring;
- (void) stopDataStoring;
- (bool) isDataStoring;

- (bool) isDebug;
- (void) setDebugState:(bool)state;
- (bool) saveData:(NSDictionary *) data;
- (bool) saveData:(NSDictionary *) data toLocalFile:(NSString*) fileName;
- (bool) saveDataWithArray:(NSArray*) array;
- (bool) saveDataToDB;

- (void) saveDummyData;

// sync data
- (void) syncAwareDB;
- (void) syncAwareDBWithSensorName:(NSString *)name;
- (BOOL) syncAwareDBInForeground;
- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary;

// sync options
- (void) allowsCellularAccess;
- (void) forbidCellularAccess;
- (void) allowsDateUploadWithoutBatteryCharging;
- (void) forbidDatauploadWithoutBatteryCharging;

- (NSData *) getCSVData;

// show progress of uploading
- (NSString *) getSyncProgressAsText;
- (NSString *) getSyncProgressAsText:(NSString*) sensorName;

// lock
- (void) lockDB;
- (void) unlockDB;
- (BOOL) isDBLock;

// Utils
- (double) convertMotionSensorFrequecyFromAndroid:(double)intervalMicroSecond;
- (void) sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag;


// url
- (NSString *) getWebserviceUrl;
- (NSString *) getInsertUrl:(NSString *)sensorName;
- (NSString *) getLatestDataUrl:(NSString *)sensorName;
- (NSString *) getCreateTableUrl:(NSString *)sensorName;
- (NSString *) getClearTableUrl:(NSString *)sensorName;

- (NSManagedObjectContext *) getSensorManagedObjectContext;

- (BOOL) getStatus;

@end
