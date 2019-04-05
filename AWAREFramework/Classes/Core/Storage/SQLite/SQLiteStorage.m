//
//  SQLiteStorage.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import "SQLiteStorage.h"
#import "SyncExecutor.h"
#import "CoreDataHandler.h"
#import "AWAREUtils.h"

@import CoreData;

@implementation SQLiteStorage{
    NSString * entityName;
    InsertEntityCallBack insertEntityCallBack;
    NSString * baseSyncDataQueryIdentifier;
    NSString * timeMarkerIdentifier;
    BOOL isUploading;
    int currentRepetitionCount;
    int requiredRepetitionCount;
    NSNumber * previousUploadingProcessFinishUnixTime; // unixtimeOfUploadingData;
    NSNumber * tempLastUnixTimestamp;
    BOOL cancel;
    int retryCurrentCount;
    BaseCoreDataHandler * coreDataHandler;
}

- (instancetype)initWithStudy:(AWAREStudy *)study sensorName:(NSString *)name{
    NSLog(@"Please use -initWithStudy:sensorName:entityName:converter!!!");
    return [self initWithStudy:study sensorName:name entityName:nil insertCallBack:nil];
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
        cancel = NO;
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
        // executor = [[SyncExecutor alloc] initWithAwareStudy:self.awareStudy sensorName:self.sensorName];
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
            if ([self isDebug]) { NSLog(@"[SQLiteStorage] %@: save data by buffer limit-based trigger", self.sensorName); }
        }
    }

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
        [self unlock];
        
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
                [self unlock];
            }else{
                // sucess to marge diff to the main context manager
                [parentContext performBlock:^{
                    if(![parentContext save:nil]){
                        // An error is occued
                        NSLog(@"Error saving context");
                        [self.buffer addObjectsFromArray:copiedArray];
                        // [self.buffer addObjectsFromArray:array];
                    }
                    if(self.isDebug) NSLog(@"[SQLiteStorage] %@: Data is saved in the sub-thread", self.sensorName);
                    [self unlock];
                }];
            }
        }];
    }
    
    return YES;
}


- (void)startSyncStorageWithCallBack:(SyncProcessCallBack)callback{
    self.syncProcessCallBack = callback;
    [self startSyncStorage];
}

- (void)startSyncStorage {

    if(self->isUploading){
        NSString * message= [NSString stringWithFormat:@"[%@] Now sendsor data is uploading.", self.sensorName];
        NSLog(@"%@", message);
        return;
    }
    
    [self setRepetationCountAfterStartToSyncDB:[self getTimeMark]];
    if (self.isDebug) NSLog(@"[SQLiteStorage:%@] start sync process ", self.sensorName);
    self-> isUploading = YES;

}

- (void)cancelSyncStorage {
    // NSLog(@"Please overwirte -cancelSyncStorage");
    cancel = YES;
}


/////////////////////////



/**
 * start sync db with timestamp
 * @discussion Please call this method in the background
 */
