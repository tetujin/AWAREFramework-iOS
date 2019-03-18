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

extern NSString * const AWARE_PREFERENCES_STATUS_HEALTHKIT;
extern NSString * const AWARE_PREFERENCES_PLUGIN_HEALTHKIT_FREQUENCY;

@interface AWAREHealthKit : AWARESensor <AWARESensorDelegate>

@property int fetchIntervalSecond; // default = 1800 second (= 30 min)

@property (readonly) AWAREHealthKitWorkout  * awareHKWorkout;
@property (readonly) AWAREHealthKitCategory * awareHKCategory;
@property (readonly) AWAREHealthKitQuantity * awareHKQuantity;

- (void) requestAuthorizationToAccessHealthKit;

/**
 * Get the last fetch data using a data type
 */
+ (NSDate * _Nullable) getLastFetchDataWithDataType:(NSString * _Nullable) dataType;

/**
 * Set the latest fetch date with a data type.
 */
+ (void) setLastFetchData:(NSDate * _Nonnull)date withDataType:(NSString * _Nullable)dataType;
@end
