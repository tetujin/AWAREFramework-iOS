//
//  IndexedSQLiteStorage.m
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/12/05.
//

#import "SQLiteSeparatedStorage.h"
#import "SyncExecutor.h"
#import "CoreDataHandler.h"
#import "AWAREUtils.h"
@import CoreData;

@implementation SQLiteSeparatedStorage{
    NSString * objectName;
    NSString * syncName;
    NSString * baseSyncDataQueryIdentifier;
    NSString * timeMarkerIdentifier;
    BOOL isUploading;
    int  currentRepetitionCount;
    int  requiredRepetitionCount;
    NSNumber * previousUploadingProcessFinishUnixTime; // unixtimeOfUploadingData;
    NSNumber * tempLastUnixTimestamp;
    // BOOL cancel;
    int retryCurrentCount;
    BaseCoreDataHandler * coreDataHandler;
    SyncExecutor * executor;
}

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
        objectName  = objectModelName;
        syncName   = syncModelName;
        self.retryLimit   = 3;
        retryCurrentCount = 0;
        tempLastUnixTimestamp   = @0;
        currentRepetitionCount  = 0;
        requiredRepetitionCount = 0;
        timeMarkerIdentifier        = [NSString stringWithFormat:@"uploader_coredata_timestamp_marker_%@", name];
        baseSyncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@", name];

        self.mainQueueManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [self.mainQueueManagedObjectContext setPersistentStoreCoordinator:dbHandler.persistentStoreCoordinator];
        previousUploadingProcessFinishUnixTime = [self getTimeMark];
        if([previousUploadingProcessFinishUnixTime isEqualToNumber:@0]){
            [self setTimeMark:[NSDate new]];
        }
        coreDataHandler = dbHandler;
    }
    return self;
}


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
            if ([self isDebug]) { NSLog(@"[SQLiteStorage] %@: save data by time-base trigger", self.sensorName); }
            self.lastSaveTimestamp = now.timeIntervalSince1970;
        }
    }else{
        // buffer size based operation
        if (self.buffer.count < [self getBufferSize]) {
            return YES;
        }else{
            if ([self isDebug]) { NSLog(@"[SQLiteStorage] %@: buffer limit-based trigger", self.sensorName); }
        }
    }

    return [self saveBufferDataInMainThread:saveInMainThread];
}

- (BOOL)saveBufferDataInMainThread:(BOOL)saveInMainThread{
    
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
                // sucess to marge diff to the main context manager
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



- (void) stageData:(NSArray * _Nonnull)  data
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
    NSDate * now = [NSDate new];
    [indexObj setValue:now  forKey:@"date"];
    [indexObj setValue:[AWAREUtils getUnixTimestamp:now] forKey:@"timestamp"];
}



- (void)startSyncStorageWithCallBack:(SyncProcessCallBack)callback{
    self.syncProcessCallBack = callback;
    [self startSyncStorage];
}

- (void) startSyncStorage {

    if(isUploading){
        NSString * message= [NSString stringWithFormat:@"[%@] sensor data is uploading.", self.sensorName];
        NSLog(@"%@", message);
        if (self.syncProcessCallBack!=nil){
            self.syncProcessCallBack(self.sensorName, AwareStorageSyncProgressUploading, -1, nil);
        }
        return;
    }
    
    if (self.isDebug) NSLog(@"[SQLiteStorage:%@] start sync process ", self.sensorName);
    isUploading = YES;
    
    [self setRepetationCountAfterStartToSyncDB:[self getTimeMark]];
}

- (void)cancelSyncStorage {
    if (executor != nil) {
        if ( executor.dataTask != nil ) {
            [executor.dataTask cancel];
            [self dataSyncIsFinishedCorrectly];
        }
    }
}

/**
 * start sync db with timestamp
 * @discussion Please call this method in the background
 */
