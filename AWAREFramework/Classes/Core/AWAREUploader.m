//
//  AWAREUploader.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREUploader.h"
#import "AWAREStudy.h"
#import "AWAREDebugMessageLogger.h"
#import "AWAREKeys.h"

@implementation AWAREUploader{
    // study
    AWAREStudy * awareStudy;
    NSString *sensorName;
    // debug
    // Debug * debugSensor;
    AWAREDebugMessageLogger * dmLogger;
    // settings
    BOOL isDebug;
    BOOL isSyncWithOnlyBatteryCharging;
    BOOL isSyncWithWifiOnly;
    BOOL isUploading;
    BOOL isLock;
    
    // for CoreData
    int fetchLimit;
    int batchSize;
    int bufferSize;
    
    NSArray * csvHeader;
}

- (instancetype) initWithAwareStudy:(AWAREStudy *)study sensorName:(NSString *)name{
    self = [self init];
    if(self != nil){
        awareStudy = study;
        sensorName = name;
        
        fetchLimit = (int)[study getMaxFetchSize];
        batchSize = 0;
        bufferSize = 0;
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        isDebug = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        isSyncWithOnlyBatteryCharging  = [userDefaults boolForKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
        isSyncWithWifiOnly = [userDefaults boolForKey:SETTING_SYNC_WIFI_ONLY];
        
        isLock = NO;
    }
    return self;
}

/////////////////////////////////////////////////

- (void) setCSVHeader:(NSArray *) headers {
    csvHeader = headers;
}

- (NSArray *) getCSVHeader{
    return csvHeader;
}

////////////////////////////////////////////////////////////////
/**
 * Settings
 */
- (bool) isUploading { return isUploading; }

- (void) setUploadingState:(bool)state{ isUploading = state; }

/////////////
//- (void) lockBackgroundUpload{ isLock = YES; }
//
//- (void) unlockBackgroundUpload{ isLock = NO; }

- (void) lockDB {
    isLock = YES;
    if([self isDebug])
        NSLog(@"[%@] Lock DB", sensorName );
}

- (void) unlockDB {
    isLock = NO;
    if([self isDebug])
        NSLog(@"[%@] Unlock DB", sensorName );
}

- (BOOL) isDBLock {
    if(isLock){
        if([self isDebug])
            NSLog(@"[%@] DB is locked now", sensorName);
    }else{
        if([self isDebug])
            NSLog(@"[%@] DB is available now", sensorName);
    }
    return isLock;
}

/////////
- (void) allowsCellularAccess{ isSyncWithWifiOnly = NO; }

- (void) forbidCellularAccess{ isSyncWithWifiOnly = YES; }

////////
- (void) allowsDateUploadWithoutBatteryCharging{ isSyncWithOnlyBatteryCharging = NO; }

- (void) forbidDatauploadWithoutBatteryCharging{ isSyncWithOnlyBatteryCharging = YES; }

//////////////////////////////////////////////////
- (bool) isDebug { return isDebug; }

- (void) setDebugState:(bool)state{
    isDebug = state;
}

- (bool) isSyncWithOnlyWifi {return isSyncWithWifiOnly;}

- (bool) isSyncWithOnlyBatteryCharging { return isSyncWithOnlyBatteryCharging;}

///////////////////////////////////////////////////////////////////

- (void) setBufferSize:(int)size{bufferSize=size;}

- (void)setFetchLimit:(int)limit{ fetchLimit = limit; }

- (void)setFetchBatchSize:(int)size{ batchSize = size; }

- (int) getBufferSize{return bufferSize;}

- (int) getFetchLimit{ return fetchLimit; }

- (int) getFetchBatchSize{ return batchSize; }


- (bool) saveDataToDB{
    NSLog(@"[NOTE] Please overwrite this method (-saveDataToDB)");
    return NO;
}

//////////////////////////////////

- (void) syncAwareDBInBackground{
    NSLog(@"[NOTE] Please overwrite this method (-syncAwareDBInBackground)");
}

- (void) syncAwareDBInBackgroundWithSensorName:(NSString*) name{
    NSLog(@"[NOTE] Please overwrite this method (-syncAwareDBInBackgroundWithSensorName:)");
}


- (void) postSensorDataWithSensorName:(NSString*) name session:(NSURLSession *)oursession{
    NSLog(@"[NOTE] Please overwrite this method (-postSensorDataWithSensorName:session)");
}

////////////////////////////////////////////////////////////////////

- (BOOL) syncAwareDBInForeground{
    return [self syncAwareDBInForegroundWithSensorName:sensorName];
}

- (BOOL) syncAwareDBInForegroundWithSensorName:(NSString*) name{
    [self syncAwareDBInBackgroundWithSensorName:name];
    return NO;
}

- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary{
     NSLog(@"[NOTE] Please overwrite this method (-syncAwareDBWithData:)");
    return NO;
}

- (NSData *)getCSVData{
    return nil;
}

////////////////////////////////////////////////////////////////////////
- (NSString *) getSyncProgressAsText{
    return @"";
}

- (NSString *) getSyncProgressAsText:(NSString *)sensorName{
    return @"";
}


////////////////////////////////////////////////////////////////////////

- (void) createTable:(NSString*) query{
    [self createTable:query withTableName:sensorName];
}

- (void) createTable:(NSString *)query withTableName:(NSString*) tableName{
    NSLog(@"[NOTE] Please overwrite this method (createTable:query:withTableName)");
}

- (BOOL) clearTable{
    NSLog(@"[NOTE] Please overwrite this method (createTable)");
    return NO;
}


/////////////////////////////////////////////////////////////////////////

- (NSData *) getLatestData {
    return [self getLatestSensorData:[self getDeviceId] withUrl:[self getLatestDataUrl:sensorName]];
}

/**
 * Get latest sensor data method
 */
- (NSData *)getLatestSensorData:(NSString *)deviceId withUrl:(NSString *)url{
    // https://forums.developer.apple.com/thread/11519
    /*
    NSString *post = [NSString stringWithFormat:@"device_id=%@", deviceId];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                            returningResponse:&response error:&error];

    return resData;
    */
    NSString *post = [NSString stringWithFormat:@"device_id=%@", deviceId];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSession sharedSession].configuration
                                                          delegate:self
                                                     delegateQueue:nil];
    dispatch_semaphore_t    sem;
    __block NSData *        result;
    
    result = nil;
    
    sem = dispatch_semaphore_create(0);
    
    [[session dataTaskWithRequest: request  completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
        // Success
        if (error != nil) {
            NSLog(@"Error: %@", error.debugDescription);
        }else{
            NSLog(@"Success: %@", [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding]);
            result = data;
        }
        
        [session finishTasksAndInvalidate];
        [session invalidateAndCancel];
        
        dispatch_semaphore_signal(sem);
        
    }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);  
    
    return result;
    
    
    
}