- (BOOL) setRepetationCountAfterStartToSyncDB:(NSNumber *) startTimestamp {
    
    @try {
        if (entityName == nil) {
            NSLog(@"***** [%@] Error: Entity Name is nil! *****", self.sensorName);
            return NO;
        }
        
        if ([self isLock]) {
            return NO;
        }else{
            [self lock];
        }
        
        NSFetchRequest* request = [[NSFetchRequest alloc] init];
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:self.mainQueueManagedObjectContext];
        
        [private performBlock:^{
            // NSLog(@"start time is ... %@",startTimestamp);
            [request setEntity:[NSEntityDescription entityForName:self->entityName inManagedObjectContext:self.mainQueueManagedObjectContext]];
            [request setIncludesSubentities:NO];
            [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp > %@", startTimestamp]];
            
            NSError* error = nil;
            // Get count of category
            NSInteger count = [private countForFetchRequest:request error:&error];
            // NSLog(@"[%@] %ld records", self->entityName , count);
            if (count == NSNotFound || count== 0) {
                if (self.isDebug) NSLog(@"[%@] There are no data in this database table",self->entityName);
                [self dataSyncIsFinishedCorrectly];
                if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, 1.0, nil);
                [self unlock]; // Unlock DB
                return;
            } else if(error != nil){
                NSLog(@"%@", error.description);
                [self dataSyncIsFinishedCorrectly];
                if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, -1, error) ;
                [self unlock]; // Unlock DB
                return;
            }
            
            // Set repetationCount
            self->currentRepetitionCount = 0;
            self->requiredRepetitionCount = (int)count/(int)[self.awareStudy getMaximumNumberOfRecordsForDBSync];
            
            if (self.isDebug) NSLog(@"[%@] %d times of sync tasks are required", self.sensorName, self->requiredRepetitionCount);
            
            // set db condition as normal
            [self unlock]; // Unlock DB
            
            // start upload
            [self syncTask];
            
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
- (void) syncTask{
    previousUploadingProcessFinishUnixTime = [self getTimeMark];
    
    if (cancel) {
        [self dataSyncIsFinishedCorrectly];
        if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, -2, nil);
        return;
    }
    // NSLog(@"[%@] marker   end: %@", sensorName, [NSDate dateWithTimeIntervalSince1970:previousUploadingProcessFinishUnixTime.longLongValue/1000]);
    
    if ([self isLock]) {
        // [self dataSyncIsFinishedCorrectly];
        [self performSelector:@selector(syncTask) withObject:nil afterDelay:1];
        return;
    }else{
        [self lock];
    }
    
    if(entityName == nil){
        NSLog(@"Entity Name is 'nil'. Please check the initialozation of this class.");
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
            NSArray *results = [private executeFetchRequest:fetchRequest error:nil] ;
            // NSLog(@"%ld",results.count); //TODO
            
            [self unlock];
            
            if (results != nil) {
                if (results.count == 0 || results.count == NSNotFound) {
                    [self dataSyncIsFinishedCorrectly];
                    if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, 1.0, nil);
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
                    // Set HTTP/POST session on main thread
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ( jsonData.length == 0 || jsonData.length == 2 ) {
                            NSString * message = [NSString stringWithFormat:@"[%@] Data is Null or Length is Zero", self.sensorName];
                            if (self.isDebug) NSLog(@"%@", message);
                            [self dataSyncIsFinishedCorrectly];
                            if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, 1.0, nil);
                            return;
                        }
                        
                        NSMutableData * mutablePostData = [[NSMutableData alloc] init];
                        if([self->entityName isEqualToString:@"EntityESMAnswer"]){
                            NSString * jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                            [mutablePostData appendData:[[self stringByAddingPercentEncodingForAWARE:jsonDataStr] dataUsingEncoding:NSUTF8StringEncoding]];
                        }else{
                            [mutablePostData appendData:jsonData];
                        }

                        @try {
                            // self->executor.debug = self.isDebug;
                            SyncExecutor * executor = [[SyncExecutor alloc] initWithAwareStudy:self.awareStudy sensorName:self.sensorName];
                            executor.debug = self.isDebug;
                            [executor syncWithData:mutablePostData callback:^(NSDictionary *result) {
                                
                                if (result!=nil) {
                                    if (self.isDebug) NSLog(@"%@",result.debugDescription);
                                    NSNumber * isSuccess = [result objectForKey:@"result"];
                                    if (isSuccess != nil) {
                                        if((BOOL)isSuccess.intValue){
                                            // set a repetation count
                                            self->currentRepetitionCount++;
                                            [self setTimeMarkWithTimestamp:self->tempLastUnixTimestamp];
                                            if (self->requiredRepetitionCount<self->currentRepetitionCount) {
                                                ///////////////// Done ////////////
                                                if (self.isDebug) NSLog(@"[%@] Done", self.sensorName);
                                                if (self.syncProcessCallBack!=nil) {
                                                    if ((double)self->requiredRepetitionCount == 0) { self->requiredRepetitionCount = 1; }
                                                    self.syncProcessCallBack(self.sensorName, (double)self->currentRepetitionCount/(double)self->requiredRepetitionCount, nil);
                                                }
                                                [self dataSyncIsFinishedCorrectly];
                                                if (self.isDebug) NSLog(@"[%@] Clear old data", self.sensorName);
                                                [self clearOldData];
                                            }else{
                                                ///////////////// continue ////////////
                                                if (self.syncProcessCallBack!=nil) {
                                                    if ((double)self->requiredRepetitionCount == 0) { self->requiredRepetitionCount = 1; }
                                                    self.syncProcessCallBack(self.sensorName, (double)self->currentRepetitionCount/(double)self->requiredRepetitionCount, nil);
                                                }
                                                if (self.isDebug) NSLog(@"[%@] Do the next sync task (%d/%d)", self.sensorName, self->currentRepetitionCount, self->requiredRepetitionCount);
                                                // [self syncTask];
                                                [self performSelector:@selector(syncTask) withObject:nil afterDelay:self.syncTaskIntervalSecond];
                                            }
                                        }else{
                                            ///////////////// retry ////////////
                                            if (self->retryCurrentCount < self.retryLimit ) {
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
                            if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, -1, nil);
                        }
                    });
                }else{
                    NSLog(@"%@] %@", self.sensorName, error.debugDescription);
                    [self dataSyncIsFinishedCorrectly];
                    if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, -1, error);
                }
            }else{
                NSLog(@"%@] results is null", self.sensorName);
                [self dataSyncIsFinishedCorrectly];
                if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, -1, nil);
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
        [self dataSyncIsFinishedCorrectly];
        if (self.syncProcessCallBack!=nil) self.syncProcessCallBack(self.sensorName, -1, nil);
        [self unlock];
    }
}

- (void) dataSyncIsFinishedCorrectly {
    if (self.isDebug) NSLog(@"[SQLiteStorage:%@] dataSyncIsFinishedCorrectly ", self.sensorName);
    isUploading = NO;
    cancel      = NO;
    requiredRepetitionCount = 0;
    currentRepetitionCount  = 0;
    retryCurrentCount       = 0;
}


- (void) clearOldData{
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:self.mainQueueManagedObjectContext]];
    [request setIncludesSubentities:NO];
    
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [private setParentContext:self.mainQueueManagedObjectContext];
    [private performBlock:^{
        
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
            /** ========== Delete uploaded data ============= */
            if(![self isLock]){
                [self lock];
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
                        NSLog(@"[%@] Sucess to clear the data from DB (timestamp <= %@ )", self.sensorName, [NSDate dateWithTimeIntervalSince1970:limitTimestamp.longLongValue/1000]);
                    }
                }
                [self unlock];
            }
        }
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
    
    NSNumber * startNum = [AWAREUtils getUnixTimestamp:start];
    NSNumber * endNum   = [AWAREUtils getUnixTimestamp:end];
    
    NSManagedObjectContext *moc = coreDataHandler.managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    [request  setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@", startNum , endNum]];
    [request setResultType:NSDictionaryResultType];
    
    NSError *error = nil;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    
    if (error!=nil) {
        NSLog(@"%@", error.debugDescription);
    }
    return results;
}


- (void)fetchTodaysDataWithHandler:(FetchDataHandler)handler{
    NSDate   * today = [self getToday];
    [self fetchDataBetweenStart:today andEnd:[today dateByAddingTimeInterval:60*60*24] withHandler:handler];
}

- (void)fetchDataBetweenStart:(NSDate *)start andEnd:(NSDate *)end withHandler:(FetchDataHandler)handler{
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [private setParentContext:self.mainQueueManagedObjectContext];
    [private performBlock:^{
        
        NSNumber * startNum = [AWAREUtils getUnixTimestamp:start];
        NSNumber * endNum   = [AWAREUtils getUnixTimestamp:end];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:self->entityName];
        [fetchRequest setEntity:[NSEntityDescription entityForName:self->entityName inManagedObjectContext:self.mainQueueManagedObjectContext]];
        [fetchRequest setIncludesSubentities:NO];
        [fetchRequest setResultType:NSDictionaryResultType];
        if([self->entityName isEqualToString:@"EntityESMAnswer"] ){
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"double_esm_user_answer_timestamp >= %@ AND double_esm_user_answer_timestamp =< %@",
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
            handler(self.sensorName, results, start, end, error);
        }
    }];
}

@end
