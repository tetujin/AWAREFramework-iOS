//
//  ESMScheduleManager.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/27.
//

#import "ESMScheduleManager.h"
#import "AWAREDelegate.h"
#import <UserNotifications/UserNotifications.h>

@implementation ESMScheduleManager{
    NSString * categoryNormalESM;
}

- (instancetype)init{
    self = [super init];
    if(self != nil){
        categoryNormalESM = @"category_normal_esm";
        _debug = NO;
    }
    return self;
}

- (BOOL)addSchedule:(ESMSchedule *)schedule{
    AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
    NSManagedObjectContext * context = delegate.managedObjectContext;
    context.persistentStoreCoordinator = delegate.persistentStoreCoordinator;
    
    NSArray * hours = schedule.fireHours;
    if (hours==nil || hours.count == 0) {
        hours = @[@0];
    }
    
    for (NSNumber * hour in hours) {
        EntityESMSchedule * entityScehdule = (EntityESMSchedule *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMSchedule class]) inManagedObjectContext:context];
        entityScehdule.schedule_id = schedule.scheduleId;
        entityScehdule.expiration_threshold = schedule.expirationThreshold;
        entityScehdule.start_date = schedule.startDate;
        entityScehdule.end_date = schedule.endDate;
        entityScehdule.noitification_body = schedule.noitificationBody;
        entityScehdule.notification_title = schedule.notificationTitle;
        entityScehdule.interface = schedule.interface;
        entityScehdule.randomize_esm = schedule.randomizeEsm;
        entityScehdule.randomize_schedule = schedule.randomizeSchedule;
        entityScehdule.temporary = schedule.temporary;
        entityScehdule.fire_hour = hour;
        // TODO
        entityScehdule.context = [self convertToJSONStringWithArray:schedule.context];
        
        for (ESMItem * esmItem in schedule.esms) {
            EntityESM * entityESM = (EntityESM *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESM class]) inManagedObjectContext:context];
            entityESM.device_id = esmItem.device_id;
            entityESM.double_esm_user_answer_timestamp = esmItem.double_esm_user_answer_timestamp;
            entityESM.esm_checkboxes = esmItem.esm_checkboxes;
            entityESM.esm_expiration_threshold = esmItem.esm_expiration_threshold;
            entityESM.esm_flows = esmItem.esm_flows;
            entityESM.esm_instructions = esmItem.esm_instructions;
            entityESM.esm_json = esmItem.esm_json;
            entityESM.esm_likert_max = esmItem.esm_likert_max;
            entityESM.esm_likert_max_label = esmItem.esm_likert_max_label;
            entityESM.esm_likert_min_label = esmItem.esm_likert_min_label;
            entityESM.esm_likert_step = esmItem.esm_likert_step;
            entityESM.esm_minute_step = esmItem.esm_minute_step;
            entityESM.esm_na = esmItem.esm_na;
            entityESM.esm_number = esmItem.esm_number;
            entityESM.esm_quick_answers = esmItem.esm_quick_answers;
            entityESM.esm_radios = esmItem.esm_radios;
            entityESM.esm_scale_max = esmItem.esm_scale_max;
            entityESM.esm_scale_max_label = esmItem.esm_scale_max_label;
            entityESM.esm_scale_min = esmItem.esm_scale_min;
            entityESM.esm_scale_min_label = esmItem.esm_scale_min_label;
            entityESM.esm_scale_start = esmItem.esm_scale_start;
            entityESM.esm_scale_step = esmItem.esm_scale_step;
            entityESM.esm_start_date= esmItem.esm_start_date;
            entityESM.esm_start_time = esmItem.esm_start_time;
            entityESM.esm_status = esmItem.esm_status;
            entityESM.esm_submit = esmItem.esm_submit;
            entityESM.esm_time_format = esmItem.esm_time_format;
            entityESM.esm_title = esmItem.esm_title;
            entityESM.esm_trigger = esmItem.esm_trigger;
            entityESM.esm_type = esmItem.esm_type;
            entityESM.esm_url = esmItem.esm_url;
            entityESM.esm_user_answer = esmItem.esm_user_answer;
            entityESM.esm_app_integration = esmItem.esm_app_integration;
            [entityScehdule addEsmsObject:entityESM];
        }
    }
    NSError * error = nil;
    bool saved = [context save:&error];
    if (saved) {
        return YES;
    }else{
        if (error != nil) {
            NSLog(@"[ESMScheduleManager] data save error: %@", error.debugDescription);
        }
        return YES;
    }
}

