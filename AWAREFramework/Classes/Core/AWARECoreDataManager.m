//
//  AWARECoreDataUploader.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/30/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARECoreDataManager.h"
#import "AWAREKeys.h"
#import "AWAREDelegate.h"
#import "EntityESMAnswer.h"
#import "SQLiteSyncExecutor.h"
#import "DBTableCreator.h"

@implementation AWARECoreDataManager {
    AWAREStudy * awareStudy;
    NSString* entityName;
    NSString* sensorName;
    
    // sync data query
    NSString * syncDataQueryIdentifier;
    NSString * baseSyncDataQueryIdentifier;
    
    // create table query
    NSString * createTableQueryIdentifier;
    NSString * baseCreateTableQueryIdentifier;
    
    // notification identifier
    NSString * dbSessionFinishNotification; // this notification should make by each sensor.
    
    NSString * timeMarkerIdentifier;
    double httpStartTimestamp;
    double postedTextLength;
    BOOL isDebug;
    BOOL isUploading;
    // BOOL isManualUpload;
    // BOOL isSyncWithOnlyBatteryCharging;
    // BOOL isSyncWithWifiOnly;
    int errorPosts;
    
    NSNumber * previousUploadingProcessFinishUnixTime; // unixtimeOfUploadingData;
    // NSNumber *  currentUploadingProcessStartUnixTime;
    NSNumber * tempLastUnixTimestamp;
    
    int currentRepetitionCounts; // current repetition count
    int repetitionTime;          // max repetition count
    
    double shortDelayForNextUpload; // second
    double longDelayForNextUpload; // second
    int thresholdForNextLongDelay; // count
    
    int bufferCount;
    NSString * syncProgress;
    
    NSMutableArray * bufferArray;
    
    NSString * tableName;
    
    SQLiteSyncExecutor * syncExexutor;
    DBTableCreator * tableCreator;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                        sensorName:(NSString *)name
                      dbEntityName:(NSString *)entity {
    self = [super initWithAwareStudy:study sensorName:name];
    if(self != nil){
        awareStudy = study;
        sensorName = name;
        tableName = name;
        entityName = entity;
        httpStartTimestamp = [[NSDate new] timeIntervalSince1970];
        postedTextLength = 0;
        errorPosts = 0;
        shortDelayForNextUpload = 1; // second
        longDelayForNextUpload = 30; // second
        thresholdForNextLongDelay = 10; // count
        bufferCount = 0; // buffer count
        syncProgress = @"";
        // isManualUpload = NO;
        baseSyncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@", sensorName];
        baseCreateTableQueryIdentifier = [NSString stringWithFormat:@"create_table_query_identifier_%@",  sensorName];
        timeMarkerIdentifier = [NSString stringWithFormat:@"uploader_coredata_timestamp_marker_%@", sensorName];
        dbSessionFinishNotification = [NSString stringWithFormat:@"aware.db.session.finish.notification.%@", sensorName];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedDbSession:) name:dbSessionFinishNotification object:nil];
        
        // Get settings
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        isDebug = [userDefaults boolForKey:SETTING_DEBUG_STATE];
//        isSyncWithOnlyBatteryCharging = [userDefaults boolForKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
//        isSyncWithWifiOnly = [userDefaults boolForKey:SETTING_SYNC_WIFI_ONLY];
        
        AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
        self.mainQueueManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [self.mainQueueManagedObjectContext setPersistentStoreCoordinator:delegate.persistentStoreCoordinator];
      
        // self.writeQueueManagedObjectContext = [[NSManagedObjectContext alloc] init];
        // [self.writeQueueManagedObjectContext setPersistentStoreCoordinator:delegate.persistentStoreCoordinator];
        
        bufferArray = [[NSMutableArray alloc] init];
        
        previousUploadingProcessFinishUnixTime = [self getTimeMark];
        
        syncExexutor = [[SQLiteSyncExecutor alloc] initWithAwareStudy:study sensorName:name dbEntityName:entityName];
        tableCreator = [[DBTableCreator alloc] initWithAwareStudy:study sensorName:name dbEntityName:entityName];
        // isUploading = syncExexutor.isUploading;
        if([previousUploadingProcessFinishUnixTime isEqualToNumber:@0]){
            NSDate * now = [NSDate new];
            [self setTimeMark:now];
            // NSLog(@"[%@] %@ <-- set new date", sensorName, now);
        }else{
            // NSLog(@"[%@] %@ <-- a previous time exist", sensorName, [NSDate dateWithTimeIntervalSince1970:[self getTimeMark].longLongValue/1000]);
        }
    }
    return self;
}

