//
//  AWAREStudy.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREDelegate.h"
#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "AWARESensorManager.h"
#import "AWARECore.h"
#import "AWAREUtils.h"

#import "SCNetworkReachability.h"
#import "PushNotification.h"
#import "TCQMaker.h"

static AWAREStudy * sharedStudy;

@implementation AWAREStudy {
    SCNetworkReachability * reachability;
    JoinStudyCompletionHandler joinStudyCompletionHandler;
    bool wifiReachable;
    bool networkReachable;
    NSInteger networkState;
    bool isDebug;
    __weak NSURLSession *session;
    NSURLSessionConfiguration *sessionConfig;
    NSMutableData * receivedData;
    NSString * deviceId;
}

+ (AWAREStudy * _Nonnull)sharedStudy{
    @synchronized(self){
        if (!sharedStudy){
            sharedStudy = [[AWAREStudy alloc] initWithReachability:YES];
        }
    }
    return sharedStudy;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedStudy == nil) {
            sharedStudy= [super allocWithZone:zone];
            return sharedStudy;
        }
    }
    return nil;
}

- (instancetype) initWithReachability: (BOOL) reachabilityState{
    self = [super init];
    if (self) {
        receivedData = [[NSMutableData alloc] init];
        _getSettingIdentifier = @"set_setting_identifier";
        _addDeviceTableIdentifier = @"add_device_table_identifier";
        _makeDeviceTableIdentifier = @"make_device_table_identifier";
        
        if(reachabilityState){
            reachability = [[SCNetworkReachability alloc] initWithHost:@"www.google.com"];
            [reachability observeReachability:^(SCNetworkStatus status){
                self->networkState = status;
                switch (status){
                    case SCNetworkStatusReachableViaWiFi:
                        self->wifiReachable = YES;
                        self->networkReachable = YES;
                        break;
                    case SCNetworkStatusReachableViaCellular:
                        self->wifiReachable = NO;
                        self->networkReachable = YES;
                        break;
                    case SCNetworkStatusNotReachable:
                        self->wifiReachable = NO;
                        self->networkReachable = NO;
                        break;
                }
            }];
        }
        
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_getSettingIdentifier];
        sessionConfig.sharedContainerIdentifier= @"com.awareframework.setting.task.identifier";
        sessionConfig.timeoutIntervalForRequest = 60;
        sessionConfig.HTTPMaximumConnectionsPerHost = 60;
        sessionConfig.timeoutIntervalForResource = 60; //60*60*24; // 1 day
        sessionConfig.allowsCellularAccess = YES;
        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
        
        isDebug = [self isDebug];
        
        ///// set device_id from iCloud /////
        NSUbiquitousKeyValueStore * iCloud = [NSUbiquitousKeyValueStore defaultStore];
        [iCloud synchronize];
        deviceId = [iCloud objectForKey:KEY_AWARE_DEVICE_ID];
        if (deviceId == nil) {
            deviceId = [AWAREUtils getSystemUUID];
            [reachability reachabilityStatus:^(SCNetworkStatus status) {
                switch (status){
                    case SCNetworkStatusReachableViaWiFi:
                    case SCNetworkStatusReachableViaCellular:
                        [iCloud setObject:self->deviceId forKey:KEY_AWARE_DEVICE_ID];
                        [iCloud synchronize];
                        break;
                    case SCNetworkStatusNotReachable:
                        break;
                }
            }];
        }
        ////////////////////////////////////////////////
    }
    return self;
}

- (void) setStudyURL:(NSString *)url{
    [self setWebserviceServer:url];
}

- (void) setWebserviceServer:(NSString *)url{
    if (url != nil) {
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:url forKey:KEY_WEBSERVICE_SERVER];
        [userDefaults synchronize];
    }
}


- (NSString *)getStudyURL{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * studyURL = [userDefaults objectForKey:KEY_WEBSERVICE_SERVER];
    if(studyURL != nil){
        return studyURL;
    }else{
        return @"";
    }
}


-(void)refreshStudySettings{
    [self joinStudyWithURL:[self getStudyURL] completion:nil];
}

