//
//  SQLiteStorage.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import "SQLiteStorage.h"
#import "SyncExecutor.h"
#import "../Tools/QuickSyncExecutor.h"
#import "CoreDataHandler.h"
#import "AWAREUtils.h"

@import CoreData;

@implementation SQLiteStorage{
    NSString * entityName;
    InsertEntityCallBack insertEntityCallBack;
    NSString * baseSyncDataQueryIdentifier;
    NSString * timeMarkerIdentifier;
    BOOL isUploading;
    int  currentRepetitionCount;
    int  requiredRepetitionCount;
    NSNumber * previousUploadingProcessFinishUnixTime; // unixtimeOfUploadingData;
    NSNumber * tempLastUnixTimestamp;
    BOOL isCanceled;
    BOOL isFetching;
    int retryCurrentCount;
    BaseCoreDataHandler * coreDataHandler;
    // SyncExecutor * executor;
    id<AWARESyncExecutorDelegate> executorDelegate;
}

- (instancetype)initWithStudy:(AWAREStudy *)study sensorName:(NSString *)name{
    NSLog(@"Please use -initWithStudy:sensorName:entityName:converter!!!");
    return [self initWithStudy:study sensorName:name entityName:@"" insertCallBack:nil];
}

- (instancetype)initWithStudy:(AWAREStudy *) study
                   sensorName:(NSString *) name
                   entityName:(NSString *) entity{
    return [self initWithStudy:study sensorName:name entityName:entity dbHandler:[CoreDataHandler sharedHandler] insertCallBack:nil];
}

- (instancetype)initWithStudy:(AWAREStudy *) study
                   sensorName:(NSString *) name
                   entityName:(NSString *) entity
                    dbHandler:(BaseCoreDataHandler *) dbHandler{
    return [self initWithStudy:study sensorName:name entityName:entity dbHandler:dbHandler insertCallBack:nil];
}

- (instancetype)initWithStudy:(AWAREStudy *)study sensorName:(NSString *)name entityName:(NSString *)entity insertCallBack:(InsertEntityCallBack)insertCallBack{

    return [self initWithStudy:study sensorName:name entityName:entity dbHandler:[CoreDataHandler sharedHandler] insertCallBack:insertCallBack];
}

