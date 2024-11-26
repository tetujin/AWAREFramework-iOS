//
//  IndexedSQLiteStorage.m
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/12/05.
//

#import "SQLiteSeparatedStorage.h"
#import "SyncExecutor.h"
#import "../Tools/QuickSyncExecutor.h"
#import "CoreDataHandler.h"
#import "AWAREUtils.h"
#import "../Tools/AWAREFetchSizeAdjuster.h"
@import CoreData;

@implementation SQLiteSeparatedStorage{
    NSString * objectName;
    NSString * syncName;
    NSString * baseSyncDataQueryIdentifier;
    NSString * timeMarkerIdentifier;
    BOOL isUploading;
    NSNumber * previousUploadingProcessFinishUnixtime; // unixtimeOfUploadingData;
    NSNumber * tempLastUnixTimestamp;
    int retryCurrentCount;
    int currentRepetitionCount;
    NSUInteger stagedRecords;
    BOOL isCanceled;
    BOOL isFetching;
    BaseCoreDataHandler * coreDataHandler;
    // SyncExecutor * executor;
    id<AWARESyncExecutorDelegate> executorDelegate;
}

@synthesize fetchSizeAdjuster;
@synthesize useCompactDataSyncFormat;

- (instancetype)initWithStudy:(AWAREStudy *)study sensorName:(NSString *)name{
    NSLog(@"[NOTE] Please use -initWithStudy:sensorName:objectModelName:indexModelName:dbHandler:");
    BaseCoreDataHandler * handler = [[BaseCoreDataHandler alloc] init];
    return [self initWithStudy:study sensorName:name
               objectModelName:@"" syncModelName:@"" dbHandler:handler];
}

- (instancetype)initWithStudy:(AWAREStudy *)study
                   sensorName:(NSString *)name
              objectModelName:(NSString *)objectModelName
               syncModelName:(NSString *)syncModelName
                    dbHandler:(BaseCoreDataHandler *)dbHandler{
    self = [super initWithStudy:study sensorName:name];
    if(self != nil){
        isUploading = NO;
        useCompactDataSyncFormat = NO;
        objectName  = objectModelName;
        syncName   = syncModelName;
        self.retryLimit   = 3;
        retryCurrentCount = 0;
        tempLastUnixTimestamp   = @0;
        timeMarkerIdentifier        = [NSString stringWithFormat:@"uploader_coredata_timestamp_marker_%@", name];
        baseSyncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@", name];

        self.mainQueueManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [self.mainQueueManagedObjectContext setPersistentStoreCoordinator:dbHandler.persistentStoreCoordinator];
        previousUploadingProcessFinishUnixtime = [self getTimeMark];
        if([previousUploadingProcessFinishUnixtime isEqualToNumber:@0]){
            [self setTimeMark:[NSDate new]];
        }
        coreDataHandler = dbHandler;
        fetchSizeAdjuster = [[AWAREFetchSizeAdjuster alloc] initWithSensorName:name];
        fetchSizeAdjuster.debug = study.isDebug;
        self.syncMode = AwareSyncModeBackground;
    }
    return self;
}

#pragma mark - Save Operations

- (BOOL)saveDataWithDictionary:(NSDictionary * _Nullable)dataDict buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread {
    [self saveDataWithArray:@[dataDict] buffer:isRequiredBuffer saveInMainThread:saveInMainThread];
    return YES;
}


- (BOOL)saveDataWithArray:(NSArray * _Nullable)dataArray buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread {

    if (!self.isStore) {
        return NO;
    }

    [self.buffer addObjectsFromArray:dataArray];
    
    if (self.saveInterval > 0 ) {
        // time based operation
        NSDate * now = [NSDate new];
        if (now.timeIntervalSince1970 < self.lastSaveTimestamp + self.saveInterval) {
            return YES;
        }else{
            if ([self isDebug]) { NSLog(@"[SQLiteStorage] %@: data is saved by time-base trigger", self.sensorName); }
            self.lastSaveTimestamp = now.timeIntervalSince1970;
        }
    }else{
        // buffer size based operation
        if (self.buffer.count < [self getBufferSize]) {
            return YES;
        }else{
            if ([self isDebug]) { NSLog(@"[SQLiteStorage] %@: data is saved by buffer limit-based trigger", self.sensorName); }
        }
    }

    return [self saveBufferDataInMainThread:saveInMainThread];
}

