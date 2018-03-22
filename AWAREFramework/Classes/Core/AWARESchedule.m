
//
//  AWARESchedule.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/17/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESchedule.h"
#import "MultiESMObject.h"

//NSString * const SCHEDULE_KEY_WEEK = @"week";
//NSString * const SCHEDULE_KEY_MONTH = @"month";
//NSString * const SCHEDULE_KEY_TYPE = @"type";
//NSString * const SCHEDULE_KEY_INTERVAL = @"interval";
//NSString * const SCHEFULE_KEY_ACTION_TYPE = @"actionType";

// Weeks
NSString * const SCHEDULE_WEEK_SUNDAY = @"Sunday";
NSString * const SCHEDULE_WEEK_MONDAY = @"Monday";
NSString * const SCHEDULE_WEEK_TUESDAY = @"Tuesday";
NSString * const SCHEDULE_WEEK_WEDNESDAY = @"Wednesday";
NSString * const SCHEDULE_WEEK_THURSDAY = @"Thursday";
NSString * const SCHEDULE_WEEK_FRIDAY = @"Friday";

// Month
NSString * const SCHEDULE_MONTH_JAN = @"January";
NSString * const SCHEDULE_MONTH_FEB = @"February";
NSString * const SCHEDULE_MONTH_MAR = @"March";
NSString * const SCHEDULE_MONTH_APR = @"April";
NSString * const SCHEDULE_MONTH_MAY = @"May";
NSString * const SCHEDULE_MONTH_JUN = @"June";
NSString * const SCHEDULE_MONTH_JUL = @"July";
NSString * const SCHEDULE_MONTH_AUG = @"August";
NSString * const SCHEDULE_MONTH_SEP = @"September";
NSString * const SCHEDULE_MONTH_OCT = @"October";
NSString * const SCHEDULE_MONTH_NOV = @"November";
NSString * const SCHEDULE_MONTH_DEC = @"December";

// Type of schedules
NSString * const SCHEDULE_TYPE_NORMAL = @"SCHEDULE_TYPE_NORMAL";
NSString * const SCHEDULE_TYPE_RANDOM = @"SCHEDULE_TYPE_RANDOM";
NSString * const SCHEDULE_TYPE_CONTEXT = @"SCHEDULE_TYPE_CONTEXT";

// Preparation of an interval
NSString * const SCHEDULE_INTERVAL_HOUR = @"SCHEDULE_INTERVAL_HOUR";
NSString * const SCHEDULE_INTERVAL_DAY = @"SCHEDULE_INTERVAL_DAY";
NSString * const SCHEDULE_INTERVAL_WEEK = @"SCHEDULE_INTERVAL_WEEK";
NSString * const SCHEDULE_INTERVAL_MONTH = @"SCHEDULE_INTERVAL_MONTH";
NSString * const SCHEDULE_INTERVAL_TEST = @"SCHEDULE_INTERVAL_TEST";


NSString * const SCHEDULE_ACTION_TYPE_BROADCAST = @"SCHEDULE_ACTION_TYPE_BROADCAST";
NSString * const SCHEDULE_ACTION_TYPE_ACTIVITY = @"SCHEDULE_ACTION_TYPE_ACTIVITY";
NSString * const SCHEDULE_ACTION_TYPE_SERVICE = @"SCHEDULE_ACTION_TYPE_SERVICE";

@implementation AWARESchedule


- (instancetype) initWithScheduleId:(NSString* ) scheduleId {
    self = [super init];
    if (self) {
        _scheduleId = scheduleId;
        _hour = [NSNumber numberWithInt:0];
        _month = @"";
        _weekday = @"";
        _schedule = nil;
        _context = @"";
        _randomize = @"";
        _actionType = @"";
        _actionClass = @"";
        _key = @"";
        _esmStr = @"";
        _interval = @0;
    }
    return self;
}


- (void) setScheduleAsNormalWithDate:(NSDate *)date
                        intervalType:(NSString *)intervalType
                                 esm:(NSString *)esm
                               title:(NSString*)title
                                body:(NSString*)body
                          identifier:(NSString*)identifier {
    double intervalValue = 0;
    if ([intervalType isEqualToString:SCHEDULE_INTERVAL_TEST]) {
        intervalValue = 60*3;
//        interval = NSMinuteCalendarUnit;
    } else if ([intervalType isEqualToString:SCHEDULE_INTERVAL_HOUR]) {
        intervalValue = 60*60;//hour
//        interval = NSHourCalendarUnit;
    } else if ([intervalType isEqualToString:SCHEDULE_INTERVAL_DAY]) {
        intervalValue = 60*60*24;//day
//        interval = NSDayCalendarUnit;
    } else if ([intervalType isEqualToString:SCHEDULE_INTERVAL_WEEK]) {
        intervalValue = 60*60*24*7;//week
//        interval = NSWeekCalendarUnit;
    } else if ([intervalType isEqualToString:SCHEDULE_INTERVAL_MONTH]) {
        intervalValue = 60*60*24*31;
//        interval = NSMonthCalendarUnit;
    } else {
        intervalValue = 60*60*24;//day
//        interval = NSDayCalendarUnit;
    }
    
    if (esm != nil) {
        _esmObject = [[MultiESMObject alloc] initWithEsmText:esm];
    }
    
    [self setScheduleAsNormalWithDate:date
                             interval:intervalValue
                                  esm:esm
                                title:title
                                 body:body
                           identifier:identifier];
}

