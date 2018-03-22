//
//  AWAREDataUploader.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/7/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREDataUploader.h"
#import "SCNetworkReachability.h"
#import "AWAREKeys.h"
#import "AWAREStudy.h"
#import "AWAREUtils.h"
#import "Processor.h"

@implementation AWAREDataUploader{
    NSString * sensorName;
    bool isUploading;
    int errorCount;
    LocalFileStorageHelper * awareLocalStorage;
    AWAREStudy * awareStudy;
    
    NSString * baseSyncDataQueryIdentifier;
    NSString * baseCreateTableQueryIdentifier;
    
    NSString * syncDataQueryIdentifier;
    NSString * createTableQueryIdentifier;
    
    double httpStart;
    double postLengthDouble;
    
    bool cancel;
    
    int currentRepetitionCounts;
    int shortDelayForNextUpload;
    int longDelayForNextUpload;
    int thresholdForNextLongDelay;
    int cpuThreshold;
    
}


- (instancetype)initWithLocalStorage:(LocalFileStorageHelper *)localStorage withAwareStudy:(AWAREStudy *) study {
    if (self = [super initWithAwareStudy:study sensorName:[localStorage getSensorName]]) {
        sensorName = [localStorage getSensorName];
        awareStudy = study;
        awareLocalStorage = localStorage;
        cancel = NO;
        isUploading = NO;
        errorCount = 0;
        shortDelayForNextUpload = 1; // second
        longDelayForNextUpload = 30; // second
        thresholdForNextLongDelay = 10; // count
        currentRepetitionCounts = 0;
        if (study != nil) {
            cpuThreshold = [study getCPUTheshold];
        }else{
            cpuThreshold = 50;
        }
        baseSyncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@", sensorName];
        baseCreateTableQueryIdentifier = [NSString stringWithFormat:@"create_table_query_identifier_%@",  sensorName];
        
        syncDataQueryIdentifier = baseSyncDataQueryIdentifier;
        createTableQueryIdentifier = baseCreateTableQueryIdentifier;
    }
    return self;
}


//////////////////////////////

- (NSData *)getCSVData{
    return [awareLocalStorage getCSVData];
}

/////////////////////////////////
/////////////////////////////////

- (bool)isUploading{
    return isUploading;
}

/**
 * Background data sync
 */
//- (void) syncAwareDB {
//    [self syncAwareDBWithSensorName:sensorName];
//}

- (void) syncAwareDBInBackground {
    [self syncAwareDBInBackgroundWithSensorName:sensorName];
}

- (void)syncAwareDBInBackgroundWithSensorName:(NSString *)name{
    [self syncAwareDBWithSensorName:name force:NO];
}

- (BOOL)syncAwareDBInForeground{
    return [self syncAwareDBInForegroundWithSensorName:sensorName];
}

- (BOOL) syncAwareDBInForegroundWithSensorName:(NSString *)name{
    [self syncAwareDBWithSensorName:name force:YES];
    return YES;
}
/** 
 * Background data sync with database name
 * @param NSString  A sensor name
 */
- (void) syncAwareDBWithSensorName:(NSString*) name force:(BOOL) force{
    
    if(isUploading){
        NSString * message= [NSString stringWithFormat:@"[%@] this ssenor is uploading data now.", name];
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeInfo  label:@""];
        return;
    }
    
    if(!force){
        // chekc wifi state
        if (![awareStudy isWifiReachable] && [self isSyncWithOnlyWifi]) {
            NSString * message = [NSString stringWithFormat:@"[%@] Wifi is not availabe.", name];
            NSLog(@"%@", message);
            [self saveDebugEventWithText:message type:DebugTypeInfo  label:@""];
            // [self dataSyncIsFinishedCorrectoly];
            return;
        }
    
        // check battery condition
        if ([self isSyncWithOnlyBatteryCharging]){//isSyncWithOnlyBatteryCharging) {
            NSInteger batteryState = [UIDevice currentDevice].batteryState;
            if ( batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull) {
            }else{
                NSString * message = [NSString stringWithFormat:@"[%@] This device is not charginig battery now.", name];
                NSLog(@"%@", message);
                [self saveDebugEventWithText:message type:DebugTypeInfo  label:name];
                return;
            }
        }
    }
    
    isUploading = YES;
    [self postSensorDataWithSensorName:sensorName];
}


