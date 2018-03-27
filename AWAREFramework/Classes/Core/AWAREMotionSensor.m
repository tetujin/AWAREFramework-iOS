//
//  AWAREMotionSensor.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/26.
//

#import "AWAREMotionSensor.h"

@implementation AWAREMotionSensor

- (void) setSensingIntervalWithSecond:(double)second{
    _sensingInterval = second;
}

- (void) setSensingIntervalWithHz:(double)hz{
    _sensingInterval = 1.0f/hz;
}

- (void)setSavingIntervalWithMinute:(double)minute{
    _savingInterval = 60.0f * minute;
}

- (void)setSavingIntervalWithSecond:(double)second{
    _savingInterval = second;
}


- (BOOL) startSensor {
    return [self startSensorWithSensingInterval:_sensingInterval];
}

- (BOOL) startSensorWithSensingInterval:(double)interval{
    return [self startSensorWithSensingInterval:interval savingInterval:_savingInterval];
}

- (BOOL) startSensorWithSensingInterval:(double)sensingInterval savingInterval:(double)savingInterval{
    NSLog(@"[%@] Please overwrite -startSensorWithSensingInterval:savingInterval method", [self getSensorName]);
    return YES;
}

@end