- (bool)isUploading{
    return [syncExexutor isUploading];
}

- (void) finishedDbSession:(id) sender {
    NSLog(@"finished db session is called!");
    // dbCondition = AwareDBConditionNormal;
}

- (void) stopStopCoreDataManager {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:dbSessionFinishNotification object:nil];
}


- (void)syncAwareDBInBackground{
    [self syncAwareDBInBackgroundWithSensorName:sensorName];
}

- (void)syncAwareDBInBackgroundWithSensorName:(NSString *)name{
    [syncExexutor sync:name fource:false];
}

- (void) uploadSensorDataInBackground {
    [syncExexutor sync:tableName fource:NO];
}

- (BOOL)syncAwareDBInForeground{
    // isManualUpload = YES;
    [syncExexutor sync:tableName fource:YES];
    return YES;
}

- (BOOL)syncDBInForeground{
    [self syncAwareDBInForeground];
    return YES;
}

//////////////////////////////////////////////////////////////////////////////


- (NSString *)getEntityName{
    return entityName;
}


//////////////////////////////////////////////////
//////////////////////////////////////////////////

- (void) setTimeMark:(NSDate *) timestamp {
    NSNumber * unixtimestamp = @0;
    if (timestamp != nil) {
        unixtimestamp = @([timestamp timeIntervalSince1970]);
    }
    [self setTimeMarkWithTimestamp:unixtimestamp];
}

- (void) setTimeMarkWithTimestamp:(NSNumber *)timestamp  {
    if(timestamp == nil){
        NSLog(@"===============[%@] timestamp is nil============================", sensorName);
        timestamp = @0;
    }
    NSLog(@"[time_mark:%@] %@", sensorName, [NSDate dateWithTimeIntervalSince1970:timestamp.longLongValue/1000].debugDescription);
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
        NSLog(@"===============timestamp is nil============================");
        return @0;
    }
}



//////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

//// save data
- (bool) saveDataWithArray:(NSArray*) array {
    if (array!=nil) {
        [self saveDataInBackgroundWithArray:array];
        return YES;
    }else{
        return NO;
    }
    
//    if(array!=nil && bufferArray!=nil){
//        [bufferArray addObjectsFromArray:array];
//        if(bufferCount > [self getBufferSize]){
//            bufferCount = 0;
//            [self saveDataInBackground];
//        }else{
//            bufferCount ++;
//        }
//        return YES;
//    }
//    return NO;
}

// save data
- (bool) saveData:(NSDictionary *)data{
    if(data!=nil && bufferArray != nil){
        [bufferArray addObject:data];
        //NSLog(@"[%@] buffer size: %d",sensorName,[self getBufferSize]);
        int bufferLimit = [self getBufferSize];
        if(bufferCount >= bufferLimit){
            bufferCount = 0;
            [self saveDataInBackground];
        }else{
            bufferCount ++;
        }
        return YES;
    }
    return NO;
}

/**
 * Save data to SQLite in the background.
 * @discussion This method should be called in the background thread.
 */
- (void) saveDataInBackground {
    @try{
        // Copy the buffer and remove the buffer objects
        // NSLog(@"[%@] start to copy %ld data", sensorName, bufferArray.count);
        NSArray * array = [bufferArray mutableCopy];
        [bufferArray removeAllObjects];
        // NSLog(@"[%@] end to copy %ld data", sensorName, array.count);
        [self saveDataInBackgroundWithArray:array];
    } @catch (NSException * error){
        NSLog(@"[%@] %@", sensorName, error.debugDescription);
        [self saveDebugEventWithText:error.debugDescription type:DebugTypeError label:[NSString stringWithFormat:@"[%@] Buffer Copy Error",sensorName]];
    }
}

