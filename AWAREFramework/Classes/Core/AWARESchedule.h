//
//  AWARESchedule.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/17/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MultiESMObject.h"

extern NSString * const SCHEDULE_WEEK_SUNDAY;
extern NSString * const SCHEDULE_WEEK_MONDAY;
extern NSString * const SCHEDULE_WEEK_TUESDAY;
extern NSString * const SCHEDULE_WEEK_WEDNESDAY;
extern NSString * const SCHEDULE_WEEK_THURSDAY;
extern NSString * const SCHEDULE_WEEK_FRIDAY;

extern NSString * const SCHEDULE_MONTH_JAN;
extern NSString * const SCHEDULE_MONTH_FEB;
extern NSString * const SCHEDULE_MONTH_MAR;
extern NSString * const SCHEDULE_MONTH_APR;
extern NSString * const SCHEDULE_MONTH_MAY;
extern NSString * const SCHEDULE_MONTH_JUN;
extern NSString * const SCHEDULE_MONTH_JUL;
extern NSString * const SCHEDULE_MONTH_AUG;
extern NSString * const SCHEDULE_MONTH_SEP;
extern NSString * const SCHEDULE_MONTH_OCT;
extern NSString * const SCHEDULE_MONTH_NOV;
extern NSString * const SCHEDULE_MONTH_DEC;

extern NSString * const SCHEDULE_INTERVAL_HOUR;
extern NSString * const SCHEDULE_INTERVAL_DAY;
extern NSString * const SCHEDULE_INTERVAL_WEEK;
extern NSString * const SCHEDULE_INTERVAL_MONTH;
extern NSString * const SCHEDULE_INTERVAL_TEST;

extern NSString * const SCHEDULE_ACTION_TYPE_BROADCAST;
extern NSString * const SCHEDULE_ACTION_TYPE_ACTIVITY;
extern NSString * const SCHEDULE_ACTION_TYPE_SERVICE;


@interface AWARESchedule : NSObject

- (instancetype) initWithScheduleId:(NSString* ) scheduleId;

// Defining the trigger
- (void) addHour: (int) hour;
- (void) addWeekday: (NSString *) weekday;
- (void) addMonth: (NSString *) month;
- (void) addTimer: (NSDate *) date;
- (void) addContext: (NSString *) context;
- (void) randomize: (NSString *) randomize;

// Defining the action
- (void) setActiongType:(NSString *) actionType;
- (void) setActionClass:(NSString *) actionClass;
- (void) setActionExtra:(NSString *) key value:(NSString*) value;

//- (NSCalendarUnit) getInterval;

//- (NSDictionary *) getScheduleAsDictionary;

// set schedule as x
- (void) setScheduleAsNormalWithDate:(NSDate *)date
                        intervalType:(NSString *)intervalType
                                 esm:(NSString *)esm
                               title:(NSString*)title
                                body:(NSString*)body
                          identifier:(NSString*)identifier;

- (void) setScheduleAsRandomWithType:(NSString *)intervalType
                                 esm:(NSString *)esm
                               title:(NSString*)title
                                body:(NSString*)body
                          identifier:(NSString*)identifier;

- (void) setScheduleAsContextBaseWithContext:(NSString *)contet
                                         esm:(NSString *)esm
                                       title:(NSString*)title
                                        body:(NSString*)body
                                  identifier:(NSString*)identifier;

@property (nonatomic,strong) IBOutlet NSString* scheduleId;

@property (nonatomic,strong) IBOutlet NSNumber* hour;
@property (nonatomic,strong) IBOutlet NSString* month;
@property (nonatomic,strong) IBOutlet NSString* weekday;
@property (nonatomic,strong) IBOutlet NSDate* schedule;
@property (nonatomic,strong) IBOutlet NSString* scheduleType;
@property (nonatomic,strong) IBOutlet NSNumber* interval;

@property (nonatomic,strong) IBOutlet NSString* title;
@property (nonatomic,strong) IBOutlet NSString* body;
//@property (nonatomic,strong) IBOutlet NSString* identifier;

@property (nonatomic,strong) IBOutlet NSString* context;
@property (nonatomic,strong) IBOutlet NSString* randomize;

@property (nonatomic,strong) IBOutlet NSString* actionType;
@property (nonatomic,strong) IBOutlet NSString* actionClass;
@property (nonatomic,strong) IBOutlet NSString* key;
@property (nonatomic,strong) IBOutlet NSString* esmStr;

@property (nonatomic, strong) IBOutlet MultiESMObject* esmObject;

@end
