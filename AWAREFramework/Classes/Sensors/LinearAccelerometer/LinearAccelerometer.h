//
//  linearAccelerometer.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/21/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
#import <CoreMotion/CoreMotion.h>

@interface LinearAccelerometer : AWARESensor <AWARESensorDelegate>

extern NSString* const AWARE_PREFERENCES_STATUS_LINEAR_ACCELEROMETER;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_LINEAR_ACCELEROMETER;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_HZ_LINEAR_ACCELEROMETER;

- (BOOL) startSensor;
- (BOOL) startSensorWithInterval:(double)interval;
- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer;
- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer fetchLimit:(int)fetchLimit;

@end
