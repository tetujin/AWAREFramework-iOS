//
//  SQLiteSyncExecutor.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2018/03/12.
//  Copyright © 2018 Yuuki NISHIYAMA. All rights reserved.
//


#import "SQLiteSyncExecutor.h"
#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "AWAREDelegate.h"
#import "EntityESMAnswer.h"
#import "Reachability.h"
#import "Processor.h"

@implementation SQLiteSyncExecutor {
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
    // double postedTextLength;
    BOOL isDebug;
    BOOL isUploading;
    BOOL isManualUpload;
    bool isSyncWithOnlyBatteryCharging;
    bool isSyncWithOnlyWifi;
    int cpuThreshold;
    NSUInteger fetchLimit;
    // BOOL isSyncWithOnlyBatteryCharging;
    // BOOL isSyncWithWifiOnly;
    
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
    
    Reachability *currentReachability;
    
    NSMutableData * receivedData;
    
    bool isFource;
    bool isLock;
    bool cancel;
}


- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                        sensorName:(NSString *)name
                      dbEntityName:(NSString *)entity {
    // self = [super initWithAwareStudy:study sensorName:name];
    if(self != nil){
        awareStudy = study;
        sensorName = name;
        tableName = name;
        entityName = entity;
        isUploading = NO;
        isFource = NO;
        cancel = NO;
        if(study!=nil){
            cpuThreshold = [study getCPUTheshold];
        }else{
            cpuThreshold = 50;
        }
        httpStartTimestamp = [[NSDate new] timeIntervalSince1970];
        currentReachability  = [Reachability reachabilityForInternetConnection];
        receivedData = [[NSMutableData alloc] init];
        // postedTextLength = 0;
        shortDelayForNextUpload = 1;   // second
        longDelayForNextUpload = 1;    // second (30)
        thresholdForNextLongDelay = 1; // count (10)
        syncProgress = @"";
        isManualUpload = NO;
        isLock = NO;
        isSyncWithOnlyBatteryCharging = [study getDataUploadStateWithOnlyBatterChargning];
        isSyncWithOnlyWifi = [study getDataUploadStateInWifi];
        fetchLimit = [study getMaxFetchSize];
        
        baseSyncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@", sensorName];
        timeMarkerIdentifier = [NSString stringWithFormat:@"uploader_coredata_timestamp_marker_%@", sensorName];
        dbSessionFinishNotification = [NSString stringWithFormat:@"aware.db.session.finish.notification.%@", sensorName];
        // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedDbSession:) name:dbSessionFinishNotification object:nil];
        
        // Get settings
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        isDebug = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        
        AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
        self.mainQueueManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [self.mainQueueManagedObjectContext setPersistentStoreCoordinator:delegate.persistentStoreCoordinator];
        
        previousUploadingProcessFinishUnixTime = [self getTimeMark];
        
        if([previousUploadingProcessFinishUnixTime isEqualToNumber:@0]){
            NSDate * now = [NSDate new];
            [self setTimeMark:now];
        }
    }
    return self;
}


- (BOOL) isUploading{
    return isUploading;
}


- (void)sync:(NSString *)name fource:(bool)fource {
    tableName = name;
    isFource = fource;
    
    NSURLSessionConfiguration *sessionConfig = nil;
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:baseSyncDataQueryIdentifier];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:self
                                                     delegateQueue:nil];
    [session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        if (dataTasks.count == 0){
            // check wifi state
            if(isUploading){
                NSString * message= [NSString stringWithFormat:@"[%@] Now sendsor data is uploading.", sensorName];
                NSLog(@"%@", message);
                return;
            }
            
            // check battery condition
            if (isSyncWithOnlyBatteryCharging && !isFource) {
                NSInteger batteryState = [UIDevice currentDevice].batteryState;
                if ( batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull) {
                }else{
                    NSLog(@"[%@] This device is not charginig battery now.", sensorName);
                    [self dataSyncIsFinishedCorrectly];
                    return;
                }
            }
            
            if (isSyncWithOnlyWifi && !isFource){
                NetworkStatus netStatus = [currentReachability currentReachabilityStatus];
                switch (netStatus) {
                    case NotReachable:
                        [self dataSyncIsFinishedCorrectly];
                        return;
                    case ReachableViaWWAN:
                        [self dataSyncIsFinishedCorrectly];
                        return;
                    default:
                        break;
                }
            }
            
            
            if (isFource){
                isManualUpload = YES;
            }
            
            // Get repititon time from CoreData in background.
            if([NSThread isMainThread]){
                // Make addtional thread
                [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                    [self setRepetationCountAfterStartToSyncDB:[self getTimeMark]];
                }];
            }else{
                [self setRepetationCountAfterStartToSyncDB:[self getTimeMark]];
            }
            isUploading = YES;
        }
    }];
}



