//
//  AWAREUploader.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocalFileStorageHelper.h"
#import "AWAREStudy.h"

@protocol AWAREDataUploaderDelegate <NSObject>

- (instancetype) initWithAwareStudy:(AWAREStudy *) study sensorName:(NSString*)name;

- (bool) isUploading;
- (void) setUploadingState:(bool)state;
//- (void) lockBackgroundUpload;
//- (void) unlockBackgroundUpload;

- (void) lockDB;
- (void) unlockDB;
- (BOOL) isDBLock;

- (void) setCSVHeader:(NSArray *) headers;
- (NSArray *) getCSVHeader;

- (void) allowsCellularAccess;
- (void) forbidCellularAccess;
- (void) allowsDateUploadWithoutBatteryCharging;
- (void) forbidDatauploadWithoutBatteryCharging;


- (bool) isDebug;
- (bool) isSyncWithOnlyWifi;
- (bool) isSyncWithOnlyBatteryCharging;


// CoreData
- (void) setBufferSize:(int)size;
- (void) setFetchLimit:(int)limit;
- (void) setFetchBatchSize:(int)size;
- (int)  getBufferSize;
- (int)  getFetchLimit;
- (int)  getFetchBatchSize;
- (bool) saveDataToDB;//TODO

- (void) syncAwareDBInBackground;
- (void) syncAwareDBInBackgroundWithSensorName:(NSString*) name;
//- (void) postSensorDataWithSensorName:(NSString*) name session:(NSURLSession *)oursession;
- (void) postSensorDataWithSensorName:(NSString*)name;
- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary;


- (BOOL) syncAwareDBInForeground;
- (BOOL) syncAwareDBInForegroundWithSensorName:(NSString*) name;


- (void) createTable:(NSString*) query;
- (void) createTable:(NSString *)query withTableName:(NSString*) tableName;
- (BOOL) clearTable;

- (NSData *) getLatestData;

- (NSString *) getNetworkReachabilityAsText;
- (NSString *) getSyncProgressAsText;
- (NSString *) getSyncProgressAsText:(NSString *)sensorName;


- (BOOL) trackDebugEvents;
- (bool) saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *)label;


- (NSString *) getWebserviceUrl;
- (NSString *) getInsertUrl:(NSString *)sensorName;
- (NSString *) getLatestDataUrl:(NSString *)sensorName;
- (NSString *) getCreateTableUrl:(NSString *)sensorName;
- (NSString *) getClearTableUrl:(NSString *)sensorName;

- (void) broadcastDBSyncEventWithProgress:(NSNumber *)progress
                                 isFinish:(BOOL)finish
                                isSuccess:(BOOL)success
                               sensorName:(NSString *)name;

- (NSData *) getCSVData;

- (void) cancelSyncProcess;
- (void) resetMark;

@end

@interface AWAREUploader : NSData <AWAREDataUploaderDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property NSManagedObjectContext *mainQueueManagedObjectContext;
@property NSManagedObjectContext *writeQueueManagedObjectContext;

@end