- (BOOL) setRepetationCountAfterStartToSyncDB:(NSNumber *) startTimestamp {

    @try {
        if (objectName == nil) {
            NSLog(@"***** [%@] Error: Entity Name is nil! *****", self.sensorName);
            return NO;
        }

        if ([self isLock]) {
            return NO;
        }else{
            [self lock];
        }
        
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:self.mainQueueManagedObjectContext];
        [private performBlock:^{
            
            NSError* error = nil;
            
            /// get a number of un-synced data
            int count = 0;
            
            ///  prepare a fetch request
            NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:self->syncName];
            [request setIncludesSubentities:NO];
            [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp > %@", startTimestamp]];
            NSArray * indexes = [private executeFetchRequest:request error:&error];
            NSInteger fetchLimit = [self.awareStudy getMaximumNumberOfRecordsForDBSync];
            
            int tempCount = 0;
            if (indexes!=nil && indexes.count>0) {
                 for (NSManagedObjectModel * mom in indexes) {
                     NSNumber * child = [mom valueForKey:@"count"];
                     if (child != nil) {
                         tempCount+=child.intValue;
                     }
                     if (tempCount > fetchLimit) {
                         count+=1;
                         tempCount = 0;
                     }
                 }
             }
            
            if (count == NSNotFound || count== 0) {
                if (self.isDebug) NSLog(@"[%@] There are no data in this database table",self->objectName);
                [self dataSyncIsFinishedCorrectly];
                if (self.syncProcessCallBack!=nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.syncProcessCallBack(self.sensorName, AwareStorageSyncProgressComplete, 1, nil);
                    });
                }
                [self unlock]; // Unlock DB
                return;
            } else if(error != nil){
                NSLog(@"%@", error.description);
                [self dataSyncIsFinishedCorrectly];
                if (self.syncProcessCallBack!=nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.syncProcessCallBack(self.sensorName, AwareStorageSyncProgressError, -1, error) ;
                    });
                }
                [self unlock]; // Unlock DB
                return;
            }

            // Set repetationCount
            self->currentRepetitionCount = 0;
            self->requiredRepetitionCount = count; //(int)count/(int)[self.awareStudy getMaximumNumberOfRecordsForDBSync];

            if (self.isDebug) NSLog(@"[%@] %d times of sync tasks are required", self.sensorName, self->requiredRepetitionCount);

            // set db condition as normal
            [self unlock]; // Unlock DB

            dispatch_async(dispatch_get_main_queue(), ^{
                // start upload
                [self syncTask];
            });

        }];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
        [self unlock]; // Unlock DB
    } @finally {
        return YES;
    }
}


/**
 * Upload method
 */
- (void) syncTask {
    previousUploadingProcessFinishUnixTime = [self getTimeMark];
    
    if ([self isLock]) {
        NSLog(@"[%@] The local-storage is locked. This sync task is canceled", self.sensorName);
        if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, AwareStorageSyncProgressLocked, -1, nil);
        return;
    }else{
        [self lock];
    }
    
    if(objectName == nil){
        NSLog(@"Entity Name is `nil`. Please check the initialozation of this class.");
    }
    
    @try {
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:self.mainQueueManagedObjectContext];
        [private performBlock:^{
            
            NSArray * results = [[NSArray alloc] init];
            
            /// prepare a fetch request
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:self->syncName];
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp > %@", self->previousUploadingProcessFinishUnixTime]];
            
            /// prepare sync buffer
            NSError * error = nil;
            NSMutableArray * buffer = [@[] mutableCopy];
            NSArray * indexes = [private executeFetchRequest:fetchRequest error:&error];
            if (indexes!=nil && indexes.count>0) {
                for (NSManagedObjectModel * mom in indexes) {
                    
                    NSArray *batchData = [mom valueForKey:@"batch_data"];
                    if (batchData != nil) {
                        [buffer addObjectsFromArray:batchData];
                    }
                    
                    /// Save current timestamp as a maker
                    NSDate * date = [mom valueForKey:@"date"];
                    if (date != nil ) {
                        self->tempLastUnixTimestamp = [AWAREUtils getUnixTimestamp:date];
                    }
                    
                    NSInteger fetchLimit = [self.awareStudy getMaximumNumberOfRecordsForDBSync];
                    if (buffer.count > fetchLimit) {
                        break;
                    }
                }
            }
            results = buffer;

            [self unlock];
            
            if (results != nil) {
                if (results.count == 0 || results.count == NSNotFound) {
                    [self dataSyncIsFinishedCorrectly];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, AwareStorageSyncProgressComplete, 1, nil);
                    });
                    return;
                }
                
                // Convert array to json data
                NSError * error = nil;
                NSData * jsonData = nil;
                @try {
                    jsonData = [NSJSONSerialization dataWithJSONObject:results options:0 error:&error];
                } @catch (NSException *exception) {
                    NSLog(@"[%@] %@",self.sensorName, exception.debugDescription);
                }
                
                if (error == nil && jsonData != nil) {
                    // Set HTTP/POST session on main thread
                    
                    if ( jsonData.length == 0 || jsonData.length == 2 ) {
                        NSString * message = [NSString stringWithFormat:@"[%@] data is null or zero", self.sensorName];
                        if (self.isDebug) NSLog(@"%@", message);
                        [self dataSyncIsFinishedCorrectly];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, AwareStorageSyncProgressComplete, 1, nil);
                        });
                        return;
                    }
                    
                    NSMutableData * mutablePostData = [[NSMutableData alloc] initWithData:jsonData];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        @try {
                            self->executor = [[SyncExecutor alloc] initWithAwareStudy:self.awareStudy sensorName:self.sensorName];
                            self->executor.debug = self.isDebug;
                            [self->executor syncWithData:mutablePostData callback:^(NSDictionary *result) {
                                if (result!=nil) {
                                    if (self.isDebug) NSLog(@"%@",result.debugDescription);
                                    NSNumber * isSuccess = [result objectForKey:@"result"];
                                    if (isSuccess != nil) {
                                        if((BOOL)isSuccess.intValue){
                                            // set a repetation count
                                            self->currentRepetitionCount++;
                                            [self setTimeMarkWithTimestamp:self->tempLastUnixTimestamp];
                                            if (self->requiredRepetitionCount <= self->currentRepetitionCount) {
                                                ///////////////// Done ////////////
                                                if (self.isDebug) NSLog(@"[%@] done", self.sensorName);
                                                if (self.syncProcessCallBack!=nil) {
                                                    if ((double)self->requiredRepetitionCount == 0) { self->requiredRepetitionCount = 1; }
                                                    self.syncProcessCallBack(self.sensorName, AwareStorageSyncProgressComplete, (double)self->currentRepetitionCount/(double)self->requiredRepetitionCount, nil);
                                                }
                                                [self dataSyncIsFinishedCorrectly];
                                                if (self.isDebug) NSLog(@"[%@] clear old data", self.sensorName);
                                                [self clearOldData];
                                            }else{
                                                ///////////////// continue ////////////
                                                if (self.syncProcessCallBack!=nil) {
                                                    if ((double)self->requiredRepetitionCount == 0) { self->requiredRepetitionCount = 1; }
                                                    self.syncProcessCallBack(self.sensorName, AwareStorageSyncProgressContinue, (double)self->currentRepetitionCount/(double)self->requiredRepetitionCount, nil);
                                                }
                                                if (self.isDebug) NSLog(@"[%@] execute next sync task (%d/%d)", self.sensorName, self->currentRepetitionCount, self->requiredRepetitionCount);
                                                [self performSelector:@selector(syncTask) withObject:nil afterDelay:self.syncTaskIntervalSecond];
                                            }
                                        }else{
                                            ///////////////// retry ////////////
                                            if (self->retryCurrentCount < self.retryLimit) {
                                                self->retryCurrentCount++;
                                                if (self.isDebug) NSLog(@"[%@] Do the next sync task (%d/%d)", self.sensorName, self->currentRepetitionCount, self->requiredRepetitionCount);
                                                // [self syncTask];
                                                [self performSelector:@selector(syncTask) withObject:nil afterDelay:self.syncTaskIntervalSecond];
                                            }else{
                                                [self dataSyncIsFinishedCorrectly];
                                            }
                                        }
                                    }
                                }
                            }];
                        } @catch (NSException *exception) {
                            NSLog(@"[%@] %@",self.sensorName, exception.debugDescription);
                            [self dataSyncIsFinishedCorrectly];
                            if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, AwareStorageSyncProgressError, -1, nil);
                        }
                    });
                }else{
                    NSLog(@"%@] %@", self.sensorName, error.debugDescription);
                    [self dataSyncIsFinishedCorrectly];
                    if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, AwareStorageSyncProgressError, -1, error);
                }
            }else{
                NSLog(@"%@] results is null", self.sensorName);
                [self dataSyncIsFinishedCorrectly];
                if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, AwareStorageSyncProgressError, -1, nil);
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
        [self dataSyncIsFinishedCorrectly];
        if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, AwareStorageSyncProgressError, -1, nil);
        [self unlock];
    }
}

