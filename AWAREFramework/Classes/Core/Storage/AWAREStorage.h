//
//  AWAREStorage.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import <Foundation/Foundation.h>
#import "TCQMaker.h"
#import "AWAREStudy.h"
#import "DBTableCreator.h"

/**
 * This delegate should be implemented by storages such as SQLite, JSON, and CSV.
 */
typedef NS_ENUM(NSUInteger, AwareStorageSyncProgress) {
    AwareStorageSyncProgressUnknown   = 0,
    AwareStorageSyncProgressContinue  = 1,
    AwareStorageSyncProgressComplete  = 2,
    AwareStorageSyncProgressUploading = 3,
    AwareStorageSyncProgressLocked    = 4,
    AwareStorageSyncProgressError     = 5,
};


@protocol AWAREStorageDelegate <NSObject>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SyncProcessCallBack)(NSString * _Nonnull name, AwareStorageSyncProgress state, double progress, NSError * _Nullable  error);
typedef void (^FetchDataHandler)(NSString * _Nonnull name, NSArray * results, NSDate * start, NSDate * end, NSError * _Nullable error);
typedef void (^LimitedDataFetchHandler)(NSString * _Nonnull name, NSArray * _Nullable results, NSDate * _Nonnull from, NSDate * _Nonnull to, BOOL isEnd, NSError * _Nullable error);

//////////////////// General //////////////////////

@property (atomic) NSMutableArray * _Nonnull buffer;
@property AWAREStudy * _Nullable awareStudy;
@property NSString * _Nullable sensorName;
@property int retryLimit;
@property double syncTaskIntervalSecond;
@property (nullable) SyncProcessCallBack syncProcessCallBack;
@property double saveInterval;
@property double lastSaveTimestamp;
@property (nullable) TableCreateCallBack tableCreatecallBack;

- (instancetype _Nullable ) initWithStudy:(AWAREStudy *_Nullable) study sensorName:(NSString*_Nullable)name;

- (bool) isSyncing;

- (bool) isDebug;
- (void) setDebug:(BOOL)status;

- (BOOL) isLock;
- (void) lock;
- (void) unlock;

- (void) resetMark;

- (BOOL) isStore;
- (void) setStore:(BOOL) state;

///////////////////// Storing///////////////////////////////

- (void) setBufferSize:(int)size;
- (int)  getBufferSize;

- (nullable NSDictionary *) getLatestData;

- (BOOL)saveDataWithArray:(NSArray *_Nullable)dataArray buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread;
- (BOOL)saveDataWithDictionary:(NSDictionary *_Nullable)dataDict buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread;

- (BOOL)saveBufferDataInMainThread:(BOOL)saveInMainThread;

- (BOOL)createLocalStorageWithName:(NSString*) fileName type:(NSString *) type;
- (BOOL)removeLocalStorageWithName:(NSString*) fileName type:(NSString *)type;
- (NSString *) getFilePathWithName:(NSString *) fileName type:(NSString *)type;
- (BOOL) appendLine:(NSString *) line withFilePath:(NSString *)path;
- (bool) clearLocalStorageWithName:(NSString*) fileName type:(NSString *)type;
- (NSNumber * _Nullable)getFileSizeWithName:(NSString *)fileName type:(NSString *)type;

///////////////////// create a remote DB table functions  //////////////////////////////
- (void) createDBTableOnServerWithTCQMaker:(TCQMaker *_Nonnull)tcqMaker;
- (void) createDBTableOnServerWithQuery:(NSString *_Nonnull)query;
- (void) createDBTableOnServerWithQuery:(NSString *_Nonnull)query tableName:(NSString *_Nonnull) table;
- (void) createDBTableOnServerWithQuery:(NSString *_Nonnull)query completion:(TableCreateCallBack _Nullable)completion;
- (void) createDBTableOnServerWithQuery:(NSString *_Nonnull)query tableName:(NSString *_Nonnull) table completion:(TableCreateCallBack _Nullable)completion;

///////////////////// sync a local-DB and remote-DB functions ////////////////////////////////
- (void) startSyncStorage;
- (void) startSyncStorageWithCallBack:(SyncProcessCallBack)callback;
- (void) cancelSyncStorage;

//////////////////// fetch data from the local-DB functions //////////////////
- (NSArray *) fetchTodaysData;
- (void) fetchTodaysDataWithHandler:(FetchDataHandler)handler;

- (NSArray *) fetchDataBetweenStart:(NSDate *)start andEnd:(NSDate *)end;
- (void) fetchDataBetweenStart:(NSDate *)start andEnd:(NSDate *)end withHandler:(FetchDataHandler)handler;

- (NSArray *) fetchDataFrom:(NSDate *)from to:(NSDate *)to;
- (void) fetchDataFrom:(NSDate *)from to:(NSDate *)to handler:(FetchDataHandler)handler;
- (void) fetchDataFrom:(NSDate *)from to:(NSDate *)to limit:(int)limit all:(bool)all handler:(LimitedDataFetchHandler)handler;
- (NSDate *) getToday;

NS_ASSUME_NONNULL_END

@end

//////////////////////////////////////

@interface AWAREStorage : NSObject <AWAREStorageDelegate>

@end