- (BOOL)saveBufferDataInMainThread:(BOOL)saveInMainThread{
    
    if (self.buffer.count == 0) {
        if (self.isDebug) NSLog(@"[%@] NO buffer data", self.sensorName);
        return YES;
    }
    
    /// generate a copied buffer
    NSArray * copiedArray = [self.buffer copy];
    [self.buffer removeAllObjects];
    
    /// get a parent context
    NSManagedObjectContext* parentContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [parentContext setPersistentStoreCoordinator:coreDataHandler.persistentStoreCoordinator];
    
    /// save data in the main-thread
    if (saveInMainThread) {
        /// stage data on context
        [self stageData:copiedArray to:self->objectName with:self->syncName on:parentContext];

        NSError *error = nil;
        if (![parentContext save:&error]) {
            NSLog(@"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
            [self.buffer addObjectsFromArray:copiedArray];
        }else{
            if(self.isDebug) NSLog(@"[SQLiteStorage] %@: data is saved in the main-thread", self.sensorName);
        }
        [self unlock];
    
    /// save data in the sub-thread
    }else{
        NSManagedObjectContext* childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [childContext setParentContext:parentContext];
        [childContext performBlock:^{

            [self stageData:copiedArray to:self->objectName with:self->syncName on:childContext];
            
            NSError *error = nil;
            if (![childContext save:&error]) {
                // An error is occued
                NSLog(@"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
                [self.buffer addObjectsFromArray:copiedArray];
                [self unlock];
            }else{
                // success to marge diff to the main context manager
                [parentContext performBlock:^{
                    if(![parentContext save:nil]){
                        NSLog(@"Error saving context");
                        [self.buffer addObjectsFromArray:copiedArray];
                    }
                    if(self.isDebug) NSLog(@"[SQLiteStorage] %@: data is saved in the sub-thread", self.sensorName);
                    [self unlock];
                }];
            }
        }];
    }
    return YES;
}


- (void) stageData:(NSArray  * _Nonnull)  data
                to:(NSString * _Nonnull) objectName
              with:(NSString * _Nonnull) syncName
                on:(NSManagedObjectContext * _Nonnull) context {
    NSManagedObject * indexObj = [NSEntityDescription insertNewObjectForEntityForName:syncName
                                                                       inManagedObjectContext:context];
    
    for (NSDictionary * d in data) {
        NSManagedObject * mo = [NSEntityDescription insertNewObjectForEntityForName:objectName
                                                             inManagedObjectContext:context];
        [mo setValuesForKeysWithDictionary:d];
    }
        
    [indexObj setValue:data forKey:@"batch_data"];
    [indexObj setValue:@(data.count) forKey:@"count"];
    [indexObj setValue:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
}

#pragma mark - Sync Functions

- (void)startSyncStorageWithCallBack:(SyncProcessCallback)callback{
    self.syncProcessCallback = callback;
    [self startSyncStorage];
}

- (void) startSyncStorage {
    
    if (objectName == nil || syncName == nil) {
        NSLog(@"***** [%@][%@] Error: Entity Name is nil! *****", self.sensorName, self);
        if (self.syncProcessCallback!=nil){
            self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressError, -1, nil);
        }
        return;
    }
    
    if(isUploading){
        NSLog(@"[%@][%@] NOTE: The storage is uploading data now.", self.sensorName, self);
        if (self.syncProcessCallback!=nil){
            self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressUploading, -1, nil);
        }
        return;
    }
    
    if (self.isDebug){
        NSLog(@"[SQLiteStorage:%@][%@] start sync process ", self.sensorName, self);
    }
    
    [self setUploadingState:YES];
    
    [self syncTask];
}

- (void) cancelSyncStorage {
    if (self.isDebug) NSLog(@"[%@][%@] cancel a sync-process",[self sensorName],self);
    if (executorDelegate != nil) {
        if (executorDelegate.dataTask != nil ) {
            [executorDelegate.dataTask cancel];
        }
        
        if (executorDelegate.session != nil){
            [executorDelegate.session invalidateAndCancel];
        }
        [self dataSyncIsFinishedCorrectly];
        isCanceled = YES;
    }
    
    if (isFetching) {
        isCanceled = YES;
    }
}

/**
 * Upload method
 */
- (void) syncTask {
    previousUploadingProcessFinishUnixtime = [self getTimeMark];
    isFetching = YES;
    @try {
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:self.mainQueueManagedObjectContext];
        [private performBlock:^{
            
            if (self.isDebug) NSLog(@"[%@][is_canceled] %@", self.sensorName, self->isCanceled?@"YES":@"NO");
            if (self->isCanceled) {
                [self dataSyncIsFinishedCorrectly];
                self->isFetching = NO;
                self->isCanceled = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.syncProcessCallback!=nil) self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressCancel, -1, nil);
                });
                return;
            }
            
            NSError * countingError = nil;
            if (self->stagedRecords == 0) {
                self->stagedRecords =  [self countStoredData:self->syncName
                                                        from:self->previousUploadingProcessFinishUnixtime
                                                     context:private
                                                  fetchLimit:0
                                                       error:countingError];
                self->currentRepetitionCount = 0;
                if (self.isDebug) NSLog(@"[%@][staged] %ld", self.sensorName, self->stagedRecords);
                if (self->stagedRecords == 0 || self->stagedRecords == NSNotFound) {
                    [self dataSyncIsFinishedCorrectly];
                   self->isFetching = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.syncProcessCallback!=nil) self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressComplete, 1, nil);
                    });
                    return;
                }
            }
            
            /// prepare a fetch request
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:self->syncName];
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp > %@", self->previousUploadingProcessFinishUnixtime]];
            [fetchRequest setFetchLimit:self->fetchSizeAdjuster.fetchSize];
            NSError * error = nil;
            NSDate  * s = [NSDate new];
            NSArray * indexes = [private executeFetchRequest:fetchRequest error:&error];
            if (self.isDebug) NSLog(@"[%@][%@] FETCH SPEED: (%ld) New SQLite ---> %f", self.sensorName, self, indexes.count, [[NSDate new] timeIntervalSinceDate:s] );
            if (self.isDebug) NSLog(@"[%@] FetchSize: %ld", self.sensorName, self->fetchSizeAdjuster.fetchSize );

            NSMutableArray * results = [@[] mutableCopy];
            if (indexes!=nil && indexes.count>0) {
                for (NSManagedObjectModel * mom in indexes) {
                    
                    NSArray *batchData = [mom valueForKey:@"batch_data"];
                    if (batchData != nil) {
                        // compact format
                        if (self.useCompactDataSyncFormat){
                            NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionary];
                            for (NSDictionary *item in batchData) {
                                for (NSString *key in item) {
                                    if (![key isEqual: @"device_id"]) {
                                        if (!resultDictionary[key]) {
                                            resultDictionary[key] = [NSMutableArray array];
                                        }
                                        [resultDictionary[key] addObject:item[key]];
                                    }
                                }
                            }
                            [results addObject:resultDictionary];
                        }else{
                        // normal format
                            [results addObjectsFromArray:batchData];
                        }
                    }
                    
                    NSNumber * timestamp = [mom valueForKey:@"timestamp"];
                    if (timestamp!=nil) self->tempLastUnixTimestamp = timestamp;
                }
            }

            if (results != nil) {
                /// Convert an array object to json
                NSError * error    = nil;
                NSData  * jsonData = nil;
                @try {
                    jsonData = [NSJSONSerialization dataWithJSONObject:results options:0 error:&error];
                } @catch (NSException *exception) {
                    NSLog(@"[%@][%@] %@", self.sensorName, self, exception.debugDescription);
                }
                
                if (error == nil && jsonData != nil) {
                    // Set HTTP/POST session on main thread
                    NSMutableData * mutablePostData = [[NSMutableData alloc] initWithData:jsonData];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        @try {
                            if (self.syncMode == AwareSyncModeQuick) {
                                self->executorDelegate = [[QuickSyncExecutor alloc] initWithAwareStudy:self.awareStudy sensorName:self.sensorName];
                            }else{
                                self->executorDelegate = [[SyncExecutor alloc] initWithAwareStudy:self.awareStudy sensorName:self.sensorName];
                            }
                            // NSLog(@"%d", NSThread.isMainThread);
                            self->isFetching = NO;
                            self->executorDelegate.debug = self.isDebug;
                            [self->executorDelegate syncWithData:mutablePostData callback:^(NSDictionary *result) {
                                if (result!=nil) {
                                    if (self.isDebug) NSLog(@"[%@][%@]%@", self.sensorName, self,  result.debugDescription);
                                    NSNumber * isSuccess = [result objectForKey:@"result"];
                                    NSString * response  = [result objectForKey:@"response"];
                                    if (isSuccess != nil && response != nil) {
                                        self->currentRepetitionCount++;
                                        double completionRate = (double)(self->currentRepetitionCount * self->fetchSizeAdjuster.fetchSize)/(double)self->stagedRecords;
                                        
                                        if (self.isDebug) {
                                            NSLog(@"[%@] sync progress: %f", self.sensorName, completionRate);
                                        }
                                        if((BOOL)isSuccess.intValue && [response isEqualToString:@""]){
                                            // "[{\"message\":\"I don't know who you are.\"}]"
                                            [self->fetchSizeAdjuster success];
                                            [self setTimeMarkWithTimestamp:self->tempLastUnixTimestamp];
                                            if (completionRate >= 1.0) {
                                                ///////////////// Done ////////////
                                                if (self.isDebug) NSLog(@"[%@] done", self.sensorName);
                                                if (self.syncProcessCallback!=nil) {
                                                    self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressComplete,completionRate, nil);
                                                }
                                                [self dataSyncIsFinishedCorrectly];
                                                if (self.isDebug) NSLog(@"[%@] clear old data", self.sensorName);
                                                [self deleteSyncedData];
                                                [self deleteOldDataIfNeeded];
                                                return;
                                            }else{
                                                ///////////////// continue ////////////
                                                if (self.syncProcessCallback!=nil) {
                                                    self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressContinue,completionRate, nil);
                                                }
                                                if (self.isDebug) NSLog(@"[%@][%@] execute next sync task (%f)", self.sensorName, self, completionRate);
                                                [self performSelector:@selector(syncTask) withObject:nil afterDelay:self.syncTaskIntervalSecond];
                                                [self deleteSyncedData];
                                                return;
                                            }
                                        }else{
                                            ///////////////// retry ////////////
                                            [self->fetchSizeAdjuster failure];
                                            
                                            if (self->retryCurrentCount < self.retryLimit) {
                                                self->retryCurrentCount++;
                                                if (self.isDebug) NSLog(@"[%@] Do the next sync task (%f)", self.sensorName, completionRate);
                                                if (self.syncProcessCallback!=nil) {
                                                    self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressContinue,completionRate, nil);
                                                }
                                                [self performSelector:@selector(syncTask) withObject:nil afterDelay:self.syncTaskIntervalSecond];
                                                return;
                                            }
                                        }
                                    }else{
                                        [self->fetchSizeAdjuster failure];
                                    }
                                }
                                NSLog(@"[%@] Error: A response from AWARE-Server is null",self.sensorName);
                                [self dataSyncIsFinishedCorrectly];
                                if (self.syncProcessCallback!=nil) self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressError, -1, nil);
                            }];
                        } @catch (NSException *exception) {
                            NSLog(@"[%@] %@",self.sensorName, exception.debugDescription);
                            [self dataSyncIsFinishedCorrectly];
                            if (self.syncProcessCallback!=nil) self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressError, -1, nil);
                        }
                    });
                }else{
                    NSLog(@"%@] %@", self.sensorName, error.debugDescription);
                    [self dataSyncIsFinishedCorrectly];
                    if (self.syncProcessCallback!=nil) self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressError, -1, error);
                }
            }else{
                NSLog(@"%@] results is null", self.sensorName);
                [self dataSyncIsFinishedCorrectly];
                if (self.syncProcessCallback!=nil) self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressError, -1, nil);
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"[%@] %@", self.sensorName, exception.reason);
        [self dataSyncIsFinishedCorrectly];
        if (self.syncProcessCallback!=nil) self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressError, -1, nil);
    }
}

