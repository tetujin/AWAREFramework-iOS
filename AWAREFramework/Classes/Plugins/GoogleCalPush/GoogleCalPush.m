//
//  GoogleCalPush.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "GoogleCalPush.h"
#import "Debug.h"

NSString* const PLUGIN_GOOGLE_CAL_PUSH_CAL_NAME = @"BalancedCampusJournal";

@implementation GoogleCalPush {
    // Variable for a calendar instance
    EKEventStore *store;
    // Calendar update timer (check calendar condition every 6 hous)
    NSTimer * calendarUpdateTimer;
    // Calendar update trigger time
    NSDate * fireDate;
    // Notification date
    NSDate * notificationDate;
    // Update interval
    double updateInteval;
    // Local push notification
    UILocalNotification * localNotification;
}

// Initializer
- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_GOOGLE_CAL_PUSH
                        dbEntityName:nil
                              dbType:AwareDBTypeJSON];
    if (self) {
        // Set a celendar update trigger time at 8pm
        fireDate  = [AWAREUtils getTargetNSDate:[NSDate date] hour:19 minute:0 second:0 nextDay:NO];
        
        // Set a notification date
        notificationDate = [AWAREUtils getTargetNSDate:[NSDate date] hour:20 minute:0 second:0 nextDay:YES];
        
        // Set an update interval
        updateInteval = 60*60*24;
        
        
        // Set latest sensor data using -setLatestValue:. The sensor list on the main page of AWARE accesses the value and shows the latest value.
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm"];
        NSString *formattedDateString = [dateFormatter stringFromDate:fireDate];
        [super setLatestValue:[NSString stringWithFormat:@"Next Calendar Update: %@", formattedDateString]];
        NSLog(@"date: %@", fireDate );
        
        // Make a calendar instance
        store = [[EKEventStore alloc] init];
        [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error){
            if(granted){
                NSLog(@"ok");
            }else{
                NSLog(@"no");
            }
        }];
    }
    return self;
}

- (void)setParameters:(NSArray *)parameters{
    
}

// Start Sensor
- (BOOL)startSensor{
    // Set a scheduled local notification for a calendar update
    [self setDailyNotification];
    // Set a scheduled calendar update timer
    [self setDailyCalUpdate];
    // Sheck events
//    [self checkCalendarEvents:nil];
    return YES;
}

// Stop Sensor
- (BOOL) stopSensor {
    // Stop the calendar update timer
    if (calendarUpdateTimer != nil) {
        [calendarUpdateTimer invalidate];
        calendarUpdateTimer = nil;
    }
    // stop a scheduled local notification
    if (localNotification != nil) {
        [AWAREUtils cancelLocalNotification:localNotification];
    }
    // remove a calendar instance
    store = nil;
    
    return YES;
}


- (void)changedBatteryState{
    [self checkCalendarEvents:nil];
}

//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////

/**
 * Set a scheduled time for a calendar update
 * @discussion  This schedule timer is not stable because sometimes depending on the device status, iOS kills or suspend background application processes. This timer is working on the application background process.
 */
- (void) setDailyCalUpdate {
    // Set a calendar update timer
    calendarUpdateTimer = [[NSTimer alloc] initWithFireDate:fireDate
                                                   interval:updateInteval
                                                     target:self
                                                   selector:@selector(checkCalendarEvents:)
                                                   userInfo:nil
                                                    repeats:YES];
    //https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Timers/Articles/usingTimers.html
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:calendarUpdateTimer forMode:NSRunLoopCommonModes];
//    [runLoop addTimer:calendarUpdateTimer forMode:NSDefaultRunLoopMode];
}


/**
 * Set a daily notification
 * @discussion  This schedule timer is not stable because sometimes depending on the device status, iOS kills or suspend background application processes. This timer is working on the application background process.
 */
- (void) setDailyNotification {
    NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
    localNotification = [AWAREUtils sendLocalNotificationForMessage:@"Swipe to make pre-populated events on your calendar!"
                                                              title:@"Please fill out your calendar"
                                                          soundFlag:YES
                                                           category:[self getSensorName]
                                                           fireDate:notificationDate
                                                     repeatInterval:NSCalendarUnitDay
                                                           userInfo:userInfo
                                                    iconBadgeNumber:0];
}

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

/**
 * Check calendar events with a -makePrepopulateEventWith:date method.
 * @discussion This method is called by "calendarUpdateTimer" method when the tigger time is comming.
 */
