
//
//  ESMScheduleManager.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/27.
//

/**
 ESMScheduleManager handles ESM schdule.
 */

#import "ESMScheduleManager.h"
#import "EntityESMAnswerHistory+CoreDataClass.h"
#import "AWAREDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import "EntityESMAnswer.h"

static ESMScheduleManager * sharedESMScheduleManager;

@implementation ESMScheduleManager{
    NSString * categoryNormalESM;
    NSMutableArray * contextObservers;
}

+ (ESMScheduleManager *)sharedESMScheduleManager{
    @synchronized(self){
        if (!sharedESMScheduleManager){
            sharedESMScheduleManager = [[ESMScheduleManager alloc] init];
        }
    }
    return sharedESMScheduleManager;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedESMScheduleManager == nil) {
            sharedESMScheduleManager= [super allocWithZone:zone];
            return sharedESMScheduleManager;
        }
    }
    return nil;
}


- (instancetype)init{
    self = [super init];
    if(self != nil){
        categoryNormalESM = @"category_normal_esm";
        _debug = NO;
        contextObservers = [[NSMutableArray alloc] init];
    }
    return self;
}

//////////////// ESM Schdule /////////////

/**
 Add ESMSchdule to this ESMScheduleManager. The ESMSchduleManager **saves a schdule to the database** and ** set a UNNotification**.

 @param schedule ESMSchdule
 @return A status of data saving operation
 */
- (BOOL) addSchedule:(ESMSchedule *) schedule{
    return [self addSchedule:schedule withNotification:YES];
}

- (BOOL) addSchedule:(ESMSchedule *) schedule withNotification:(BOOL)notification{
    // AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
    
    NSManagedObjectContext * manageContext = [CoreDataHandler sharedHandler].managedObjectContext;
    manageContext.persistentStoreCoordinator = [CoreDataHandler sharedHandler].persistentStoreCoordinator;
    
    NSDate * now = [NSDate new];
    NSArray * hours = schedule.fireHours;
    
    if(hours.count == 0){
        hours = @[@(-1)];
    }
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
        /**  Hours Based ESM */
        if (hour.intValue != -1 && notification) {
            [self setHourBasedNotification:entityScehdule datetime:now];
        }
        if (hour.intValue == -1 && notification && ![entityScehdule.contexts isEqualToString:@""]){
            [self setContextBasedNotification:entityScehdule];
        }
        // NSLog(@"-> %@", entityScehdule.randomize_schedule);
    }
    
    for (NSDateComponents * timer in schedule.timers) {
        EntityESMSchedule * entityScehdule = [[EntityESMSchedule alloc] initWithContext:manageContext];
        entityScehdule = [self transferESMSchedule:schedule toEntity:entityScehdule];
        entityScehdule.timer = timer;
        for (ESMItem * esmItem in schedule.esms) {
            EntityESM * entityESM = (EntityESM *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESM class]) inManagedObjectContext:manageContext];
            [entityScehdule addEsmsObject:[self transferESMItem:esmItem toEntity:entityESM]];
        }
        /**  Timer Based ESM */
        if( timer != nil && notification){
            [self setTimeBasedNotification:entityScehdule datetime:now];
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
    
    return saved;
}


/**
 Transfer parameters in ESMSchdule to EntityESMSchedule instance.

 @param schedule ESMSchdule
 @param entityScehdule EntityESMSchdule
 @return EntityESMSchdule which has parameters of ESMSchdule
 */
- (EntityESMSchedule *) transferESMSchedule:(ESMSchedule *)schedule toEntity:(EntityESMSchedule *)entityScehdule{
    entityScehdule.schedule_id = schedule.scheduleId;
    entityScehdule.expiration_threshold = schedule.expirationThreshold;
    entityScehdule.start_date = schedule.startDate;
    entityScehdule.end_date = schedule.endDate;
    entityScehdule.notification_body = schedule.notificationBody;
    entityScehdule.notification_title = schedule.notificationTitle;
    entityScehdule.interface = schedule.interface;
    entityScehdule.randomize_esm = schedule.randomizeEsm;
    entityScehdule.randomize_schedule = schedule.randomizeSchedule;
    entityScehdule.temporary = schedule.temporary;
    entityScehdule.repeat = @(schedule.repeat);
    return entityScehdule;
}


/**
Transfer parameters in ESMSchdule to EntityESMSchedule instance.

 @param esmItem ESMItem
 @param entityESM EntityESM
 @return EntityESM which has parameters of ESMItem
 */
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


