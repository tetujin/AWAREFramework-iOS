//
//  AWAREStudy.h
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

// int frequencyCleanOldData; // (0 = never, 1 = weekly, 2 = monthly, 3 = daily, 4 = always)

typedef enum: NSInteger {
    cleanOldDataTypeNever   = 0,
    cleanOldDataTypeWeekly  = 1,
    cleanOldDataTypeMonthly = 2,
    cleanOldDataTypeDaily   = 3,
    cleanOldDataTypeAlways  = 4
} cleanOldDataType;


typedef enum: NSInteger {
    AwareDBTypeUnknown = 0,
    AwareDBTypeJSON    = 1,   // JSON
    AwareDBTypeSQLite  = 2,   // SQLite
    AwareDBTypeCSV     = 3    // CSV
} AwareDBType;

typedef enum: NSInteger{
    AwareUIModeNormal       = 0,
    AwareUIModeHideAll      = 1,
    AwareUIModeHideSettings = 2,
    AwareUIModeHideSensors  = 3,
} AwareUIMode;

typedef enum: NSInteger{
    AwareStudyStateNoChange   = 0,
    AwareStudyStateNew        = 1,
    AwareStudyStateUpdate     = 2,
    AwareStudyStateDataFormatError        = 3,
    AwareStudyStateNetworkConnectionError = 4,
} AwareStudyState;

@interface AWAREStudy : NSObject <NSURLSessionDataDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate>

NS_ASSUME_NONNULL_BEGIN

typedef void (^JoinStudyCompletionHandler)(NSArray * config, AwareStudyState state, NSError * _Nullable  error);
typedef void (^FetchStudyConfigurationCompletionHandler)(NSArray * config, NSError * _Nullable  error);

@property (strong, nonatomic) NSString* getSettingIdentifier;
@property (strong, nonatomic) NSString* makeDeviceTableIdentifier;
@property (strong, nonatomic) NSString* addDeviceTableIdentifier;

+ (AWAREStudy * _Nonnull)sharedStudy;

- (instancetype) initWithReachability: (BOOL) reachabilityState;

- (void) setStudyURL:(NSString *)url;
- (NSString * _Nullable) getStudyURL;
- (NSString * ) getDeviceId;

- (bool) isNetworkReachable;
- (bool) isWifiReachable;
- (NSString *) getNetworkReachabilityAsText;

- (bool) isStudy;

////////////////////////////////////
- (void) setDebug:(bool)state;
- (void) setAutoDBSyncOnlyWifi:(bool)state;
- (void) setAutoDBSyncOnlyBatterChargning:(bool)state;
- (void) setAutoDBSyncIntervalWithMinutue:(int)minutue;
- (void) setAutoDBSync:(bool) state;
- (void) setMaximumByteSizeForDBSync:(NSInteger)size;  // for Text File
- (void) setMaximumNumberOfRecordsForDBSync:(NSInteger)number;  // for SQLite DB
- (void) setDBType:(AwareDBType)type;
- (void) setCleanOldDataType:(cleanOldDataType)type;
- (void) setUIMode:(AwareUIMode) mode;
- (void) setCPUTheshold:(int)threshold;

/////////////////////////////////////
- (bool) isDebug;
- (bool) isAutoDBSyncOnlyWifi;
- (bool) isAutoDBSyncOnlyBatterChargning;
- (int)  getAutoDBSyncIntervalSecond; // second
- (NSInteger) getMaximumByteSizeForDBSync;  // for Text File
- (NSInteger) getMaximumNumberOfRecordsForDBSync;
- (AwareDBType) getDBType;
- (cleanOldDataType) getCleanOldDataType;
- (AwareUIMode) getUIMode;
- (int)  getCPUTheshold;
- (BOOL) isAutoDBSync;

/// [Remote Server Based Settings]
- (void) fetchStudyConfiguration:(NSString * _Nonnull)url completion:(FetchStudyConfigurationCompletionHandler _Nullable) completionHandler;
- (NSArray *) getStudyConfiguration;
- (void) joinStudyWithURL:(NSString* _Nonnull)url completion:(JoinStudyCompletionHandler _Nullable) completionHandler;
- (void) refreshStudySettings;
- (BOOL) clearStudySettings;

- (NSString *) getStudyConfigurationAsText;

- (void) setDeviceName:(NSString *) deviceName;
- (NSString * _Nonnull) getDeviceName;

- (void) setSetting:(NSString * _Nonnull)key value:(NSObject * _Nonnull)value;
- (void) setSetting:(NSString * _Nonnull)key value:(NSObject * _Nonnull)value packageName:(NSString * _Nullable) packageName;

- (NSString *) getSetting:(NSString * )key;

- (NSArray *) getSensorSettings;

NS_ASSUME_NONNULL_END

@end
