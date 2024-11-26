//
//  SyncExecutor.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import "SyncExecutor.h"
#import "AWAREURLSessionManager.h"

@implementation SyncExecutor{
    AWAREStudy * awareStudy;
    NSString * sensorName;
    NSMutableData * receivedData;
    NSString * baseSyncDataQueryIdentifier;
    bool isSyncing;
}

@synthesize debug;
@synthesize executorCallback;
@synthesize session;
@synthesize dataTask;

- (instancetype)initWithAwareStudy:(AWAREStudy *)study sensorName:(NSString *)name{
    self = [super init];
    if (self != nil) {
        awareStudy = study;
        sensorName = name;
        _timeoutIntervalForRequest  = 60;
        _maximumConnectionsPerHost = 60;
        _timeoutIntervalForResource = 60;
        baseSyncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@",sensorName];
        isSyncing = NO;
        debug     = [study isDebug];
        
        // Set session configuration
        NSURLSessionConfiguration *sessionConfig = nil;
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:baseSyncDataQueryIdentifier];
        sessionConfig.sharedContainerIdentifier     = @"com.awareframework.sync.task.identifier";
        sessionConfig.timeoutIntervalForRequest     = _timeoutIntervalForRequest;
        sessionConfig.HTTPMaximumConnectionsPerHost = _maximumConnectionsPerHost;
        sessionConfig.timeoutIntervalForResource    = _timeoutIntervalForResource;
        sessionConfig.allowsCellularAccess          = YES;
        
//        session = [AWAREURLSessionManager.shared getURLSession:baseSyncDataQueryIdentifier];
//        if (session == nil) {
        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
//            [AWAREURLSessionManager.shared addURLSession:session];
//        }
    }
    return self;
}

- (void)syncWithData:(NSData *)data callback:(SyncExecutorCallback)callback{
    
    NSString * baseURL = [self getWebserviceUrl];
    if (baseURL == nil || [baseURL isEqualToString:@""]) {
        NSLog(@"[%@] The base URL is null", sensorName);
        return;
    }
    
    if (isSyncing) {
        NSLog(@"[%@] still in a sync process", sensorName);
        return;
    }else{
        isSyncing = true;
    }
    
    executorCallback = callback;
    
    receivedData = [[NSMutableData alloc] init];
    
    NSString *deviceId = [self getDeviceId];
    NSString *url      = [self getInsertUrl:sensorName];

    // set HTTP/POST body information
    NSString* post = [NSString stringWithFormat:@"device_id=%@&data=", deviceId];
    NSData* postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSMutableData * mutablePostData = [[NSMutableData alloc] initWithData:postData];
    [mutablePostData appendData:data]; // <-- this data should be JSON format
    NSString* postLength = [NSString stringWithFormat:@"%tu", [mutablePostData length]];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:mutablePostData];
    
//    NSLog(@"%@", [[NSString alloc] initWithData:mutablePostData encoding:NSUTF8StringEncoding]);

    session.configuration.timeoutIntervalForRequest     = _timeoutIntervalForRequest;
    session.configuration.HTTPMaximumConnectionsPerHost = _maximumConnectionsPerHost;
    session.configuration.timeoutIntervalForResource    = _timeoutIntervalForResource;
    session.configuration.allowsCellularAccess = YES;
    
    dataTask = [session dataTaskWithRequest:request];
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
//- (void)URLSession:(NSURLSession *)session
//          dataTask:(NSURLSessionDataTask *)dataTask
//didReceiveResponse:(NSURLResponse *)response
// completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
//    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
//    int responseCode = (int)[httpResponse statusCode];
//    if ( responseCode == 200 ) {
//        completionHandler(NSURLSessionResponseAllow);
//    } else {
//
//    }
//}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    // show progress of upload
    if (debug) {
        NSLog(@"[%@] ---> %3.2f%%", sensorName, (double)totalBytesSent/(double)totalBytesExpectedToSend*100.0f);
    }
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
    if (debug) {
        if (error != nil) {
            NSLog(@"[%@] URLSession:didBecomeInvalidWithError: %@", sensorName, error.debugDescription);
        }else{
            NSLog(@"[%@] URLSession:didBecomeInvalid", sensorName);
        }
    }
}

//////////////////////////////////////////////
/////////////////////////////////////////////

/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (debug) {
        if (error!=nil) {
            NSLog(@"[%@] URLSession:task:didCompleteWithError: %@", sensorName, error.debugDescription);
        }else{
            NSLog(@"[%@] URLSession:task:didComplete", sensorName);
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->isSyncing = NO;
        NSString * response = @"";
        if (self->receivedData) {
            response = [[NSString alloc] initWithData:self->receivedData encoding:NSUTF8StringEncoding];
        }
        
        if (error!=nil) {
            [self broadcastDBSyncEventWithProgress:@(-1) isFinish:NO isSuccess:NO sensorName:self->sensorName];
            if (self->executorCallback!=nil) {
                self->executorCallback(@{@"result":@(NO),@"name":self->sensorName,@"error":error.debugDescription,@"response":response});
            }
        }else{
            [self broadcastDBSyncEventWithProgress:@100 isFinish:YES isSuccess:YES sensorName:self->sensorName];
            if (self->executorCallback!=nil) {
                self->executorCallback(@{@"result":@(YES),@"name":self->sensorName,@"response":response});
            }
        }
        self->receivedData = [[NSMutableData alloc] init];
    });
}


///////////////////////////////////////////

/**
 * AWARE URL makers
 */
- (NSString *)getWebserviceUrl{
    NSString* url = [awareStudy getStudyURL];
    if (url == NULL || [url isEqualToString:@""]) {
        NSLog(@"[SyncExecutor] Error: You don't have a StudyURL.");
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