/**
 * start sync db with timestamp
 * @discussion Please call this method in the background
 */
- (BOOL) setRepetationCountAfterStartToSyncDB:(NSNumber *) startTimestamp {

    @try {
        if (entityName == nil) {
            NSLog(@"***** ERROR: Entity Name is nil! *****");
            return NO;
        }
        
        if ([self isDBLock]) {
            [self dataSyncIsFinishedCorrectly];
            return NO;
        }else{
            [self lockDB];
        }
        
        NSFetchRequest* request = [[NSFetchRequest alloc] init];
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:self.mainQueueManagedObjectContext];
        NSString * entity = [entityName copy];
        
        [private performBlock:^{
            // NSLog(@"start time is ... %@",startTimestamp);
            [request setEntity:[NSEntityDescription entityForName:entity inManagedObjectContext:self.mainQueueManagedObjectContext]];
            [request setIncludesSubentities:NO];
            [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@", startTimestamp]];
            
            NSError* error = nil;
            // Get count of category
            NSInteger count = [private countForFetchRequest:request error:&error];
            NSLog(@"[%@] %ld records", [self getEntityName], count);
            if (count == NSNotFound) {
                [self dataSyncIsFinishedCorrectly];
                [self unlockDB]; // Unlock DB
                NSLog(@"[%@] There are no data in this database table",[self getEntityName]);
                return;
            } else if(error != nil){
                [self dataSyncIsFinishedCorrectly];
                [self unlockDB]; // Unlock DB
                NSLog(@"%@", error.description);
                count = 0;
                return;
            }
            // Set repetationCount
            currentRepetitionCounts = 0;
            repetitionTime = (int)count/(int)[self getFetchLimit];
            
            // set db condition as normal
            [self unlockDB]; // Unlock DB
            
            // start upload
            [self syncTask];
            
        }];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
        [self unlockDB]; // Unlock DB
        [self dataSyncIsFinishedCorrectly];
    } @finally {
        return YES;
    }
    
}


/**
 * Upload method
 */
