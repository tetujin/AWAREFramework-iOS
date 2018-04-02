//
//  AWAREStorage.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import <Foundation/Foundation.h>
#import "TCQMaker.h"
#import "AWAREStudy.h"
/**
 * This delegate should be implemented by storages such as SQLite, JSON, and CSV.
 */
@protocol AWAREStorageDelegate <NSObject>

typedef void (^SyncProcessCallBack)(NSString *name, double progress, NSError * _Nullable  error);

//////////////////// General //////////////////////

@property (atomic) NSMutableArray * _Nonnull buffer;
@property AWAREStudy * _Nullable awareStudy;
@property NSString * _Nullable sensorName;
@property int retryLimit;
@property double syncTaskIntervalSecond;
@property SyncProcessCallBack syncProcessCallBack;

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

- (BOOL)createLocalStorageWithName:(NSString*) fileName type:(NSString *) type;
- (BOOL)removeLocalStorageWithName:(NSString*) fileName type:(NSString *)type;
- (NSString *) getFilePathWithName:(NSString *) fileName type:(NSString *)type;
- (BOOL) appendLine:(NSString *) line withFilePath:(NSString *)path;
- (bool) clearLocalStorageWithName:(NSString*) fileName type:(NSString *)type;
- (NSNumber * _Nullable)getFileSizeWithName:(NSString *)fileName type:(NSString *)type;
///////////////////// Initializing Server DB //////////////////////////////

- (void) createDBTableOnServerWithTCQMaker:(TCQMaker *_Nonnull)tcqMaker;
- (void) createDBTableOnServerWithQuery:(NSString *_Nonnull)query;
- (void) createDBTableOnServerWithQuery:(NSString *_Nonnull)query tableName:(NSString *_Nonnull) table;

///////////////////// Syncing ////////////////////////////////

- (void) startSyncStorage;
- (void) startSyncStorageWithCallBack:(SyncProcessCallBack)callback;
- (void) cancelSyncStorage;

@end

//////////////////////////////////////

@interface AWAREStorage : NSObject <AWAREStorageDelegate>

@end