- (BOOL) deleteScheduleWithId:(NSString *)scheduleId{
    AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
    NSManagedObjectContext * context = delegate.managedObjectContext;
    context.persistentStoreCoordinator = delegate.persistentStoreCoordinator;
    NSFetchRequest *deleteRequest = [[NSFetchRequest alloc] init];
    [deleteRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class]) inManagedObjectContext:context]];
    [deleteRequest setIncludesPropertyValues:NO]; // fetch only a managed object ID
    [deleteRequest setPredicate: [NSPredicate predicateWithFormat:@"schedule_id == %@", scheduleId]];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:deleteRequest error:&error];
    
    for (NSManagedObject *data in results) {
        [context deleteObject:data];
    }
    
    NSError *saveError = nil;
    BOOL deleted = [context save:&saveError];
    if (deleted) {
        return YES;
    }else{
        if (saveError!=nil) {
            NSLog(@"[ESMScheduleManager] data delete error: %@", error.debugDescription);
        }
        return YES;
    }
}

- (BOOL)deleteAllSchedules{
    AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
    NSManagedObjectContext * context = delegate.managedObjectContext;
    context.persistentStoreCoordinator = delegate.persistentStoreCoordinator;
    NSFetchRequest *deleteRequest = [[NSFetchRequest alloc] init];
    [deleteRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class]) inManagedObjectContext:context]];
    [deleteRequest setIncludesPropertyValues:NO]; // fetch only a managed object ID
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:deleteRequest error:&error];
    
    for (NSManagedObject *data in results) {
        [context deleteObject:data];
    }
    
    NSError *saveError = nil;
    BOOL deleted = [context save:&saveError];
    if (deleted) {
        return YES;
    }else{
        if (saveError!=nil) {
            NSLog(@"[ESMScheduleManager] data delete error: %@", error.debugDescription);
        }
        return YES;
    }
}

- (NSArray *)getValidSchedules{
    return [self getValidSchedulesWithDatetime:[NSDate new]];
}

- (NSArray *)getValidSchedulesWithDatetime:(NSDate *)datetime{
    
    NSMutableArray * fetchedESMSchedules = [[NSMutableArray alloc] init];
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    
    
    // NSNumber * interface = @0;
    // NSArray * notifications = [UIApplication sharedApplication].scheduledLocalNotifications;
    // NSLog(@"Registered Notifications: %ld", notifications.count);
    // NSMutableArray * validSchedules = [[NSMutableArray alloc] init];
    
    
    /////////////////////////////////////////////////////////
    // get fixed esm schedules
    //    NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([EntityESMSchedule class])];
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    [req setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class])
                               inManagedObjectContext:delegate.managedObjectContext]];
    // [req setFetchLimit:1];
    
    //[req setPredicate:[NSPredicate predicateWithFormat:@"(start_date <= %@) AND (end_date >= %@) AND (fire_hour=-1)", datetime, datetime]];
    // OR (expiration=0)
    [req setPredicate:[NSPredicate predicateWithFormat:@"(start_date <= %@) AND (end_date >= %@) OR (expiration_threshold=0)", datetime, datetime]];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"start_date" ascending:NO];
    NSSortDescriptor *sortBySID = [[NSSortDescriptor alloc] initWithKey:@"schedule_id" ascending:NO];
    [req setSortDescriptors:@[sort,sortBySID]];
    
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
//    if ([self isDebug]){
//        if(results != nil){
//            NSLog(@"Stored ESM Schedules are %ld", results.count);
//        }else{
//            NSLog(@"Stored ESM Schedule is Null.");
//        }
//    }
    
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
                // NSLog(esm.debugDescription);
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
            for (EntityESMSchedule * storedSchedule in fetchedESMSchedules) {
                if([storedSchedule.schedule_id isEqualToString:scheduleId]){
                    // NSLog(@"%@ is already exist!", scheduleId);
                    hasScheduleId = YES;
                    break;
                }
            }
            if(!hasScheduleId && scheduleId != nil){
                [fetchedESMSchedules addObject:schedule];
                NSLog(@"[id:%@][randomize:%@][expiration:%@]",scheduleId,randomize,expiration);
            }
        }
    }
    
    if([self debug]){
         NSLog(@"esm schedule: %ld", fetchedESMSchedules.count);
    }
    
    return fetchedESMSchedules;
}