- (instancetype)initWithStudy:(AWAREStudy *)study sensorName:(NSString *)name entityName:(NSString *)entity dbHandler:(BaseCoreDataHandler *)dbHandler insertCallBack:(InsertEntityCallBack)insertCallBack{
    self = [super initWithStudy:study sensorName:name];
    if(self != nil){
        currentRepetitionCount = 0;
        requiredRepetitionCount = 0;
        isUploading = NO;
        // cancel = NO;
        self.retryLimit = 3;
        retryCurrentCount = 0;
        entityName = entity;
        insertEntityCallBack = insertCallBack;
        baseSyncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@", name];
        timeMarkerIdentifier = [NSString stringWithFormat:@"uploader_coredata_timestamp_marker_%@", name];
        tempLastUnixTimestamp = @0;
        
        self.mainQueueManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [self.mainQueueManagedObjectContext setPersistentStoreCoordinator:dbHandler.persistentStoreCoordinator];
        previousUploadingProcessFinishUnixTime = [self getTimeMark];
        if([previousUploadingProcessFinishUnixTime isEqualToNumber:@0]){
            NSDate * now = [NSDate new];
            [self setTimeMark:now];
        }
        coreDataHandler = dbHandler;
        self.syncMode = AwareSyncModeBackground;
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
    
    NSArray * copiedArray = [self.buffer copy];
    [self.buffer removeAllObjects];
    
    NSManagedObjectContext* parentContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [parentContext setPersistentStoreCoordinator:coreDataHandler.persistentStoreCoordinator];
    
    if (saveInMainThread) {
        // Save data in the main thread //
        for (NSDictionary * bufferedData in copiedArray) {
            if(self->insertEntityCallBack != nil){
                self->insertEntityCallBack(bufferedData,parentContext,self->entityName);
            }else{
                NSManagedObject * entitySample = [NSEntityDescription
                                                      insertNewObjectForEntityForName:self->entityName
                                                      inManagedObjectContext:parentContext];
                [entitySample setValuesForKeysWithDictionary:bufferedData];
            }
        }
        NSError *error = nil;
        if (![parentContext save:&error]) {
            NSLog(@"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
            [self.buffer addObjectsFromArray:copiedArray];
        }else{
            if(self.isDebug) NSLog(@"[SQLiteStorage] %@: Data is saved in the main-thread", self.sensorName);
        }
        
    }else{
        // Save data in the sub thread //
        NSManagedObjectContext* childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [childContext setParentContext:parentContext];
        
        [childContext performBlock:^{
            
            for (NSDictionary * bufferedData in copiedArray) {
                // [self insertNewEntityWithData:bufferedData managedObjectContext:childContext entityName:entityName];
                if(self->insertEntityCallBack != nil){
                    self->insertEntityCallBack(bufferedData,childContext,self->entityName);
                }else{
                    NSManagedObject * entitySample = [NSEntityDescription
                                                                   insertNewObjectForEntityForName:self->entityName
                                                                   inManagedObjectContext:childContext];
                    [entitySample setValuesForKeysWithDictionary:bufferedData];
                }
            }
            
            NSError *error = nil;
            if (![childContext save:&error]) {
                // An error is occued
                NSLog(@"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
                [self.buffer addObjectsFromArray:copiedArray];
            }else{
                // success to marge diff to the main context manager
                [parentContext performBlock:^{
                    if(![parentContext save:nil]){
                        // An error is occued
                        NSLog(@"Error saving context");
                        [self.buffer addObjectsFromArray:copiedArray];
                        // [self.buffer addObjectsFromArray:array];
                    }
                    if(self.isDebug) NSLog(@"[SQLiteStorage] %@: data is saved in the sub-thread", self.sensorName);
                }];
            }
        }];
    }
    return YES;
}

-(void)startSyncStorageWithCallback:(SyncProcessCallback)callback{
    self.syncProcessCallback = callback;
    [self startSyncStorage];
}

- (void) startSyncStorage {

    if (entityName == nil) {
        NSLog(@"***** [%@] Error: Entity Name is nil! *****", self.sensorName);
        return;
    }
    
    if(isUploading){
        NSString * message= [NSString stringWithFormat:@"[%@] NOTE: sensor data is uploading.", self.sensorName];
        NSLog(@"%@", message);
        if (self.syncProcessCallback!=nil){
            self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressUploading, -1, nil);
        }
        return;
    }else{
        [self setUploadingState:YES];
    }

    if (self.isDebug) NSLog(@"[SQLiteStorage:%@] start sync process ", self.sensorName);
    
    
    [self setRepetationCountAfterStartToSyncDB:[self getTimeMark]];
}

- (void)cancelSyncStorage {
    if (executorDelegate != nil) {
        if ( executorDelegate.dataTask != nil ) {
            [executorDelegate.dataTask cancel];
        }
        if ( executorDelegate.session != nil){
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
 * start sync db with timestamp
 * @discussion Please call this method in the background
 */
- (BOOL) setRepetationCountAfterStartToSyncDB:(NSNumber *) startTimestamp {

    @try {
        isFetching = YES;
        
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:self.mainQueueManagedObjectContext];
        [private performBlock:^{
            
            NSError* error = nil;
            // Get count of category
            NSUInteger count = [self countStoredDataFrom:startTimestamp context:private fetchLimit:0 error:error];
            // NSLog(@"[%@] %ld records", self->entityName , count);
            if (count == NSNotFound || count== 0) {
                if (self.isDebug) NSLog(@"[%@] There are no data in this database table",self->entityName);
                [self dataSyncIsFinishedCorrectly];
                self->isCanceled = NO;
                self->isFetching = NO;
                if (self.syncProcessCallback!=nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressComplete, 1, nil);
                    });
                }
                return;
            } else if(error != nil){
                NSLog(@"%@", error.description);
                [self dataSyncIsFinishedCorrectly];
                self->isCanceled = NO;
                self->isFetching = NO;
                if (self.syncProcessCallback!=nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressError, -1, error) ;
                    });
                }
                return;
            }

            // Set repetationCount
            self->currentRepetitionCount = 0;
            self->requiredRepetitionCount = (int)count/(int)[self.awareStudy getMaximumNumberOfRecordsForDBSync];

            if (self.isDebug) NSLog(@"[%@] %d times of sync tasks are required", self.sensorName, self->requiredRepetitionCount);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // start upload
                [self syncTask];
            });

        }];
    } @catch (NSException *exception) {
        NSLog(@"[%@] %@", self.sensorName, exception.reason);
    } @finally {
        return YES;
    }
}


/**
 * Upload method
 */
