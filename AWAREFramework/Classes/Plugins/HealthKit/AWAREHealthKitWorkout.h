//
//  AWAREHealthKitWorkout.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2016/12/21.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <HealthKit/HealthKit.h>

@interface AWAREHealthKitWorkout : AWARESensor

NS_ASSUME_NONNULL_BEGIN

- (void) saveWorkoutData:(NSArray <HKWorkout * > * _Nonnull)data;

NS_ASSUME_NONNULL_END

@end