/**
 * Upload method
 */
//- (void) postSensorDataWithSensorName:(NSString* )name session:(NSURLSession *)oursession {
- (void) postSensorDataWithSensorName:(NSString*)name{

    NSString *deviceId = [awareStudy getDeviceId];
    NSString *url = [self getInsertUrl:name];
    
    if (cancel){
        [self dataSyncIsFinishedCorrectly];
        return;
    }
    // NSLog(@"url: %@", url);
    
    NSMutableString* sensorData = [awareLocalStorage getSensorDataForPost];
    NSString* formatedSensorData = [awareLocalStorage fixJsonFormat:sensorData];
    
    if (sensorData.length == 0 || [sensorData isEqualToString:@"[]"]) {
        NSString * message = [NSString stringWithFormat:@"[%@] Data length is zero => %ld", sensorName, sensorData.length];
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeInfo  label:@""];
        [self dataSyncIsFinishedCorrectly];
        [awareLocalStorage resetMark];
        
        NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
        [userInfo setObject:@100 forKey:@"KEY_UPLOAD_PROGRESS_STR"];
        [userInfo setObject:@YES forKey:@"KEY_UPLOAD_FIN"];
        [userInfo setObject:@YES forKey:@"KEY_UPLOAD_SUCCESS"];
        [userInfo setObject:sensorName forKey:@"KEY_UPLOAD_SENSOR_NAME"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
                                                            object:nil
                                                          userInfo:userInfo];
        
        return;
    }
    
    // Set session configuration
    NSURLSessionConfiguration *sessionConfig = nil;
    // double unxtime = [[NSDate new] timeIntervalSince1970];
    syncDataQueryIdentifier = baseSyncDataQueryIdentifier; //[NSString stringWithFormat:@"%@%f", baseSyncDataQueryIdentifier, unxtime];
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:syncDataQueryIdentifier];
    sessionConfig.timeoutIntervalForRequest = 60;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60;
    sessionConfig.timeoutIntervalForResource = 60;
    sessionConfig.allowsCellularAccess = YES;
    
    NSString * percentEncodedValues = [AWAREUtils stringByAddingPercentEncoding:formatedSensorData unreserved:@""];
    
    // set HTTP/POST body information
    NSString* post = [NSString stringWithFormat:@"device_id=%@&data=%@", deviceId, percentEncodedValues];
    NSData* postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString* postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    //    NSLog(@"Data Length: %@", postLength);
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSString * logMessage = [NSString stringWithFormat:@"[%@] This is background task for upload sensor data", sensorName];
    NSLog(@"%@", logMessage);
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];

    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    
    httpStart = [[NSDate new] timeIntervalSince1970];
    postLengthDouble = [[NSNumber numberWithInteger:postData.length] doubleValue];
    [self saveDebugEventWithText:logMessage type:DebugTypeInfo  label:syncDataQueryIdentifier];
    
    [dataTask resume];
}



- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    // test: server peformance
    double diff = [[NSDate new] timeIntervalSince1970] - httpStart;
    if (postLengthDouble > 0 && diff > 0) {
        NSString *networkPeformance = [NSString stringWithFormat:@"%0.2f KB/s",postLengthDouble/diff/1000.0f];
        NSLog(@"[%@] %@", sensorName, networkPeformance);
        [self saveDebugEventWithText:networkPeformance type:DebugTypeInfo label:sensorName];
    }
    
    completionHandler(NSURLSessionResponseAllow);
   
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    if (responseCode == 200) {
        [session finishTasksAndInvalidate];
    }else{
        [session invalidateAndCancel];
    }
}


