//
//  ESMScheduleManager.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/27.
//

#import "ESMScheduleManager.h"
#import "EntityESMAnswerHistory+CoreDataClass.h"
#import "AWAREDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import "EntityESMAnswer.h"

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

- (BOOL) addSchedule:(ESMSchedule *)schedule{
    AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
    NSManagedObjectContext * manageContext = delegate.sharedCoreDataHandler.managedObjectContext;
    manageContext.persistentStoreCoordinator = delegate.sharedCoreDataHandler.persistentStoreCoordinator;
    
    NSArray * hours = schedule.fireHours;
    //////////////////////////////////////////////
    for (NSNumber * hour in hours) {
        EntityESMSchedule * entityScehdule = [[EntityESMSchedule alloc] initWithContext:manageContext];
        entityScehdule = [self transferESMSchedule:schedule toEntity:entityScehdule];
        entityScehdule.fire_hour = hour;
        // contexts
        entityScehdule.contexts = [self convertToJSONStringWithArray:schedule.contexts];
        // weekdays
        entityScehdule.weekdays = [self convertToJSONStringWithArray:schedule.weekdays];
        for (ESMItem * esmItem in schedule.esms) {
            EntityESM * entityESM = (EntityESM *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESM class]) inManagedObjectContext:manageContext];
            [entityScehdule addEsmsObject:[self transferESMItem:esmItem toEntity:entityESM]];
        }
    }
    
    for (NSDateComponents * timer in schedule.timers) {
        EntityESMSchedule * entityScehdule = [[EntityESMSchedule alloc] initWithContext:manageContext];
        entityScehdule = [self transferESMSchedule:schedule toEntity:entityScehdule];
        entityScehdule.timer = timer;
        for (ESMItem * esmItem in schedule.esms) {
            EntityESM * entityESM = (EntityESM *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESM class]) inManagedObjectContext:manageContext];
            [entityScehdule addEsmsObject:[self transferESMItem:esmItem toEntity:entityESM]];
        }
    }
    
    NSError * error = nil;
    bool saved = [manageContext save:&error];
    if (saved) {
    }else{
        if (error != nil) {
            NSLog(@"[ESMScheduleManager] data save error: %@", error.debugDescription);
        }
    }
    [self refreshNotificationSchedules];
    return saved;
}

- (EntityESMSchedule *) transferESMSchedule:(ESMSchedule *)schedule toEntity:(EntityESMSchedule *)entityScehdule{
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
    entityScehdule.repeat = @(schedule.repeat);
    return entityScehdule;
}

- (EntityESM *) transferESMItem:(ESMItem *)esmItem toEntity:(EntityESM *)entityESM{
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
    return entityESM;
}



- (BOOL) deleteScheduleWithId:(NSString *)scheduleId{
    AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
    NSManagedObjectContext * context = delegate.sharedCoreDataHandler.managedObjectContext;
    context.persistentStoreCoordinator = delegate.sharedCoreDataHandler.persistentStoreCoordinator;
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
    NSManagedObjectContext * context = delegate.sharedCoreDataHandler.managedObjectContext;
    context.persistentStoreCoordinator = delegate.sharedCoreDataHandler.persistentStoreCoordinator;
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


/////////////////////////////////////////////////////////


/**
 Get valid ESM schedules at the current time

 @return Valid ESM schedules as an NSArray
 */
- (NSArray *)getValidSchedules{
    return [self getValidSchedulesWithDatetime:[NSDate new]];
}


/**
 Get valid ESM schedules at a particular time

 @param datetime A NSDate for fetching valid ESMs from DB
 @return Valid ESM schedules as an NSArray from a paricular time
 */
- (NSArray *)getValidSchedulesWithDatetime:(NSDate *)datetime{
    
    // NSMutableArray * fetchedESMSchedules = [[NSMutableArray alloc] init];
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    
    // Fetch vaild schedules by date and expiration
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    [req setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class])
                               inManagedObjectContext:delegate.sharedCoreDataHandler.managedObjectContext]];
    [req setPredicate:[NSPredicate predicateWithFormat:@"(start_date <= %@) AND (end_date >= %@)", datetime, datetime]];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"start_date" ascending:NO];
    NSSortDescriptor *sortBySID = [[NSSortDescriptor alloc] initWithKey:@"schedule_id" ascending:NO];
    [req setSortDescriptors:@[sort,sortBySID]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:req
                                                                                               managedObjectContext:delegate.sharedCoreDataHandler.managedObjectContext
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:nil];
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    NSArray * periodValidSchedules = [fetchedResultsController fetchedObjects];
    
    
    /////// Fetch history data of ESM answers
    NSFetchRequest *historyReq = [[NSFetchRequest alloc] init];
    [historyReq setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMAnswerHistory class])
                                      inManagedObjectContext:delegate.sharedCoreDataHandler.managedObjectContext]];
    NSNumber * now = @(datetime.timeIntervalSince1970);
    NSNumber * start = @([AWAREUtils getTargetNSDate:[NSDate new] hour:0 nextDay:false].timeIntervalSince1970);
    [historyReq setPredicate:[NSPredicate predicateWithFormat:@"(timestamp >= %@) && (timestamp <= %@)", start,now]]; //(timestamp >= %@) &&
    NSSortDescriptor *historySort = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [historyReq setSortDescriptors:@[historySort]];
    NSFetchedResultsController *historyFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:historyReq
                                                                                                      managedObjectContext:delegate.sharedCoreDataHandler.managedObjectContext
                                                                                                        sectionNameKeyPath:nil
                                                                                                                 cacheName:nil];
    NSError * historyError = nil;
    if (![historyFetchedResultsController performFetch:&historyError]) {
        NSLog(@"Unresolved error %@, %@", historyError, [historyError userInfo]);
    }
    NSArray * answerHistory = [historyFetchedResultsController fetchedObjects];
    
    
    ///////////////////////////////////////////////////////////
    NSMutableArray * validSchedules = [[NSMutableArray alloc] init];
    if (periodValidSchedules==nil) {
        return validSchedules;
    }
    
    for (EntityESMSchedule * schedule in periodValidSchedules) {
        NSNumber * hour = schedule.fire_hour;
        NSDateComponents * timer = (NSDateComponents *)schedule.timer;
        // NSString * context = schedule.context;
        // NSNumber * weekday = schedule.weekday;
        
        bool isValidSchedule = NO;
        /**  Hours Based ESM */
        if (hour.intValue != -1) {
            isValidSchedule = [self isValidHourBasedESMSchedule:schedule history:answerHistory targetDatetime:datetime];
            
            /**  Context Based ESM */
            //        if (context != nil) {
            //
            //        }
            
            /**  Week Based ESM */
            //        if (![weekday isEqualToNumber:@0]) {
            //            isValidSchedule = [self isValidTimerBasedESMSchedule:schedule history:answerHistory targetDatetime:datetime];
            //        }
        }
        
        /**  Timer Based ESM */
        if( timer != nil ){
            isValidSchedule = [self isValidTimerBasedESMSchedule:schedule history:answerHistory targetDatetime:datetime];
        }
        
        if (isValidSchedule) {
            [validSchedules addObject:schedule];
        }
    }

    return validSchedules;
}