- (void) checkCalendarEvents:(id) sender {
    
    // Get all events
    NSDate * now = [NSDate new];
    if ( [now timeIntervalSince1970] > [[AWAREUtils getTargetNSDate:now hour:18 nextDay:NO] timeIntervalSince1970]) {
        [self makePrepopulateEvetnsWith:now];
    }
    
    // Make yesterday's pre-popluated events
    NSDate * yesterday = [AWAREUtils getTargetNSDate:[NSDate new] hour:-24 minute:0 second:0 nextDay:NO];
    [self makePrepopulateEvetnsWith:yesterday];
}


/**
 * Make pre-populate events with a target date(NSDate).
 * @param   NSDate      A target date
 * @discussion This method called by -checkCalendarEvents: on self or -application:didReceiveLocalNotification: on notificationAppDelegate.m after recieving a local push notification.
 */
- (void) makePrepopulateEvetnsWith:(NSDate *) date {
    // Init a dateformatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    // Save a making prepopulate events to a debug sensor
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString * debugMessage = [NSString stringWithFormat:@"[%@] BalancedCampusJournal Plugin start to populate events at ", [timeFormat stringFromDate:date]];
    [self saveDebugEventWithText:debugMessage type:DebugTypeInfo label:[timeFormat stringFromDate:date]];

    // Get the target calendar(BalancedCampusCalendar) from local calendars
    EKCalendar * awareCal = nil;
    for (EKCalendar * cal in [store calendarsForEntityType:EKEntityTypeEvent]) {
        NSLog(@"[%@] %@", cal.title, cal.calendarIdentifier );
        if ([cal.title isEqualToString:PLUGIN_GOOGLE_CAL_PUSH_CAL_NAME]) {
            awareCal = cal;
        }
    }
    
    // If the target calendar is not existing, this program finishes, and save the event to the debug sensor.
    if (awareCal == nil) {
        NSString* message = @"[ERROR] AWARE iOS can not find a 'BalancedCampusJournal' on your Calendar.";
        NSLog(@"%@", message);
        [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
        [self saveDebugEventWithText:message type:DebugTypeError label:@""];
        return;
    }
    
    //http://stackoverflow.com/questions/1889164/get-nsdate-today-yesterday-this-week-last-week-this-month-last-month-var
    // Get a today's start timestamp (e.g., 2/26/2016 00:00:00)
    NSDate * startOfNSDate = [AWAREUtils getTargetNSDate:date hour:0 minute:0 second:0 nextDay:NO];
    // Get a today's end timestamp (e.g., 2/26/2016 24:00:00)
    NSDate * endOfNSDate = [AWAREUtils getTargetNSDate:date hour:24 minute:0 second:0 nextDay:NO];
    // Initialize a variable for current events
    NSMutableArray * currentEvents = [[NSMutableArray alloc] init];
    // Initialize a variable for existing journal events
    NSMutableArray * existingJournalEvents = [[NSMutableArray alloc] init];
    // Initialize a variable for prepopulate events
    NSMutableArray * prepopulatedEvents = [[NSMutableArray alloc] init];
    
    NSPredicate *predicate = [store predicateForEventsWithStartDate:startOfNSDate
                                                            endDate:endOfNSDate
                                                          calendars:nil];
    __block bool finished = NO;
    [store enumerateEventsMatchingPredicate:predicate usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
        // Check this event against each ekObjectID in notification
        // NSLog(@"%@", ekEvent.title);
        if (!ekEvent.allDay) {
            [currentEvents addObject:ekEvent]; // Add all events to curretEvents variable
            if(ekEvent.calendar != awareCal){
                [existingJournalEvents addObject:ekEvent]; // Add existing journal events excluding events of BalancedCampusJournal to existingJournalEvents variable
            }else{
                // NSLog(@"%@", ekEvent.debugDescription);
                [prepopulatedEvents addObject:ekEvent]; // Add prepopulated(BalancedCampusJournal's) events to prepopulated events
            }
        }
        finished = stop;
    }];
    
    // Wait to finish getting all events
    int count = 0;
    bool isEmpty = NO;
    while (!finished ) {
        [NSThread sleepForTimeInterval:0.05];
        NSLog(@"%d",count);
        if (count > 60) {
            NSString * debugMessage = @"TIMEOUT: Calendar Update";
            if([self isDebug])[AWAREUtils sendLocalNotificationForMessage:debugMessage soundFlag:NO];
            [self saveDebugEventWithText:debugMessage type:DebugTypeError label:@""];
            isEmpty = YES;
            break;
        }
        count++;
    }
    
    /**
     * Make Null Events to ArrayList
     */
    NSDate * tempNSDate = startOfNSDate;
    NSMutableArray * nullTimes = [[NSMutableArray alloc] init];
    for ( int i=0; i<currentEvents.count; i++) {
        EKEvent * event= [currentEvents objectAtIndex:i];
        NSDate * nullEnd = event.startDate;
        int gap = [nullEnd timeIntervalSince1970] - [tempNSDate timeIntervalSince1970];
        NSLog(@"Gap between events %d", gap);
        if (gap > 0) {
            [nullTimes addObject:[[NSArray alloc] initWithObjects:tempNSDate, nullEnd, nil]];
        }
        tempNSDate = event.endDate;
    }
    if (tempNSDate != nil) {
        if (([endOfNSDate timeIntervalSince1970] - [tempNSDate timeIntervalSince1970]) > 0) {
            [nullTimes addObject:[[NSArray alloc] initWithObjects:tempNSDate, endOfNSDate, nil]];
        }
    }else{
        if (nullTimes.count == 0) {
            [nullTimes addObject:[[NSArray alloc] initWithObjects:startOfNSDate, endOfNSDate, nil]];
        }
    }
    
    NSMutableArray * preNullEvents = [[NSMutableArray alloc] init];
    NSDate * nullStartDate = startOfNSDate; //[AWAREUtils getTargetNSDate:date hour:0 minute:0 second:0 nextDay:NO];
    NSDate * nullEndDate = startOfNSDate; //[AWAREUtils getTargetNSDate:date  hour:0 minute:0 second:0 nextDay:NO];
    for ( EKEvent * event in prepopulatedEvents ) {
        NSDate * nullStart = nullEndDate;
        NSDate * nullEnd = event.startDate;
        int gap = [nullEnd timeIntervalSince1970] - [nullStart timeIntervalSince1970];
        if (gap > 0) {
            [preNullEvents addObject:[[NSArray alloc] initWithObjects:nullStart, nullEnd, nil]];
        }
        nullStartDate = event.startDate;
        nullEndDate = event.endDate;
    }
    
    if (preNullEvents.count == 0 && prepopulatedEvents.count > 0) {
        NSString * debugMessage = [NSString stringWithFormat:@"[%@] Your Calandar is already updated today.",         [dateFormatter stringFromDate:date]];
        if ([self isDebug]) {
            [AWAREUtils sendLocalNotificationForMessage:debugMessage soundFlag:YES];
        }
        [self saveDebugEventWithText:debugMessage type:DebugTypeInfo label:@""];
        return;
    }
    
    /**
     * Make hours ArrayList
     */
    NSMutableArray *hours = [[NSMutableArray alloc] init];
    for (int i=0; i<25; i++) {
        NSDate * today = date;
        [hours addObject:[AWAREUtils getTargetNSDate:today hour:i minute:0 second:0 nextDay:NO]];
    }
    
    NSString * prepopulateTitle = @"#event_category #Location #brief_description";
    
    /**
     * Add pre-populate events to calendar!
     */
    for (NSArray * times in nullTimes) {
        NSDate * nullStart = [times objectAtIndex:0];
        NSDate * nullEnd = [times objectAtIndex:1];
        NSDate * tempNullTime = nullStart;
        
        if ((nullEnd.timeIntervalSince1970 - nullStart.timeIntervalSince1970) == 0) {
            continue;
        }
        
        for (int i=0; i<hours.count; i++) {
            NSDate * currentHour = [hours objectAtIndex:i];
            //set start date
            if (tempNullTime <= currentHour ){
                if (nullEnd >= currentHour) {
                    EKEvent * event = [EKEvent eventWithEventStore:store];
                    event.title = prepopulateTitle;
                    event.calendar  = awareCal;
                    double gap = [nullEnd timeIntervalSince1970] - [currentHour timeIntervalSince1970];
                    if ( gap < 60*60) {
                        event.startDate = tempNullTime;
                        event.endDate   = currentHour;
                        
                        // Make a New Calendar
                        EKEvent * additionalEvent = [EKEvent eventWithEventStore:store];
                        additionalEvent.title = prepopulateTitle;
                        additionalEvent.calendar  = awareCal;
                        additionalEvent.startDate = currentHour;
                        additionalEvent.endDate = nullEnd;
                        int gap = [additionalEvent.endDate timeIntervalSince1970] - [additionalEvent.startDate timeIntervalSince1970];
                        if (gap > 0) {
                            NSError * e = nil;
                            [store saveEvent:additionalEvent span:EKSpanThisEvent commit:YES error:&e];
                            if (e != nil) {
                                NSString * debugString = [NSString stringWithFormat:@"[%d] error: %@", i, e.debugDescription];
                                NSLog(@"%@", debugString);
                                [self saveDebugEventWithText:debugString type:DebugTypeError label:[self getSensorName]];
                            } else {
                                NSLog(@"[%d] success!", i);
                            }
                        }
                    } else {
                        // NSLog(@"start:%@  end:%@", [timeFormat stringFromDate:tempNullTime], [timeFormat stringFromDate:currentHour]);
                        NSLog(@"%@ - %@", [timeFormat stringFromDate:tempNullTime], [timeFormat stringFromDate:currentHour]);
                        event.startDate = tempNullTime;
                        event.endDate   = currentHour;
                    }
                    
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i * 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        NSError * error;
                        double gapgap = [event.endDate timeIntervalSince1970] - [event.startDate timeIntervalSince1970];
                        if (gapgap > 0) {
                            [store saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
                            if (error != nil) {
//                                NSLog(@"[%d] error: %@", i, error.debugDescription);
                                NSString * debugString = [NSString stringWithFormat:@"[%d] error: %@", i, error.debugDescription];
                                NSLog(@"%@", debugString);
                                [self saveDebugEventWithText:debugString type:DebugTypeError label:[self getSensorName]];
                            }else{
                                NSLog(@"[%d] success to store  ", i);
                            }
                        }else{
                            
                        }
                    });
                    tempNullTime = currentHour;
                }
            }
        }
    }
    
    /**
     * Copy Existing Events
     */
    int g = 1;
    for ( EKEvent * event in existingJournalEvents ) {
        bool isPrepopulated = NO;
        for (EKEvent * preEvent in prepopulatedEvents) {
            if ([preEvent.title isEqualToString:event.title] &&
                [preEvent.startDate isEqualToDate:event.startDate] &&
                [preEvent.endDate isEqualToDate:event.endDate]) {
                isPrepopulated = YES;
                break;
            }
        }
        
        if (isPrepopulated) {
            continue;
        }
        
        // Add questions to a note of aware events
        EKEvent * awareEvent = [EKEvent eventWithEventStore:store];
        awareEvent.notes = event.notes;
        awareEvent.title = event.title;
        awareEvent.startDate = event.startDate;
        awareEvent.endDate = event.endDate;
        awareEvent.location = event.location;
        // Change an aware event's calendar
        awareEvent.calendar = awareCal;
        // Save events to the aware calendar
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, g * 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            NSError * error = nil;
            [store saveEvent:awareEvent span:EKSpanThisEvent commit:YES error:&error];
            if (error != nil) {
//                NSLog(@"[%d] error: %@", g, error.debugDescription);
                NSString * debugString = [NSString stringWithFormat:@"[%d] error: %@", g , error.debugDescription];
                NSLog(@"%@", debugString);
                [self saveDebugEventWithText:debugString type:DebugTypeError label:[self getSensorName]];
            }else{
                NSLog(@"[%d] success!",g);
            }
        });
        g++;
    }
    
    // == Send Notification ==
    NSString * message = [NSString stringWithFormat:@"[%@] Hi! Your Calendar is updated.",[dateFormatter stringFromDate:date]];
    [AWAREUtils sendLocalNotificationForMessage:message soundFlag:NO];
    [self saveDebugEventWithText:message type:DebugTypeInfo label:[self getSensorName]];
}



