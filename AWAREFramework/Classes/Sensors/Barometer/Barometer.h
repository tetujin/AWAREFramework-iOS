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
#import "AWAREMotionSensor.h"

extern NSString* const AWARE_PREFERENCES_STATUS_BAROMETER;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_BAROMETER;

@interface Barometer : AWAREMotionSensor <AWARESensorDelegate>

@end
