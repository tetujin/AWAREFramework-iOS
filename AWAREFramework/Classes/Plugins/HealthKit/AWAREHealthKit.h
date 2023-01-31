//
//  AWAREHealthKit.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/1/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREHealthKitWorkout.h"
#import "AWAREHealthKitCategory.h"
#import "AWAREHealthKitQuantity.h"


extern NSString * _Nonnull const AWARE_PREFERENCES_STATUS_HEALTHKIT;
extern NSString * _Nonnull const AWARE_PREFERENCES_PLUGIN_HEALTHKIT_FREQUENCY;
extern NSString * _Nonnull const AWARE_PREFERENCES_PLUGIN_HEALTHKIT_PREPERIOD_DAYS;

@interface AWAREHealthKit : AWARESensor <AWARESensorDelegate>

NS_ASSUME_NONNULL_BEGIN

@property int fetchIntervalSecond; // default = 1800 second (= 30 min)
@property int preperiodDays;       // default = 0 (= from current time)

@property (readonly) AWAREHealthKitWorkout  * awareHKWorkout;
@property (readonly) AWAREHealthKitCategory * awareHKCategory;
@property (readonly) AWAREHealthKitQuantity * awareHKQuantity;
@property (readonly) AWAREHealthKitQuantity * awareHKHeartRate;
@property (readonly) AWAREHealthKitCategory * awareHKSleep;

- (void) requestAuthorizationToAccessHealthKit;
- (void) requestAuthorizationWithDataTypes:(NSSet *) dataTypes completion:(void (^)(BOOL success, NSError * _Nullable error))completion;
- (void) requestAuthorizationWithAllDataTypes:(void (^)(BOOL success, NSError * _Nullable error))completion;

/**
 * Get the last fetch data using a data type
 */
// - (NSDate * _Nullable) getLastRecordTimeWithHKDataType:(NSString * _Nonnull)type;

/**
 * Set the latest fetch date with a data type.
 */
// - (void) setLastRecordTime:(NSDate * _Nonnull)date withHKDataType:(NSString * _Nonnull)type;

- (void) setLastFetchTimeForAll:(NSDate * _Nullable) date;

NS_ASSUME_NONNULL_END

@end
