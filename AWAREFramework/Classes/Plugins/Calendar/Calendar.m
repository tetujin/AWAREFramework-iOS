//
//  Calendar.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/04/03.
//

#import "Calendar.h"
#import "CalEvent.h"
#import "EntityCalendar+CoreDataClass.h"

@implementation Calendar{
    EKEventStore   * store;
    EKSource       * source;
    NSTimer        * timer;
    CalendarEventHandler calendarEventHandler;
    CalendarEventsHandler calendarEventsHandler;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = [[SQLiteStorage alloc] initWithStudy:study
                                                       sensorName:@"plugin_calendar"
                                                       entityName:NSStringFromClass([EntityCalendar class])
                                                   insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                                       EntityCalendar * calEntity = (EntityCalendar *)[NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:childContext];
                                                           calEntity.device_id = [data objectForKey:@"device_id"];
                                                           calEntity.timestamp = [data objectForKey:@"timestamp"];
                                                           calEntity.calendar_id = [data objectForKey:@"calendar_id"];
                                                           calEntity.account_name = [data objectForKey:@"account_name"];
                                                           calEntity.calendar_name = [data objectForKey:@"calendar_name"];
                                                           calEntity.owner_account = [data objectForKey:@"owner_account"];
                                                           calEntity.event_id = [data objectForKey:@"event_id"];
                                                           calEntity.title = [data objectForKey:@"title"];
                                                           calEntity.location = [data objectForKey:@"location"];
                                                           calEntity.calendar_description = [data objectForKey:@"description"];
                                                           calEntity.begin = [data objectForKey:@"begin"];
                                                           calEntity.end = [data objectForKey:@"end"];
                                                           calEntity.all_day = [data objectForKey:@"all_day"];
                                                           calEntity.note = [data objectForKey:@"note"];
                                                           calEntity.status = [data objectForKey:@"state"];
                                                       }];
    self = [super initWithAwareStudy:study sensorName:@"plugin_calendar" storage:storage];
    if (self!=nil) {
        store = [[EKEventStore alloc] init];
        // events = [[NSMutableArray alloc] init];
        _vaildFutureDays = 0;
        _vaildPastDays = 0;
        _checkingIntervalSecond = 60; //*15;
        _sensingEventHour = 0;
    }
    return self;
}


- (void)setParameters:(NSArray *)parameters{
    
    
}

- (void)createTable{
    if ([self isDebug]) NSLog(@"[%@] Create table", [self getSensorName]);
    CalEvent *calEvent = [[CalEvent alloc] init];
    [self.storage createDBTableOnServerWithQuery:[calEvent getCreateTableQuery]];
}

/**
 Start Calendar sensor

 @return run or not
 */
- (BOOL)startSensor{
    // request a calendar access
    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error){
        if(granted){ // yes
            // subscribe calender update events
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(storeChanged:)
                                                         name:EKEventStoreChangedNotification
                                                       object:self->store];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self collectCalendarEvents];
            });
        }else{ // no
            
        }
    }];
    
    if (timer==nil) {
        timer = [NSTimer scheduledTimerWithTimeInterval:_checkingIntervalSecond
                                                 target:self
                                               selector:@selector(collectCalendarEventsIfNeed)
                                               userInfo:nil
                                                repeats:YES];
    }
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults doubleForKey:@"plugin_calendar_setting_next_fetch"] != 0) {
        NSDate * nextFetch = [AWAREUtils getTargetNSDate:[NSDate new] hour:_sensingEventHour nextDay:YES];
        [defaults setDouble:nextFetch.timeIntervalSince1970 forKey:@"plugin_calendar_setting_next_fetch"];
    }
    
    return YES;
}


- (BOOL) stopSensor {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:EKEventStoreChangedNotification
                                                  object:store];
    store = nil;
    if (timer!=nil) {
        [timer invalidate];
        timer = nil;
    }
    return YES;
}


/////////////////////////////////////////

- (BOOL) collectCalendarEventsIfNeed {
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    double nextFetch = [defaults doubleForKey:@"plugin_calendar_setting_next_fetch"];
    
    NSDate * now = [NSDate new];
    
    if (nextFetch < now.timeIntervalSince1970) {
        
        [self collectCalendarEvents];
        
        [defaults setDouble:[AWAREUtils getTargetNSDate:[NSDate new] hour:_sensingEventHour nextDay:YES].timeIntervalSince1970 forKey:@"plugin_calendar_setting_next_fetch"];
        [defaults synchronize];
        return YES;
    }
    
    return NO;
}