/**
 * This method downloads and sets a study configuration by using study URL. (NOTE: This URL can get from a study QRCode.)
 *
 * @param url An study URL (e.g., https://r2d2.hcii.cs.cmu.edu/aware/dashboard/index.php/webservice/index/study_number/PASSWORD)
 * @param completionHandler A handler for the joining process
 */
- (void)joinStudyWithURL:(NSString *)url completion:(JoinStudyCompletionHandler)completionHandler{

    [self setStudyURL:url];
    
    joinStudyCompletionHandler = completionHandler;
    receivedData = [[NSMutableData alloc] init];
    NSString * uuid = [self getDeviceId];
    NSString * post = [NSString stringWithFormat:@"device_id=%@", uuid];
    NSData   * postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString * postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
}


/* The task has received a response and no further messages will be
 * received until the completion block is called. The disposition
 * allows you to cancel a request or to turn a data task into a
 * download task. This delegate message is optional - if you do not
 * implement it, you can get the response as a property of the task.
 *
 * This method will not be called for background upload tasks (which cannot be converted to download tasks).
 */
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    // NSLog(@"%d",responseCode);
    if (responseCode == 200) {
        [session finishTasksAndInvalidate];
    }else{
        [session invalidateAndCancel];
    }
    completionHandler(NSURLSessionResponseAllow);
}


/* Sent when data is available for the delegate to consume.  It is
 * assumed that the delegate will retain and not copy the data.  As
 * the data may be discontiguous, you should use
 * [NSData enumerateByteRangesUsingBlock:] to access it.
 */
-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    if (data!=nil) {
        [receivedData appendData:data];
    }
}


/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    if (error != nil) {
        NSLog(@"ERROR: %@ %ld", error.debugDescription , error.code);
        if (error.code == -1202) {
            /**
             * If the error code is -1202, this device needs .crt for SSL(secure) connection.
             */
            // Install CRT file for SSL
            // NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            // NSString* url = [userDefaults objectForKey:KEY_STUDY_QR_CODE];
        }
    }else{
        if (receivedData != nil) {
            [self setStudySettings:[receivedData copy]];
        }
    }
}

/**
 * This method sets downloaded study configurations.
 *
 * @param data A response (study configurations) from the aware server
 */
- (void) setStudySettings:(NSData *) data {
    NSError * error = nil;
    NSArray * studySettings = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if(error != nil){
        NSLog(@"Error: %@", error.debugDescription);
        if (self->joinStudyCompletionHandler!=nil) {
            self->joinStudyCompletionHandler(@[], AwareStudyStateError, error);
        }
        return;
    }
    NSString * studySettingsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // compare the latest configuration string with the previous configuration string.
    NSString * previousConfig = [self removeStudyStartTimeFromConfig:[self getStudyConfigurationAsText]];
    NSString * currentConfig  = [self removeStudyStartTimeFromConfig:studySettingsString];
    
    if([previousConfig isEqualToString:currentConfig]){
        if (isDebug) NSLog(@"[AWAREStudy] The study configuration is same as previous configuration!");
        if (self->joinStudyCompletionHandler!=nil) {
            self->joinStudyCompletionHandler(studySettings, AwareStudyStateNoChange, error);
        }
        return ;
    }else{
        if (isDebug) NSLog(@"[AWAREStudy] The study configuration is updated!");
    }
    
    [self setStudyConfiguration:studySettingsString];
    
    // NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSArray * sensors = @[];
    NSArray * plugins = @[];
    if (studySettings.count > 0) {
        NSDictionary * settings = [studySettings objectAtIndex:0];
        sensors = [settings objectForKey:@"sensors"];
        plugins = [settings objectForKey:KEY_PLUGINS];
    }
    
    if (sensors != nil){
        for (NSDictionary * setting in sensors) {
            NSString * key = [setting objectForKey:@"setting"];
            NSObject * value = [setting objectForKey:@"value"];
            [self setSetting:key value:value];
        }
    }
    if (plugins != nil){
        for (NSDictionary * plugin in plugins) {
            NSString * pluginName = [plugin objectForKey:@"plugin"];
            NSArray * settings = [plugin objectForKey:@"settings"];
            if (settings != nil) {
                for (NSDictionary * setting in settings) {
                    NSString * key = [setting objectForKey:@"setting"];
                    NSObject * value = [setting objectForKey:@"value"];
                    [self setSetting:key value:value packageName:pluginName];
                }
            }
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString * url =  [self getStudyURL];
        NSString * uuid = [self getDeviceId]; //[AWAREUtils getSystemUUID];
        
        bool isExistDeviceId = [self isExistDeviceId:uuid onAwareServer:url];
        if (!isExistDeviceId) {
            [self addNewDeviceToAwareServer:url withDeviceId:uuid];
        }

        [self setStudyState:YES];
        
        [NSNotificationCenter.defaultCenter postNotificationName:ACTION_AWARE_UPDATE_STUDY_CONFIG object:nil];
        if (self->joinStudyCompletionHandler!=nil) {
            if (isExistDeviceId) {
                self->joinStudyCompletionHandler(studySettings, AwareStudyStateUpdate, error);
            }else{
                self->joinStudyCompletionHandler(studySettings, AwareStudyStateNew, error);
            }
        }
    });
}