- (BOOL) isValidHourBasedESMSchedule:(EntityESMSchedule  *)schedule history:(NSArray *)history targetDatetime:(NSDate *)datetime{
    // NSSet * childEsms = schedule.esms;
    // NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"esm_number" ascending:YES];
    // NSArray *sortDescriptors = [NSArray arrayWithObjects:sort,nil];
    // NSArray *sortedEsms = [childEsms sortedArrayUsingDescriptors:sortDescriptors];
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

    ////// start/end time based validation /////
    if(scheduleId == nil){
        return NO;
    }else if([expiration isEqualToNumber:@0]){
        return YES;
    }else if ( ((now.timeIntervalSince1970 >= validStartDateToday.timeIntervalSince1970) && (now.timeIntervalSince1970 <= validEndDateToday.timeIntervalSince1970 )) ||
              ((now.timeIntervalSince1970 >= validStartDateNextday.timeIntervalSince1970) && (now.timeIntervalSince1970 <= validEndDateNextday.timeIntervalSince1970)) ){
        
    }else{
        return NO;
    }

    /////  history based validation  //////
    if (history != nil) {
        for (EntityESMAnswerHistory * answeredESM in history) {
            NSString * historyScheduleId = answeredESM.schedule_id;
            NSNumber * historyFireHour   = answeredESM.fire_hour;
            if ([scheduleId isEqualToString:historyScheduleId] && [fireHour isEqualToNumber:historyFireHour]) {
                // NSLog(@"schedule id=%@, fire-hour=%@", scheduleId, fireHour);
                return NO;
            }
        }
    }
    NSLog(@"[id:%@][randomize:%@][expiration:%@]",scheduleId,randomize,expiration);
    return YES;
}


- (BOOL) isValidTimerBasedESMSchedule:(EntityESMSchedule  *)schedule history:(NSArray *)history targetDatetime:(NSDate *)datetime{
    /////  history based validation  //////
//    NSString * scheduleId = schedule.schedule_id;
//    if (history != nil) {
//        for (EntityESMAnswerHistory * answeredESM in history) {
//            NSString * historyScheduleId = answeredESM.schedule_id;
//            if ([scheduleId isEqualToString:historyScheduleId]) {
//                return NO;
//            }
//        }
//    }
    return YES;
}


//////////////////////////////////////////////////////////////

- (void)setNotificationSchedules {
    
    NSDate * now = [NSDate new];
    
    // Get ESMs from SQLite by using CoreData
    NSArray * esmSchedules = [self getValidSchedulesWithDatetime:now];
    if(esmSchedules == nil) return;
    
    ////////////////////////////////////
    for (int i=0; i<esmSchedules.count; i++) {
        
        EntityESMSchedule * schedule = esmSchedules[i];
        
        NSNumber * hour = schedule.fire_hour;
        NSDateComponents * timer = (NSDateComponents *)schedule.timer;
        
        /**  Hours Based ESM */
        if (hour.intValue != -1) {
            [self setHourBasedNotification:schedule datetime:now];
        }
    
        /**  Timer Based ESM */
        if( timer != nil ){
            [self setTimerBasedNotification:schedule datetime:now];
        }
    }
    // [self getValidSchedulesWithDatetime:[NSDate new]];
}