/////////////////////////////////////////////////////////////////////////////////

/**
 * Return current network condition with a text
 */
- (NSString *) getNetworkReachabilityAsText{
    return [awareStudy getNetworkReachabilityAsText];
}


/** /////////////////////////////////////////////////////////
 * makers
 * /////////////////////////////////////////////////////////
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


/** ////////////////////////////////////////////////////
 * Set Debug Sensor
 * //////////////////////////////////////////////////////
 */
- (BOOL) trackDebugEvents {
    if(awareStudy != nil){
        dmLogger = [[AWAREDebugMessageLogger alloc] initWithAwareStudy:awareStudy];
        return YES;
    }else{
        NSLog(@"AWAREStudy variable is nil");
        return NO;
    }
}


/* //////////////////////////////////////////////////////////////
 * A wrapper method for Debug Message Tracker
 * //////////////////////////////////////////////////////////////
 */

- (BOOL)saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *)label{
    if (dmLogger != nil) {
        [dmLogger saveDebugEventWithText:eventText type:type label:label];
    } else {
        // NSLog(@"AWAREDebugMessageLogger is nil");
        if([self trackDebugEvents]){
            [dmLogger saveDebugEventWithText:eventText type:type label:label];
        }else{
            return NO;
        }
    }
    return YES;
}




/**
 * /////////////////////////////////////////////////////////
 *  Broadcast CoreData(insert/fetch/delete) and data upload events
 * /////////////////////////////////////////////////////////
 */
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


///////////////////////////////////////////////////////////////////
-  (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
  completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                              NSURLCredential * _Nullable credential)) completionHandler{
    // http://stackoverflow.com/questions/19507207/how-do-i-accept-a-self-signed-ssl-certificate-using-ios-7s-nsurlsession-and-its
    
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        
        NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
        SecTrustRef trust = [protectionSpace serverTrust];
        NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
        
        // NSArray *certs = [[NSArray alloc] initWithObjects:(id)[[self class] sslCertificate], nil];
        // int err = SecTrustSetAnchorCertificates(trust, (CFArrayRef)certs);
        // SecTrustResultType trustResult = 0;
        // if (err == noErr) {
        //    err = SecTrustEvaluate(trust, &trustResult);
        // }
        
        // if ([challenge.protectionSpace.host isEqualToString:@"aware.ht.sfc.keio.ac.jp"]) {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // } else if ([challenge.protectionSpace.host isEqualToString:@"r2d2.hcii.cs.cmu.edu"]) {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // } else if ([challenge.protectionSpace.host isEqualToString:@"api.awareframework.com"]) {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // } else {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // }
        
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSLog(@"*** [%@] Please overwrite -URLSession:dataTask:didReceiveResponse:completionHandler: ***",session.configuration.identifier);
    completionHandler(NSURLSessionResponseAllow);
    [session invalidateAndCancel];
    
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    // NSLog(@"*** [%@] Please overwrite -URLSession:dataTask:bytesSent:totalBytesSent:totalBytesExpectedToSend ***", session.configuration.identifier);
    NSLog(@"[%@] %.2f%%",session.configuration.identifier, (double)totalBytesSent/(double)totalBytesExpectedToSend*100.0f);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    NSLog(@"*** [%@] Please overwrite -URLSession:dataTask:didReceivedData ***",session.configuration.identifier);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error{
     NSLog(@"*** [%@] Please overwrite -URLSession:task:didReceivedData ***",session.configuration.identifier);
    if (error != nil) {
        NSLog(@"%@",error.debugDescription);
    }
}

- (void) cancelSyncProcess {
    NSLog(@"*** Please overwrite -cancelSyncProcess!!! ***");
}

- (void) resetMark {
    NSLog(@"*** Please overwrite -cancelSyncProcess!!! ***");
}

@end
