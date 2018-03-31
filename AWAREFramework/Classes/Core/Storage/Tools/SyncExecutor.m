//
//  SyncExecutor.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import "SyncExecutor.h"

@implementation SyncExecutor{
    AWAREStudy * awareStudy;
    NSString * sensorName;
    NSMutableData * receivedData;
    NSString * baseSyncDataQueryIdentifier;
    bool isSyncing;
    SyncExecutorCallBack executorCallback;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study sensorName:(NSString *)name{
    self = [super init];
    if (self != nil) {
        awareStudy = study;
        sensorName = name;
        _timeoutIntervalForRequest = 60;
        _HTTPMaximumConnectionsPerHost = 60;
        _timeoutIntervalForResource = 60;
        baseSyncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@",sensorName];
        isSyncing = NO;
        
        // Set session configuration
        NSURLSessionConfiguration *sessionConfig = nil;
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:baseSyncDataQueryIdentifier];
        sessionConfig.timeoutIntervalForRequest = _timeoutIntervalForRequest;
        sessionConfig.HTTPMaximumConnectionsPerHost = _HTTPMaximumConnectionsPerHost;
        sessionConfig.timeoutIntervalForResource = _timeoutIntervalForResource;
        sessionConfig.allowsCellularAccess = YES;
        
        
        _session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                              delegate:self
                                                         delegateQueue:nil];
        
    }
    return self;
}

- (void)syncWithData:(NSData *)data callback:(SyncExecutorCallBack)callback{
    
    if (isSyncing) {
        NSLog(@"[%@] still in a sync process", sensorName);
        return;
    }
    
    executorCallback = callback;
    
    receivedData = [[NSMutableData alloc] init];
    
    NSString *deviceId = [self getDeviceId];
    NSString *url = [self getInsertUrl:sensorName];

    // set HTTP/POST body information
    NSString* post = [NSString stringWithFormat:@"device_id=%@&data=", deviceId];
    NSData* postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSMutableData * mutablePostData = [[NSMutableData alloc] initWithData:postData];
    [mutablePostData appendData:data]; // <-- this data should be JSON format
    NSString* postLength = [NSString stringWithFormat:@"%ld", [mutablePostData length]];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:mutablePostData];

    
    // Set session configuration
    NSURLSessionConfiguration *sessionConfig = nil;
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:baseSyncDataQueryIdentifier];
    sessionConfig.timeoutIntervalForRequest = _timeoutIntervalForRequest;
    sessionConfig.HTTPMaximumConnectionsPerHost = _HTTPMaximumConnectionsPerHost;
    sessionConfig.timeoutIntervalForResource = _timeoutIntervalForResource;
    sessionConfig.allowsCellularAccess = YES;
    
    _session = [NSURLSession sessionWithConfiguration:sessionConfig
                                             delegate:self
                                        delegateQueue:nil];
    
    NSURLSessionDataTask* dataTask = [_session dataTaskWithRequest:request];

    [dataTask resume];
    
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
    NSLog(@"%@:%f%%", sensorName, (double)totalBytesSent/(double)totalBytesExpectedToSend*100.0f);
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
    
}

/////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    if (error != nil) {
        NSLog(@"[%@] the session did become invaild with error: %@", sensorName, error.debugDescription);
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
    receivedData = [[NSMutableData alloc] init];
    isSyncing = NO;
    if (error!=nil) {
        [self broadcastDBSyncEventWithProgress:@(-1) isFinish:NO isSuccess:NO sensorName:sensorName];
        NSLog(@"[%@] Error: %@", sensorName, error.debugDescription);
        executorCallback(@{@"result":@(NO),@"name":sensorName,@"error":error.debugDescription});
    }else{
        [self broadcastDBSyncEventWithProgress:@100 isFinish:YES isSuccess:YES sensorName:sensorName];
        executorCallback(@{@"result":@(YES),@"name":sensorName});
    }
}


///////////////////////////////////////////

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


- (BOOL) isSyncing{
    return isSyncing;
}

@end
