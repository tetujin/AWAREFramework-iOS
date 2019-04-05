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

NSString * const AWARE_PREFERENCES_STATUS_PLUGIN_IOS_ESM     = @"status_plugin_ios_esm";
NSString * const AWARE_PREFERENCES_PLUGIN_IOS_ESM_TABLE_NAME = @"plugin_ios_esm_table_name";
NSString * const AWARE_PREFERENCES_PLUGIN_IOS_ESM_CONFIG_URL = @"plugin_ios_esm_config_url";

@implementation IOSESM {
    NSString * baseHttpSessionId;
    NSString * currentHttpSessionId;
    NSString * categoryIOSESM;
    NSMutableData * receiveData;
    bool isLock;
    NSString * tableName;
    NSArray * pluginSettings;
    // int responseCode;
    AWAREStudy * awareStudy;
    UIViewController * viewController;
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
        awareStudy = study;
        baseHttpSessionId = [NSString stringWithFormat:@"plugin_ios_esm_http_session_id"];
        currentHttpSessionId = [NSString stringWithFormat:@"%@_%f", baseHttpSessionId, [NSDate new].timeIntervalSince1970];
        categoryIOSESM = @"plugin_ios_esm_category";
        receiveData = [[NSMutableData alloc] init];
        isLock = NO;
        tableName = @"esms";
        _table = @"esms";
        
//        pluginSettings = [study getPluginSettingsWithKey:[NSString stringWithFormat:@"status_%@", SENSOR_PLUGIN_IOS_ESM]];
//        NSString * tempTableName = [self getStringFromSettings:pluginSettings key:@"plugin_ios_esm_table_name"];
//        if(tempTableName != nil){
//            tableName = tempTableName;
//        }
    }
    return self;
}


///////////////////////////////////////////////////////////////////
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
    _url = [self getStringFromSettings:parameters key:@"plugin_ios_esm_config_url"];
    _table = [self getStringFromSettings:parameters key:@"plugin_ios_esm_table_name"];
    if (_table == nil){
        _table = @"esms";
    }
}

///////////////////////////////////////////////////////////////////
- (BOOL)startSensor{
    [self setSensingState:YES];
    return [self startSensorWithURL:_url tableName:_table];
}

- (BOOL) startSensorWithURL:(NSString *)urlStr tableName:(NSString *)table{
    
    if (_table == nil) {
        return NO;
    }
    
    if(_url == nil){
        return NO;
    }
    
    // [self setBufferSize:0];
    
    // Get contents from URL
    NSURL * url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@?device_id=%@",urlStr,[self getDeviceId]]];
    [self getESMConfigFileFromURL:url];

    tableName = table;
    if(tableName == nil){
        tableName = @"esms";
    }
    
    [self performSelector:@selector(updateLatestValue:) withObject:nil afterDelay:3];

    return YES;
}

- (BOOL) stopSensor{
    // remove the sensor
    [self setSensingState:NO];
    return YES;
}

- (BOOL)quitSensor{
    [self removeNotificationSchedulesFromSQLite];
    [self removeNotificationSchedules];
    return YES;
}

////////////////////////////////////////////////////////////

- (void) updateLatestValue:(id)sender{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MM/dd HH:mm"];
    
    NSArray * esms = [self getScheduledESMs];
    NSMutableString * value = [[NSMutableString alloc] init];
    for(NSDictionary * dict in esms){
        
        NSDate   * fireDate   = [dict objectForKey:@"fire_date"];
        NSNumber * expiration = [dict objectForKey:@"expiration_threshold"];
        NSString * scheduleId = [dict objectForKey:@"schedule_id"];
        NSDate   * originalFireDate     = [dict objectForKey:@"original_fire_date"];
        NSNumber * randomize  = [dict objectForKey:@"randomize"];
        
        if(fireDate != nil &&
           expiration != nil &&
           scheduleId != nil &&
           originalFireDate != nil &&
           randomize != nil){
            NSString * tempValue = [NSString stringWithFormat:@"[%@][%@][%@][%@]", scheduleId, [format stringFromDate:fireDate], expiration, randomize];
            NSLog(@"%@",tempValue);
            [value appendFormat:@"%@\n",tempValue];
        }
    }
    [self setLatestValue:value];
    // [self setLatestData:[NSDictionary ]esms];
}


//////////////////////////////////////////////////////////
//- (void)syncAwareDBInBackgroundWithSensorName:(NSString *)name{
//    [super syncAwareDBInBackgroundWithSensorName:name];
//}


///////////////////////////////////////////////////////////
- (void) getESMConfigFileFromURL:(NSURL *)url{
   
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
    NSString *postLength = nil;
    
    // Set settion configu and HTTP/POST body.
    NSURLSessionConfiguration *sessionConfig = nil;
    
    // Make a HTTP session id
    currentHttpSessionId = [NSString stringWithFormat:@"%@", baseHttpSessionId]; //, [NSDate new].timeIntervalSince1970];
    
    // Make a seesion config for HTTP/POST
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:currentHttpSessionId];
    sessionConfig.timeoutIntervalForRequest = 60.0;
    sessionConfig.timeoutIntervalForResource = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 20;
    sessionConfig.allowsCellularAccess = YES;
    // sessionConfig.discretionary = YES;
    
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    // set HTTP/POST body information
    if([self isDebug]){
        NSLog(@"--- [%@] This is background task ----", [self getSensorName] );
    }
    session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
