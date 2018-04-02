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
        _noitificationBody = @"";
        _notificationTitle = @"";
        _fireHours = @[];
        _context = @[];
        _interface = @0;
        _randomizeEsm = @0;
        _randomizeSchedule = @0;
        _temporary = @0;
        _esms = [[NSMutableArray alloc] init];
    }
    return self;
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