- (void) syncTask{
    
    NSString *deviceId = [self getDeviceId];
    NSString *url = [self getInsertUrl:tableName];
    
    previousUploadingProcessFinishUnixTime = [self getTimeMark];
    
    if (cancel) {
        [self dataSyncIsFinishedCorrectly];
        return;
    }
    // NSLog(@"[%@] marker   end: %@", sensorName, [NSDate dateWithTimeIntervalSince1970:previousUploadingProcessFinishUnixTime.longLongValue/1000]);
    
    if ([self isDBLock]) {
        [self dataSyncIsFinishedCorrectly];
        [self performSelector:@selector(syncTask) withObject:nil afterDelay:1];
        // [self performSelector:@selector(saveDataToDB) withObject:nil afterDelay:1];
        return;
    }else{
        [self lockDB];
    }
    
    if(entityName == nil){
        NSLog(@"Entity Name is 'nil'. Please check the initialozation of this class.");
    }
    // set a repetation count
    currentRepetitionCounts++;
    
    @try {
        // NSLog(@"[pretime:%@] %@", sensorName, previousUploadingProcessFinishUnixTime);
        
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:self.mainQueueManagedObjectContext];
        [private performBlock:^{
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
            [fetchRequest setFetchLimit:[self getFetchLimit]]; // <-- set a fetch limit for this query
            [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:self.mainQueueManagedObjectContext]];
            [fetchRequest setIncludesSubentities:NO];
            [fetchRequest setResultType:NSDictionaryResultType];
            if([[self getEntityName] isEqualToString:@"EntityESMAnswerBC"] ||
               [[self getEntityName] isEqualToString:@"EntityESMAnswer"] ){
                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"double_esm_user_answer_timestamp >= %@",
                                            previousUploadingProcessFinishUnixTime]];
            }else{
                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@", previousUploadingProcessFinishUnixTime]];
            }

            //Set sort option
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
            NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
            [fetchRequest setSortDescriptors:sortDescriptors];
            
            
            //Get NSManagedObject from managedObjectContext by using fetch setting
            NSArray *results = [private executeFetchRequest:fetchRequest error:nil] ;
            // NSLog(@"%ld",results.count); //TODO
            
            [self unlockDB];
            
            if (results != nil) {
                if (results.count == 0 || results.count == NSNotFound) {
                    [self dataSyncIsFinishedCorrectly];
                    [self broadcastDBSyncEventWithProgress:@100 isFinish:@YES isSuccess:@YES sensorName:sensorName];
                    return;
                }else{
                    
                }
                
                // Save current timestamp as a maker
                NSDictionary * lastDict = [results lastObject];//[results objectAtIndex:results.count-1];
                tempLastUnixTimestamp = [lastDict objectForKey:@"timestamp"];
                if([[self getEntityName] isEqualToString:@"EntityESMAnswerBC"] ||
                   [[self getEntityName] isEqualToString:@"EntityESMAnswer"] ){
                    tempLastUnixTimestamp = [lastDict objectForKey:@"double_esm_user_answer_timestamp"];
                }
                if (tempLastUnixTimestamp == nil) {
                    tempLastUnixTimestamp = @0;
                }
                
                // Convert array to json data
                NSError * error = nil;
                NSData * jsonData = nil;
                @try {
                    jsonData = [NSJSONSerialization dataWithJSONObject:results options:0 error:&error];
                } @catch (NSException *exception) {
                    NSLog(@"[%@] %@",sensorName, exception.debugDescription);
                }
                
                if (error == nil && jsonData != nil) {
                    // Set HTTP/POST session on main thread
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ( jsonData.length == 0 || jsonData.length == 2 ) {
                            NSString * message = [NSString stringWithFormat:@"[%@] Data is Null or Length is Zero", sensorName];
                            NSLog(@"%@", message);
                            [self dataSyncIsFinishedCorrectly];
                            [self broadcastDBSyncEventWithProgress:@(100) isFinish:YES isSuccess:YES sensorName:sensorName];
                            return;
                        }
                        // Set session configuration
                        NSURLSessionConfiguration *sessionConfig = nil;
                        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:baseSyncDataQueryIdentifier];
                        sessionConfig.timeoutIntervalForRequest = 60;
                        sessionConfig.HTTPMaximumConnectionsPerHost = 60;
                        sessionConfig.timeoutIntervalForResource = 60;
                        sessionConfig.allowsCellularAccess = YES;
                        
                        
                        // set HTTP/POST body information
                        NSString* post = [NSString stringWithFormat:@"device_id=%@&data=", deviceId];
                        NSData* postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
                        NSMutableData * mutablePostData = [[NSMutableData alloc] initWithData:postData];
                        
                        // escape "&"s
                        if([[self getEntityName] isEqualToString:@"EntityESMAnswerBC"] ||
                           [[self getEntityName] isEqualToString:@"EntityESMAnswer"] ){
                            
                            NSString * jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                            // NSLog(@"%@", [self stringByAddingPercentEncodingForAWARE:jsonDataStr]);
                            [mutablePostData appendData:[[self stringByAddingPercentEncodingForAWARE:jsonDataStr] dataUsingEncoding:NSUTF8StringEncoding]];
                        }else{
                            [mutablePostData appendData:jsonData];
                        }
                        
                        
                        NSString* postLength = [NSString stringWithFormat:@"%ld", [mutablePostData length]];
                        NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
                        [request setURL:[NSURL URLWithString:url]];
                        [request setHTTPMethod:@"POST"];
                        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
                        [request setHTTPBody:mutablePostData];
                        
                        
                        NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                                              delegate:self
                                                                         delegateQueue:nil];
                        
                        NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
                        
                        httpStartTimestamp = [[NSDate new] timeIntervalSince1970];
                        // postedTextLength = [[NSNumber numberWithInteger:mutablePostData.length] doubleValue];
                        
                        if([[self getEntityName] isEqualToString:@"EntityOpenWeather"]){
                            
                            // NSLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
                            
                        } else if ([[self getEntityName] isEqualToString:@"EntityESMAnswer"]){
                            
                            // NSLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
                            
                        } else if ([[self getEntityName] isEqualToString:@"EntityESMAnswerBC"]){
                            
                            // NSLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
                        }
                        
                        [dataTask resume];
                    });
                }else{
                    NSLog(@"[Error] %@: %@", [self getEntityName], error.debugDescription);
                }
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
        [self dataSyncIsFinishedCorrectly];
        [self unlockDB];
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