///////////////////////////////////////////////////////

/**
 * This method sets downloaded study configurations.
 *
 * @param url of the target aware server
 * @param deviceId of this client
 */
- (bool) addNewDeviceToAwareServer:(NSString *)url withDeviceId:(NSString *) deviceId {
    if([self createTableWithURL:url deviceId:deviceId]){
        if (self->isDebug) NSLog(@"[AWAREStudy] A table create query to %@ is succeed.", url);
        if([self insertDeviceIdToAwareServerWithURL:url deviceId:deviceId]){
            if (self->isDebug) NSLog(@"[AWAREStudy] A device_id (%@) registration is succeed.", deviceId);
        }else{
            NSLog(@"[AWAREStudy] A device_id (%@) registration is filaed.", deviceId);
        }
    }else{
        NSLog(@"[AWAREStudy] A table create query to %@ is failed.", url);
    }
    return YES;
}

- (bool) isExistDeviceId:(NSString *)deviceId onAwareServer:(NSString *)url{
    NSString * result = [self getLatestStoredDataInAwareServerWithUrl:url deviceId:deviceId];
    if([result isEqualToString:@"[]"] ){
        if (isDebug) NSLog(@"[AWAREStudy] Your device_id (%@) is not stored.", deviceId);
        return NO;
    }else{
        if (isDebug) NSLog(@"[AWAREStudy] Your device_id (%@) is already stored.", deviceId);
        return YES;
    }
}

- (NSString *)getLatestStoredDataInAwareServerWithUrl:(NSString *)serverUrl deviceId:(NSString *)deviceId {
    // https://forums.developer.apple.com/thread/11519
    // [NOTE] https://api.awareframework.com/index.php/webservice/index/STUDYID/APIKEY/aware_device/latest
    NSString * url = [NSString stringWithFormat:@"%@/aware_device/latest", serverUrl]; ///aware_device/latest
    NSString *post = [NSString stringWithFormat:@"device_id=%@", deviceId];
    // NSLog(@"%@", url);
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
            NSLog(@"[AWAREStudy] Error: %@", error.debugDescription);
        }else{
            if (self->isDebug) NSLog(@"Success: %@", [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding]);
            result = data;
        }
        [session finishTasksAndInvalidate];
        [session invalidateAndCancel];
        dispatch_semaphore_signal(sem);
    }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    NSString * str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    
    return str;
}



/**
 * Create an aware_device table with an url and an uuid
 * @param url An url for create aware_device table on aware database
 * @param uuid An uuid for create aware_device table on aware database
 * @return A result of creating a table of the aware_deivce table
 */
