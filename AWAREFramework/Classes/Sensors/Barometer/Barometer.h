//
//  Barometer.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
#import <CoreMotion/CoreMotion.h>

extern NSString* const AWARE_PREFERENCES_STATUS_BAROMETER;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_BAROMETER;

@interface Barometer : AWARESensor <AWARESensorDelegate>

- (BOOL) startSensor;
- (BOOL) startSensorWithInterval:(double)interval;
- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer;
- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer fetchLimit:(int)fetchLimit;

- (BOOL) setInterval:(double)interval;
- (double) getInterval;

@end