- (void) dataSyncIsFinishedCorrectly {
    if (self.isDebug) NSLog(@"[SQLiteStorage:%@] dataSyncIsFinishedCorrectly ", self.sensorName);
    [self setUploadingState:NO];
    retryCurrentCount      = 0;
    stagedRecords          = 0;
    currentRepetitionCount = 0;
}


- (void) deleteSyncedData {

    NSNumber * clearTimestamp =  [[NSNumber alloc] initWithDouble:self->tempLastUnixTimestamp.doubleValue];

    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [private setParentContext:self.mainQueueManagedObjectContext];
    [private performBlock:^{
        NSFetchRequest* deleteRequest = [[NSFetchRequest alloc] initWithEntityName:self->syncName];
        [deleteRequest setIncludesSubentities:YES];
        [deleteRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp <= %@", clearTimestamp]];
        NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:deleteRequest];
        NSError *deleteError = nil;
        if ([private executeRequest:delete error:&deleteError]) {
            if(self.isDebug){
                NSLog(@"[%@] Success to clear the synced data from DB (timestamp <= %@ )", self.sensorName, clearTimestamp);
            }
        }else{
            NSLog(@"%@", deleteError.description);
        }

        [self->_mainQueueManagedObjectContext performBlock:^{
            NSError * error = nil;
            if([self->_mainQueueManagedObjectContext save:&error]){
                if (self.isDebug) NSLog(@"[%@] merged all changes on the temp-DB into the main DB", self.sensorName);
            }else{
                if (self.isDebug) NSLog(@"[%@] %@", self.sensorName, error.debugDescription);
            }
        }];
    }];
}