//  }

    if(![awareStudy isNetworkReachable]){
        if([AWAREUtils isForeground]){
            [self sendAlertMessageWithTitle:@"Network Connection Error on iOS ESM plugin" message:@"Network connection is failed" cancelButton:@"Close"];
        }
    }
}



- (void) saveRecievedESMsWithData:(NSData *)data
                         response:(NSURLResponse *)response
                            error:(NSError *)error {

    if(data.length != 0){
        
        NSError *e = nil;
        NSArray * esmArray = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingAllowFragments
                                                               error:&e];
        if ( e != nil) {
            NSLog(@"ERROR: %@", e.debugDescription);

            if([AWAREUtils isForeground]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self sendAlertMessageWithTitle:@"Configuration Format Error of iOS ESM"
                                            message:[NSString stringWithFormat:@"%@",e.debugDescription]
                                       cancelButton:@"Close"];
                });
            }
            return;
        }
        
        if(esmArray == nil){
            NSLog(@"ERROR: web esm array is null.");
            if([AWAREUtils isForeground]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    // [AWAREUtils sendLocalNotificationForMessage:@"ERROR iOS ESM:\nESM list is empty." soundFlag:NO];
                    [self sendAlertMessageWithTitle:@"Error iOS ESM" message:@"ESM list is empty." cancelButton:@"Close"];
                });
            }
            return;
        }
        
        NSString * jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@", jsonStr);
        
        [self setScheduledESMs:esmArray];

    }else{
        if([AWAREUtils isForeground]){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self sendAlertMessageWithTitle:@"Error iOS ESM" message:@"ESM data is empty" cancelButton:@"Close"];
            });
        }
    }
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
            if([self isDebug]){
                NSLog(@"[%@] Got Web ESM configuration file from server", [self getSensorName]);
            }
        }else{
            [session invalidateAndCancel];
            receiveData = [[NSMutableData alloc] init];
        }
    }else{
        NSLog(@"******** ios esm ********");
        // [super URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
        [session invalidateAndCancel];
        completionHandler(NSURLSessionResponseAllow);
    }
}


-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    if (self.isDebug) NSLog(@"iOS ESM Plugin: Did received Data");
    // NSLog(@"%@", dataTask.currentRequest.URL);
    
    // NSString * log = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // NSLog(@"%@",log);
    
    if([session.configuration.identifier isEqualToString:currentHttpSessionId]){
        if(data != nil){
            NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            [receiveData appendData:data];
        }
    }else{
        NSLog(@"****** ios esm *******");
        // [super URLSession:session dataTask:dataTask didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    
    if (self.isDebug) NSLog(@"iOS ESM Plugin: Did compleate");
    
    if(error != nil){
        NSLog(@"Error: %@", error.debugDescription);
        receiveData = [[NSMutableData alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            if([AWAREUtils isForeground]){
                [self sendAlertMessageWithTitle:@"[iOS ESM] Configuration File Download Error"
                                        message:error.debugDescription
                                   cancelButton:@"Close"];
            }
            // NSString * message = [NSString stringWithFormat:@"[iOS ESM] Configuration File Download Error: %@", error.debugDescription];
            // [self saveDebugEventWithText:message type:DebugTypeWarn label:@"iOS ESM"];
        });
        return;
    }
    
    if([session.configuration.identifier isEqualToString:currentHttpSessionId]){
        [self saveRecievedESMsWithData:[receiveData copy] response:nil error:error];
        receiveData = [[NSMutableData alloc] init];
    }else{
       // [super URLSession:session task:task didCompleteWithError:error];
    }
    
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    
    if([session.configuration.identifier isEqualToString:currentHttpSessionId]){
        if (error != nil) {
            if([self isDebug]){
                NSLog(@"[%@] the session did become invaild with error: %@", [self getSensorName], error.debugDescription);
            }
            if([AWAREUtils isForeground]){
                //[AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"ERROR iOS ESM:\n%@",error.debugDescription] soundFlag:NO];
                [self sendAlertMessageWithTitle:@"Error iOS ESM" message:error.debugDescription cancelButton:@"Close"];
            }
        }
    }else{
        //[super URLSession:session didBecomeInvalidWithError:error];
    }
}

//////////////////////////////////////////////////////////////



