//
//  Gravity.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/21/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
#import "AWAREMotionSensor.h"
#import <CoreMotion/CoreMotion.h>

extern NSString* const AWARE_PREFERENCES_STATUS_GRAVITY;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_GRAVITY;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_HZ_GRAVITY;

@interface Gravity : AWAREMotionSensor <AWARESensorDelegate>

@end