- (void) syncTask {
    
    if (isCanceled) {
        [self dataSyncIsFinishedCorrectly];
        isCanceled = NO;
        isFetching = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.syncProcessCallback!=nil) self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressCancel, -1, nil);
        });
        return;
    }
    
    previousUploadingProcessFinishUnixTime = [self getTimeMark];

    if(entityName == nil){
        NSLog(@"Entity Name is `nil`. Please check the initialozation of this class.");
    }
    
    @try {
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:self.mainQueueManagedObjectContext];
        [private performBlock:^{
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:self->entityName];
            [fetchRequest setFetchLimit: self.awareStudy.getMaximumNumberOfRecordsForDBSync ]; // <-- set a fetch limit for this query
            [fetchRequest setEntity:[NSEntityDescription entityForName:self->entityName inManagedObjectContext:self.mainQueueManagedObjectContext]];
            [fetchRequest setIncludesSubentities:NO];
            [fetchRequest setResultType:NSDictionaryResultType];
            if([self->entityName isEqualToString:@"EntityESMAnswer"] ){
                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"double_esm_user_answer_timestamp > %@",
                                            self->previousUploadingProcessFinishUnixTime]];
            }else{
                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp > %@", self->previousUploadingProcessFinishUnixTime]];
            }
            
            //Set sort option
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
            NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
            [fetchRequest setSortDescriptors:sortDescriptors];
            
            //Get NSManagedObject from managedObjectContext by using fetch setting
            
            NSDate * s = [NSDate new];
            NSArray *results = [private executeFetchRequest:fetchRequest error:nil] ;
            if (self.isDebug) NSLog(@"[%@] SQLite ---> %f", self.sensorName, [[NSDate new] timeIntervalSinceDate:s] );
            
            if (results != nil) {
                if (results.count == 0 || results.count == NSNotFound) {
                    [self dataSyncIsFinishedCorrectly];
                    self->isCanceled = NO;
                    self->isFetching = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.syncProcessCallback!=nil) self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressComplete, 1, nil);
                    });
                    return;
                }
                
                // Save current timestamp as a maker
                NSDictionary * lastDict = [results lastObject];//[results objectAtIndex:results.count-1];
                self->tempLastUnixTimestamp = [lastDict objectForKey:@"timestamp"];
                if([self->entityName isEqualToString:@"EntityESMAnswer"] ){
                    self->tempLastUnixTimestamp = [lastDict objectForKey:@"double_esm_user_answer_timestamp"];
                }
                if (self->tempLastUnixTimestamp == nil) {
                    self->tempLastUnixTimestamp = @0;
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
                    NSMutableData * mutablePostData = [[NSMutableData alloc] init];
                    if([self->entityName isEqualToString:@"EntityESMAnswer"]){
                        NSString * jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        [mutablePostData appendData:[[self stringByAddingPercentEncodingForAWARE:jsonDataStr] dataUsingEncoding:NSUTF8StringEncoding]];
                    }else{
                        [mutablePostData appendData:jsonData];
                    }

                    dispatch_async(dispatch_get_main_queue(), ^{
                        @try {
                            if (self.syncMode == AwareSyncModeQuick) {
                                self->executorDelegate = [[QuickSyncExecutor alloc] initWithAwareStudy:self.awareStudy sensorName:self.sensorName];
                            }else{
                                self->executorDelegate = [[SyncExecutor alloc] initWithAwareStudy:self.awareStudy sensorName:self.sensorName];
                            }
                            self->isFetching = NO;
                            self->executorDelegate.debug = self.isDebug;
                            [self->executorDelegate syncWithData:mutablePostData callback:^(NSDictionary *result) {
                                if (result!=nil) {
                                    if (self.isDebug) NSLog(@"%@",result.debugDescription);
                                    NSNumber * isSuccess = [result objectForKey:@"result"];
                                    if (isSuccess != nil) {
                                        if((BOOL)isSuccess.intValue){
                                            // set a repetation count
                                            self->currentRepetitionCount++;
                                            [self setTimeMarkWithTimestamp:self->tempLastUnixTimestamp];
                                            if (self->requiredRepetitionCount<=self->currentRepetitionCount) {
                                                ///////////////// Done ////////////
                                                if (self.isDebug) NSLog(@"[%@] Done", self.sensorName);
                                                if (self.syncProcessCallback!=nil) {
                                                    if ((double)self->requiredRepetitionCount == 0) { self->requiredRepetitionCount = 1; }
                                                    self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressComplete, (double)self->currentRepetitionCount/(double)self->requiredRepetitionCount, nil);
                                                }
                                                [self dataSyncIsFinishedCorrectly];
                                                if (self.isDebug) NSLog(@"[%@] Clear old data", self.sensorName);
                                                [self clearOldData];
                                            }else{
                                                ///////////////// continue ////////////
                                                if (self.syncProcessCallback!=nil) {
                                                    if ((double)self->requiredRepetitionCount == 0) { self->requiredRepetitionCount = 1; }
                                                    self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressContinue, (double)self->currentRepetitionCount/(double)self->requiredRepetitionCount, nil);
                                                }
                                                if (self.isDebug) NSLog(@"[%@] Do the next sync task (%d/%d)", self.sensorName, self->currentRepetitionCount, self->requiredRepetitionCount);
                                                [self performSelector:@selector(syncTask) withObject:nil afterDelay:self.syncTaskIntervalSecond];
                                            }
                                            return;
                                        }else{
                                            ///////////////// retry ////////////
                                            if (self->retryCurrentCount < self.retryLimit) {
                                                self->retryCurrentCount++;
                                                if (self.isDebug) NSLog(@"[%@] Do the next sync task (%d/%d)", self.sensorName, self->currentRepetitionCount, self->requiredRepetitionCount);
                                                // [self syncTask];
                                                [self performSelector:@selector(syncTask) withObject:nil afterDelay:self.syncTaskIntervalSecond];
                                                return;
                                            }
                                        }
                                    }
                                }
                                if (self.syncProcessCallback!=nil) {
                                    self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressError, -1, nil);
                                }
                                [self dataSyncIsFinishedCorrectly];
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
        NSLog(@"%@", exception.reason);
        [self dataSyncIsFinishedCorrectly];
        if (self.syncProcessCallback!=nil) self.syncProcessCallback(self.sensorName, AwareStorageSyncProgressError, -1, nil);
    }
}

- (void) dataSyncIsFinishedCorrectly {
    if (self.isDebug) NSLog(@"[SQLiteStorage:%@] dataSyncIsFinishedCorrectly ", self.sensorName);
    [self setUploadingState:NO];
    requiredRepetitionCount = 0;
    currentRepetitionCount  = 0;
    retryCurrentCount       = 0;
}

- (void) setUploadingState:(BOOL)state{
    isUploading = state;
}

- (void) clearOldData { //Immediately{
    
    cleanOldDataType cleanType = [self.awareStudy getCleanOldDataType];
    NSDate * clearLimitDate = nil;
    bool skip = YES;
    switch (cleanType) {
        case cleanOldDataTypeNever:
            skip = YES;
            break;
        case cleanOldDataTypeDaily:
            skip = NO;
            clearLimitDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-1*60*60*24];
            break;
        case cleanOldDataTypeWeekly:
            skip = NO;
            clearLimitDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-1*60*60*24*7];
            break;
        case cleanOldDataTypeMonthly:
            clearLimitDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-1*60*60*24*31];
            skip = NO;
            break;
        case cleanOldDataTypeAlways:
            clearLimitDate = nil;
            skip = NO;
            break;
        default:
            skip = YES;
            break;
    }
    
    if(!skip){
        
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:self.mainQueueManagedObjectContext];
        [private performBlock:^{
            /** ========== Delete uploaded data ============= */
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:self->entityName];
            NSNumber * limitTimestamp = @0;
            if(clearLimitDate == nil){
                limitTimestamp = self->tempLastUnixTimestamp;
            }else{
                limitTimestamp = @([clearLimitDate timeIntervalSince1970]*1000);
            }
            
            if([self->entityName isEqualToString:@"EntityESMAnswer"] ){
                [request setPredicate:[NSPredicate predicateWithFormat:@"(double_esm_user_answer_timestamp <= %@)", limitTimestamp]];
            }else{
                [request setPredicate:[NSPredicate predicateWithFormat:@"(timestamp <= %@)", limitTimestamp]];
            }
            
            NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
            NSError *deleteError = nil;
            [private executeRequest:delete error:&deleteError];
            if (deleteError != nil) {
                NSLog(@"%@", deleteError.description);
            }else{
                if(self.isDebug){
                    NSLog(@"[%@] Success to clear the data from DB (timestamp <= %@ )", self.sensorName, [NSDate dateWithTimeIntervalSince1970:limitTimestamp.longLongValue/1000]);
                }
            }
            
            [self->_mainQueueManagedObjectContext performBlock:^{
                NSError * error = nil;
                if([self->_mainQueueManagedObjectContext save:&error]){
                    if(self.isDebug) NSLog(@"[%@] merged all changes on the temp-DB into the main DB", self.sensorName);
                }else{
                    if (error!=nil) {
                        NSLog(@"[%@] %@", self.sensorName, error.debugDescription);
                    }
                }
            }];
        }];
    }
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
    NSNumber * startNum = [AWAREUtils getUnixTimestamp:from];
    NSNumber * endNum   = [AWAREUtils getUnixTimestamp:to];
    
    NSManagedObjectContext *moc = coreDataHandler.managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    [request  setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@", startNum , endNum]];
    [request setResultType:NSDictionaryResultType];
    
    NSError *error = nil;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    
    if (error!=nil) {
        NSLog(@"[%@] %@", [self sensorName], error.debugDescription);
    }
    return results;
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
        
        NSNumber * startNum = [AWAREUtils getUnixTimestamp:from];
        NSNumber * endNum   = [AWAREUtils getUnixTimestamp:to];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:self->entityName];