- (void) setScheduledESMs:(NSArray *) ESMArray {
    
    @try {
        dispatch_async( dispatch_get_main_queue() , ^{
            NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            context.persistentStoreCoordinator = [CoreDataHandler sharedHandler].persistentStoreCoordinator;
            
            int number = 0;
            
            for (NSDictionary * schedule in ESMArray) {
                NSArray * hours = [schedule objectForKey:@"hours"];
                // NSArray * weekdays = [schedule objectForKey:@"weekdays"];
                // NSArray * months = [schedule objectForKey:@"months"];
                NSArray * esms = [schedule objectForKey:@"esms"];
                
                NSNumber * randomize_schedule = [schedule objectForKey:@"randomize"];
                NSNumber * expiration = [schedule objectForKey:@"expiration"];
                
                NSString * startDateStr = [schedule objectForKey:@"start_date"];
                NSString *   endDateStr = [schedule objectForKey:@"end_date"];
                
                
                NSString * notificationTitle = [schedule objectForKey:@"notification_title"];
                NSString * notificationBody = [schedule objectForKey:@"notification_body"];
                NSString * scheduleId = [schedule objectForKey:@"schedule_id"];
                NSString * eventContext = [self convertNSArraytoJsonStr:[schedule objectForKey:@"context"]];
                if(eventContext == nil) {
                    eventContext = @"[]";
                }
                
                NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"MM-dd-yyyy"];
                // [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
                
                NSDate *startDate = [formatter dateFromString:startDateStr];
                NSDate *endDate   = [formatter dateFromString:endDateStr];
                
                if(startDate == nil){
                    startDate = [[NSDate alloc] initWithTimeIntervalSince1970:0];
                }
                
                if(endDate == nil){
                    endDate = [[NSDate alloc] initWithTimeIntervalSince1970:2147483647];
                }
                
                if(expiration == nil) expiration = @0;
                
                NSNumber * interface = [schedule objectForKey:@"interface"];
                if(interface == nil) interface = @0;
                // NSLog(@"interface: %@", interface);
                
                for (NSNumber * hour in hours) {
                    EntityESMSchedule * entityESMSchedule = (EntityESMSchedule *) [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMSchedule class])
                                                                                                           inManagedObjectContext:context];
                    entityESMSchedule.fire_hour = hour;
                    entityESMSchedule.expiration_threshold = expiration;
                    entityESMSchedule.start_date = startDate;
                    entityESMSchedule.end_date = endDate;
                    entityESMSchedule.notification_title = notificationTitle;
                    entityESMSchedule.notification_body = notificationBody;
                    entityESMSchedule.randomize_schedule = randomize_schedule;
                    entityESMSchedule.schedule_id = scheduleId;
                    entityESMSchedule.contexts = eventContext;
                    entityESMSchedule.interface = interface;
                    
                    for (NSDictionary * esmDict in esms) {
                        NSDictionary * esm = [esmDict objectForKey:@"esm"];
                        EntityESM * entityEsm = (EntityESM *) [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESM class])
                                                                                            inManagedObjectContext:context];
                        entityEsm.esm_type   = [esm objectForKey:@"esm_type"];
                        entityEsm.esm_title  = [esm objectForKey:@"esm_title"];
                        entityEsm.esm_submit = [esm objectForKey:@"esm_submit"];
                        entityEsm.esm_instructions = [esm objectForKey:@"esm_instructions"];
                        entityEsm.esm_radios     = [self convertNSArraytoJsonStr:[esm objectForKey:@"esm_radios"]];
                        entityEsm.esm_checkboxes = [self convertNSArraytoJsonStr:[esm objectForKey:@"esm_checkboxes"]];
                        entityEsm.esm_likert_max = [esm objectForKey:@"esm_likert_max"];
                        entityEsm.esm_likert_max_label = [esm objectForKey:@"esm_likert_max_label"];
                        entityEsm.esm_likert_min_label = [esm objectForKey:@"esm_likert_min_label"];
                        entityEsm.esm_likert_step = [esm objectForKey:@"esm_likert_step"];
                        entityEsm.esm_quick_answers = [self convertNSArraytoJsonStr:[esm objectForKey:@"esm_quick_answers"]];
                        entityEsm.esm_expiration_threshold = [esm objectForKey:@"esm_expiration_threshold"];
                        // entityEsm.esm_status    = [esm objectForKey:@"esm_status"];
                        entityEsm.esm_status = @0;
                        entityEsm.esm_trigger   = [esm objectForKey:@"esm_trigger"];
                        entityEsm.esm_scale_min = [esm objectForKey:@"esm_scale_min"];
                        entityEsm.esm_scale_max = [esm objectForKey:@"esm_scale_max"];
                        entityEsm.esm_scale_start = [esm objectForKey:@"esm_scale_start"];
                        entityEsm.esm_scale_max_label = [esm objectForKey:@"esm_scale_max_label"];
                        entityEsm.esm_scale_min_label = [esm objectForKey:@"esm_scale_min_label"];
                        entityEsm.esm_scale_step = [esm objectForKey:@"esm_scale_step"];
                        entityEsm.esm_json = [self convertNSArraytoJsonStr:@[esm]];
                        entityEsm.esm_number = @(number);
                        // for date&time picker
                        entityEsm.esm_start_time = [esm objectForKey:@"esm_start_time"];
                        entityEsm.esm_start_date = [esm objectForKey:@"esm_start_date"];
                        entityEsm.esm_time_format = [esm objectForKey:@"esm_time_format"];
                        entityEsm.esm_minute_step = [esm objectForKey:@"esm_minute_step"];
                        // for web ESM url
                        entityEsm.esm_url = [esm objectForKey:@"esm_url"];
                        // for na
                        entityEsm.esm_na = @([[esm objectForKey:@"esm_na"] boolValue]);
                        entityEsm.esm_flows = [self convertNSArraytoJsonStr:[esm objectForKey:@"esm_flows"]];
                        // NSLog(@"[%d][integration] %@",number, [esm objectForKey:@"esm_app_integration"]);
                        entityEsm.esm_app_integration = [esm objectForKey:@"esm_app_integration"];
                        // entityEsm.esm_schedule = entityESMSchedule;
                        
                        [entityESMSchedule addEsmsObject:entityEsm];
                        
                        number ++;
                    }
                }
            }
            
            // remove all ESMs from SQLite
            [self removeNotificationSchedulesFromSQLite];
            [self removeNotificationSchedules];
            
            // save new ESMs
            NSError * e = nil;
            if(![context save:&e]){
                NSLog(@"Error: %@", e.debugDescription);
                if([AWAREUtils isForeground]){
                    [self sendAlertMessageWithTitle:@"ERROR iOS ESM" message:e.debugDescription cancelButton:@"Close"];
                }
            }else{
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSData * currentData = [NSJSONSerialization dataWithJSONObject:ESMArray options:0 error:nil];
                NSData * previousData = [defaults objectForKey:@"previous.ios.esm.plugin.configuration.file"];
                if(previousData != nil && ![currentData isEqual:previousData]){
                    if([AWAREUtils isForeground]){
                        NSString * encodedString = [[NSString alloc] initWithData:currentData encoding:NSUTF8StringEncoding];
                        [self sendAlertMessageWithTitle:@"ESM configuration is updated correctly!" message:encodedString cancelButton:@"Close"];
                    }
                }
                [defaults setObject:currentData forKey:@"previous.ios.esm.plugin.configuration.file"];
            }
            
            [self setNotificationSchedules];
            
        });
    } @catch (NSException *exception) {
        NSLog(@"ERROR: A format convert error are ocured @ WebESM. %@", exception.debugDescription);
        if([AWAREUtils isForeground]){
            [self sendAlertMessageWithTitle:@"ERROR iOS ESM" message:exception.debugDescription cancelButton:@"Close"];
        }
    } @finally {
        
    }
    
}