/**
 Delete ESMSchdule by a schedule ID

 @param scheduleId Schdule ID
 @return A status of data deleting operation
 */
- (BOOL) deleteScheduleWithId:(NSString *)scheduleId{
    // AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
    NSManagedObjectContext * context = [CoreDataHandler sharedHandler].managedObjectContext;
    context.persistentStoreCoordinator = [CoreDataHandler sharedHandler].persistentStoreCoordinator;
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


/**
 Delete all of ESMSchdule in the DB

 @return A status of data deleting operation
 */
- (BOOL)deleteAllSchedules{
    return [self deleteAllSchedulesWithNotification:YES];
}

- (BOOL) deleteAllSchedulesWithNotification:(BOOL)notification{
    // AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
    NSManagedObjectContext * context = [CoreDataHandler sharedHandler].managedObjectContext;
    context.persistentStoreCoordinator = [CoreDataHandler sharedHandler].persistentStoreCoordinator;
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
        if(notification){
            [self removeESMNotificationsWithHandler:^{
                
            }];
        }
        return YES;
    }else{
        if (saveError!=nil) {
            NSLog(@"[ESMScheduleManager] data delete error: %@", error.debugDescription);
        }
        return YES;
    }
}


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
    // AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    
    // Fetch vaild schedules by date and expiration
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    [req setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class])
                               inManagedObjectContext:[CoreDataHandler sharedHandler].managedObjectContext]];
    [req setPredicate:[NSPredicate predicateWithFormat:@"(start_date <= %@) AND (end_date >= %@)", datetime, datetime]];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"start_date" ascending:NO];
    NSSortDescriptor *sortBySID = [[NSSortDescriptor alloc] initWithKey:@"schedule_id" ascending:NO];
    [req setSortDescriptors:@[sort,sortBySID]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:req
                                                                                               managedObjectContext:[CoreDataHandler sharedHandler].managedObjectContext
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:nil];
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    NSArray * periodValidSchedules = [fetchedResultsController fetchedObjects];
    
    
    /////// Fetch ESM answer history from Today
    NSFetchRequest *historyReq = [[NSFetchRequest alloc] init];
    [historyReq setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMAnswerHistory class])
                                      inManagedObjectContext:[CoreDataHandler sharedHandler].managedObjectContext]];
    NSNumber * now = @(datetime.timeIntervalSince1970);
    NSNumber * start = @([AWAREUtils getTargetNSDate:[NSDate new] hour:0 nextDay:false].timeIntervalSince1970);
    [historyReq setPredicate:[NSPredicate predicateWithFormat:@"(timestamp >= %@) && (timestamp <= %@)", start, now]]; //(timestamp >= %@) &&
    NSSortDescriptor *historySort = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [historyReq setSortDescriptors:@[historySort]];
    NSFetchedResultsController *historyFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:historyReq
                                                                                                      managedObjectContext:[CoreDataHandler sharedHandler].managedObjectContext
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
        NSString * contexts = schedule.contexts;
        if (contexts == nil || [contexts isEqualToString:@""]) {
            contexts = nil;
        }
        // NSNumber * weekday = schedule.weekday;
        
        bool isValidSchedule = NO;
        /**  Hours Based ESM */
        if (hour.intValue != -1) {
            isValidSchedule = [self isValidHourBasedESMSchedule:schedule history:answerHistory targetDatetime:datetime];
        }
        
        /**  Timer Based ESM */
        if( timer != nil ){
            isValidSchedule = [self isValidTimerBasedESMSchedule:schedule history:answerHistory targetDatetime:datetime];
        } else if(hour.intValue == -1){
            isValidSchedule = YES;
        }
        
        /** Context **/
//        if( contexts != nil ){
//            isValidSchedule = [self isValidContextBasedESMSchedule:schedule];
//        }
        
        if (isValidSchedule) {
            [validSchedules addObject:schedule];
        }
    }

    return validSchedules;
}



/**
 Validate an ESM Schdule

 @param schedule EntityESMSchdule
 @param history An array list of EntityESMAnswerHistory
 @param datetime A target datetime
 @return vaild or invaild
 */
