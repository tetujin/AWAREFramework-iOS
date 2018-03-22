//
//  Rotation.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
#import <CoreMotion/CoreMotion.h>

extern NSString* const AWARE_PREFERENCES_STATUS_ROTATION;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_ROTATION;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_HZ_ROTATION;


@interface Rotation : AWARESensor <AWARESensorDelegate>

- (BOOL) startSensor;
- (BOOL) startSensorWithInterval:(double)interval;
- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer;
- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer fetchLimit:(int)fetchLimit;

@end
