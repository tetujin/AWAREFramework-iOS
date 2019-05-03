//
//  IOSESM.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 10/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "IOSESM.h"
#import "TCQMaker.h"
#import "EntityESM+CoreDataClass.h"
#import "EntityESMSchedule+CoreDataClass.h"
#import "EntityESMAnswerHistory+CoreDataClass.h"
#import "EntityESMAnswer.h"
#import "AWAREUtils.h"
#import "AWAREKeys.h"
#import "CoreDataHandler.h"
#import "ESMScheduleManager.h"
#import "SCNetworkReachability.h"

NSString * const AWARE_PREFERENCES_STATUS_PLUGIN_IOS_ESM     = @"status_plugin_ios_esm";
NSString * const AWARE_PREFERENCES_PLUGIN_IOS_ESM_TABLE_NAME = @"plugin_ios_esm_table_name";
NSString * const AWARE_PREFERENCES_PLUGIN_IOS_ESM_CONFIG_URL = @"plugin_ios_esm_config_url";

@implementation IOSESM {
    NSString      * baseHttpSessionId;
    NSString      * currentHttpSessionId;
    NSString      * categoryIOSESM;
    NSMutableData * receiveData;
    NSString      * tableName;
    NSArray       * pluginSettings;
    UIViewController   * viewController;
    ESMScheduleManager * esmManager;
    ESMConfigurationSetupCompleteHandler completionHandler;
    ESMConfigurationSetupErrorHandler    errorHandler;
}

-(instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    
    AWAREStorage * storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_IOS_ESM entityName:NSStringFromClass([EntityESMAnswer class]) insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
        EntityESMAnswer * entityESMAnswer = (EntityESMAnswer *)[NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:childContext];
        entityESMAnswer.device_id  = [data objectForKey:@"device_id"];
        entityESMAnswer.timestamp  = [data objectForKey:@"timestamp"];
        entityESMAnswer.esm_json   = [data objectForKey:@"esm_json"];
        entityESMAnswer.esm_status = [data objectForKey:@"esm_status"];
        entityESMAnswer.esm_expiration_threshold = [data objectForKey:@"esm_expiration_threshold"];
        entityESMAnswer.double_esm_user_answer_timestamp = [data objectForKey:@"double_esm_user_answer_timestamp"];
        entityESMAnswer.esm_user_answer = [data objectForKey:@"esm_user_answer"];
        entityESMAnswer.esm_trigger = [data objectForKey:@"esm_trigger"];
    }];
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_IOS_ESM
                             storage:storage];
    if(self != nil){
        baseHttpSessionId    = [NSString stringWithFormat:@"plugin_ios_esm_http_session_id"];
        currentHttpSessionId = [NSString stringWithFormat:@"%@_%f", baseHttpSessionId, [NSDate new].timeIntervalSince1970];
        categoryIOSESM       = @"plugin_ios_esm_category";
        receiveData          = [[NSMutableData alloc] init];
        tableName            = @"esms";
        _table               = @"esms";
        esmManager           = [ESMScheduleManager sharedESMScheduleManager];
    }
    return self;
}

- (void)createTable{
    TCQMaker *tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:@"esm_json"                         type:TCQTypeText    default:@"''"];
    [tcqMaker addColumn:@"esm_status"                       type:TCQTypeInteger default:@"0"];
    [tcqMaker addColumn:@"esm_expiration_threshold"         type:TCQTypeInteger default:@"0"];
    [tcqMaker addColumn:@"double_esm_user_answer_timestamp" type:TCQTypeReal    default:@"0"];
    [tcqMaker addColumn:@"esm_user_answer"                  type:TCQTypeText    default:@"''"];
    [tcqMaker addColumn:@"esm_trigger"                      type:TCQTypeText    default:@"''"];
    NSString * query = [tcqMaker getTableCreateQueryWithUniques:nil];
    [self.storage createDBTableOnServerWithQuery:query tableName:SENSOR_ESMS];
}

- (void)setParameters:(NSArray *)parameters{
    _url   = [self getStringFromSettings:parameters key:@"plugin_ios_esm_config_url"];
    _table = [self getStringFromSettings:parameters key:@"plugin_ios_esm_table_name"];
    if (_table == nil){
        _table = @"esms";
    }
}