- (NSArray *) getNotificationSchedules {
    return @[];
}

- (void)setNotificationSchedules {
    
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
        
        NSNumber * fireHour   = schedule.fire_hour;
        NSNumber * expiration = schedule.expiration_threshold;
        NSDate   * fireDate   = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES];
        NSDate   * originalFireDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES];
        NSString * scheduleId = schedule.schedule_id;
        NSNumber * interface  = schedule.interface;
        
        if(![randomize isEqualToNumber:@0]){
            // Make a andom date
            int randomMin = (int)[self randomNumberBetween:-1*randomize.intValue maxNumber:randomize.intValue];
            fireDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] minute:randomMin second:0 nextDay:YES];
        }
        
        // The fireData is Valid Time?
        NSDate * expirationTime = [originalFireDate dateByAddingTimeInterval:expiration.integerValue * 60];
        NSDate * inspirationTime = originalFireDate;
        if(randomize.intValue > 0){
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
            [AWAREUtils sendLocalNotificationForMessage:schedule.noitification_body
                                                  title:schedule.notification_title
                                              soundFlag:YES
                                               category:categoryNormalESM
                                               fireDate:fireDate
                                         repeatInterval:NSCalendarUnitDay
                                               userInfo:userInfo
                                        iconBadgeNumber:1];
        }
        
        // WIP: WEEKLY and MONTHLY Notifications
        
        // WIP: Quick ESM (YES/NO and Text)
        
        // WIP: Event based ESMs (battery, activity, and/or network)
        
        // WIP: Location based ESMs
    }
    
    
    
    
    [self getValidSchedulesWithDatetime:[NSDate new]];
    
    // [self setLatestValue:[NSString stringWithFormat:@"You have %ld scheduled notification(s)", results.count]];
    // });
}

- (void) refreshNotificationSchedules {
    [self removeNotificationSchedules];
    [self setNotificationSchedules];
}


- (void) removeNotificationSchedules {
    [UNUserNotificationCenter.currentNotificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        if(requests != nil){
            NSMutableArray * unrequredNotifications = [[NSMutableArray alloc] init];
            for (UNNotificationRequest * request in requests) {
                if([request.content.categoryIdentifier isEqualToString:self->categoryNormalESM]) {
                    [unrequredNotifications addObject:request.identifier];
                }
            }
            if (unrequredNotifications.count > 0) {
                [UNUserNotificationCenter.currentNotificationCenter removePendingNotificationRequestsWithIdentifiers:unrequredNotifications];
            }
        }
    }];
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


////////////////
////////////////////////////////


- (NSInteger)randomNumberBetween:(int)min maxNumber:(int)max {
    return min + arc4random_uniform(max - min + 1);
}

- (NSString *) convertToJSONStringWithArray:(NSArray *) array{
    NSError * error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        NSLog(@"[EntityESM] Convert Error to JSON-String from NSArray: %@", error.debugDescription);
        return @"";
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (jsonString != nil) {
        return jsonString;
    }else{
        return @"";
    }
}

- (NSString *) convertToJSONStringWithDictionary:(NSDictionary *) dictionary{
    NSError * error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        NSLog(@"[EntityESM] Convert Error to JSON-String from NSDictionary: %@", error.debugDescription);
        return @"";
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (jsonString != nil) {
        return jsonString;
    }else{
        return @"";
    }
}

@end
