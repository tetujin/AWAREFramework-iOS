//
//  ESMManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMManager.h"

@implementation ESMManager{
    NSMutableArray * esmSchedules;
}

- (instancetype)init{
    self = [super init];
    if(self != nil){
        esmSchedules = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addESMSchedules:(ESMSchedule *)schdule{
    [esmSchedules addObject:schdule];
}


- (void)startAllESMSchedules{
    for (ESMSchedule * schedule in esmSchedules) {
        [schedule startScheduledESM];
    }
}

- (void)stopAllESMSchedules{
    for (ESMSchedule * schedule in esmSchedules) {
        [schedule stopScheduledESM];
    }
}


@end