/////////////////////////////////////////////////
/////////////////////////////////////////////////

/* The task has received a response and no further messages will be
 * received until the completion block is called. The disposition
 * allows you to cancel a request or to turn a data task into a
 * download task. This delegate message is optional - if you do not
 * implement it, you can get the response as a property of the task.
 *
 * This method will not be called for background upload tasks (which cannot be converted to download tasks).
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    
    completionHandler(NSURLSessionResponseAllow);
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    if ( responseCode == 200 ) {
        [session finishTasksAndInvalidate];
    } else {
        [session invalidateAndCancel];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    // show progress of upload
    NSLog(@"%@:%f%% (%d/%d)", entityName, (double)totalBytesSent/(double)totalBytesExpectedToSend*100.0f, currentRepetitionCounts, repetitionTime);
}


/* Sent when data is available for the delegate to consume.  It is
 * assumed that the delegate will retain and not copy the data.  As
 * the data may be discontiguous, you should use
 * [NSData enumerateByteRangesUsingBlock:] to access it.
 */
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    
    if (data != nil && receivedData != nil){
        [receivedData appendData:data];
    }
    // if ([session.configuration.identifier isEqualToString:syncDataQueryIdentifier]) {
    // If the data is null, this method is not called.
    // NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // NSLog(@"[%@] Data is coming! => %@", sensorName, result);
    // }
    
}

/////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    if (error != nil) {
        NSLog(@"[%@] the session did become invaild with error: %@", sensorName, error.debugDescription);
        [AWAREUtils sendLocalNotificationForMessage:error.debugDescription soundFlag:NO];
        [session invalidateAndCancel];
    }else{
        [session finishTasksAndInvalidate];
    }
}

//////////////////////////////////////////////
/////////////////////////////////////////////

