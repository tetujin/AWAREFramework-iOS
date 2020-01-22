//
//  SQLiteStorage.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import <UIKit/UIKit.h>
#import "AWAREStorage.h"
#import "BaseCoreDataHandler.h"

@interface SQLiteStorage : AWAREStorage <AWAREStorageDelegate>

@property NSManagedObjectContext * _Nonnull mainQueueManagedObjectContext;
//@property NSManagedObjectContext *writeQueueManagedObjectContext;

typedef void (^InsertEntityCallBack)(NSDictionary * _Nonnull dataDict, NSManagedObjectContext * _Nonnull childContext , NSString* _Nonnull entity);

- (instancetype _Nonnull)initWithStudy:(AWAREStudy * _Nullable) study
                   sensorName:(NSString * _Nonnull) name
                   entityName:(NSString * _Nonnull) entity
               insertCallBack:(InsertEntityCallBack _Nullable)insertCallBack;

- (instancetype _Nonnull)initWithStudy:(AWAREStudy * _Nullable) study
                   sensorName:(NSString * _Nonnull) name
                   entityName:(NSString * _Nonnull) entity
                   dbHandler:(BaseCoreDataHandler * _Nonnull) dbHandler
               insertCallBack:(InsertEntityCallBack _Nullable)insertCallBack;
 
- (instancetype _Nonnull)initWithStudy:(AWAREStudy * _Nullable) study
                   sensorName:(NSString * _Nonnull) name
                   entityName:(NSString * _Nonnull) entity;

- (instancetype _Nonnull)initWithStudy:(AWAREStudy * _Nullable) study
                   sensorName:(NSString * _Nonnull) name
                   entityName:(NSString * _Nonnull) entity
                    dbHandler:(BaseCoreDataHandler * _Nonnull) dbHandler;

- (NSUInteger)countStoredDataWithError:(NSError * _Nullable) error;
- (NSUInteger)countUnsyncedDataWithError:(NSError * _Nullable) error;

- (BOOL) isExistUnsyncedDataWithError:(NSError * _Nullable) error;
- (void) setDBHandler:(BaseCoreDataHandler * _Nonnull)handler;

@end