- (void) setScheduleAsNormalWithDate:(NSDate *)date
                            interval:(double) interval
                                 esm:(NSString *)esm
                               title:(NSString*)title
                                body:(NSString*)body
                          identifier:(NSString*)identifier {
    _scheduleType = SCHEDULE_TYPE_NORMAL;
    _schedule = date;
    _esmStr = esm;
    _title = title;
    _body = body;
    _interval = [NSNumber numberWithDouble:interval];
    if (esm != nil) {
        _esmObject = [[MultiESMObject alloc] initWithEsmText:esm];
    }
}


- (void) setScheduleAsRandomWithType:(NSString *)intervalType
                                 esm:(NSString *)esm
                               title:(NSString*)title
                                body:(NSString*)body
                          identifier:(NSString*)identifier {
    _scheduleType = SCHEDULE_TYPE_RANDOM;
    NSDate *date = [NSDate new];
    double now = [date timeIntervalSince1970];
    double gap = 0;
    if ([intervalType isEqualToString:SCHEDULE_INTERVAL_HOUR]) {
        gap = arc4random() % 60*60;//hour
    } else if ([intervalType isEqualToString:SCHEDULE_INTERVAL_DAY]) {
        gap = arc4random() % 60*60*24;//day
    } else if ([intervalType isEqualToString:SCHEDULE_INTERVAL_WEEK]) {
        gap = arc4random() % 60*60*24*7;//week
    } else if ([intervalType isEqualToString:SCHEDULE_INTERVAL_MONTH]) {
        gap = arc4random() % 60*60*24*31;//month
    } else {
        gap = arc4random() % 60*60*24;//day
    }
    _interval = [NSNumber numberWithDouble:gap];
    
//    if ([intervalType isEqualToString:SCHEDULE_INTERVAL_TEST]) {
//        _interval = [NSNumber numberWithInteger:NSMinuteCalendarUnit];
//    } else if ([intervalType isEqualToString:SCHEDULE_INTERVAL_HOUR]) {
//        _interval = [NSNumber numberWithInteger:NSHourCalendarUnit];
//    } else if ([intervalType isEqualToString:SCHEDULE_INTERVAL_DAY]) {
//        _interval = [NSNumber numberWithInteger:NSDayCalendarUnit];
//    } else if ([intervalType isEqualToString:SCHEDULE_INTERVAL_WEEK]) {
//        _interval = [NSNumber numberWithInteger:NSWeekCalendarUnit];
//    } else if ([intervalType isEqualToString:SCHEDULE_INTERVAL_MONTH]) {
//        _interval = [NSNumber numberWithInteger:NSMonthCalendarUnit];
//    } else {
//        _interval = [NSNumber numberWithInteger:NSDayCalendarUnit];
//    }
    
    double nextSchedule = now + gap;
    _schedule = [[NSDate alloc] initWithTimeIntervalSince1970:nextSchedule];
    _esmStr = esm;
    _title = title;
    _body = body;
}


- (void) setScheduleAsContextBaseWithContext:(NSString *)contet
                                         esm:(NSString *)esm
                                       title:(NSString*)title
                                        body:(NSString*)body
                                  identifier:(NSString*)identifier {
    _scheduleType = SCHEDULE_TYPE_CONTEXT;
    _esmStr = esm;
    _title = title;
    _body = body;
}



// Defining the trigger
- (void) addHour: (int) hour {
    _hour = [NSNumber numberWithInt:hour];
}

- (void) addWeekday: (NSString *) weekday {
    _weekday = weekday;
}

- (void) addMonth: (NSString *) month {
    _month = month;
}

- (void) addTimer: (NSDate *) date {
     _schedule = date;
}

- (void) addContext: (NSString *) context {
    _context = context;
}

    
- (void) randomize: (NSString *) randomize {
    _randomize = randomize;
}


// Defining the action
- (void) setActiongType:(NSString *) actionType {
    _actionType = actionType;
}

- (void) setActionClass:(NSString *) actionClass {
    _actionClass = actionClass;
}

- (void) setActionExtra:(NSString *) key value:(NSString*) value {
    _key = key;
    _esmStr = value;
}

@end