/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error;
{
    // NSLog(@"didCompleteWithError:")
    NSNumber * progress = @(0);
    if (repetitionTime > 0) {
        progress = @((double)currentRepetitionCounts/(double)repetitionTime*100.0f);
    }
    
    if(isDebug){
        if (currentRepetitionCounts > repetitionTime) {
            [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"[%@] Finish to upload data",sensorName] soundFlag:NO];
        }else{
            [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"[%@] Success to upload sensor data to AWARE server with %@%@",sensorName,progress, @"%%"]  soundFlag:NO];
        }
    }
    // broad cast current progress of data upload!
    NSNumber *finish = @NO;
    if (currentRepetitionCounts > repetitionTime) {
        progress = @100;
        finish = @YES;
    }
    // NSNumber * progress = @((double)currentRepetitionCounts/(double)repetitionTime*100.0f);
    [self broadcastDBSyncEventWithProgress:progress isFinish:finish isSuccess:@YES sensorName:sensorName];
    // [self broadcastDBSyncEventWithProgress:progress isFinish:NO isSuccess:YES sensorName:sensorName];
    // Set TimeMark
    [self setTimeMarkWithTimestamp: tempLastUnixTimestamp];
    // NSLog(@"[setTimeMaker:%@] %@", sensorName, [NSDate dateWithTimeIntervalSince1970:tempLastUnixTimestamp.longLongValue/1000]);
    
    
    /** =========== Start next data upload =========== */
    if (currentRepetitionCounts > repetitionTime ){
        [self clearOldData];
        [self dataSyncIsFinishedCorrectly];
    }else{
        // Get main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            //https://developer.apple.com/library/ios/documentation/Performance/Conceptual/EnergyGuide-iOS/WorkLessInTheBackground.html#//apple_ref/doc/uid/TP40015243-CH22-SW1
//            if(isManualUpload){
            if([AWAREUtils isForeground]){
                [self performSelector:@selector(syncTask) withObject:nil afterDelay: 0.3 ];
            }else{
                float cpuUsage = [Processor getCpuUsage];
                // NSLog(@"[%@] CPU Usage:%0.2f %%", sensorName, cpuUsage);
                if(cpuUsage > cpuThreshold){
                    // https://developer.apple.com/library/content/documentation/Performance/Conceptual/EnergyGuide-iOS/WorkLessInTheBackground.html
                    NSString * logMsg = [NSString stringWithFormat:@"[%@] Over CPU Usage (%d%%) -> Stop Data Upload Process", sensorName, cpuThreshold];
                    NSLog(@"%@", logMsg);
                    // [ saveDebugEventWithText:logMsg type:DebugTypeWarn label:sensorName];
                    [self dataSyncIsFinishedCorrectly];
                    return;
                }
                // Make a long delay by each 10 upload process
                if (currentRepetitionCounts%thresholdForNextLongDelay == 0) {
                    [self performSelector:@selector(syncTask) withObject:nil afterDelay:longDelayForNextUpload];
                }else{
                    [self performSelector:@selector(syncTask) withObject:nil afterDelay:shortDelayForNextUpload];
                }
            }
        });
    }
    
    receivedData = [[NSMutableData alloc] init];
    
    return;
}

/**
 * init variables for data upload
 * @discussion This method is called when finish to data upload session
 */
- (void) dataSyncIsFinishedCorrectly {
    NSLog(@"[%@] Session task finished", sensorName);
    // set uploading state is NO
    isUploading = NO;
    isManualUpload = NO;
    cancel = NO;
    // init repetation time and current count
    repetitionTime = 0;
    currentRepetitionCounts = 0;
}

- (void) clearOldData{
    
    // if (lastSyncedTimestamp == nil) { return; }
    // NSDate * dateOfLastSyncedData = [[NSDate alloc] initWithTimeIntervalSince1970:lastSyncedTimestamp.doubleValue/1000];
    
    ////////
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:self.mainQueueManagedObjectContext]];
    [request setIncludesSubentities:NO];
    
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [private setParentContext:self.mainQueueManagedObjectContext];
    [private performBlock:^{
        
        cleanOldDataType cleanType = [awareStudy getCleanOldDataType];
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
            if(![self isDBLock]){
                [self lockDB];
                NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
                NSNumber * limitTimestamp = @0;
                if(clearLimitDate == nil){
                    limitTimestamp = tempLastUnixTimestamp;
                }else{
                    limitTimestamp = @([clearLimitDate timeIntervalSince1970]*1000);
                }
                
                if([[self getEntityName] isEqualToString:@"EntityESMAnswerBC"] ||
                   [[self getEntityName] isEqualToString:@"EntityESMAnswer"] ){
                    [request setPredicate:[NSPredicate predicateWithFormat:@"(double_esm_user_answer_timestamp <= %@)", limitTimestamp]];
                }else{
//                    NSPredicate *  expirePredicate = [NSPredicate predicateWithFormat:@"timestamp <= %@", limitTimestamp];
//                    NSPredicate * lastSyncPreciate = [NSPredicate predicateWithFormat:@"timestamp <= %@", tempLastUnixTimestamp];
//                    [request setPredicate: [NSCompoundPredicate andPredicateWithSubpredicates:@[expirePredicate, lastSyncPreciate]]];
                    // [request setPredicate:[NSPredicate predicateWithFormat:@"(timestamp <= %@ && timestamp <= %@)", limitTimestamp, tempLastUnixTimestamp]];
                     [request setPredicate:[NSPredicate predicateWithFormat:@"(timestamp <= %@)", limitTimestamp]];
                }
                
                NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
                NSError *deleteError = nil;
                [private executeRequest:delete error:&deleteError];
                if (deleteError != nil) {
                    NSLog(@"%@", deleteError.description);
                }else{
                    NSLog(@"[%@] Sucess to clear the data from DB (timestamp <= %@ )", sensorName, [NSDate dateWithTimeIntervalSince1970:limitTimestamp.longLongValue/1000]);
                }
                [self unlockDB];
            }
        }
    }];
}