- (bool) createTableWithURL:(NSString *)url deviceId:(NSString *) uuid{
    // preparing for insert device information
    url = [NSString stringWithFormat:@"%@/aware_device/create_table", url];
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "board text default '',"
    "brand text default '',"
    "device text default '',"
    "build_id text default '',"
    "hardware text default '',"
    "manufacturer text default '',"
    "model text default '',"
    "product text default '',"
    "serial text default '',"
    "release text default '',"
    "release_type text default '',"
    "sdk text default ''," // version
    "label text default '', "
    "UNIQUE (device_id)";
    
    NSString *post = [NSString stringWithFormat:@"device_id=%@&fields=%@", uuid, query];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    url = [NSString stringWithFormat:@"%@?%@", url, unixtime];
    
    NSURL * urlObj = [NSURL URLWithString:url];
    if(urlObj == nil){
        return NO;
    }
    [request setURL:urlObj];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSession sharedSession].configuration
                                                          delegate:self
                                                     delegateQueue:nil];
    dispatch_semaphore_t    sem;
    __block BOOL        result;
    result = NO;
    sem = dispatch_semaphore_create(0);
    
    [[session dataTaskWithRequest: request  completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
        // Success
        if (error != nil) {
            NSLog(@"[AWAREStudy] Error: %@", error.debugDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                // [AWAREUtils sendLocalNotificationForMessage:error.debugDescription soundFlag:YES];
            });
        }
        if( data != nil ){
            if (self->isDebug) NSLog(@"Success: %@", [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding]);
            result = YES;
        }
        [session finishTasksAndInvalidate];
        [session invalidateAndCancel];
        dispatch_semaphore_signal(sem);
        
    }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return result;
}


- (BOOL) insertDeviceIdToAwareServerWithURL:(NSString *)url
                                   deviceId:(NSString *)uuid{
    NSString *name = [self getDeviceName]; //[[UIDevice currentDevice] name];//ok
    return [self insertDeviceIdToAwareServerWithURL:url
                                           deviceId:uuid
                                         deviceName:name];
}

- (BOOL) insertDeviceIdToAwareServerWithURL:(NSString *)url
                                   deviceId:(NSString *)uuid
                                 deviceName:(NSString *)deviceName {
    return [self insertDeviceIdToAwareServerWithURL:url
                                           deviceId:deviceId
                                         deviceName:deviceName
                                         completion:nil];
}

- (BOOL) updateDeviceName:(NSString *)deviceName
               completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler{
    [self setDeviceName:deviceName];
    NSString * deviceId = [self getDeviceId];
    NSString * url = [self getStudyURL];
    if ([url isEqualToString:@""]) {
        return NO;
    }
    
    return [self insertDeviceIdToAwareServerWithURL:url
                                            deviceId:deviceId
                                          deviceName:deviceName
                                          completion:completionHandler];
}