////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

/**
 * Check an existance of BalancedCampusJournal
 * @discussion This method is called by main page of AWARE, when the sensor list is pushed.
 * @return   bool    An existance of BalancedCampusJounal
 */
- (BOOL) isTargetCalendarCondition {
    bool isAvaiable = NO;
    EKEventStore *tempStore = [[EKEventStore alloc] init];
    for (EKCalendar *cal in [tempStore calendarsForEntityType:EKEntityTypeEvent]) {
        NSLog(@"%@", cal.title);
        if ([cal.title isEqualToString:PLUGIN_GOOGLE_CAL_PUSH_CAL_NAME]) {
            isAvaiable = YES;
        }
    }
    return isAvaiable;
}

/**
 * Show an existance of BalancedCampusJournal with an alert view
 * @discussion This method is called by main page of AWARE, when the sensor list is pushed.
 */
- (void) showTargetCalendarCondition {
    bool isAvaiable = NO;
    EKEventStore *tempStore = [[EKEventStore alloc] init];
    for (EKCalendar *cal in [tempStore calendarsForEntityType:EKEntityTypeEvent]) {
        NSLog(@"%@", cal.title);
        if ([cal.title isEqualToString:PLUGIN_GOOGLE_CAL_PUSH_CAL_NAME]) {
            isAvaiable = YES;
        }
    }
    
    tempStore = nil;
    if (isAvaiable) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Correct"
                                                         message:@"'BalancedCampusJournal' calendar is available!"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:nil];
        [alert show];
    }else{
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Miss"
                                                         message:@"AWARE can not find 'BalancedCampusJournal' calendar."
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:nil];
        [alert show];
    }
}



@end