- (BOOL) isValidHourBasedESMSchedule:(EntityESMSchedule  *)schedule history:(NSArray *)history targetDatetime:(NSDate *)datetime{

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MM/dd/yyyy HH:mm"];
    [NSTimeZone resetSystemTimeZone];
    
    NSString * scheduleId = schedule.schedule_id;
    if(scheduleId == nil){
        if (_debug) NSLog(@"[ESMScheduleManager] (invalid) Schdule ID is Empty");
        return NO;
    }
    
    NSNumber * randomize = schedule.randomize_schedule;
    if(randomize == nil) randomize = @0;
    NSNumber * expiration = schedule.expiration_threshold;
    if(expiration == nil) expiration = @0;

    NSDate * now = [NSDate date];
    NSNumber * fireHour = schedule.fire_hour;
    NSDate * targetDateInToday       = [AWAREUtils getTargetNSDate:now hour:[fireHour intValue] nextDay:NO];
    NSDate * targetDateInNextday     = [AWAREUtils getTargetNSDate:now hour:[fireHour intValue] nextDay:YES];
    
    double nowUnix = now.timeIntervalSince1970;
    
    /// randomize mode -> need to make a buffer ////
    if (randomize.intValue > 0) {
        ////// start/end time based validation /////
        int validRange = 60 * (randomize.intValue + expiration.intValue); // min
        NSDate * validStartDateToday   = [targetDateInToday   dateByAddingTimeInterval:-1 * validRange];
        NSDate * validEndDateToday     = [targetDateInToday   dateByAddingTimeInterval:validRange];
        
        NSDate * validStartDateNextday = [targetDateInNextday dateByAddingTimeInterval:-1 * validRange];
        NSDate * validEndDateNextday   = [targetDateInNextday dateByAddingTimeInterval:validRange];
        
        if ( ((nowUnix  >= validStartDateToday.timeIntervalSince1970) && (nowUnix  <= validEndDateToday.timeIntervalSince1970 )) ||
             ((nowUnix  >= validStartDateNextday.timeIntervalSince1970) && (nowUnix  <= validEndDateNextday.timeIntervalSince1970)) ){
            if (_debug) NSLog(@"[ESMScheduleManager] (valid) start < now < end");
        }else{
            if (_debug) NSLog(@"[ESMScheduleManager] (invalid) out of term");
            return NO;
        }
    //// normal mode ////
    }else{
        int validRange = 60 * expiration.intValue;
        NSDate * validStartDateToday   = targetDateInToday;
        NSDate * validEndDateToday     = [targetDateInToday   dateByAddingTimeInterval:validRange];
        
        NSDate * validStartDateNextday = targetDateInNextday;
        NSDate * validEndDateNextday   = [targetDateInNextday dateByAddingTimeInterval:validRange];
        if ( ((nowUnix  >= validStartDateToday.timeIntervalSince1970) && (nowUnix  <= validEndDateToday.timeIntervalSince1970 )) ||
             ((nowUnix  >= validStartDateNextday.timeIntervalSince1970) && (nowUnix  <= validEndDateNextday.timeIntervalSince1970)) ){
            if (_debug) NSLog(@"[ESMScheduleManager] (valid) start < now < end");
        }else{
            if (_debug) NSLog(@"[ESMScheduleManager] (invalid) out of term");
            return NO;
        }
    }

    
    /////  history based validation  //////
    if (history != nil) {
        for (EntityESMAnswerHistory * answeredESM in history) {
            NSString * historyScheduleId = answeredESM.schedule_id;
            NSNumber * historyFireHour   = answeredESM.fire_hour;
            if ([scheduleId isEqualToString:historyScheduleId] && [fireHour isEqualToNumber:historyFireHour]) {
                if (_debug) NSLog(@"[ESMScheduleManager] (invalid) => schedule id=%@, fire-hour=%@", scheduleId, fireHour);
                return NO;
            }else{
                if (_debug) NSLog(@"[ESMScheduleManager] (valid) schedule id=%@, fire-hour=%@", scheduleId, fireHour);
            }
        }
    }
    
    if([expiration isEqualToNumber:@0]){
        return YES;
    }
    
    NSLog(@"[id:%@][hour:%@][randomize:%@][expiration:%@]",scheduleId,fireHour,randomize,expiration);
    return YES;
}


- (BOOL) isValidTimerBasedESMSchedule:(EntityESMSchedule  *)schedule history:(NSArray *)history targetDatetime:(NSDate *)datetime{
    return YES;
}


///////////////// UNNotifications ///////////////////////