//        [fetchRequest setEntity:[NSEntityDescription entityForName:self->entityName inManagedObjectContext:self.mainQueueManagedObjectContext]];
        [fetchRequest setIncludesSubentities:NO];
        [fetchRequest setResultType:NSDictionaryResultType];
        if([self->entityName isEqualToString:@"EntityESMAnswer"] ){
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"double_esm_user_answer_timestamp >= %@ AND double_esm_user_answer_timestamp =< %@",
                                        startNum, endNum]];
        }else if([self->entityName isEqualToString:@"EntityHealthKitQuantityHR"] ){
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp_start >= %@ AND timestamp_start <= %@",
                                        startNum, endNum]];
        }else{
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@", startNum, endNum]];
        }
        
        //Set sort option
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        //Get NSManagedObject from managedObjectContext by using fetch setting
        NSError * error = nil;
        NSArray *results = [private executeFetchRequest:fetchRequest error:&error];
        if (error!=nil) {
            NSLog(@"[%@] %@", self.sensorName, error.debugDescription);
        }
        if (handler != nil) {
            handler(self.sensorName, results, from, to, error);
        }
    }];
}

- (void)fetchDataFrom:(NSDate *)from to:(NSDate *)to limit:(int)limit all:(bool)all handler:(LimitedDataFetchHandler)handler{
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [private setParentContext:self.mainQueueManagedObjectContext];
    [private performBlock:^{
        
        NSNumber * startNum = [AWAREUtils getUnixTimestamp:from];
        NSNumber * endNum   = [AWAREUtils getUnixTimestamp:to];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:self->entityName];
        [fetchRequest setIncludesSubentities:NO];
        [fetchRequest setResultType:NSDictionaryResultType];
        if([self->entityName isEqualToString:@"EntityESMAnswer"] ){
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"double_esm_user_answer_timestamp >= %@ AND double_esm_user_answer_timestamp =< %@",
                                        startNum, endNum]];
        }else{
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@", startNum, endNum]];
        }
        
        [fetchRequest setFetchLimit:limit];

        //Set sort option
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        //Get NSManagedObject from managedObjectContext by using fetch setting
        NSError * error = nil;
        NSArray *results = [private executeFetchRequest:fetchRequest error:&error];
        
        if (error!=nil) {
            NSLog(@"[%@] %@", self.sensorName, error.debugDescription);
        }
        if (handler != nil) {
            if (results.count < limit || all) {
                handler(self.sensorName, results, from, to, true, error);
            }else{
                handler(self.sensorName, results, from, to, false, error);
                NSDictionary * dict = results.lastObject;
                if (dict != nil) {
                    NSNumber * timestamp = dict[@"timestamp"];
                    if (timestamp != nil) {
                        NSDate * date = [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue/1000];
                        [self fetchDataFrom:date to:to limit:limit all:all handler:handler];
                    }else{
                        handler(self.sensorName, results, from, to, true, error);
                    }
                }else{
                    handler(self.sensorName, results, from, to, true, error);
                }
            }
        }
    }];
}

- (bool)isSyncing{
    return isUploading;
}

- (NSUInteger)countStoredDataWithError:(NSError *) error{
    return [self countStoredDataFrom:@(0) context:_mainQueueManagedObjectContext fetchLimit:0 error:error];
}

- (NSUInteger)countUnsyncedDataWithError:(NSError *) error{
    return [self countStoredDataFrom:[self getTimeMark] context:_mainQueueManagedObjectContext fetchLimit:0 error:error];
}

- (BOOL)isExistUnsyncedDataWithError:(NSError *)error{
    return [self countStoredDataFrom:[self getTimeMark] context:_mainQueueManagedObjectContext fetchLimit:1 error:error];
}

- (NSUInteger)countStoredDataFrom:(NSNumber * _Nullable)from context:(NSManagedObjectContext * _Nonnull)context fetchLimit:(int)limit error:(NSError * _Nullable) error {
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:self->entityName inManagedObjectContext:context]];
    [request setIncludesSubentities:NO];
    if (limit != 0) {
        [request setFetchLimit:0];
    }
    if (from!=nil) {
        [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp > %@", from]];
    }
    
    return [context countForFetchRequest:request error:&error];
}

@end