- (BOOL) insertDeviceIdToAwareServerWithURL:(NSString *)url
                                   deviceId:(NSString *)uuid
                                 deviceName:(NSString *)deviceName
                                 completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler{
    
    // preparing for insert device information
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString* machine =  [NSString stringWithCString:systemInfo.machine  encoding:NSUTF8StringEncoding]; // ok
    // NSString* nodeName = [NSString stringWithCString:systemInfo.nodename encoding:NSUTF8StringEncoding]; // ok
    NSString* release =  [NSString stringWithCString:systemInfo.release  encoding:NSUTF8StringEncoding]; // ok
    // NSString* systemName = [NSString stringWithCString:systemInfo.sysname encoding:NSUTF8StringEncoding];// ok
    NSString* version = [NSString stringWithCString:systemInfo.version encoding:NSUTF8StringEncoding];

    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];//ok
    NSString *localizeModel = [[UIDevice currentDevice] localizedModel];//
    NSString *model = [[UIDevice currentDevice] model]; //ok
    NSString *manufacturer = @"Apple";//ok
    
    
    NSMutableDictionary *jsonQuery = [[NSMutableDictionary alloc] init];
    [jsonQuery setValue:uuid            forKey:@"device_id"];
    [jsonQuery setValue:unixtime        forKey:@"timestamp"];
    [jsonQuery setValue:manufacturer    forKey:@"board"];
    [jsonQuery setValue:model           forKey:@"brand"];
    [jsonQuery setValue:[AWAREUtils deviceName] forKey:@"device"];
    [jsonQuery setValue:version         forKey:@"build_id"];
    [jsonQuery setValue:machine         forKey:@"hardware"];
    [jsonQuery setValue:manufacturer    forKey:@"manufacturer"];
    [jsonQuery setValue:model           forKey:@"model"];
    [jsonQuery setValue:[AWAREUtils deviceName]    forKey:@"product"];
    [jsonQuery setValue:version         forKey:@"serial"];
    [jsonQuery setValue:release         forKey:@"release"];
    [jsonQuery setValue:localizeModel   forKey:@"release_type"];
    [jsonQuery setValue:systemVersion   forKey:@"sdk"];
    [jsonQuery setValue:deviceName      forKey:@"label"];
    
    NSMutableArray *a = [[NSMutableArray alloc] init];
    [a addObject:jsonQuery];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:a
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString *jsonString = @"";
    if (! jsonData) {
        NSLog(@"[AWAREStudy] Error: %@", error.debugDescription);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (self->isDebug) NSLog(@"%@",jsonString);
    }
    NSString *post = [NSString stringWithFormat:@"data=%@&device_id=%@", jsonString,uuid];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    //[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    url = [NSString stringWithFormat:@"%@/aware_device/insert?%@", url,unixtime];
    
    
    NSURL * urlObj = [NSURL URLWithString:url];
    if(urlObj == nil){
        return NO;
    }
    [request setURL:urlObj];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSession sharedSession].configuration
                                                          delegate:self
                                                     delegateQueue:nil];
    
    
    dispatch_semaphore_t    sem;
    __block BOOL         result;
    result = NO;
    sem = dispatch_semaphore_create(0);
    
    [[session dataTaskWithRequest: request  completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            NSLog(@"Error: %@", error.debugDescription);
        }
        if( data != nil ){
            if (self->isDebug) NSLog(@"Success: %@", [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding]);
            result = YES;
        }
        [session finishTasksAndInvalidate];
        [session invalidateAndCancel];
        dispatch_semaphore_signal(sem);
        if ( completionHandler != nil ) {
            completionHandler(data, response, error);
        }
    }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return result;
}


///////////////////////////////////////////////////////////////////////
// Getter
////////////////////////////////////////////////////////////////////////

- (void) setDeviceName:(NSString *) deviceName {
    [self setDeviceName:deviceName sync:NO completion:nil];
}

- (void) setDeviceName:(NSString *)deviceName
                  sync:(BOOL)sync
            completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler{
    // Set the given device name into local storage
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:deviceName forKey:KEY_AWARE_DEVICE_NAME];
    [userDefaults synchronize];
    
}

- (NSString *) getDeviceName {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *name = [[UIDevice currentDevice] name];
    if ([userDefaults objectForKey:KEY_AWARE_DEVICE_NAME] != nil) {
        name = [userDefaults objectForKey:KEY_AWARE_DEVICE_NAME];
    }
    return name;
}

/**
 * Get a device id from a local storage.
 * @return a device id of this device
 */
- (NSString *)getDeviceId {
    return deviceId;
    // return [AWAREUtils getSystemUUID];
}


- (void) setSetting:(NSString *)key value:(NSObject *)value{
    [self setSetting:key value:value packageName:@""];
}