/**
 set an hour based UNNotification

 @param schedule EntityESMSchedule
 @param datetime A target time
 */
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
    content.body = schedule.notification_body;
    content.sound = [UNNotificationSound defaultSound];
    content.categoryIdentifier = categoryNormalESM;
    content.userInfo = userInfo;
    content.badge = @(1);

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:fireDate];
    UNCalendarNotificationTrigger * trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:repeat];

    NSString *notificationId = [NSString stringWithFormat:@"%@_%@_%@",KEY_AWARE_NOTIFICATION_DEFAULT_REQUEST_IDENTIFIER,fireHour.stringValue,schedule.schedule_id];

    UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:notificationId content:content trigger:trigger];

    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center removePendingNotificationRequestsWithIdentifiers:@[notificationId]];
    [center removeDeliveredNotificationsWithIdentifiers:@[notificationId]];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error!=nil) {
            NSLog(@"[ESMScheduleManager:HourBasedNotification] %@", error.debugDescription);
        }else{
            if (self->_debug) NSLog(@"[ESMScheduleManager:HourBasedNotification] Set a notification: %ld:%ld",trigger.dateComponents.hour,trigger.dateComponents.minute);
            UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
            [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
                for (UNNotificationRequest * request in requests) {
                    NSLog(@"%@",request.identifier);
                }
            }];
        }
    }];
}



/**
 Set a time based notifiation

 @param schedule EntityESMSchdule
 @param datetime A target datetime of the notification (NSDate)
 */
- (void) setTimeBasedNotification:(EntityESMSchedule *)schedule datetime:(NSDate *)datetime{
    
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
    content.body = schedule.notification_body;
    content.sound = [UNNotificationSound defaultSound];
    content.categoryIdentifier = categoryNormalESM;
    content.userInfo = userInfo;
    content.badge = @(1);
    
    NSDateComponents * components = (NSDateComponents *)schedule.timer;
    if (components !=nil) {
        UNCalendarNotificationTrigger * trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:repeat];
        NSString * requestId = [NSString stringWithFormat:@"%@_%ld_%ld_%@",KEY_AWARE_NOTIFICATION_DEFAULT_REQUEST_IDENTIFIER,components.hour,components.minute, schedule.schedule_id];
        UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:requestId content:content trigger:trigger];
        
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        [center removePendingNotificationRequestsWithIdentifiers:@[requestId]];
        [center removeDeliveredNotificationsWithIdentifiers:@[requestId]];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error!=nil) {
                NSLog(@"[ESMScheduleManager:TimerBasedNotification] %@", error.debugDescription);
            }else{
                if(self->_debug)NSLog(@"[ESMScheduleManager:TimerBasedNotification] Set a notification");
            }
        }];
    }
}

/**
 Set a time based notifiation
 
 @param schedule EntityESMSchdule
 */
- (void) setContextBasedNotification:(EntityESMSchedule *)schedule{
    NSString * contextsString = schedule.contexts;
    NSData * contextsData = [contextsString dataUsingEncoding:NSUTF8StringEncoding];
    NSError * error = nil;
    NSArray * contexts = [NSJSONSerialization JSONObjectWithData:contextsData options:0 error:&error];
    if (error!=nil) {
        return;
    }
    if (contexts==nil || contexts.count == 0) {
        return;
    }
    for (NSString * context in contexts) {
        NSLog(@"context: %@",context);

        NSString * title = schedule.notification_title;
        id observer = [[NSNotificationCenter defaultCenter] addObserverForName:context
                                                                        object:nil
                                                                         queue:[NSOperationQueue currentQueue]
                                                                    usingBlock:^(NSNotification * _Nonnull note) {
            UNMutableNotificationContent * content = [[UNMutableNotificationContent alloc] init];
            content.title = title;
            content.sound = [UNNotificationSound defaultSound];
            content.badge = @1;

            UNNotificationTrigger * trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
            UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:@"aware.esm.context.notification" content:content trigger:trigger];

            [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[@"aware.esm.context.notification"]];
            [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:@[@"aware.esm.context.notification"]];
            [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {

            }];
            
        }];
        [contextObservers addObject:observer];

    }
}

- (void) sendContextBasedESMNotification:(NSNotification *)notification{
    
    NSLog(@"%@",notification.debugDescription);
    
}

/**
 Set a time based notifiation
 
 @param schedule EntityESMSchdule
 */
- (BOOL) isValidContextBasedESMSchedule:(EntityESMSchedule *)schedule {
    
    return YES;
}