- (void) dataSyncIsFinishedCorrectly {
    if (self.isDebug) NSLog(@"[SQLiteStorage:%@] dataSyncIsFinishedCorrectly ", self.sensorName);
    isUploading = NO;
    // cancel      = NO;
    requiredRepetitionCount = 0;
    currentRepetitionCount  = 0;
    retryCurrentCount       = 0;
}


- (void) clearOldData {
//    NSManagedObjectContext* parentContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
//    [parentContext setPersistentStoreCoordinator:coreDataHandler.persistentStoreCoordinator];
//
//    NSManagedObjectContext* childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//    [childContext setParentContext:parentContext];
//    [childContext performBlock:^{
//    }];
    
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
                
        NSFetchRequest* deleteRequest = [[NSFetchRequest alloc] initWithEntityName:self->syncName];
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
                NSLog(@"[%@] Sucess to clear the data from DB (date <= %@ )", self.sensorName, clearLimitDate);
            }
        }else{
            NSLog(@"%@", deleteError.description);
        }
        
        /////////////////////
        if([self.awareStudy getCleanOldDataType] != cleanOldDataTypeNever){
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
                    NSLog(@"[%@] Sucess to clear the data from DB (date <= %@ )", self.sensorName, clearLimitDate);
                }
            }else{
                NSLog(@"%@", deleteError.description);
            }
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


//////////////////////////////////

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

- (NSString *)stringByAddingPercentEncodingForAWARE:(NSString *) string {
    // NSString *unreserved = @"-._~/?{}[]\"\':, ";
    NSString *unreserved = @"";
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet
                                      alphanumericCharacterSet];
    [allowed addCharactersInString:unreserved];
    return [string stringByAddingPercentEncodingWithAllowedCharacters:allowed];
}


//////////////////

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

    // NSDate * start = [NSDate new];
    NSArray *results = [context executeFetchRequest:fetchRequest error:error];
    // NSLog(@"--> %f", [[NSDate new] timeIntervalSinceDate:start]);
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

- (bool)isSyncing{
    return isUploading;
}


@end