-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    
    if ([session.configuration.identifier isEqualToString:syncDataQueryIdentifier]) {
        // If the data is null, this method is not called.
        NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"[%@] Data is coming! => %@", sensorName, result);
    } else if ([session.configuration.identifier isEqualToString:createTableQueryIdentifier]){
        NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"[%@] %@",sensorName, newStr);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    

    if ([session.configuration.identifier isEqualToString:syncDataQueryIdentifier]) {
        if (!error) {
            NSLog(@"[%@] Upload Succeed!", sensorName);
            // [self receivedResponseFromServer:task.response withData:nil error:nil];
            [self checkNextUpload];
        } else {
            NSString * log = [NSString stringWithFormat:@"[%@] Session task is finished with error (%d). %@", sensorName, [awareLocalStorage getMarker], error.debugDescription];
            [self saveDebugEventWithText:log type:DebugTypeError label:syncDataQueryIdentifier];
            NSLog(@"%@",log);
            
            if (errorCount < 3){
                errorCount++;
                [self postSensorDataWithSensorName:sensorName];
            }else{
                [self dataSyncIsFinishedCorrectly];
                NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setObject:@(-1) forKey:@"KEY_UPLOAD_PROGRESS_STR"];
                [userInfo setObject:@YES forKey:@"KEY_UPLOAD_FIN"];
                [userInfo setObject:@NO forKey:@"KEY_UPLOAD_SUCCESS"];
                [userInfo setObject:sensorName forKey:@"KEY_UPLOAD_SENSOR_NAME"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
                                                                    object:nil
                                                                  userInfo:userInfo];
            }
        }
    } else if ([session.configuration.identifier isEqualToString:createTableQueryIdentifier]){

    }
}


- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    if (error != nil) {
        NSLog(@"[%@] the session did become invaild with error: %@", sensorName, error.debugDescription);
        [AWAREUtils sendLocalNotificationForMessage:error.debugDescription soundFlag:NO];
    }
    // NSLog(@"%@", sensorName);
    // [session invalidateAndCancel];
    // [self dataSyncIsFinishedCorrectoly];
}


- (void)checkNextUpload{
    
    [awareLocalStorage setNextMark];
    NSString *bytes = [self getFileStrSize:(double)[awareLocalStorage getFileSize]];
    NSString *message = @"";
    
    if( [awareLocalStorage getMarker] == 0 ){
        // success to upload data
        message = [NSString stringWithFormat:@"[%@] Sucess to upload sensor data to AWARE server with %@", sensorName, bytes];
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeInfo label:syncDataQueryIdentifier];
        
        // send notification
        if ([self isDebug]) [AWAREUtils sendLocalNotificationForMessage:message soundFlag:NO];
        
        // remove store data
        [awareLocalStorage clearFile:sensorName];
        [self saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Remove stored data", sensorName]
                                type:DebugTypeInfo
                               label:syncDataQueryIdentifier];
        // init http/post condition
        [self dataSyncIsFinishedCorrectly];
        
        NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
        [userInfo setObject:@100 forKey:@"KEY_UPLOAD_PROGRESS_STR"];
        [userInfo setObject:@YES forKey:@"KEY_UPLOAD_FIN"];
        [userInfo setObject:@YES forKey:@"KEY_UPLOAD_SUCCESS"];
        [userInfo setObject:sensorName forKey:@"KEY_UPLOAD_SENSOR_NAME"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
                                                            object:nil
                                                          userInfo:userInfo];
        
    } else {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger length = [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
        long denominator = (long)[awareLocalStorage getFileSize]/(long)length;
        
        NSString* formatedLength = [self getFileStrSize:(double)length];
        
        message = [NSString stringWithFormat:@"[%@] Sucess to upload sensor data to AWARE server with %@ - %d/%ld", sensorName, formatedLength, [awareLocalStorage getMarker], denominator];
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeInfo label:syncDataQueryIdentifier];
        
        // send notification
        if ([self isDebug]) [AWAREUtils sendLocalNotificationForMessage:message soundFlag:NO];
        
        // upload sensor data again
        [self saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Upload stored data again", sensorName]
                                type:DebugTypeInfo
                               label:syncDataQueryIdentifier];
        
        // [self postSensorDataWithSensorName:sensorName];
        currentRepetitionCounts++;
        // Get main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            //https://developer.apple.com/library/ios/documentation/Performance/Conceptual/EnergyGuide-iOS/WorkLessInTheBackground.html#//apple_ref/doc/uid/TP40015243-CH22-SW1
            if([AWAREUtils isForeground]){
                [self performSelector:@selector(postSensorDataWithSensorName:) withObject:sensorName afterDelay:0.3];
            }else{

                float cpuUsage = [Processor getCpuUsage];
                // NSLog(@"[%@] CPU Usage:%0.2f %%", sensorName, cpuUsage);
                if(cpuUsage > cpuThreshold){
                    // https://developer.apple.com/library/content/documentation/Performance/Conceptual/EnergyGuide-iOS/WorkLessInTheBackground.html
                    NSString * logMsg = [NSString stringWithFormat:@"[%@] Over CPU Usage (%d%%) -> Stop Data Upload Process", sensorName, cpuThreshold];
                    NSLog(@"%@", logMsg);
                    [self saveDebugEventWithText:logMsg type:DebugTypeWarn label:sensorName];
                    [self dataSyncIsFinishedCorrectly];
                    return;
                }
                
                // Make a long delay by each 10 upload process
                if ([self isNeedLongBreak]) {
                    [self performSelector:@selector(postSensorDataWithSensorName:) withObject:sensorName afterDelay:longDelayForNextUpload];
                }else{
                    [self performSelector:@selector(postSensorDataWithSensorName:) withObject:sensorName afterDelay:shortDelayForNextUpload];
                }
            }
        });
        
        
        double progress = [awareLocalStorage getMarker]/(double)denominator*100;
        if(progress>100){
            progress = 100;
        }
        
        NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
        [userInfo setObject:@(progress) forKey:@"KEY_UPLOAD_PROGRESS_STR"];
        [userInfo setObject:@YES forKey:@"KEY_UPLOAD_FIN"];
        [userInfo setObject:@YES forKey:@"KEY_UPLOAD_SUCCESS"];
        [userInfo setObject:sensorName forKey:@"KEY_UPLOAD_SENSOR_NAME"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
                                                            object:nil
                                                          userInfo:userInfo];
    }
}