/**
 Remove pending notification schedules which has KEY_AWARE_NOTIFICATION_DEFAULT_REQUEST_IDENTIFIER.
 
 @note This operation is aynchroized!!
 */
- (void)removeESMNotificationsWithHandler:(NotificationRemoveCompleteHandler)handler {
    
    NSDate * now = [NSDate new];
    
    for (id observer in contextObservers) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
    [contextObservers removeAllObjects];
    
    // Get ESMs from SQLite by using CoreData
    NSArray * esmSchedules = [self getValidSchedulesWithDatetime:now];
    if(esmSchedules == nil) return;
    
    // remove all old notifications from UNUserNotificationCenter
    UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        if (requests != nil) {
            for (UNNotificationRequest * request in requests) {
                NSString * identifer = request.identifier;
                if (identifer!=nil) {
                    if ([identifer hasPrefix:KEY_AWARE_NOTIFICATION_DEFAULT_REQUEST_IDENTIFIER]) {
                        if (self->_debug) NSLog(@"[ESMScheduleManager] remove pending notification: %@", identifer);
                        [center removePendingNotificationRequestsWithIdentifiers:@[identifer]];
                    }
                }
            }
        }
        if (handler != nil) {
            handler();
        }
    }];
}


/**
 Refresh notifications times
 */
- (void) refreshESMNotifications{
    NSDate * now = [NSDate new];
    
    for (id observer in contextObservers) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
    [contextObservers removeAllObjects];
    
    // Get ESMs from SQLite by using CoreData
    NSArray * esmSchedules = [self getValidSchedulesWithDatetime:now];
    if(esmSchedules == nil) return;
    
    // remove all old notifications from UNUserNotificationCenter
    UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        if (requests != nil) {
            for (UNNotificationRequest * request in requests) {
                NSString * identifer = request.identifier;
                if (identifer!=nil) {
                    if ([identifer hasPrefix:KEY_AWARE_NOTIFICATION_DEFAULT_REQUEST_IDENTIFIER]) {
                        if (self->_debug) NSLog(@"[ESMScheduleManager] remove pending notification: %@", identifer);
                        [center removePendingNotificationRequestsWithIdentifiers:@[identifer]];
                    }
                }
            }
        }
        
        //////// Set new UNNotifications /////////
        for (int i=0; i<esmSchedules.count; i++) {

            EntityESMSchedule * schedule = esmSchedules[i];

            NSNumber * hour = schedule.fire_hour;
            NSDateComponents * timer = (NSDateComponents *)schedule.timer;
            NSString * contexts = schedule.contexts;
            
            /**  Hours Based ESM */
            if (hour.intValue != -1) {
                [self setHourBasedNotification:schedule datetime:now];
            }

            /**  Timer Based ESM */
            if( timer != nil ){
                [self setTimeBasedNotification:schedule datetime:now];
            }
            
            /** Context Based ESM */
//            if (![contexts isEqualToString:@""]){
//                [self setContextBasedNotification:schedule];
//            }
        }
    }];
}


////////////// DEBUG ////////////////


/**
 Remove all ESM Schdules from database.
 
 @note This method remove all of schedule entities from SQLite. Please use care fully.
 
 @return A state of the remove offeration success or not.
 */
- (BOOL) removeAllSchedulesFromDB {
    // AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([EntityESMSchedule class])];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    NSError *deleteError = nil;
    [[CoreDataHandler sharedHandler].managedObjectContext executeRequest:delete error:&deleteError];
    if(deleteError != nil){
        NSLog(@"[ESMScheduleManager:removeNotificationScheduleFromSQLite] Error: A delete query is failed");
        return NO;
    }
    return YES;
}


/**
 Remove all pending/delivded notifications from the UNUserNotificationCenter for a debug
 */
- (void) removeAllNotifications {
    UNUserNotificationCenter * notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    [notificationCenter removeAllDeliveredNotifications];
    [notificationCenter removeAllPendingNotificationRequests];
}

/**
 Remove all ESM answer histories

 @return A status of the removing ESM history
 */
- (BOOL) removeAllESMHitoryFromDB {
    // AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([EntityESMAnswerHistory class])];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    NSError *deleteError = nil;
    [[CoreDataHandler sharedHandler].managedObjectContext executeRequest:delete error:&deleteError];
    if(deleteError != nil){
        NSLog(@"[ESMScheduleManager:removeESMHistoryFromSQLite] Error: A delete query is failed");
        return NO;
    }
    return YES;
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
