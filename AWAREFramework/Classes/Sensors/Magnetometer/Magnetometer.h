//
//  Magnetometer.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <CoreMotion/CoreMotion.h>
#import "AWAREKeys.h"

extern NSString* const AWARE_PREFERENCES_STATUS_MAGNETOMETER;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_MAGNETOMETER;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_HZ_MAGNETOMETER;

@interface Magnetometer : AWARESensor <AWARESensorDelegate>

- (BOOL) startSensor;
- (BOOL) startSensorWithInterval:(double)interval;
- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer;
- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer fetchLimit:(int)fetchLimit;

@end
