//
//  WebESM.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/8/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "WebESM.h"
#import "TCQMaker.h"
#import "EntityESM+CoreDataClass.h"
#import "EntityESMSchedule.h"
#import "SingleESMObject.h"
#import "EntityESMHistory.h"
#import "EntityESMAnswer.h"
#import "AWAREUtils.h"
#import "AWAREKeys.h"
#import "AWAREDelegate.h"

@implementation WebESM {
    NSString * baseHttpSessionId;
    NSString * currentHttpSessionId;
    NSString * categoryWebESM;
    NSMutableData * receiveData;
    bool isLock;
}

-(instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_WEB_ESM //@"esms"
                        dbEntityName:NSStringFromClass([EntityESMAnswer class])
                              dbType:AwareDBTypeCoreData];
    if(self != nil){
        baseHttpSessionId = [NSString stringWithFormat:@"plugin_web_esm_http_session_id"];
        currentHttpSessionId = [NSString stringWithFormat:@"%@_%f", baseHttpSessionId, [NSDate new].timeIntervalSince1970];
        categoryWebESM = @"plugin_web_esm_category";
        receiveData = [[NSMutableData alloc] init];
        isLock = NO;
        [self allowsDateUploadWithoutBatteryCharging];
        [self allowsCellularAccess];
        [self setCSVHeader:@[@"esm_json",
                             @"esm_status",
                             @"esm_expiration_threshold",
                             @"double_esm_user_answer_timestamp",
                             @"esm_user_answer",
                             @"esm_trigger"]];
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
    
    [self createTable:query withTableName:@"esms"];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    // Get contents from URL
    [self setBufferSize:0];
    
    // url
    NSString * urlStr = [self getURLFromSettings:settings key:@"plugin_web_esm_url"];
    NSURL * url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@?device_id=%@",urlStr,[self getDeviceId]]];
    [self getESMConfigFileFromURL:url];
    
    NSArray *esms = [self getValidESMsWithDatetime:[NSDate new]];
    if(esms != nil){
        [self setLatestValue:[NSString stringWithFormat:@"You have %d esm(s)", (int)esms.count]];
    }
    
    return YES;
}

- (BOOL) stopSensor{
    // remove the sensor
    return YES;
}

///////////////////////////////////////////////////////////


//- (void)syncAwareDB{
//    [self syncAwareDBInBackgroundWithSensorName:@"esms"];
//}
//
//
//- (void) syncAwareDBInBackground{
//    [self syncAwareDBInBackgroundWithSensorName:@"esms"];
//}
//
//
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
    currentHttpSessionId = [NSString stringWithFormat:@"%@_%f", baseHttpSessionId, [NSDate new].timeIntervalSince1970];
    
    
    // Make a seesion config for HTTP/POST
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:currentHttpSessionId];
    sessionConfig.timeoutIntervalForRequest = 180.0;
    sessionConfig.timeoutIntervalForResource = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60;
    sessionConfig.allowsCellularAccess = YES;
    sessionConfig.discretionary = YES;
    
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
}


- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    if([session.configuration.identifier isEqualToString:currentHttpSessionId]){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        int responseCode = (int)[httpResponse statusCode];
        if (responseCode == 200) {
            if([self isDebug]){
                NSLog(@"[%@] Got Web ESM configuration file from server", [self getSensorName]);
            }
        }
        [session finishTasksAndInvalidate];
        [session invalidateAndCancel];
        completionHandler(NSURLSessionResponseAllow);
    }else{
        [super URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    }
}


