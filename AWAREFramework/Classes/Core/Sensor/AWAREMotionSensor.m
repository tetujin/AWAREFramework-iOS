//
//  AWAREMotionSensor.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/26.
//

#import "AWAREMotionSensor.h"

@implementation AWAREMotionSensor

- (instancetype)initWithAwareStudy:(AWAREStudy *)study sensorName:(NSString *)name storage:(AWAREStorage *)localStorage{
    self = [super initWithAwareStudy:study sensorName:name storage:localStorage];
    if (self!=nil) {
        [self setSensingIntervalWithSecond:MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND];
        [self setSavingIntervalWithSecond:MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND];
    }
    return self;
}

- (void) setSensingIntervalWithSecond:(double)second{
    _sensingInterval = second;
}

- (void) setSensingIntervalWithHz:(double)hz{
    _sensingInterval = 1.0f/hz;
}

- (void)setSavingIntervalWithMinute:(double)minute{
    _savingInterval = 60.0f * minute;
    if (self.storage != nil) {
        self.storage.saveInterval = _savingInterval;
    }
}

- (void)setSavingIntervalWithSecond:(double)second{
    _savingInterval = second;
    if (self.storage != nil) {
        self.storage.saveInterval = _savingInterval;
    }
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

- (BOOL) isHigherThanThresholdWithTargetValue:(double)value lastValueKey:(NSString *)key{
    
    NSDictionary * lastData = [self getLatestData];
    if (lastData == nil) {
        if (self.isDebug) { NSLog(@"[%@] -isHigherThanThreshold: -getLastest return nil", self.getSensorName ); }
        return NO;
    }

    NSNumber * lastValue = [lastData objectForKey:key];
    if (lastValue == nil) {
        if (self.isDebug) { NSLog(@"[%@] -isHigherThanThreshold: '%@' is wrong key", self.getSensorName, key ); }
        return NO;
    }
    
    double lastVal = lastValue.doubleValue;
    if ( fabs(value - lastVal) > self.threshold ) {
        if (self.isDebug) {NSLog(@"[%@] get a higher value than the threshold [ %f > %f ]", self.getSensorName, fabs(value - lastVal), self.threshold); }
        return YES;
    }
    
    return NO;
}

@end
