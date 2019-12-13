//
//  AWAREStudy.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "AWARESensorManager.h"
#import "AWARECore.h"
#import "AWAREUtils.h"
#import "AWAREDevice.h"

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
    NSURLSession *session;
    NSURLSessionConfiguration *sessionConfig;
    NSMutableData * receivedData;
    NSString * deviceId;
    NSNumber * cashMaxBatchSize;
    NSNumber * cashMaxRecords;
    NSNumber * cashIsDebug;
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
        sessionConfig.sharedContainerIdentifier     = @"com.awareframework.setting.task.identifier";
        sessionConfig.timeoutIntervalForRequest     = 60;
        sessionConfig.HTTPMaximumConnectionsPerHost = 60;
        sessionConfig.timeoutIntervalForResource    = 60; //60*60*24; // 1 day
        sessionConfig.allowsCellularAccess          = YES;
        
        
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

- (void)fetchStudyConfiguration:(NSString *)url completion:(FetchStudyConfigurationCompletionHandler)completionHandler{
    
    NSString * uuid = [self getDeviceId];
    NSString * post = [NSString stringWithFormat:@"device_id=%@", uuid];
    NSData   * postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString * postLength = [NSString stringWithFormat:@"%zd", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data,
                                                                                          NSURLResponse * _Nullable response,
                                                                                          NSError * _Nullable error) {
        if(error==nil && data!=nil){
            NSError * jsonError = nil;
            NSArray * awareConfigArray = [NSJSONSerialization JSONObjectWithData:data
                                                                         options:NSJSONReadingAllowFragments
                                                                           error:&jsonError];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(awareConfigArray != nil){
                    completionHandler(awareConfigArray,nil);
                }else{
                    completionHandler([self getStudyConfiguration],nil);
                }
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler([self getStudyConfiguration], error);
            });
        }
    }];
    [task resume];
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
    NSString * postLength = [NSString stringWithFormat:@"%zd", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
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
        NSLog(@"ERROR: %@ %zd", error.debugDescription , error.code);
        if (error.code == -1202) {
            /**
             * If the error code is -1202, this device needs .crt for SSL(secure) connection.
             */
            // Install CRT file for SSL
            // NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            // NSString* url = [userDefaults objectForKey:KEY_STUDY_QR_CODE];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->joinStudyCompletionHandler != nil) {
                self->joinStudyCompletionHandler([self getStudyConfiguration], AwareStudyStateNetworkConnectionError, error);
            }
        });
    }else{
        if (receivedData != nil) {
            /// save configuration
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setStudyConfigurationWithData:[self->receivedData copy]
                                         completion:self->joinStudyCompletionHandler];
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                self->joinStudyCompletionHandler([self getStudyConfiguration], AwareStudyStateDataFormatError, error);
            });
        }
    }
}

- (NSString *) getKeyForIsDeviceIdOnAWAREServer {
    return [[NSString alloc] initWithFormat:@"key_device_id_on_server_%@", [self getStudyURL]];
}

/**
 * This method sets downloaded study configurations.
 *
 * @param data A response (study configurations) from the aware server
 */