-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    
    NSLog(@"did received data");
    
    if([session.configuration.identifier isEqualToString:currentHttpSessionId]){
        if(data != nil){
            NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        
        if(data != nil){
            
            [receiveData appendData:data];
            
            // [session finishTasksAndInvalidate];
            // [session invalidateAndCancel];
        }
    }else{
        [super URLSession:session dataTask:dataTask didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
    didCompleteWithError:(NSError *)error{
    
    NSLog(@"did compleate");
    
    if([session.configuration.identifier isEqualToString:currentHttpSessionId]){
        NSString * r = [[NSString alloc] initWithData:receiveData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", r);
        if(receiveData.length != 0){
            NSError *e = nil;
            NSArray * webESMArray = [NSJSONSerialization JSONObjectWithData:receiveData
                                                                    options:NSJSONReadingAllowFragments
                                                                      error:&e];
            if ( e != nil) {
                NSLog(@"ERROR: %@", e.debugDescription);
                [session finishTasksAndInvalidate];
                [session invalidateAndCancel];
                return;
            }
            
            if(webESMArray == nil){
                NSLog(@"ERROR: web esm array is null.");
                [session finishTasksAndInvalidate];
                [session invalidateAndCancel];
                return;
            }
            NSString * jsonStr = [[NSString alloc] initWithData:receiveData encoding:NSUTF8StringEncoding];
            NSLog(@"%@", jsonStr);
            
            [self setWebESMsWithArray:webESMArray];
            receiveData = [[NSMutableData alloc] init];
            [session finishTasksAndInvalidate];
            [session invalidateAndCancel];
        }
    }else{
        [super URLSession:session task:task didCompleteWithError:error];
    }

}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    
    if([session.configuration.identifier isEqualToString:currentHttpSessionId]){
        if (error != nil) {
            if([self isDebug]){
                NSLog(@"[%@] the session did become invaild with error: %@", [self getSensorName], error.debugDescription);
            }
        }
        [session invalidateAndCancel];
        [session finishTasksAndInvalidate];
    }else{
        [super URLSession:session didBecomeInvalidWithError:error];
    }
}


- (BOOL) setWebESMsWithSchedule:(ESMSchedule *)esmSchedule{
    if(esmSchedule != nil){
        NSMutableDictionary * dictSchedule = [[NSMutableDictionary alloc] init];
        [dictSchedule setObject:esmSchedule.fireHours forKey:@"hours"];
        [dictSchedule setObject:esmSchedule.scheduledESMs forKey:@"esms"];
        [dictSchedule setObject:esmSchedule.randomizeSchedule  forKey:@"randomize_schedule"];
        [dictSchedule setObject:@(esmSchedule.timeoutSecond) forKey:@"expiration"];
        
        [dictSchedule setObject:esmSchedule.title forKey:@"notification_title"];
        [dictSchedule setObject:esmSchedule.body forKey:@"notification_body"];
        [dictSchedule setObject:esmSchedule.identifier forKey:@"schedule_id"];
        [dictSchedule setObject:esmSchedule.context forKey:@"context"];
        
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM-dd-yyyy"];
        if(esmSchedule.startDate != nil){
            [dictSchedule setObject:[formatter stringFromDate:esmSchedule.startDate] forKey:@"start_date"];
        }else{
            [dictSchedule setObject:[formatter stringFromDate:[NSDate new]] forKey:@"start_date"];
        }
        [formatter setDateFormat:@"MM-dd-yyyy"];
        if(esmSchedule.endDate != nil){
            [dictSchedule setObject:[formatter stringFromDate:esmSchedule.endDate] forKey:@"end_date"];
        }else{
            [dictSchedule setObject:[formatter stringFromDate:[NSDate distantFuture]] forKey:@"end_date"];
        }
        
        [self setWebESMsWithArray:@[dictSchedule]];
        
        return YES;
    }else{
        return NO;
    }
}


- (void) setWebESMsWithArray:(NSArray *) webESMArray {
    
    @try {
        dispatch_async( dispatch_get_main_queue() , ^{
            AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
            NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            context.persistentStoreCoordinator =  delegate.persistentStoreCoordinator;
            
            int number = 0;
            
            for (NSDictionary * schedule in webESMArray) {
                NSArray * hours = [schedule objectForKey:@"hours"];
                NSArray * esms = [schedule objectForKey:@"esms"];
                NSNumber * randomize_schedule = [schedule objectForKey:@"randomize_schedule"];
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
                
                if(expiration == nil) expiration = @0;
                
                for (NSNumber * hour in hours) {
                    EntityESMSchedule * entityWebESM = (EntityESMSchedule *) [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMSchedule class])
                                                                                                           inManagedObjectContext:context];
                    entityWebESM.fire_hour = hour;
                    entityWebESM.expiration_threshold = expiration;
                    entityWebESM.start_date = startDate;
                    entityWebESM.end_date = endDate;
                    entityWebESM.notification_title = notificationTitle;
                    entityWebESM.noitification_body = notificationBody;
                    entityWebESM.randomize_schedule = randomize_schedule;
                    entityWebESM.schedule_id = scheduleId;
                    entityWebESM.context = eventContext;
                    
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
                        entityEsm.esm_na = @([[esm objectForKey:@"esm_na"] boolValue]);
                        entityEsm.esm_number = @(number);
                        entityEsm.esm_url = [esm objectForKey:@"esm_url"];
                        
                        [entityWebESM addEsmsObject:entityEsm];
                        
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
            }
            
            // isLock = NO;
            [self setNotificationSchedules];
            // [self performSelector:@selector(setNotificationSchedules) withObject:nil afterDelay:1];
        });
    } @catch (NSException *exception) {
        NSLog(@"ERROR: A format convert error are ocured @ WebESM. %@", exception.debugDescription);
    } @finally {
        
    }

}

- (void) refreshNotifications {
    [self removeNotificationSchedules];
    [self setNotificationSchedules];
}

- (void) removeNotificationSchedulesFromSQLite {
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([EntityESMSchedule class])];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    NSError *deleteError = nil;
    [delegate.managedObjectContext executeRequest:delete error:&deleteError];
    if(deleteError != nil){
        NSLog(@"ERROR: A delete query is failed");
    }
}

///////////////////////////////////////////////////////////////


- (void) setNotificationSchedules {
    // Get ESMs from SQLite by using CoreData
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([EntityESMSchedule class])];
    [fetchRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class])
                                        inManagedObjectContext:delegate.managedObjectContext]];
    
    NSDate * now = [NSDate new];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(start_date <= %@) AND (end_date >= %@)", now, now]];
    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetchRequest error:&error] ;
    
    if(results == nil) return;
    
    for (int i=0; i<results.count; i++) {
        
        EntityESMSchedule * schedule = results[i];
    
        NSNumber * randomize = schedule.randomize_schedule;
        if(randomize == nil) randomize = @0;
        
        NSNumber * fireHour = schedule.fire_hour;
        NSNumber * expiration = schedule.expiration_threshold;
        NSDate * fireDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES];
        NSDate * originalFireDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES];
        NSString * scheduleId = schedule.schedule_id;
        
        // original fire date
        // NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([EntityESMHistory class])];
        // [request setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMHistory class])
        //                                    inManagedObjectContext:delegate.managedObjectContext]];
        // [request setPredicate:[NSPredicate predicateWithFormat:@"original_fire_date = %@", [AWAREUtils getUnixTimestamp:originalFireDate]]];
        
        //NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"original_fire_date" ascending:NO];
        //[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
        //[request setSortDescriptors:@[sort]];
        
        // NSError* e = nil;
        // NSUInteger count = [delegate.managedObjectContext countForFetchRequest:request error:&e];
        // NSLog(@"original_fire_date = %@ ===> count: %ld", [AWAREUtils getUnixTimestamp:originalFireDate], count);
        
        if(![randomize isEqualToNumber:@0]){
            // Make a andom date
            int randomMin = (int)[self randomNumberBetween:-1*randomize.integerValue maxNumber:randomize.integerValue];
            fireDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] minute:randomMin second:0 nextDay:YES];
        }
        
        // NSLog(@"[%@] Fire Date: %@", scheduleId, [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES]);
        // NSLog(@"[%@] Fire Date: %@ (%@)", scheduleId, fireDate, [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES]);
        
        NSDictionary * userInfo = [[NSDictionary alloc] initWithObjects:@[originalFireDate, randomize, scheduleId,expiration]
                                                               forKeys:@[@"original_fire_date", @"randomize",
                                                                         @"schedule_id", @"expiration_threshold"]];
        if(![fireHour isEqualToNumber:@-1]){
            // [TEST]
            // fireDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:11 minute:30 second:0 nextDay:YES];
            [AWAREUtils sendLocalNotificationForMessage:schedule.noitification_body
                                      title:schedule.notification_title
                                  soundFlag:YES
                                   category:categoryWebESM
                                   fireDate:fireDate
                             repeatInterval:NSCalendarUnitDay
                                   userInfo:userInfo
                            iconBadgeNumber:1];
        }
        // WIP: Quick ESM (YES/NO and Text)
        
        // WIP: Event based ESMs (battery, activity, and/or network)
        
        // WIP: Location based ESMs
        
    }
    
    [self getValidESMsWithDatetime:[NSDate new]];
    
    [self setLatestValue:[NSString stringWithFormat:@"You have %ld scheduled notification(s)", results.count]];
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
        if([notification.category isEqualToString:categoryWebESM]) {
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
    }
}