- (void) collectCalendarEvents {
    NSArray * events = [self getEvents];
    
    for (CalEvent * event in events) {
        NSMutableDictionary * dict = [event getCalEventAsDictionaryWithDeviceId:self.getDeviceId
                                                                      timestamp:[AWAREUtils getUnixTimestamp:[NSDate new]]];
        [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
        SensorEventHandler handler = [self getSensorEventHandler];
        if (handler!=nil) {
            handler(self, dict);
        }
        [self setLatestData:dict];
    }
}

/**
 This method is called when any canelar events are modified on the Calendar.app

 @param notification A notification from NSNotificationCenter
 */
- (void) storeChanged:(NSNotification *) notification {
    if ([self isDebug]) NSLog(@"A calendar event is updated!");
    [self collectCalendarEvents];
}



/**
 Get calendar lists

 @return A list of calendars
 */
- (NSArray *) getCalendars {
    NSMutableArray * cals = [[NSMutableArray alloc] init];
    for (EKSource *calSource in store.sources) {
        if([self isDebug]) NSLog(@"%@",calSource);
        [cals addObject:calSource.title];
    }
    return cals;
}


/**
 Get calendar evetns

 @return Calendar events as a NSArray format
*/
- (NSArray *) getEvents {
    // [events removeAllObjects];
    NSMutableArray * events = [[NSMutableArray alloc] init];
    NSArray <EKEvent *> * ekEvents = [store eventsMatchingPredicate:[self getPredication]];
    if (calendarEventsHandler!=nil) {
        calendarEventsHandler(self, ekEvents);
    }
    if (ekEvents != nil) {
        for (EKEvent * ekEvent in ekEvents) {
            if (calendarEventHandler!=nil) {
                calendarEventHandler(self, ekEvent);
            }
            CalEvent* event = [[CalEvent alloc] initWithEKEvent:ekEvent];
            [events addObject:event];
        }
    }
    return events;
}


- (NSPredicate *) getPredication {
    
    NSDate *now = [NSDate date];
    
    NSDate * vaildPastDate = now;
    if (_vaildPastDays != 0) {
        vaildPastDate = [[NSDate alloc] initWithTimeIntervalSinceNow:60*60*24*_vaildPastDays];
    }
    
    NSDate * vaildFutureDate = now;
    if (_vaildFutureDays != 0) {
        vaildFutureDate = [[NSDate alloc] initWithTimeIntervalSinceNow:60*60*24*_vaildPastDays];
    }
    
    NSDate * startDate = [AWAREUtils getTargetNSDate:vaildPastDate hour:0 nextDay:NO];
    NSDate * endDate = [AWAREUtils getTargetNSDate:vaildFutureDate hour:0 nextDay:YES];
    
    NSPredicate *predicate = [store predicateForEventsWithStartDate:startDate
                                                            endDate:endDate
                                                          calendars:nil];
    return predicate;
}

/////////////////////////////////////////////////////////

- (void) setLatestValueWithEvent:(CalEvent *) event {
    // update latest updated sensor value.
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm"];
    NSString *formattedDateString = [dateFormatter stringFromDate:[NSDate new]];
    [super setLatestValue:[NSString stringWithFormat:@"[%@] %@ (%@)", event.status, event.title, formattedDateString]];
}

- (void)setCalendarEventHandler:(CalendarEventHandler)handler{
    calendarEventHandler = handler;
}

- (void) setCalendarEventsHandler:(CalendarEventsHandler)handler{
    calendarEventsHandler = handler;
}

//////////////////////////////////////////////////////////////////////////////////////
//- (void) updateExistingEvents {
//    [events removeAllObjects];
//    // Loop through all events in range
//    [store enumerateEventsMatchingPredicate:[self getPredication] usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
//        // Check this event against each ekObjectID in notification
//        CalEvent* calEvent = [[CalEvent alloc] initWithEKEvent:ekEvent];
//        [self->events addObject:calEvent];
//        NSLog(@"%@",calEvent.title);
//    }];
//}


//- (void) saveOriginalCalEvents {
//    [store enumerateEventsMatchingPredicate:[self getPredication] usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
//        // Check this event against each ekObjectID in notification
//        CalEvent* calEvent = [[CalEvent alloc] initWithEKEvent:ekEvent eventType:CalEventTypeOriginal];
//        [self saveCalEvent:calEvent];
//    }];
//}

//- (CalEvent *) getDeletedCalEvent:(NSMutableArray *) currentEvents{
//    CalEvent * deletedCalEvent = nil;
//    for (CalEvent* oldCalEvent in events) {
//        bool deletedFlag = YES;
//        for (EKEvent* currentEvent in currentEvents ) {
//            if ([oldCalEvent.eventId isEqualToString:currentEvent.eventIdentifier]) {
//                deletedFlag = NO;
//            }
//        }
//        if ( deletedFlag ) {
//            //            deletedEKEvent = oldCalEvent;
//            deletedCalEvent = oldCalEvent;
//            NSLog(@"%@", oldCalEvent.description);
//            break;
//        }
//    }
//    return deletedCalEvent;
//}


//- (BOOL) isAdd :(EKEvent *) event {
//    for (CalEvent* oldCalEvent in events) {
//        if ([oldCalEvent.eventId isEqualToString:event.eventIdentifier]) {
//            return NO;
//        }
//    }
//    return YES;
//}



//- (CalEvent *) getDeletedCalEventWithManageId:(NSObject*) manageId {
//    for (CalEvent* calEvent in events) {
//        if([calEvent.objectManageId isEqual:manageId]){
//            return calEvent;
//        }
//    }
//    return nil;
//}


@end