- (void) deleteOldDataIfNeeded {
    
    if([self.awareStudy getCleanOldDataType] != cleanOldDataTypeNever){
        
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:self.mainQueueManagedObjectContext];
        [private performBlock:^{
            NSDate * clearLimitDate = nil;
            switch ([self.awareStudy getCleanOldDataType]) {
                case cleanOldDataTypeNever:
                    break;
                case cleanOldDataTypeDaily:
                    clearLimitDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-1*60*60*24];
                    break;
                case cleanOldDataTypeWeekly:
                    clearLimitDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-1*60*60*24*7];
                    break;
                case cleanOldDataTypeMonthly:
                    clearLimitDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-1*60*60*24*31];
                    break;
                case cleanOldDataTypeAlways:
                    clearLimitDate = nil;
                    break;
                default:
                    break;
            }
        
            NSFetchRequest* deleteRequest = [[NSFetchRequest alloc] initWithEntityName:self->objectName];
            [deleteRequest setIncludesSubentities:YES];
            NSNumber * clearTimestamp = self->tempLastUnixTimestamp;
            
            if ( clearLimitDate != nil){
                clearTimestamp = [AWAREUtils getUnixTimestamp:clearLimitDate];
            }
            
            [deleteRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp <= %@", clearTimestamp]];
            NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:deleteRequest];
            NSError *deleteError = nil;
            if ([private executeRequest:delete error:&deleteError]) {
                if(self.isDebug){
                    NSLog(@"[%@] success to clear the data from DB (date <= %@ )", self.sensorName, clearLimitDate);
                }
            }else{
                NSLog(@"%@", deleteError.description);
            }
        

            [self->_mainQueueManagedObjectContext performBlock:^{
                NSError * error = nil;
                if([self->_mainQueueManagedObjectContext save:&error]){
                    NSLog(@"[%@] merged all changes on the temp-DB into the main DB", self.sensorName);
                }else{
                    NSLog(@"[%@] %@", self.sensorName, error.debugDescription);
                }
            }];
         }];
    }
}