- (void)setViewController:(UIViewController *)vc{
    viewController = vc;
}

- (void) sendAlertMessageWithTitle:(NSString*)title message:(NSString *) message cancelButton:(NSString *)closeButtonTitle{
    
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

- (void) refreshNotifications {
    [self removeNotificationSchedules];
    [self setNotificationSchedules];
}

- (void) removeNotificationSchedulesFromSQLite {
    // AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([EntityESMSchedule class])];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    NSError *deleteError = nil;
    [[CoreDataHandler sharedHandler].managedObjectContext executeRequest:delete error:&deleteError];
    // [delegate.sharedCoreDataHandler.managedObjectContext executeRequest:delete error:&deleteError];
    if(deleteError != nil){
        NSLog(@"ERROR: A delete query is failed");
    }
}

///////////////////////////////////////////////////////////////


- (void) setNotificationSchedules {
    // Get ESMs from SQLite by using CoreData
    // AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([EntityESMSchedule class])];
    [fetchRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class])
                                        inManagedObjectContext:[CoreDataHandler sharedHandler].managedObjectContext]];
    
    NSDate * now = [NSDate new];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(start_date <= %@) AND (end_date >= %@)", now, now]];
    NSError *error = nil;
    NSArray *results = [[CoreDataHandler sharedHandler].managedObjectContext executeFetchRequest:fetchRequest error:&error] ;
    
    if(results == nil) return;
    
    for (int i=0; i<results.count; i++) {
        
        EntityESMSchedule * schedule = results[i];
        
        NSNumber * randomize = schedule.randomize_schedule;
        if(randomize == nil) randomize = @0;
        
        NSNumber * fireHour   = schedule.fire_hour;
        NSNumber * expiration = schedule.expiration_threshold;
        NSDate   * fireDate   = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES];
        NSDate   * originalFireDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES];
        NSString * scheduleId = schedule.schedule_id;
        NSNumber * interface  = schedule.interface;
        
        if(![randomize isEqualToNumber:@0]){
            // Make a andom date
            int randomMin = (int)[self randomNumberBetween:-1*randomize.integerValue maxNumber:randomize.integerValue];
            fireDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] minute:randomMin second:0 nextDay:YES];
        }
        
        // The fireData is Valid Time?
        NSDate * expirationTime = [originalFireDate dateByAddingTimeInterval:expiration.integerValue * 60];
        NSDate * inspirationTime = originalFireDate;
        if(randomize > 0){
            // expirationTime = [fireDate dateByAddingTimeInterval:expiration.integerValue * 60 + randomize.integerValue*60];
            inspirationTime = [originalFireDate dateByAddingTimeInterval:-1*randomize.integerValue * 60];
        }
        bool isInTime = NO;
        if(inspirationTime.timeIntervalSince1970 <= now.timeIntervalSince1970
           && expirationTime.timeIntervalSince1970 >= now.timeIntervalSince1970){
            isInTime = YES;
        }
        NSLog(@"[BASE_TIME:%@]\n[CURRENT_TIME:%@]\n[EXPIRATION_TIME:%@][IN_TIME:%d]", inspirationTime, now, expirationTime, isInTime);
        // Check an answering condition
        if(isInTime){
            
            [fireDate dateByAddingTimeInterval:60*60*24]; // <- temporary solution
            
//            NSFetchRequest *fetchRequest4History = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([EntityESMHistory class])];
//            [fetchRequest4History setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMHistory class])
//                                                        inManagedObjectContext:delegate.managedObjectContext]];
//            [fetchRequest4History setPredicate:[NSPredicate predicateWithFormat:@"(trigger==%@) AND (original_fire_date >= %@) AND (original_fire_date <= %@)",
//                                                scheduleId,[AWAREUtils getUnixTimestamp:inspirationTime], [AWAREUtils getUnixTimestamp:expirationTime]]];
//            NSError *error4History = nil;
//            NSArray *histories = [delegate.managedObjectContext executeFetchRequest:fetchRequest4History error:&error4History] ;
//            if(histories != nil){
//                if (histories.count > 0) {
//                    [fireDate dateByAddingTimeInterval:60*60*24];
//                }
//            }
            
        }
        
        // NSLog(@"[%@] Fire Date: %@", scheduleId, [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES]);
        // NSLog(@"[%@] Fire Date: %@ (%@)", scheduleId, fireDate, [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES]);
        
        NSDictionary * userInfo = [[NSDictionary alloc] initWithObjects:@[originalFireDate, randomize, scheduleId,expiration,fireDate,interface]
                                                                forKeys:@[@"original_fire_date", @"randomize",
                                                                          @"schedule_id", @"expiration_threshold",@"fire_date",@"interface"]];
        
        // if([fireHour isEqualToNumber:@-1] || [fireHour isEqualToNumber:@0]){
        if([fireHour isEqualToNumber:@-1]){
            
        }else{ // If the value is 1-24
            // [TEST]
            // fireDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:11 minute:30 second:0 nextDay:YES];
//            [AWAREUtils sendLocalNotificationForMessage:schedule.noitification_body
//                                                  title:schedule.notification_title
//                                              soundFlag:YES
//                                               category:categoryIOSESM
//                                               fireDate:fireDate
//                                         repeatInterval:NSCalendarUnitDay
//                                               userInfo:userInfo
//                                        iconBadgeNumber:1];
            UNMutableNotificationContent * content = [[UNMutableNotificationContent alloc] init];
            content.title = schedule.notification_title;
            content.body = schedule.notification_body;
            content.sound = [UNNotificationSound defaultSound];
            content.categoryIdentifier = categoryIOSESM;
            content.userInfo = userInfo;
            content.badge = @(1);
            
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDateComponents *components = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:fireDate];
            UNCalendarNotificationTrigger * trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:YES];
            
            UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:KEY_AWARE_NOTIFICATION_DEFAULT_REQUEST_IDENTIFIER content:content trigger:trigger];
            
            [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                
            }];
        }
        
        // WIP: WEEKLY and MONTHLY Notifications
        
        // WIP: Quick ESM (YES/NO and Text)
        
        // WIP: Event based ESMs (battery, activity, and/or network)
        
        // WIP: Location based ESMs
    }
    

    
    
    [self getValidESMSchedulesWithDatetime:[NSDate new]];
    
    // [self setLatestValue:[NSString stringWithFormat:@"You have %ld scheduled notification(s)", results.count]];
    // });
}