- (bool) isNeedLongBreak{
    if (currentRepetitionCounts%thresholdForNextLongDelay == 0) {
        NSLog(@"[%@] long break", sensorName);
        return YES;
    }else{
        NSLog(@"[%@] short break", sensorName);
        return NO;
    }
}

- (void) dataSyncIsFinishedCorrectly {
    isUploading = NO;
    cancel = NO;
    currentRepetitionCounts = 0;
    NSLog(@"[%@] Session task finished correctly.", sensorName);
//    errorPosts = 0;
    errorCount = 0;
}

- (bool)foregroundSyncRequestWithSensorName:(NSString * )name{
    // init variables
    NSString *deviceId = [awareStudy getDeviceId];
    NSString *url = [self getInsertUrl:name];
    NSError *error = nil;
    int responseCode = 0;
    NSString* newStr = @"";
    
    @autoreleasepool {
        // Get sensor data
        NSMutableString* sensorData = [awareLocalStorage getSensorDataForPost];
        sensorData = [awareLocalStorage fixJsonFormat:sensorData];
        
        if (sensorData.length == 0 || sensorData.length == 2) {
            NSString * message = [NSString stringWithFormat:@"[%@] Data length is zero => %ld", name, sensorData.length ];
            NSLog(@"%@", message);
            [self saveDebugEventWithText:message type:DebugTypeInfo label:@""];
            [awareLocalStorage resetMark];
            return YES;
        }
        NSString * message = [NSString stringWithFormat:@"[%@] Start sensor data upload in the foreground => %ld", name, sensorData.length ];
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeInfo label:@""];
        
        NSString *post = [NSString stringWithFormat:@"device_id=%@&data=%@", deviceId, sensorData];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:url]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:postData];
        [request setTimeoutInterval:60*3];
        request.allowsCellularAccess = YES;
        
        NSHTTPURLResponse *response = nil;
        NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response error:&error];
        newStr = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
        responseCode = (int)[response statusCode];
        
        post = nil;
        postData = nil;
        postLength = nil;
        request = nil;
        response = nil;
        sensorData = nil;
    }

    if(responseCode == 200){
        NSLog(@"Success to upload the data: %@", newStr);
        [awareLocalStorage setNextMark];
        return YES;
    }else{
        return NO;
    }
}

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/**
 * Sync with AWARE database
 */
- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary {
    // init variables
    NSString *deviceId = [awareStudy getDeviceId];
    NSError *error = nil;
    NSData*d=[NSJSONSerialization dataWithJSONObject:dictionary options:2 error:&error];
    NSString* jsonstr = [[NSString alloc] init];
    if (!error) {
        jsonstr = [[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];
    } else {
        NSString * errorStr = [NSString stringWithFormat:@"[%@] %@", sensorName, [error localizedDescription]];
        [AWAREUtils sendLocalNotificationForMessage:errorStr soundFlag:YES];
        return NO;
    }
    NSString *post = [NSString stringWithFormat:@"device_id=%@&data=%@", deviceId, jsonstr];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *url = [self getInsertUrl:sensorName];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    [request setAllowsCellularAccess:YES];
    //NSData *resData = [NSURLConnection sendSynchronousRequest:request
    //                                        returningResponse:&response error:&error];
    // NSString* newStr = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSession sharedSession].configuration
                                                          delegate:self
                                                     delegateQueue:nil];
    dispatch_semaphore_t    sem;
    __block NSData *        result;
    __block NSURLResponse * response;
    
    result = nil;
    
    sem = dispatch_semaphore_create(0);
    
    [[session dataTaskWithRequest: request  completionHandler: ^(NSData *data, NSURLResponse *sessionResponse, NSError *sessionError) {
        // Success
        if (error != nil) {
            NSLog(@"Error: %@", sessionError.debugDescription);
        }else{
            NSLog(@"Success: %@", [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding]);
            result = data;
        }
        
        response = sessionResponse;
        
        [session finishTasksAndInvalidate];
        // [session invalidateAndCancel];
        
        dispatch_semaphore_signal(sem);
        
    }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    // NSLog(@"response status code: %ld", (long)[httpResponse statusCode]);
    
    int responseCode = (int)[httpResponse statusCode];
    if(responseCode == 200){
        // NSLog(@"Success to upload the data: %@", [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding]);
        return YES;
    }else{
       return NO;
    }
}


/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/**
 * Get progress
 */
- (NSString *)  getSyncProgressAsText {
    return [self getSyncProgressAsText:sensorName];
}

- (NSString *) getSyncProgressAsText:(NSString *)name {
    double fileSize = [awareLocalStorage getFileSizeWithName:name];
    NSString *bytes = [self getFileStrSize:fileSize];
    return [NSString stringWithFormat:@"(%@)",bytes];
}

- (NSString *) getFileStrSize:(double)size{
    NSString *bytes = @"";
    if (size >= 1000*1000) { //MB
        bytes = [NSString stringWithFormat:@"%.2f MB", size /(double)(1000*1000)];
    } else if (size >= 1000) { //KB
        bytes = [NSString stringWithFormat:@"%.2f KB", size /(double)1000];
    } else if (size < 1000) {
        bytes = [NSString stringWithFormat:@"%d Bytes", (int)size ];
    } else {
        bytes = [NSString stringWithFormat:@"%d Bytes", (int)size ];
    }
    return [NSString stringWithFormat:@"%@",bytes];
}


////////////////////////////////////////////
////////////////////////////////////////////
/**
 * Create Table Methods
 */

- (void) createTable:(NSString*) query {
    [self createTable:query withTableName:sensorName];
}

- (void) createTable:(NSString *)query withTableName:(NSString*) tableName {
    NSString *post = nil;
    NSData *postData = nil;
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
//    NSURLSession *session = nil;
    NSString *postLength = nil;
    NSURLSessionConfiguration *sessionConfig = nil;
    
    // Make a post query for creating a table
    post = [NSString stringWithFormat:@"device_id=%@&fields=%@", [awareStudy getDeviceId], query];
    postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[self getCreateTableUrl:tableName]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    // Generate an unique identifier for background HTTP/POST on iOS
    // double unxtime = [[NSDate new] timeIntervalSince1970];
    // createTableQueryIdentifier = [NSString stringWithFormat:@"%@%f", baseCreateTableQueryIdentifier, unxtime];
    createTableQueryIdentifier = [NSString stringWithFormat:@"%@", baseCreateTableQueryIdentifier];
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:createTableQueryIdentifier];
    sessionConfig.timeoutIntervalForRequest = 180.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60;
    sessionConfig.timeoutIntervalForResource = 60;
    sessionConfig.allowsCellularAccess = YES;
//    sessionConfig.discretionary = YES;
    
    NSString * debugMessage = [NSString stringWithFormat:@"[%@] Sent a query for creating a table in the background", sensorName];
    [self saveDebugEventWithText:debugMessage type:DebugTypeInfo label:@""];
    session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
}



/**
 * WIP:
 */
- (BOOL)clearTable{
    return NO;
}

- (void) cancelSyncProcess{
    cancel = true;
}

- (void) resetMark{
    NSLog(@"reset a mark of sync process in a text-based DB.");
    [awareLocalStorage resetMark];
}

@end