- (BOOL) startSensor {
    [self setSensingState:YES];
    return [self startSensorWithURL:_url completionHandler:nil];
}

- (BOOL)startSensorWithURL:(NSString *)urlStr{
    return [self startSensorWithURL:urlStr completionHandler:nil];
}

- (BOOL) startSensorWithURL:(NSString *)urlStr completionHandler:(ESMConfigurationSetupCompleteHandler)handler{
    
    _url = urlStr;
    if (_url == nil) return NO;

    completionHandler = handler;
    
    NSString * configURL = [NSString stringWithFormat:@"%@?device_id=%@", _url, [self getDeviceId]];
    NSURL    * url = [[NSURL alloc] initWithString:configURL];

    [self downloadESMConfigurationWithURL:url];

    return YES;
}

- (BOOL) stopSensor {
    [self setSensingState:NO];
    return YES;
}

- (BOOL)quitSensor{
    [esmManager removeAllNotifications];
    [esmManager removeAllSchedulesFromDB];
    return YES;
}

- (void) downloadESMConfigurationWithURL:(NSURL *)url{
   
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
    NSString *postLength = nil;
    
    // Set settion configu and HTTP/POST body.
    NSURLSessionConfiguration *sessionConfig = nil;
    
    // Make a HTTP session id
    currentHttpSessionId = [NSString stringWithFormat:@"%@", baseHttpSessionId]; //, [NSDate new].timeIntervalSince1970];
    
    // Make a seesion config for HTTP/POST
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:currentHttpSessionId];
    sessionConfig.timeoutIntervalForRequest     = 60.0;
    sessionConfig.timeoutIntervalForResource    = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 20;
    sessionConfig.allowsCellularAccess = YES;
    // sessionConfig.requestCachePolicy = NSURLCacheStorageAllowedInMemoryOnly;
    
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    // request.cachePolicy = NSURLRequestReturnCacheDataDontLoad;
    // set HTTP/POST body information
    if(self.isDebug) NSLog(@"--- [%@] This is background task ----", [self getSensorName] );
    session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
}


- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    if([session.configuration.identifier isEqualToString:currentHttpSessionId]){
        
        completionHandler(NSURLSessionResponseAllow);
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        int responseCode = (int)[httpResponse statusCode];
        
        if (responseCode == 200) {
            [session finishTasksAndInvalidate];
            if(self.isDebug) NSLog(@"[%@] Got Web ESM configuration file from server", [self getSensorName]);
        }else{
            [session invalidateAndCancel];
            receiveData = [[NSMutableData alloc] init];
        }
    }else{
        NSLog(@"******** ios esm ********");
        [session invalidateAndCancel];
        completionHandler(NSURLSessionResponseAllow);
    }
}


-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    if (self.isDebug) NSLog(@"iOS ESM Plugin: Did received config data");

    if([session.configuration.identifier isEqualToString:currentHttpSessionId]){
        if(data != nil){
            if(self.isDebug)NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            [receiveData appendData:data];
        }
    }else{
        NSLog(@"****** iOS ESM *******");
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    
    if (self.isDebug) NSLog(@"iOS ESM Plugin: Did compleate");
    
    if(error != nil){
        NSLog(@"Error: %@", error.debugDescription);
        receiveData = [[NSMutableData alloc] init];
        [self sendAlertMessageWithTitle:@"[iOS ESM] Configuration File Download Error"
                                message:error.debugDescription
                           cancelButton:@"Close"];
        if( errorHandler != nil ) errorHandler(error);
        return;
    }
    
    if([session.configuration.identifier isEqualToString:currentHttpSessionId]){
        [self setESMSchedulesWithData:[receiveData copy] response:nil error:error];
        receiveData = [[NSMutableData alloc] init];
    }
    
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    if([session.configuration.identifier isEqualToString:currentHttpSessionId]){
        if (error != nil) {
            NSLog(@"[%@] the session did become invaild with error: %@", [self getSensorName], error.debugDescription);
            [self sendAlertMessageWithTitle:@"Error iOS ESM" message:error.debugDescription cancelButton:@"Close"];
            if( errorHandler != nil ) errorHandler(error);
        }
    }
}