- (NSInteger)randomNumberBetween:(NSInteger)min maxNumber:(NSInteger)max {
    return min + arc4random_uniform(max - min + 1);
}


- (void) removeNotificationSchedules {
    NSArray * notifications = [UIApplication sharedApplication].scheduledLocalNotifications;
    
    if(notifications == nil){
        return;
    }
    
    for (UILocalNotification * notification in notifications) {
        if([notification.category isEqualToString:categoryIOSESM]) {
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
    }
}

- (NSArray *) getValidESMSchedulesWithDatetime:(NSDate *) datetime {
    
    NSMutableArray * esmSchedules = [[NSMutableArray alloc] init];
    
    /////////////////////////////////////////////////////////
    // get fixed esm schedules
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    [req setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class])
                    inManagedObjectContext:[CoreDataHandler sharedHandler].managedObjectContext]];

    //[req setPredicate:[NSPredicate predicateWithFormat:@"(start_date <= %@) AND (end_date >= %@) AND (fire_hour=-1)", datetime, datetime]];
    // OR (expiration=0)
    [req setPredicate:[NSPredicate predicateWithFormat:@"(start_date <= %@) AND (end_date >= %@) OR (expiration_threshold=0)", datetime, datetime]];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"start_date" ascending:NO];
    NSSortDescriptor *sortBySID = [[NSSortDescriptor alloc] initWithKey:@"schedule_id" ascending:NO];
    [req setSortDescriptors:@[sort,sortBySID]];
    
    NSFetchedResultsController *fetchedResultsController
    = [[NSFetchedResultsController alloc] initWithFetchRequest:req
                                          managedObjectContext:[CoreDataHandler sharedHandler].managedObjectContext
                                            sectionNameKeyPath:nil
                                                     cacheName:nil];
    
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    NSArray *results = [fetchedResultsController fetchedObjects];
    if ([self isDebug]){
        if(results != nil){
            NSLog(@"Stored ESM Schedules are %tu", results.count);
        }else{
            NSLog(@"Stored ESM Schedule is Null.");
        }
    }
    
    for (EntityESMSchedule * schedule in results) {
        NSSet * childEsms = schedule.esms;
        // NSNumber * interface = schedule.interface;
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"esm_number" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sort,nil];
        NSArray *sortedEsms = [childEsms sortedArrayUsingDescriptors:sortDescriptors];
        // NSLog(@"[child esms:%ld]",childEsms.count);
        /**
         * Check validation of the schedule by 'expiration' and 'randomization' element
         */
        NSString * scheduleId = schedule.schedule_id;

        NSNumber * randomize = schedule.randomize_schedule;
        if(randomize == nil) randomize = @0;
        NSNumber * expiration = schedule.expiration_threshold;
        if(expiration == nil) expiration = @0;
        int validRange = 60*(randomize.intValue + expiration.intValue); // min
        
        NSNumber * fireHour = schedule.fire_hour;
        NSDate * targetDateToday       = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:NO];
        NSDate * targetDateNextday     = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES];
        NSDate * validStartDateToday   = [targetDateToday   dateByAddingTimeInterval:-1 * validRange];
        NSDate * validEndDateToday     = [targetDateToday   dateByAddingTimeInterval:validRange];
        NSDate * validStartDateNextday = [targetDateNextday dateByAddingTimeInterval:-1 * validRange];
        NSDate * validEndDateNextday   = [targetDateNextday dateByAddingTimeInterval:validRange];
        NSDate * now = [NSDate date];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MM/dd/yyyy HH:mm"];
        [NSTimeZone resetSystemTimeZone];
        // NSString *date = [dateFormat stringFromDate:time];
        
        bool isValidESM = NO;
        if(scheduleId == nil){
            isValidESM = NO;
            // NSLog(@"invalid condition: schedule_id is null");
        }else if([expiration isEqualToNumber:@0]){
            //NSLog(@"-----");
            //NSLog(@"vaild condition  : expiration is '0' : %@",scheduleId);
            //NSLog(@"-----");
            isValidESM = YES;
        }else if ( ((now.timeIntervalSince1970 >= validStartDateToday.timeIntervalSince1970) && (now.timeIntervalSince1970 <= validEndDateToday.timeIntervalSince1970 )) ||
                   ((now.timeIntervalSince1970 >= validStartDateNextday.timeIntervalSince1970) && (now.timeIntervalSince1970 <= validEndDateNextday.timeIntervalSince1970)) ){
//            NSLog(@"-----");
//            NSLog(@"vaild condition  : [%@ <-- (%@) --> %@] : %@",
//                  [dateFormat stringFromDate:validStartDateToday],
//                  [dateFormat stringFromDate:now],
//                  [dateFormat stringFromDate:validEndDateToday],
//                  scheduleId);
//            NSLog(@"vaild condition  : [%@ <-- (%@) --> %@] : %@",
//                  [dateFormat stringFromDate:validStartDateNextday],
//                  [dateFormat stringFromDate:now],
//                  [dateFormat stringFromDate:validEndDateNextday],
//                  scheduleId);
//            NSLog(@"-----");
            isValidESM = YES;
        }else{
//            NSLog(@"-----");
//            NSLog(@"invaild condition: [%@ <-- (%@) --> %@] : %@",
//                  [dateFormat stringFromDate:validStartDateToday],
//                  [dateFormat stringFromDate:now],
//                  [dateFormat stringFromDate:validEndDateToday],
//                  scheduleId);
//            NSLog(@"invaild condition: [%@ <-- (%@) --> %@] : %@",
//                  [dateFormat stringFromDate:validStartDateNextday],
//                  [dateFormat stringFromDate:now],
//                  [dateFormat stringFromDate:validEndDateNextday],
//                  scheduleId);
//            NSLog(@"-----");
            // NSLog(@"invalid condition: unkown");
        }
        
        if(isValidESM){
            for (EntityESM * esm in sortedEsms) {
                esm.timestamp = [AWAREUtils getUnixTimestamp:datetime];
                // esm.interface = interface;
                // debug
//                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//                [dateFormat setDateFormat:@"MM/dd/yyyy HH:mm"];
//                [NSTimeZone resetSystemTimeZone];
//                NSString *date = [dateFormat stringFromDate:datetime];
//                
//                [dateFormat setTimeZone:[NSTimeZone systemTimeZone]];
//                NSLog(@"[timestamp:%@][type:%@][trigger:%@][fire:%@][interface:%@] %@",
//                      esm.esm_number, esm.esm_type,
//                      esm.esm_trigger, date, esm.interface, esm.esm_title );
            }
            bool hasScheduleId = NO;
            for (EntityESMSchedule * storedSchedule in esmSchedules) {
                if([storedSchedule.schedule_id isEqualToString:scheduleId]){
                    // NSLog(@"%@ is already exist!", scheduleId);
                    hasScheduleId = YES;
                    break;
                }
            }
            if(!hasScheduleId && scheduleId != nil){
                [esmSchedules addObject:schedule];
                NSLog(@"[id:%@][randomize:%@][expiration:%@]",scheduleId,randomize,expiration);
            }
        }
    }
    
    if([self isDebug]){
        NSLog(@"esm schedule: %tu", esmSchedules.count);
    }
    
    return esmSchedules;

    
    ///////////////////////////////////////////////////////
    // Get notification schedules
    // NSNumber * interface = @0;
