//
//  Accelerometer.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "AWAREKeys.h"
#import "AWAREMotionSensor.h"

extern NSString* const AWARE_PREFERENCES_STATUS_ACCELEROMETER;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_ACCELEROMETER;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_HZ_ACCELEROMETER;

@interface Accelerometer : AWAREMotionSensor <AWARESensorDelegate>

@end