- (void) setSetting:(NSString *)key value:(NSObject *)value packageName:(NSString *) packageName {
    if (key==nil || value==nil || packageName==nil) return;
    
    // Convert all of setting values to NSString from NSObject
    // NOTE: Android version of AWARE is saving all of setting data as String even if the value is boolean and number. Similarly, all of setting values from an aware-server is string format. For converting all of the string-values to adaptive value (e.g., number, bool, and string) is hard to do at this phase, therefore, a setting value is saved as an NSString,
    NSString * convertedSettingValue = @"";
    if ([value isKindOfClass:[NSString class]]) {
        convertedSettingValue = (NSString*)value;
    }else{
        if ([value isKindOfClass:[@(YES) class]]) {
            if (((NSNumber*)value).boolValue){
                convertedSettingValue = @"true";
            }else{
                convertedSettingValue = @"false";
            }
        }else if([value isKindOfClass:[NSNumber class]]){
            convertedSettingValue = ((NSNumber *)value).stringValue;
            if (convertedSettingValue==nil) {
                convertedSettingValue = @"";
            }
        }else{
            NSLog(@"[ERROR@AWAREStudy][setting value-type error] %@ is not supported.", NSStringFromClass([value class]));
        }
    }
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray * mutableSettings = [[NSMutableArray alloc] init];
    NSMutableArray * settings = [userDefaults objectForKey:KEY_SENSORS];
    if (settings == nil) {
        mutableSettings = [[NSMutableArray alloc] init];
    }else{
        mutableSettings = [[NSMutableArray alloc] initWithArray:settings];
    }
    bool isKeyExist = false;
    int  targetSettingIndex = 0;
    for (int i=0; i<settings.count; i++) {
        NSDictionary * setting = settings[i];
        NSString * settingKey = [setting objectForKey:@"setting"];
        if (settingKey != nil) {
            if ([settingKey isEqualToString:key]) {
                isKeyExist = true;
                targetSettingIndex = i;
                break;
            }
        }
    }
    NSDictionary * newSetting = @{@"setting":key, @"value":convertedSettingValue, @"package_name":packageName};
    if (isKeyExist) {
        [mutableSettings replaceObjectAtIndex:targetSettingIndex withObject:newSetting];
    }else{
        [mutableSettings addObject:newSetting];
    }
    [userDefaults setObject:mutableSettings forKey:KEY_SENSORS];
    [userDefaults synchronize];
    
    if([key isEqualToString:@"mqtt_password"]){
        [userDefaults setObject:value forKey:KEY_MQTT_PASS];
    }else if([key isEqualToString:@"mqtt_username"]){
        [userDefaults setObject:value forKey:KEY_MQTT_USERNAME];
    }else if([key isEqualToString:@"mqtt_server"]){
        [userDefaults setObject:value forKey:KEY_MQTT_SERVER];
    }else if([key isEqualToString:@"mqtt_port"]){
        [userDefaults setObject:value forKey:KEY_MQTT_PORT];
    }else if([key isEqualToString:@"mqtt_keep_alive"]){
        [userDefaults setObject:value forKey:KEY_MQTT_KEEP_ALIVE];
    }else if([key isEqualToString:@"mqtt_qos"]){
        [userDefaults setObject:value forKey:KEY_MQTT_QOS];
    }else if([key isEqualToString:@"study_id"]){
        [userDefaults setObject:value forKey:KEY_STUDY_ID];
    }else if([key isEqualToString:@"webservice_server"]){
        [userDefaults setObject:value forKey:KEY_WEBSERVICE_SERVER];
    }else if([key isEqualToString:@"frequency_webservice"]){
        [userDefaults setDouble:((NSNumber *)value).intValue*60 forKey:SETTING_SYNC_INT]; // save data as second
    }else if([key isEqualToString:@"frequency_clean_old_data"]){
        // (0 = never, 1 = weekly, 2 = monthly, 3 = daily, 4 = always)
        [userDefaults setInteger:((NSNumber *)value).integerValue forKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
    }else if([key isEqualToString:@"webservice_wifi_only"]){
        [userDefaults setBool: ((NSNumber *)value).boolValue forKey:SETTING_SYNC_WIFI_ONLY];
    }
}


- (NSString *) getSetting:(NSString *)key{
    if (key==nil) return @"";
    NSString * value = nil;
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray * settings = [userDefaults objectForKey:KEY_SENSORS];
    for (NSDictionary * setting in settings) {
        NSString * dictKey = [setting objectForKey:@"setting"];
        NSString * dictVal = [setting objectForKey:@"value"];
        if (dictKey != nil) {
            if ([dictKey isEqualToString:key]) {
                value = dictVal;
                break;
            }
        }
    }
    if (value != nil) {
        return value;
    }else{
        return @"";
    }
}

- (NSArray *) getSensorSettings{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray * settings = [userDefaults objectForKey:KEY_SENSORS];
    return settings;
}


/**
 * Get a study configuration as text
 * @return a study configuration as a NSString
 */
- (NSString *) getStudyConfigurationAsText {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * studyConfigurationText = @"";
    studyConfigurationText = [userDefaults objectForKey:@"key_aware_study_configuration_json_text"];
    if (studyConfigurationText == nil) {
        studyConfigurationText = @"";
    }
    return studyConfigurationText;
}


/**
 * Set a study configuration as text
 */
- (void) setStudyConfiguration:(NSString* ) configuration {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if(configuration !=nil){
        [userDefaults setObject:configuration forKey:@"key_aware_study_configuration_json_text"];
    }
}


/**
 * Clean all AWARE study configuration from a local storage (NSUserDefaults)
 * @return a result of a cleaning operation
 */
- (BOOL) clearStudySettings{
    // AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    // AWARECore * core = delegate.sharedAWARECore;
    [[AWARESensorManager sharedSensorManager] stopAndRemoveAllSensors];
    
    [self setStudyState:NO];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:KEY_MQTT_SERVER];
    [userDefaults removeObjectForKey:KEY_MQTT_USERNAME];
    [userDefaults removeObjectForKey:KEY_MQTT_PASS];
    [userDefaults removeObjectForKey:KEY_MQTT_PORT];
    [userDefaults removeObjectForKey:KEY_MQTT_KEEP_ALIVE];
    [userDefaults removeObjectForKey:KEY_MQTT_QOS];
    [userDefaults removeObjectForKey:KEY_STUDY_ID];
    [userDefaults removeObjectForKey:KEY_WEBSERVICE_SERVER];
    [userDefaults removeObjectForKey:KEY_SENSORS];
    [userDefaults removeObjectForKey:KEY_PLUGINS];
    [userDefaults removeObjectForKey:KEY_USER_SENSORS];
    [userDefaults removeObjectForKey:KEY_USER_PLUGINS];
    [userDefaults removeObjectForKey:KEY_STUDY_QR_CODE];
    [userDefaults removeObjectForKey:@"key_aware_study_configuration_json_text"];
    return [userDefaults synchronize];
}