//    NSArray * notifications = [UIApplication sharedApplication].scheduledLocalNotifications;
//    NSLog(@"Registered Notifications: %ld", notifications.count);
//    
//    NSMutableArray * validSchedules = [[NSMutableArray alloc] init];
//    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
//    for (UILocalNotification * notification in notifications) {
//        if([notification.category isEqualToString:categoryIOSESM]) {
//            //@"fire_date",@"randomize",@"schedule_id"
//            NSDictionary * userInfo = notification.userInfo;
//            // NSDate * fireDate = notification.fireDate;
//            // NSDate * fireDate = [notification.fireDate dateByAddingTimeInterval:-1*randomize];
//            //NSNumber * randomize = [userInfo objectForKey:@"randomize"];
//            NSNumber * expiration = [userInfo objectForKey:@"expiration_threshold"];
//            NSString * scheduleId = [userInfo objectForKey:@"schedule_id"];
//            NSDate * fireDate = [userInfo objectForKey:@"original_fire_date"];
//            if(fireDate == nil) fireDate = notification.fireDate;
//            NSNumber * randomize = [userInfo objectForKey:@"randomize"];
//            if(randomize == nil) randomize = 0;
//            
//            // check expiration
//            NSDate * expirationTime = [fireDate dateByAddingTimeInterval:expiration.integerValue * 60];
//
//            if(randomize > 0){
//                // expirationTime = [fireDate dateByAddingTimeInterval:expiration.integerValue * 60 + randomize.integerValue*60];
//                fireDate = [fireDate dateByAddingTimeInterval:-1*randomize.integerValue * 60];
//            }
//            
//            if(fireDate.timeIntervalSince1970 > datetime.timeIntervalSince1970){
//                // expire_time = [current_time] - [24hours] - [randomized_time];
//                expirationTime = [expirationTime dateByAddingTimeInterval:-1*(60*60*24)];
//                fireDate       = [fireDate dateByAddingTimeInterval:-1*(60*60*24)];
//            }
//            
//            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//            [dateFormat setDateFormat:@"dd HH:mm"];
//            [NSTimeZone resetSystemTimeZone];
//            
//            NSLog( @"Now = %@ [valid duration = (%@ <---> %@)]",
//                  [dateFormat stringFromDate:datetime],
//                  [dateFormat stringFromDate:fireDate],
//                  [dateFormat stringFromDate:expirationTime]
//                  );
//            NSLog(@"Expiration ---> %ld",expiration.integerValue);
//            NSLog(@"Randomize  ---> %ld",randomize.integerValue);
//            if( expiration.integerValue == 0 || (datetime.timeIntervalSince1970 >= fireDate.timeIntervalSince1970 && datetime.timeIntervalSince1970 <= expirationTime.timeIntervalSince1970))
//            {
//                bool isNew = YES;
//                for (UILocalNotification * notif in validSchedules ) {
//                    NSString * sId = [notif.userInfo objectForKey:@"schedule_id"];
//                    if([sId isEqualToString:scheduleId]){
//                        isNew = NO;
//                        break;
//                    }
//                }
//                if(isNew){
//                    [validSchedules addObject:notification];
//                }
//            }
//        }
//    }
//    
//    
//    
//    for (UILocalNotification * notif  in validSchedules) {
//        NSString * scheduleId = [notif.userInfo objectForKey:@"schedule_id"];
//        NSDate * fireDate = notif.fireDate;
//        // NSNumber * expiration = [notif.userInfo objectForKey:@"expiration_threshold"];
//        NSNumber * interface = [notif.userInfo objectForKey:@"interface"];
//        // NSLog(@"===> %@", [AWAREUtils getUnixTimestamp:fireDate]);
//        
//        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([EntityESMSchedule class])];
//        [fetchRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class])
//                                            inManagedObjectContext:delegate.managedObjectContext]];
//        // [fetchRequest setFetchLimit:1]; // comment out this line for getting multiple esm from SQLite
//        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(start_date <= %@) AND (end_date >= %@) AND (schedule_id=%@)", datetime, datetime, scheduleId]];
//        
//        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"start_date" ascending:NO];
//        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
//        
//        NSFetchedResultsController *fetchedResultsController
//        = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
//                                              managedObjectContext:delegate.managedObjectContext
//                                                sectionNameKeyPath:nil
//                                                         cacheName:nil];
//        
//        NSError *error = nil;
//        if (![fetchedResultsController performFetch:&error]) {
//            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        }
//        
//        NSArray *results = [fetchedResultsController fetchedObjects];
//        
//        for (EntityESMSchedule * schedule in results) {
//            
//            NSSet * childEsms = schedule.esms;
//            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"esm_number" ascending:YES];
//            NSArray *sortDescriptors = [NSArray arrayWithObjects:sort,nil];
//            NSArray *sortedEsms = [childEsms sortedArrayUsingDescriptors:sortDescriptors];
//            for (EntityESM * esm in sortedEsms) {
//                
//                esm.timestamp = [AWAREUtils getUnixTimestamp:fireDate];
//                esm.interface = interface;
//                
//                [esmSchedules addObject:esm];
//                NSDate * time = fireDate;
//                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//                [dateFormat setDateFormat:@"MM/dd/yyyy HH:mm"];
//                [NSTimeZone resetSystemTimeZone];
//                NSString *date = [dateFormat stringFromDate:time];
//                
//                [dateFormat setTimeZone:[NSTimeZone systemTimeZone]];
//                NSLog(@"[timestamp:%@][type:%@][trigger:%@][fire:%@][interface:%@] %@",
//                      esm.esm_number, esm.esm_type,
//                      esm.esm_trigger, date, esm.interface, esm.esm_title );
//            }
//        }
//    }
    
    
    
    ////////////////////////////////////////////
    // return
