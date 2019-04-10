//
//  AWAREMotionSensor.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/26.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AWARESensor.h"

@interface AWAREMotionSensor : AWARESensor

@property (readonly) double savingInterval;
@property (readonly) double sensingInterval;
@property double threshold;

- (void) setSensingIntervalWithSecond:(double)second;
- (void) setSensingIntervalWithHz:(double)hz;

- (void) setSavingIntervalWithSecond:(double)second;
- (void) setSavingIntervalWithMinute:(double)minute;

- (BOOL) startSensor;
- (BOOL) startSensorWithSensingInterval:(double)interval;
- (BOOL) startSensorWithSensingInterval:(double)sensingInterval savingInterval:(double)savingInterval;

- (BOOL) isHigherThanThresholdWithTargetValue:(double)value lastValueKey:(NSString * _Nonnull)key;

@end