/**
 * Get a Wi-Fi network reachable as a boolean
 * @return a Wi-Fi network reachable as a boolean
 */
- (bool) isWifiReachable { return wifiReachable; }


- (bool) isNetworkReachable { return networkReachable; }

/**
 * Get a network condition as text
 * @return a network reachability as a text
 */
- (NSString *) getNetworkReachabilityAsText{
    NSString * reachabilityText = @"";
    switch (networkState){
        case SCNetworkStatusReachableViaWiFi:
            reachabilityText = @"wifi";
            break;
        case SCNetworkStatusReachableViaCellular:
            reachabilityText = @"cellular";
            break;
        case SCNetworkStatusNotReachable:
            reachabilityText = @"no";
            break;
        default:
            reachabilityText = @"unknown";
            break;
    }
    return reachabilityText;
}

- (NSString *) removeStudyStartTimeFromConfig:(NSString*) configStr {
    if (configStr == nil) return @"";
    NSError *error = nil;
    NSString* pattern = @"(\\{\"setting\":\"study_start\",\"value\":\"\\d{4,}\"\\},)";
    //    NSString* pattern = @"setting";
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    if (error == nil){
        NSArray *matches = [regex matchesInString:configStr options:0 range:NSMakeRange(0, configStr.length)];
        for (NSTextCheckingResult *match in matches){
            NSMutableString* str = [[NSMutableString alloc] initWithString:configStr];
            [str deleteCharactersInRange:match.range];
            configStr = str;
        }
    }
    return configStr;
}

- (cleanOldDataType) getCleanOldDataType{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
}