//    return esmSchedules;
}


//            if( datetime.timeIntervalSince1970 > expirationTime.timeIntervalSince1970 ){
//                // check history and expiration of the esm
//                // NSLog(@"%f > %f", datetime.timeIntervalSince1970, expirationTime.timeIntervalSince1970 );
//                continue;
//            }else{
//                // check a duplicate schedule
//
//                NSLog(@"%f > %f", datetime.timeIntervalSince1970, expirationTime.timeIntervalSince1970 );
//
//                bool isNew = YES;
//                for (UILocalNotification * notif in validSchedules ) {
//                    NSString * sId = [notif.userInfo objectForKey:@"schedule_id"];
//                    if([sId isEqualToString:scheduleId]){
//                        isNew = NO;
//                        break;
//                    }
//                }
//
//                if(isNew){
//                    [validSchedules addObject:notification];
//                }else{
//                    continue;
//                }
//            }


- (NSArray *) getScheduledESMs{
    NSMutableArray * esms = [[NSMutableArray alloc] init];
    NSArray * notifications = [UIApplication sharedApplication].scheduledLocalNotifications;
    
    if(notifications == nil){
        return esms;
    }
    
    for (UILocalNotification * notification in notifications) {
        if([notification.category isEqualToString:categoryIOSESM]) {
            // [[UIApplication sharedApplication] cancelLocalNotification:notification];
            [esms addObject:notification.userInfo];
        }
    }
    
    return esms;
}