#pragma mark - Storage Configurations

- (void) resetMark {
    [self setTimeMarkWithTimestamp:@0];
}

- (void) setTimeMark:(NSDate *) timestamp {
    NSNumber * unixtimestamp = @0;
    if (timestamp != nil) {
        unixtimestamp = @([timestamp timeIntervalSince1970]);
    }
    [self setTimeMarkWithTimestamp:unixtimestamp];
}


- (void) setTimeMarkWithTimestamp:(NSNumber *)timestamp  {
    if(timestamp == nil){
        // NSLog(@"===============[%@] timestamp is nil============================", sensorName);
        timestamp = @0;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:timestamp forKey:timeMarkerIdentifier];
    [userDefaults synchronize];
}


- (NSNumber *) getTimeMark {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber * timestamp = [userDefaults objectForKey:timeMarkerIdentifier];
    
    if(timestamp != nil){
        return timestamp;
    }else{
        // NSLog(@"===============timestamp is nil============================");
        return @0;
    }
}

//- (NSString *)stringByAddingPercentEncodingForAWARE:(NSString *) string {
//    // NSString *unreserved = @"-._~/?{}[]\"\':, ";
//    NSString *unreserved = @"";
//    NSMutableCharacterSet *allowed = [NSMutableCharacterSet
//                                      alphanumericCharacterSet];
//    [allowed addCharactersInString:unreserved];
//    return [string stringByAddingPercentEncodingWithAllowedCharacters:allowed];
//}

