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

- (void) addContext:(NSString *)context {
    NSMutableArray * tempContexts = [[NSMutableArray alloc] initWithArray:_contexts];
    [tempContexts addObject:context];
    _contexts = tempContexts;
}

-(void)addWeekday:(AwareESMWeekday)weekday {
    NSMutableArray * tempWeekdays = [[NSMutableArray alloc] initWithArray:_weekdays];
    [tempWeekdays addObject:@(weekday)];
    _weekdays = tempWeekdays;
}

- (void) addHours:(NSArray <NSNumber *> *) hours {
    for (NSNumber * hour in hours) {
        [self addHour:hour];
    }
}

- (void) addHour:(NSNumber *)hour{
    NSMutableArray * tempHours = [[NSMutableArray alloc] initWithArray:_fireHours];
    [tempHours addObject:hour];
    _fireHours = tempHours;
}


- (void) addTimer:(NSDateComponents *)timer{
    NSMutableArray * tempTimers = [[NSMutableArray alloc] initWithArray:_timers];
    [tempTimers addObject:timer];
    _timers = tempTimers;
}

- (void)addESM:(ESMItem *)esmItem{
    if (esmItem!=nil) {
        NSMutableArray * newESMs = [[NSMutableArray alloc] initWithArray:_esms];
        esmItem.esm_number = @(esmNumber);
        esmNumber++;
        [newESMs addObject:esmItem];
        _esms = newESMs;
    }
}

- (void)addESMs:(NSArray<ESMItem *> *)esmItems{
    NSMutableArray * newESMs = [[NSMutableArray alloc] initWithArray:_esms];
    if (esmItems !=nil) {
        for (ESMItem * esm in esmItems) {
            esm.esm_number = @(esmNumber);
            esmNumber++;
            [newESMs addObject:esm];
        }
    }
    _esms = newESMs;
}

@end