/**
 Set ESM Schedules by using received NSData.

 @param data An ESM configuration
 @param response HTTP session response
 @param error An Error message
 */
- (void) setESMSchedulesWithData:(NSData *)data
                         response:(NSURLResponse *)response
                            error:(NSError *)error {
    
    if(data.length != 0){
        
        NSError * e = nil;
        NSArray * config = [NSJSONSerialization JSONObjectWithData:data
                                                           options:NSJSONReadingAllowFragments
                                                             error:&e];
        if ( e != nil) {
            NSLog(@"ERROR: %@", e.debugDescription);
            [self sendAlertMessageWithTitle:@"[iOS ESM ERROR] ESM Configuration Format Error"
                                    message:[NSString stringWithFormat:@"%@", e.debugDescription]
                               cancelButton:@"Close"];
            if( errorHandler != nil ) errorHandler(error);
            return;
        }
        
        if(config == nil){
            NSLog(@"ERROR: ESM configuration is null");
            [self sendAlertMessageWithTitle:@"[iOS ESM ERROR] ESM Configuration is null"
                                    message:@"Configuration Array is null"
                               cancelButton:@"Close"];
            if( errorHandler != nil ) errorHandler(error);
            return;
        }
        
        dispatch_async( dispatch_get_main_queue() , ^{
            
            /// remove scheduled ESM
            ESMScheduleManager * manager = [ESMScheduleManager sharedESMScheduleManager];
            [manager removeAllSchedulesFromDB];
            [manager removeAllNotifications];
            
            /// Set ESM schedules
            BOOL isESMReady = [manager setScheduleByConfig:config];
            
            if (isESMReady) {
                // Save the new ESM configuration if the configuration is new
                NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                NSData * newConfig      = [NSJSONSerialization dataWithJSONObject:config options:0 error:nil];
                NSData * previousConfig = [defaults objectForKey:@"previous.ios.esm.plugin.configuration.file"];
                if(previousConfig != nil && ![newConfig isEqual:previousConfig]){
                    if(AWAREUtils.isForeground && self.isDebug){
                        [self sendAlertMessageWithTitle:@"ESM configuration is updated correctly!"
                                                message:newConfig.debugDescription
                                           cancelButton:@"Close"];
                    }
                }
                [defaults setObject:newConfig forKey:@"previous.ios.esm.plugin.configuration.file"];
                
                if (self->completionHandler) {
                    self->completionHandler();
                }
            }
            
        });
        
    }else{
        [self sendAlertMessageWithTitle:@"Error iOS ESM" message:@"ESM data is empty" cancelButton:@"Close"];
        if( errorHandler != nil ) errorHandler(error);
    }
}

- (void)setErrorHandler:(ESMConfigurationSetupErrorHandler)handler{
    errorHandler = handler;
}

- (void)setViewController:(UIViewController *)vc{
    viewController = vc;
}

- (void) sendAlertMessageWithTitle:(NSString*)title message:(NSString *) message cancelButton:(NSString *)closeButtonTitle{
    // NSLog(@"%d, %d",[AWAREUtils isForeground], [self isDebug]);
    if (NSThread.isMainThread) {
        if([AWAREUtils isForeground] && [self isDebug]){
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:title
                                                                            message:message
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:closeButtonTitle
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            if(viewController != nil){
                [viewController presentViewController:alert animated:YES completion:nil];
            }
        }
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendAlertMessageWithTitle:title message:message cancelButton:closeButtonTitle];
        });
    }
}

- (NSString *) convertNSArraytoJsonStr:(NSArray *)array{
    if(array != nil){
        NSError * error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];
        if(error == nil){
            return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }
    return @"[]";
}

- (NSString *) getStringFromSettings:(NSArray *)settings key:(NSString *)key{
    NSString * value;
    for (NSDictionary * dict in settings ) {
        NSString * setting = [dict objectForKey:@"setting"];
        if( [setting isEqualToString:key]){
            value = [dict objectForKey:@"value"];
            break;
        }
    }
    return value;
}

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

+ (BOOL) hasESMAppearedInThisSession{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:@"key_esm_appeared_section"];
}

+ (void) setESMAppearedState:(BOOL)state{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:state forKey:@"key_esm_appeared_section"];
    [userDefaults synchronize];
}

@end