#pragma mark - Status

- (bool)isSyncing{
    return isUploading;
}

- (void)setUploadingState:(BOOL)state{
    if (self.isDebug) NSLog(@"[%@][%@]%@",self.sensorName,self,state?@"YES":@"NO");
    isUploading = state;
}


#pragma mark - Fetch Operations

-(NSArray *)fetchTodaysData{
    NSDate * today = [self getToday];
    return [self fetchDataBetweenStart:today andEnd:[today dateByAddingTimeInterval:60*60*24]];
}

- (NSArray *)fetchDataBetweenStart:(NSDate *)start andEnd:(NSDate *)end{
    return [self fetchDataFrom:start to:end];
}

- (NSArray *)fetchDataFrom:(NSDate *)from to:(NSDate *)to{
    
    NSManagedObjectContext *moc = coreDataHandler.managedObjectContext;
    NSError *error = nil;
    NSArray *results = [self fetchDataFrom:from to:to context:moc error:&error];
    if (error!=nil) {
        NSLog(@"%@", error.debugDescription);
    }
    return results;
}

- (NSArray *)fetchDataFrom:(NSDate *)from
                        to:(NSDate *)to
                   context:(NSManagedObjectContext *)context
                     error:(NSError *__autoreleasing  _Nullable * _Nullable)error{
    NSNumber * startNum = [AWAREUtils getUnixTimestamp:from];
    NSNumber * endNum   = [AWAREUtils getUnixTimestamp:to];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:self->objectName];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(timestamp >= %@) AND (timestamp <= %@)", startNum, endNum]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    [fetchRequest setResultType:NSDictionaryResultType];

    NSArray *results = [context executeFetchRequest:fetchRequest error:error];
    if (results==nil) {
        return @[];
    }else{
        return results;
    }
}

- (void)fetchTodaysDataWithHandler:(FetchDataHandler)handler{
    NSDate   * today = [self getToday];
    [self fetchDataFrom:today to:[today dateByAddingTimeInterval:60*60*24]  handler:handler];
}

- (void)fetchDataBetweenStart:(NSDate *)start andEnd:(NSDate *)end withHandler:(FetchDataHandler)handler{
    [self fetchDataFrom:start to:end handler:handler];
}

- (void)fetchDataFrom:(NSDate *)from to:(NSDate *)to handler:(FetchDataHandler)handler{
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [private setParentContext:self.mainQueueManagedObjectContext];
    [private performBlock:^{
        NSError *error = nil;
        NSArray * mergedResult = [self fetchDataFrom:from to:to context:private error:&error];
        
        if (error!=nil) {
            NSLog(@"[%@] %@", self.sensorName, error.debugDescription);
        }
        if (handler != nil) {
            handler(self.sensorName, mergedResult, from, to, error);
        }
    }];
}

- (NSUInteger)countStoredData:(NSString *)entityName
                         from:(NSNumber * _Nullable)from
                      context:(NSManagedObjectContext * _Nonnull)context
                   fetchLimit:(int)limit
                        error:(NSError * _Nullable) error {
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context]];
    [request setIncludesSubentities:NO];
    if (limit != 0) {
        [request setFetchLimit:0];
    }
    if (from!=nil) {
        [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp > %@", from]];
    }
    
    NSDate  * s = [NSDate new];
    NSUInteger count =  [context countForFetchRequest:request error:&error];
    if (self.isDebug) NSLog(@"[%@] COUNT SPEED: New SQLite ---> %f", self.sensorName, [[NSDate new] timeIntervalSinceDate:s] );
    return count;
}


@end