////////////////////////////////////////////////////////////////

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





////////////////////////////////////////////////////////////

- (NSString *)getStringFromSettings:(NSArray *)settings key:(NSString *)key{
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

//////////////////////////////////////////////////////////////

- (void) saveDummyData {
    [self saveESMAnswerWithTimestamp:[AWAREUtils getUnixTimestamp:[NSDate new]]
                            deviceId:[self getDeviceId]
                             esmJson:@"[]"
                          esmTrigger:@"dummy"
              esmExpirationThreshold:@0
              esmUserAnswerTimestamp:[AWAREUtils getUnixTimestamp:[NSDate new]]
                       esmUserAnswer:@"dummy"
                           esmStatus:@2];
}


- (void) saveESMAnswerWithTimestamp:(NSNumber * )timestamp
                           deviceId:(NSString *) deviceId
                            esmJson:(NSString *) esmJson
                         esmTrigger:(NSString *) esmTrigger
             esmExpirationThreshold:(NSNumber *) esmExpirationThreshold
             esmUserAnswerTimestamp:(NSNumber *) esmUserAnswerTimestamp
                      esmUserAnswer:(NSString *) esmUserAnswer
                          esmStatus:(NSNumber *) esmStatus {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        context.persistentStoreCoordinator = [CoreDataHandler sharedHandler].persistentStoreCoordinator;
        EntityESMAnswer * answer = (EntityESMAnswer *)
        [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMAnswer class])
                                      inManagedObjectContext:context];
        // add special data to dic from each uielements
        answer.device_id = deviceId;
        answer.timestamp = timestamp;
        answer.esm_json = esmJson;
        answer.esm_trigger = esmTrigger;
        answer.esm_user_answer = esmUserAnswer;
        answer.esm_expiration_threshold = esmExpirationThreshold;
        answer.double_esm_user_answer_timestamp = esmUserAnswerTimestamp;
        answer.esm_status = esmStatus;
        
        NSError * error = nil;
        [context save:&error];
        if(error != nil){
            NSLog(@"%@", error.debugDescription);
            if([self isDebug]){
                // [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"ERROR: %@",  error.debugDescription] soundFlag:NO];
            }
        }
    });
}



///////////////////////////////////////////////
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


//////////////////////////////////////////////////

+ (BOOL) hasESMAppearedInThisSession{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:@"key_esm_appeared_section"];
}

+ (void) setESMAppearedState:(BOOL)state{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:state forKey:@"key_esm_appeared_section"];
    [userDefaults synchronize];
}

//+ (void)setTableVersion:(int)version{
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    [userDefaults setInteger:version forKey:@"key_esm_table_version"];
//    [userDefaults synchronize];
//}
//
//+ (int)getTableVersion{
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    NSInteger version = [userDefaults integerForKey:@"key_esm_table_version"];
//    
//    if(version == 0){ // "0" means that the table version is not setted yet.
//        version = 2; // verion 2 is the latest version (2016/12/16)
//    }
//    return (int)version;
//}

@end