- (void) setHourBasedNotification:(EntityESMSchedule *)schedule datetime:(NSDate *) datetime {
    
    NSNumber * randomize = schedule.randomize_schedule;
    if(randomize == nil) randomize = @0;
    
    NSNumber * fireHour   = schedule.fire_hour;
    NSNumber * expiration = schedule.expiration_threshold;
    NSDate   * fireDate   = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES];
    NSDate   * originalFireDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES];
    NSString * scheduleId = schedule.schedule_id;
    NSNumber * interface  = schedule.interface;
    bool repeat = YES;
    if (schedule.repeat!=nil) {
        repeat = schedule.repeat.boolValue;
    }
    
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
    if(inspirationTime.timeIntervalSince1970 <= datetime.timeIntervalSince1970
       && expirationTime.timeIntervalSince1970 >= datetime.timeIntervalSince1970){
        isInTime = YES;
    }
    // NSLog(@"[BASE_TIME:%@]\n[CURRENT_TIME:%@]\n[EXPIRATION_TIME:%@][IN_TIME:%d]", inspirationTime, now, expirationTime, isInTime);
    // Check an answering condition
    if(isInTime){
        [fireDate dateByAddingTimeInterval:60*60*24]; // <- temporary solution
    }
    
    
    NSDictionary * userInfo = [[NSDictionary alloc] initWithObjects:@[originalFireDate, randomize, scheduleId,expiration,fireDate,interface]
                                                            forKeys:@[@"original_fire_date", @"randomize",
                                                                      @"schedule_id", @"expiration_threshold",@"fire_date",@"interface"]];
    
    // If the value is 0-23
    UNMutableNotificationContent * content = [[UNMutableNotificationContent alloc] init];
    content.title = schedule.notification_title;
    content.body = schedule.noitification_body;
    content.sound = [UNNotificationSound defaultSound];
    content.categoryIdentifier = categoryNormalESM;
    content.userInfo = userInfo;
    content.badge = @(1);
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:fireDate];
    UNCalendarNotificationTrigger * trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:repeat];
    
    UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:[NSString stringWithFormat:@"%@_%@",KEY_AWARE_NOTIFICATION_DEFAULT_REQUEST_IDENTIFIER,fireHour.stringValue] content:content trigger:trigger];
    
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error!=nil) {
            // NSLog(@"[ESMScheduleManager:HourBasedNotification] %@", error.debugDescription);
        }else{
            // NSLog(@"[ESMScheduleManager:HourBasedNotification] Set a notification");
        }
    }];
}



- (void) setTimerBasedNotification:(EntityESMSchedule *)schedule datetime:(NSDate *)datetime{
    
    NSNumber * randomize = schedule.randomize_schedule;
    if(randomize == nil) randomize = @0;
    
    NSNumber * fireHour   = schedule.fire_hour;
    NSNumber * expiration = schedule.expiration_threshold;
    NSDate   * fireDate   = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES];
    NSDate   * originalFireDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:[fireHour intValue] nextDay:YES];
    NSString * scheduleId = schedule.schedule_id;
    NSNumber * interface  = schedule.interface;
    bool repeat = YES;
    if (schedule.repeat!=nil) {
        repeat = schedule.repeat.boolValue;
    }
    
    NSDictionary * userInfo = [[NSDictionary alloc] initWithObjects:@[originalFireDate, randomize, scheduleId,expiration,fireDate,interface]
                                                            forKeys:@[@"original_fire_date", @"randomize",
                                                                      @"schedule_id", @"expiration_threshold",@"fire_date",@"interface"]];
    
    
    UNMutableNotificationContent * content = [[UNMutableNotificationContent alloc] init];
    content.title = schedule.notification_title;
    content.body = schedule.noitification_body;
    content.sound = [UNNotificationSound defaultSound];
    content.categoryIdentifier = categoryNormalESM;
    content.userInfo = userInfo;
    content.badge = @(1);
    
    NSDateComponents * components = (NSDateComponents *)schedule.timer;
    if (components !=nil) {
        UNCalendarNotificationTrigger * trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:repeat];
        NSString * requestId = [NSString stringWithFormat:@"%@_%ld_%ld",KEY_AWARE_NOTIFICATION_DEFAULT_REQUEST_IDENTIFIER,components.hour,components.minute];
        UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:requestId content:content trigger:trigger];
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            // NSLog(@"%@",request.debugDescription);
            if (error!=nil) {
                NSLog(@"[ESMScheduleManager:TimerBasedNotification] %@", error.debugDescription);
            }else{
                // NSLog(@"[ESMScheduleManager:TimerBasedNotification] Set a notification");
            }
        }];
    }
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
    [delegate.sharedCoreDataHandler.managedObjectContext executeRequest:delete error:&deleteError];
    if(deleteError != nil){
        NSLog(@"[ESMScheduleManager:removeNotificationScheduleFromSQLite] Error: A delete query is failed");
    }
}










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