- (void) setStudyConfigurationWithData:(NSData *) data
                            completion:(JoinStudyCompletionHandler)completionHandler{
    NSError * error = nil;
    NSArray * studySettings = [NSJSONSerialization JSONObjectWithData:data
                                                              options:NSJSONReadingMutableContainers
                                                                error:&error];
    if(error != nil){
        NSLog(@"[AWAREStudy|setStudySettings] Error: %@", error.debugDescription);
        if (completionHandler!=nil) {
            completionHandler([self getStudyConfiguration], AwareStudyStateDataFormatError, error);
        }
        return;
    }
    
    AwareStudyState studyState = AwareStudyStateNoChange;

    NSString * url        =  [self getStudyURL];
    NSString * deviceId   = [self getDeviceId];
    NSString * deviceName = [self getDeviceName];

    AWAREDevice * awareDevice = [[AWAREDevice alloc] initWithAwareStudy:self];
    [[AWARESensorManager sharedSensorManager] addSensor:awareDevice];
    NSString * key = [self getKeyForIsDeviceIdOnAWAREServer];
    if (![NSUserDefaults.standardUserDefaults boolForKey: key]) {
        /// create an aware_device table and register a device if it is needed
        [awareDevice insertDeviceId:deviceId name:deviceName];
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:key];
        [NSUserDefaults.standardUserDefaults synchronize];
        studyState = AwareStudyStateNew;
        
        if (self->isDebug) { NSLog(@"[AWAREStudy|AddDeviceId] The device_id (%@) is not registered yet", [self getDeviceId]); }
        awareDevice.storage.tableCreateCallback = ^(bool result, NSData *data, NSError *error) {
            AWAREDevice * aDevice = (AWAREDevice *)[[AWARESensorManager sharedSensorManager] getSensor:@"aware_device"];
            if (aDevice != nil) {
                if (result) {
                    if (self->isDebug) { NSLog(@"[AWAREStudy] aware_device table is created on %@", url); }
                    [aDevice unlockOperation];
                    [aDevice.storage startSyncStorageWithCallback:^(NSString * _Nonnull name, AwareStorageSyncProgress syncState, double progress, NSError * _Nullable error) {
                        if (error == nil) {
                            if (progress >= 1) {
                                NSLog(@"[%@] %f", name, progress);
                                if (self->isDebug) { NSLog(@"[AWAREStudy|AddDeviceId] The device_id (%@) registration is succeed", [self getDeviceId]); }
                                aDevice.storage.syncProcessCallback = nil;
                            }
                        }else{
                            NSLog(@"[%@] Error: %@", name, error.debugDescription);
                            if (self->isDebug) { NSLog(@"[AWAREStudy|AddDeviceId] The device_id (%@) registration is failed", [self getDeviceId]); }
                            aDevice.storage.syncProcessCallback = nil;
                        }
                        [aDevice unlockOperation];
                    }];
                    [aDevice lockOperation];
                }else{
                    if (self->isDebug) NSLog(@"[AWAREStudy] aware_device table is not created on %@", url);
                    [NSUserDefaults.standardUserDefaults setBool:NO forKey:[self getKeyForIsDeviceIdOnAWAREServer]];
                    [NSUserDefaults.standardUserDefaults synchronize];
                }
                aDevice.storage.tableCreateCallback = nil;
            }
        };
    
        [awareDevice createTable];
        [awareDevice lockOperation];
    
    }else{
        if (self->isDebug){  NSLog(@"[AWAREStudy|AddDeviceId] The device_id (%@) is already registered", [self getDeviceId]); }
        studyState = AwareStudyStateUpdate;
        [awareDevice.storage startSyncStorage];
    }
    
    // compare the latest configuration string with the previous configuration string.
    NSString * studySettingsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString * previousConfig = [self removeStudyStartTimeFromConfig:[self getStudyConfigurationAsText]];
    NSString * currentConfig  = [self removeStudyStartTimeFromConfig:studySettingsString];
    if([previousConfig isEqualToString:currentConfig]){
        if (isDebug) NSLog(@"[AWAREStudy] The study configuration is same as previous configuration!");
        if (completionHandler!=nil) {
            completionHandler(studySettings, AwareStudyStateNoChange, error);
        }
        return;
    }else{
        if (isDebug) NSLog(@"[AWAREStudy] The study configuration is updated!");
    }
    [self setStudyConfiguration:studySettingsString];
    
    /// save sensor and plugin configurations
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
    
    [self setStudyState:YES];
    
    /// call a completion handler if exist
    if (completionHandler != nil) {
        completionHandler(studySettings, studyState, error);
    }
}

- (void) registerDevice {

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

- (NSArray * ) getStudyConfiguration {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * studyConfigurationText = [userDefaults objectForKey:@"key_aware_study_configuration_json_text"];
    if (studyConfigurationText == nil) {
        return @[];
    }
    NSError * error = nil;
    NSArray * config = [NSJSONSerialization JSONObjectWithData:[studyConfigurationText dataUsingEncoding:NSUTF8StringEncoding]
                                                       options:NSJSONReadingAllowFragments
                                                         error:&error];
    if (error != nil) {
        if (isDebug) { NSLog(@"[AWAREStudy] Error@getStudyConfiguration: %@", error.debugDescription); }
        return @[];
    }
    if (config == nil) {
        if (isDebug) { NSLog(@"[AWAREStudy] Error: StudyConfiguration is nil"); }
        return @[];
    }else{
        return config;
    }
}


/**
 * Set a study configuration as text
 */
- (void) setStudyConfiguration:(NSString* ) configuration {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if(configuration != nil){
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
    cashIsDebug = @(state);
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
    [userDefaults setInteger:number forKey:KEY_MAX_FETCH_SIZE_NORMAL_SENSOR];
    [userDefaults synchronize];
    cashMaxRecords = @(number);
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
    if (cashIsDebug != nil) {
        return cashIsDebug.boolValue;
    }else{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        bool state = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        cashIsDebug = @(state);
        isDebug = state;
        return state;
    }
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
    if (cashMaxRecords != nil) {
        return cashMaxRecords.integerValue;
    }else{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger max = [userDefaults integerForKey:KEY_MAX_FETCH_SIZE_NORMAL_SENSOR];
        cashMaxRecords =@(max);
        return max;
    }
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

- (void)setMaximumNumberOfRecordsForBatchStyleDBSync:(NSInteger)max{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:max forKey:KEY_MAX_FETCH_SIZE_BATCH_STYLE_DB];
    [userDefaults synchronize];
    cashMaxBatchSize = @(max);
}

- (NSInteger)getMaximumNumberOfRecordsForBatchStyleDBSync{
    if (cashMaxBatchSize != nil) {
        return cashMaxBatchSize.integerValue;
    }else{
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger max = [userDefaults integerForKey:KEY_MAX_FETCH_SIZE_BATCH_STYLE_DB];
        cashMaxBatchSize = @(max);
        return max;
    }
}

@end
