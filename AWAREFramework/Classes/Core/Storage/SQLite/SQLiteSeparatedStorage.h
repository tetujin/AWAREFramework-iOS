//
//  IndexedSQLiteStorage.h
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/12/05.
//

#import "AWAREStorage.h"
#import "BaseCoreDataHandler.h"
#import "AWAREFetchSizeAdjuster.h"

NS_ASSUME_NONNULL_BEGIN

@interface SQLiteSeparatedStorage : AWAREStorage <AWAREStorageDelegate>

@property NSManagedObjectContext * _Nonnull mainQueueManagedObjectContext;
// @property NSManagedObjectContext * _Nullable writeQueueManagedObjectContext;

//typedef void (^InsertCallBack)(NSDictionary <NSString *, id> * _Nonnull dataDict,
//                                     NSManagedObjectContext * _Nonnull childContext,
//                                     NSString * _Nonnull entity );
@property AWAREFetchSizeAdjuster * fetchSizeAdjuster;
@property bool useCompactDataSyncFormat;

- (instancetype _Nonnull )initWithStudy:(AWAREStudy * _Nullable) study
                             sensorName:(NSString * _Nonnull) name
                        objectModelName:(NSString * _Nonnull) objectModelName
                          syncModelName:(NSString * _Nonnull) syncModelName
                              dbHandler:(BaseCoreDataHandler * _Nonnull) dbHandler;

@end

NS_ASSUME_NONNULL_END
