//
//  IndexedSQLiteStorage.h
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/12/05.
//

#import "AWAREStorage.h"
#import "BaseCoreDataHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface SQLiteIndexedStorage : AWAREStorage <AWAREStorageDelegate>

@property NSManagedObjectContext * _Nonnull mainQueueManagedObjectContext;
// @property NSManagedObjectContext * _Nullable writeQueueManagedObjectContext;

//typedef void (^InsertCallBack)(NSDictionary <NSString *, id> * _Nonnull dataDict,
//                                     NSManagedObjectContext * _Nonnull childContext,
//                                     NSString * _Nonnull entity );

- (instancetype _Nonnull )initWithStudy:(AWAREStudy * _Nullable) study
                             sensorName:(NSString * _Nonnull) name
                        objectModelName:(NSString * _Nonnull) objectModelName
                         indexModelName:(NSString * _Nonnull) indexModelName
                              dbHandler:(BaseCoreDataHandler * _Nonnull) dbHandler;

@end

NS_ASSUME_NONNULL_END