/////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

/**
 * AWARE URL makers
 */
- (NSString *)getWebserviceUrl{
    NSString* url = [awareStudy getWebserviceServer];
    if (url == NULL || [url isEqualToString:@""]) {
        NSLog(@"[Error] You did not have a StudyID. Please check your study configuration.");
        return @"";
    }
    return url;
}


- (NSString *)getDeviceId{
    //    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    //    NSString* deviceId = [userDefaults objectForKey:KEY_MQTT_USERNAME];
    NSString * deviceId = [awareStudy getDeviceId];
    return deviceId;
}

- (NSString *)getInsertUrl:(NSString *)name{
    //    - insert: insert new data to the table
    return [NSString stringWithFormat:@"%@/%@/insert", [self getWebserviceUrl], name];
}


- (NSString *)getLatestDataUrl:(NSString *)name{
    //    - latest: returns the latest timestamp on the server, for synching what’s new on the phone
    return [NSString stringWithFormat:@"%@/%@/latest", [self getWebserviceUrl], name];
}


- (NSString *)getCreateTableUrl:(NSString *)name{
    //    - create_table: creates a table if it doesn’t exist already
    return [NSString stringWithFormat:@"%@/%@/create_table", [self getWebserviceUrl], name];
}


- (NSString *)getClearTableUrl:(NSString *)name{
    //    - clear_table: remove a specific device ID data from the database table
    return [NSString stringWithFormat:@"%@/%@/clear_table", [self getWebserviceUrl], name];
}





////////////////////////////////////
- (NSString *)getEntityName{
    return entityName;
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
        NSLog(@"===============[%@] timestamp is nil============================", sensorName);
        timestamp = @0;
    }
    // NSLog(@"[time_mark:%@] %@", sensorName, [NSDate dateWithTimeIntervalSince1970:timestamp.longLongValue/1000].debugDescription);
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

////

- (void) lockDB {
    isLock = YES;
    // NSLog(@"[%@] Lock DB", sensorName );
}

- (void) unlockDB {
    isLock = NO;
    // NSLog(@"[%@] Unlock DB", sensorName );
}

- (BOOL) isDBLock {
    if(isLock){
        if(isDebug) NSLog(@"[%@] DB is locked now", sensorName);
    }else{
        if(isDebug) NSLog(@"[%@] DB is available now", sensorName);
    }
    return isLock;
}

/////////////////////////

- (void) broadcastDBSyncEventWithProgress:(NSNumber *)progress
                                 isFinish:(BOOL)finish
                                isSuccess:(BOOL)success
                               sensorName:(NSString *)name{
    NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:progress forKey:@"KEY_UPLOAD_PROGRESS_STR"];
    [userInfo setObject:@(finish) forKey:@"KEY_UPLOAD_FIN"];
    [userInfo setObject:@(success) forKey:@"KEY_UPLOAD_SUCCESS"];
    [userInfo setObject:name forKey:@"KEY_UPLOAD_SENSOR_NAME"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
                                                        object:nil
                                                      userInfo:userInfo];
    
}

- (int) getFetchLimit{ return fetchLimit; }

- (void) cancelSyncProcess {
    cancel = YES;
}

- (void) resetMark {
    NSLog(@"reset a mark of sync process in a SQLite.");
    [self setTimeMarkWithTimestamp:@1];
    previousUploadingProcessFinishUnixTime = [self getTimeMark];
}

@end