- (void) saveDataInBackgroundWithArray:(NSArray *)array{
    AWAREDelegate * delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext* parentContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [parentContext setPersistentStoreCoordinator:delegate.persistentStoreCoordinator];
    
    NSManagedObjectContext* childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [childContext setParentContext:parentContext];
    
    [childContext performBlock:^{
        if(![self isDBLock]){
            [self lockDB];
            // Convert a NSDictionary to a SQLite Entity
            for (NSDictionary * bufferedData in array) {
                // insert new data
                [self insertNewEntityWithData:bufferedData managedObjectContext:childContext entityName:[self getEntityName]];
            }
            NSError *error = nil;
            if (![childContext save:&error]) {
                // An error is occued
                NSLog(@"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
                [bufferArray addObjectsFromArray:array];
                [self unlockDB];
            }else{
                // sucess to marge diff to the main context manager
                [parentContext performBlock:^{
                    if(![parentContext save:nil]){
                        // An error is occued
                        NSLog(@"Error saving context");
                        [bufferArray addObjectsFromArray:array];
                    }
                    //if([self isDebug])
                    NSLog(@"[%@] Data is saved", sensorName);
                    [self unlockDB];
                }];
            }
            
        }else{
            NSLog(@"[%@] DB is locked by another thread", [self getEntityName]);
            [bufferArray addObjectsFromArray:array];
        }
    }];
}


- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString*) entity {
    NSLog(@"[%@] Please overwrite this method on a sub-class of AWARESensor if you use the background data storage.", entity);
}

///////////////////////////////////////////////

/**
 * This method saves data (that is on the RAM) to DB (SQLite).
 * @discussion This method will monopolize main-thread. I recomend you to use saveData: and -saveDataInBackground.
 * @discussion This method should be called in main-thread.
 */
- (bool) saveDataToDB {
//    NSLog(@"[%@] buffer count => %d", [self getEntityName], bufferCount);
    
    if(bufferCount > [self getBufferSize]){
        bufferCount = 0;
    }else{
        bufferCount ++;
        return NO;
    }
    
    if ([self isDBLock]) {
        // NSLog(@"[%@] DB is locked by the other thread.", [self getEntityName]);
        return NO;
    }else{
        // NSLog(@"[%@] lock the DB", [self getEntityName]);
        [self lockDB];
    }
    
    @try {
        NSError * error = nil;
        AWAREDelegate * appDelegate = (AWAREDelegate*)[UIApplication sharedApplication].delegate;
        [appDelegate.managedObjectContext save:&error];
        if ( error != nil ){
            NSLog(@"[%@] %@", sensorName, error.debugDescription );
        }
        NSLog(@"[%@] Data is saved", sensorName);
        [self unlockDB];
    }@catch(NSException *exception) {
        NSLog(@"%@", exception.reason);
        if ([self isDBLock]) {
            [self unlockDB];
        }
        return NO;
    }
    return YES;
}

////////////////////
- (void)cancelSyncProcess{
    [syncExexutor cancelSyncProcess];
}

- (void)resetMark{
    [syncExexutor resetMark];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////




- (NSString *)stringByAddingPercentEncodingForAWARE:(NSString *)string{
    // NSString *unreserved = @"-._~/?{}[]\"\':, ";
    NSString *unreserved = @"";
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet
                                      alphanumericCharacterSet];
    [allowed addCharactersInString:unreserved];
    return [string stringByAddingPercentEncodingWithAllowedCharacters:allowed];
}

- (NSString *) getSyncProgressAsText:(NSString *)sensorName{
    return syncProgress;
}

- (NSString *)getSyncProgressAsText{
    return syncProgress;
}

//////////////////////

- (void)createTable:(NSString *)query{
    [tableCreator createTable:query];
}

- (void) createTable:(NSString *)query withTableName:(NSString *)tableName{
    [tableCreator createTable:query withTableName:tableName];
}


@end
