//
//  ESMSchedule.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/27.
//

#import "ESMSchedule.h"

@implementation ESMSchedule{
    int esmNumber;
}

/**
 Initialize ESMSchdule instance
 
 @return An initialized object, or nil if an object could not be created for some reason that would not result in an exception.
 */
- (instancetype)init{
    self = [super init];
    if (self != nil) {
        esmNumber = 0;
        _scheduleId = [NSUUID new].UUIDString;
        _expirationThreshold = @0;
        _startDate = [[NSDate alloc] init];
        _endDate   = [[NSDate alloc] initWithTimeIntervalSinceNow:60*60*24*365]; // 1 Year
        _timers   = [[NSArray alloc] init]; // NSDateComponents
        _noitificationBody = @"";
        _notificationTitle = @"";
        _fireHours = [[NSArray alloc] init]; // NSNumber 0-23
        _contexts =  [[NSArray alloc] init]; // NSString
        _weekdays =  [[NSArray alloc] init]; //
        // _months =  [[NSMutableArray alloc] init];
        _interface = @0;
        _randomizeEsm = @0;
        _randomizeSchedule = @0;
        _temporary = @0;
        _repeat = YES;
        _esms = [[NSMutableArray alloc] init];
    }
    return self;
}


/**
 Add a monitoring context for triggering ESM notification.

 @note This function is under developing
 
 @param context A context for triggering ESM notification. The nominated contexts are listed in AWAREKeys.h, also the names of context are "ACTION_AWARE_*".
 */
- (void) addContext:(NSString *)context {
    NSMutableArray * tempContexts = [[NSMutableArray alloc] initWithArray:_contexts];
    [tempContexts addObject:context];
    _contexts = tempContexts;
}


/**
 Add a valid day of the week of an ESM schedule.
 
 @note This function is under developing
 
 @param weekday A valid day of the week of an ESM schedule with an AwareESMWeekday.
 */
-(void)addWeekday:(AwareESMWeekday)weekday {
    NSMutableArray * tempWeekdays = [[NSMutableArray alloc] initWithArray:_weekdays];
    [tempWeekdays addObject:@(weekday)];
    _weekdays = tempWeekdays;
}


/**
 Add valid hours of ESM in a day.
 
 @note The hour should take between 0 and 23.
 
 @param hours A list (NSArray) of valid hours (NSNumber).
 */
- (void) addHours:(NSArray <NSNumber *> *) hours {
    for (NSNumber * hour in hours) {
        [self addHour:hour];
    }
}

/**
 Add valid hour of ESM in a day. The hour should take between 0 and 23.
 
 @param hour A valid hour (NSNumber).
 */
- (void) addHour:(NSNumber *)hour{
    NSMutableArray * tempHours = [[NSMutableArray alloc] initWithArray:_fireHours];
    [tempHours addObject:hour];
    _fireHours = tempHours;
}


/**
 Add an NSDateComponents for making fixed datetime ESMs.
 
 @param timer An NSDateComponents
 */
- (void) addTimer:(NSDateComponents *)timer{
    NSMutableArray * tempTimers = [[NSMutableArray alloc] initWithArray:_timers];
    [tempTimers addObject:timer];
    _timers = tempTimers;
}


/**
 Add an ESMItem

 @param esmItem An EMSItem which has a components of ESM
 */
- (void)addESM:(ESMItem *)esmItem{
    if (esmItem!=nil) {
        NSMutableArray * newESMs = [[NSMutableArray alloc] initWithArray:_esms];
        [esmItem setNumber:esmNumber];
        esmNumber++;
        [newESMs addObject:esmItem];
        _esms = newESMs;
    }
}


/**
 Add ESMItems

 @param esmItems An NSArray list which has ESMItems
 */
- (void)addESMs:(NSArray<ESMItem *> *)esmItems{
    NSMutableArray * newESMs = [[NSMutableArray alloc] initWithArray:_esms];
    if (esmItems !=nil) {
        for (ESMItem * esm in esmItems) {
            [esm setNumber:esmNumber];
            esmNumber++;
            [newESMs addObject:esm];
        }
    }
    _esms = newESMs;
}


/**
 Set an interface type: One-By-One or All-In-One

 @param interfaceType A type of ESM Interface
 */
- (void)setInterfaceType:(AwareESMInterfaceType)interfaceType{
    self.interface = @(interfaceType);
}

@end
