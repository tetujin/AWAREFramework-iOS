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
    NSMutableArray * events;
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
        events = [[NSMutableArray alloc] init];
        _offsetStartDay = 0;
        _offsetStartMonth = 0;
        _offsetStartYear = 0;
        _offsetEndDay = 1;
        _offsetEndMonth = 0;
        _offsetEndYear = 0;
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
        }else{ // no
            
        }
    }];
    
    [self getEvents];
    
    return YES;
}


- (BOOL) stopSensor {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:EKEventStoreChangedNotification
                                                  object:store];
    store = nil;
    return YES;
}


/////////////////////////////////////////


/**
 This method is called when any canelar events are modified on the Calendar.app

 @param notification A notification from NSNotificationCenter
 */
- (void) storeChanged:(NSNotification *) notification {
    if ([self isDebug]) NSLog(@"A calendar event is updated!");
}



/**
 Get calendar lists

 @return A list of calendars
 */
- (NSArray *) getCalendars {
    NSMutableArray * cals = [[NSMutableArray alloc] init];
    for (EKSource *calSource in store.sources) {
        NSLog(@"%@",calSource);
        [cals addObject:calSource.title];
    }
    return cals;
}

- (void) getEvents {
    [events removeAllObjects];
    NSArray <EKEvent *> * ekEvents = [store eventsMatchingPredicate:[self getPredication]];
    if (ekEvents != nil) {
        for (EKEvent * ekEvent in ekEvents) {
            NSLog(@"[%@] %@",ekEvent.calendar.title, ekEvent.title);
            CalEvent* event = [[CalEvent alloc] initWithEKEvent:ekEvent];
            [self->events addObject:event];
        }
    }
}

- (void) saveCalendarEvent:(CalEvent *)calEvent{
    NSMutableDictionary * dict = [calEvent getCalEventAsDictionaryWithDeviceId:self.getDeviceId
                                                                     timestamp:[AWAREUtils getUnixTimestamp:[NSDate new]]];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, dict);
    }
    [self setLatestData:dict];
}

- (NSPredicate *) getPredication {
    NSDate *now = [NSDate date];
    NSDateComponents *offsetComponentsEnd = [NSDateComponents new];
    [offsetComponentsEnd setDay:_offsetEndDay];
    [offsetComponentsEnd setMonth:_offsetEndMonth];
    [offsetComponentsEnd setYear:_offsetEndYear];
    [offsetComponentsEnd setHour:0];
    [offsetComponentsEnd setMinute:0];
    [offsetComponentsEnd setSecond:0];
    NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponentsEnd toDate:now options:0];
    
    NSDateComponents *offsetComponentsStart = [NSDateComponents new];
    [offsetComponentsStart setDay:_offsetStartDay];
    [offsetComponentsStart setMonth:_offsetStartMonth];
    [offsetComponentsStart setYear:_offsetStartYear];
    [offsetComponentsStart setHour:0];
    [offsetComponentsStart setMinute:0];
    [offsetComponentsStart setSecond:0];
    NSDate *startDate = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponentsStart toDate:now options:0];
    
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


//////////////////////////////////////////////////////////////////////////////////////
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
