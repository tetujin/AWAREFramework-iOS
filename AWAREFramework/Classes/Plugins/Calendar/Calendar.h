//
//  Calendar.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/04/03.
//

/**
 *
 */

#import "AWARESensor.h"
#import <EventKitUI/EventKitUI.h>

/**
 
 NOTE: If you can not see a "shared Google Calendar" on your iPhone, you have to check the calendar on the URL ( http://www.google.com/calendar/iphoneselect ).
 
 */

extern NSString* const AWARE_PREFERENCES_STATUS_CALENDAR;

@interface Calendar : AWARESensor

typedef void (^CalendarEventHandler)(AWARESensor *sensor, EKEvent *event);
typedef void (^CalendarEventsHandler)(AWARESensor *sensor, NSArray<EKEvent *> *events);

@property int vaildFutureDays;
@property int vaildPastDays;
@property int sensingEventHour;
@property double checkingIntervalSecond;

- (void) collectCalendarEvents;
- (void) setCalendarEventHandler:(CalendarEventHandler)handler;
- (void) setCalendarEventsHandler:(CalendarEventsHandler)handler;

@end