- (NSArray *) getValidESMsWithDatetime:(NSDate *) datetime {
    
    NSMutableArray * esmSchedules = [[NSMutableArray alloc] init];
    
    
    ///////////////////////////////////////////////////////
    // Get notification schedules
    
    NSArray * notifications = [UIApplication sharedApplication].scheduledLocalNotifications;
    
    NSMutableArray * validSchedules = [[NSMutableArray alloc] init];
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    for (UILocalNotification * notification in notifications) {
        if([notification.category isEqualToString:categoryWebESM]) {
            //@"fire_date",@"randomize",@"schedule_id"
            NSDictionary * userInfo = notification.userInfo;
            NSDate * fireDate = notification.fireDate;
            //NSNumber * randomize = [userInfo objectForKey:@"randomize"];
            NSNumber * expiration = [userInfo objectForKey:@"expiration_threshold"];
            NSString * scheduleId = [userInfo objectForKey:@"schedule_id"];
            // NSDate * originalFireDate = [userInfo objectForKey:@"original_fire_date"];
            // NSNumber * randomize = [userInfo objectForKey:@"randomize"];
            
            // check expiration
            NSDate * expirationTime = [fireDate dateByAddingTimeInterval:expiration.integerValue * 60];
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"dd HH:mm"];
            [NSTimeZone resetSystemTimeZone];
            
            NSLog( @"Now = %@ [valid duration = (%@ <---> %@)]",
                  [dateFormat stringFromDate:datetime],
                  [dateFormat stringFromDate:fireDate],
                  [dateFormat stringFromDate:expirationTime]
                  );
            if( expiration.integerValue == 0 ||
               (datetime.timeIntervalSince1970 >= fireDate.timeIntervalSince1970 &&
                datetime.timeIntervalSince1970 <= expirationTime.timeIntervalSince1970))
            {
                bool isNew = YES;
                for (UILocalNotification * notif in validSchedules ) {
                    NSString * sId = [notif.userInfo objectForKey:@"schedule_id"];
                    if([sId isEqualToString:scheduleId]){
                        isNew = NO;
                        break;
                    }
                }
                if(isNew){
                    [validSchedules addObject:notification];
                }
            }
        }
    }


    
    for (UILocalNotification * notif  in validSchedules) {
        NSString * scheduleId = [notif.userInfo objectForKey:@"schedule_id"];
        NSDate * fireDate = notif.fireDate;
        // NSLog(@"===> %@", [AWAREUtils getUnixTimestamp:fireDate]);
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([EntityESMSchedule class])];
        [fetchRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class])
                                            inManagedObjectContext:delegate.managedObjectContext]];
        [fetchRequest setFetchLimit:1];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(start_date <= %@) AND (end_date >= %@) AND (schedule_id=%@)", datetime, datetime, scheduleId]];
        
        
        
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"start_date" ascending:NO];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
        
        NSFetchedResultsController *fetchedResultsController
        = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                              managedObjectContext:delegate.managedObjectContext
                                                sectionNameKeyPath:nil
                                                         cacheName:nil];
        
        NSError *error = nil;
        if (![fetchedResultsController performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
        
        NSArray *results = [fetchedResultsController fetchedObjects];
        
        for (EntityESMSchedule * schedule in results) {
            
            NSSet * childEsms = schedule.esms;
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"esm_number" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObjects:sort,nil];
            NSArray *sortedEsms = [childEsms sortedArrayUsingDescriptors:sortDescriptors];
            for (EntityESM * esm in sortedEsms) {
                
                esm.timestamp = [AWAREUtils getUnixTimestamp:fireDate];
                [esmSchedules addObject:esm];
                NSDate * time = fireDate;
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"MM/dd/yyyy HH:mm"];
                [NSTimeZone resetSystemTimeZone];
                NSString *date = [dateFormat stringFromDate:time];
                
                [dateFormat setTimeZone:[NSTimeZone systemTimeZone]];
                NSLog(@"[timestamp:%@][type:%@][trigger:%@][fire:%@] %@",
                      esm.esm_number, esm.esm_type,
                      esm.esm_trigger, date, esm.esm_title );
            }
        }
    }
    
    
    
    /////////////////////////////////////////////////////////
    // get fixed esm schedules
    NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([EntityESMSchedule class])];
    [req setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class])
                                        inManagedObjectContext:delegate.managedObjectContext]];
    [req setFetchLimit:1];
    [req setPredicate:[NSPredicate predicateWithFormat:@"(start_date <= %@) AND (end_date >= %@) AND (fire_hour=-1)", datetime, datetime]];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"start_date" ascending:NO];
    [req setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    NSFetchedResultsController *fetchedResultsController
    = [[NSFetchedResultsController alloc] initWithFetchRequest:req
                                          managedObjectContext:delegate.managedObjectContext
                                            sectionNameKeyPath:nil
                                                     cacheName:nil];
    
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    NSArray *results = [fetchedResultsController fetchedObjects];
    
    for (EntityESMSchedule * schedule in results) {
        
        NSSet * childEsms = schedule.esms;
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"esm_number" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sort,nil];
        NSArray *sortedEsms = [childEsms sortedArrayUsingDescriptors:sortDescriptors];
        for (EntityESM * esm in sortedEsms) {

            esm.timestamp = [AWAREUtils getUnixTimestamp:datetime];
            [esmSchedules addObject:esm];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"MM/dd/yyyy HH:mm"];
            [NSTimeZone resetSystemTimeZone];
            NSString *date = [dateFormat stringFromDate:datetime];
            
            [dateFormat setTimeZone:[NSTimeZone systemTimeZone]];
            NSLog(@"[timestamp:%@][type:%@][trigger:%@][fire:%@] %@",
                  esm.esm_number, esm.esm_type,
                  esm.esm_trigger, date, esm.esm_title );
        }
    }

    ////////////////////////////////////////////
    // return
    return esmSchedules;
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

- (NSString *)getURLFromSettings:(NSArray *)settings key:(NSString *)key{
    NSString * url;
    for (NSDictionary * dict in settings ) {
        for (NSString * key in [dict allKeys]) {
            if([key isEqualToString:key]){
                url = [dict objectForKey:key];
            }
        }
    }
    return url;
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
        AWAREDelegate * delegate = (AWAREDelegate *)[UIApplication sharedApplication].delegate;
        NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        context.persistentStoreCoordinator = delegate.persistentStoreCoordinator;
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
                [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"ERROR: %@",  error.debugDescription] soundFlag:NO];
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


@end