//////////////////////////////////////////////////////
-  (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
  completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                              NSURLCredential * _Nullable credential)) completionHandler{
    // http://stackoverflow.com/questions/19507207/how-do-i-accept-a-self-signed-ssl-certificate-using-ios-7s-nsurlsession-and-its
    
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        
        NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
        SecTrustRef trust = [protectionSpace serverTrust];
        NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
        
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    }
}

//////////////////////////////////////////////////////////


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    
    if(response != nil){
        NSLog(@"%@", response.debugDescription);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    
    if(data != nil){
        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] );
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    if(error != nil){
        NSLog(@"%@", error.debugDescription);
    }
}


//////////////////////////////////////////////////////////////////////////////////////////////

- (void) setDebug:(bool)state{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:state forKey:SETTING_DEBUG_STATE];
    [userDefaults synchronize];
    isDebug = state;
}

- (void) setAutoDBSyncOnlyWifi:(bool)state{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:state forKey:SETTING_SYNC_WIFI_ONLY];
    [userDefaults synchronize];
}

- (void) setAutoDBSyncOnlyBatterChargning:(bool)state{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:state forKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
    [userDefaults synchronize];
}

- (void) setAutoDBSyncIntervalWithMinutue:(int)minutue{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@((double)minutue*60.0f) forKey:SETTING_SYNC_INT];
    [userDefaults synchronize];
}


- (void) setMaximumByteSizeForDBSync:(NSInteger)size{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(size) forKey:KEY_MAX_DATA_SIZE];
    [userDefaults synchronize];
    
    // AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    AWARECore * core =[AWARECore sharedCore];
    if(core != nil){
        [[AWARESensorManager sharedSensorManager] resetAllMarkerPositionsInDB];
    }
}

- (void) setMaximumNumberOfRecordsForDBSync:(NSInteger)number{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(number) forKey:KEY_MAX_FETCH_SIZE_NORMAL_SENSOR];
    [userDefaults synchronize];
}

- (void) setDBType:(AwareDBType)type{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:type forKey:SETTING_DB_TYPE];
    [userDefaults synchronize];
}

- (void) setCleanOldDataType:(cleanOldDataType)type{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:type forKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
    [userDefaults synchronize];
}

- (void)setUIMode:(AwareUIMode)mode{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:mode forKey:SETTING_UI_MODE];
    [userDefaults synchronize];
}

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

- (bool) isDebug {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:SETTING_DEBUG_STATE];
}


- (bool) isAutoDBSyncOnlyWifi {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:SETTING_SYNC_WIFI_ONLY];
}

- (bool) isAutoDBSyncOnlyBatterChargning {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
}

- (int) getAutoDBSyncIntervalSecond {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return (int)[userDefaults integerForKey:SETTING_SYNC_INT];
}

- (NSInteger) getMaximumByteSizeForDBSync{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
}

- (NSInteger) getMaximumNumberOfRecordsForDBSync{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:KEY_MAX_FETCH_SIZE_NORMAL_SENSOR];
}

- (AwareDBType) getDBType{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:SETTING_DB_TYPE];
}

- (AwareUIMode) getUIMode{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    AwareUIMode uiMode = (AwareUIMode)[userDefaults integerForKey:SETTING_UI_MODE];
    return uiMode;
}

- (void) setAutoDBSync:(bool) state {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:state forKey:SETTING_AUTO_SYNC];
    [userDefaults synchronize];
}

- (BOOL) isAutoDBSync{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:SETTING_AUTO_SYNC];
}

- (void) setCPUTheshold:(int)threshold{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:threshold forKey:SETTING_CPU_THESHOLD];
    [userDefaults synchronize];
}

- (int) getCPUTheshold {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    int theshold = (int)[userDefaults integerForKey:SETTING_CPU_THESHOLD];
    if (theshold == 0) {
        theshold = 50;
    }
    return theshold;
}

- (bool)isStudy{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:SETTING_AWARE_STUDY_STATE];
}

- (void) setStudyState:(bool)state{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:state forKey:SETTING_AWARE_STUDY_STATE];
    [userDefaults synchronize];
}

@end
