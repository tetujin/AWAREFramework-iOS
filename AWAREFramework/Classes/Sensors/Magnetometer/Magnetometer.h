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
#import "AWAREMotionSensor.h"

extern NSString * _Nonnull const AWARE_PREFERENCES_STATUS_MAGNETOMETER;
extern NSString * _Nonnull const AWARE_PREFERENCES_FREQUENCY_MAGNETOMETER;
extern NSString * _Nonnull const AWARE_PREFERENCES_FREQUENCY_HZ_MAGNETOMETER;

@interface Magnetometer : AWAREMotionSensor <AWARESensorDelegate>

@end

@interface AWAREMagnetometerCoreDataHandler : BaseCoreDataHandler
+ (AWAREMagnetometerCoreDataHandler * _Nonnull)shared;
@end
