//
//  Rotation.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREMotionSensor.h"
#import "AWAREKeys.h"
#import <CoreMotion/CoreMotion.h>

extern NSString * _Nonnull const AWARE_PREFERENCES_STATUS_ROTATION;
extern NSString * _Nonnull const AWARE_PREFERENCES_FREQUENCY_ROTATION;
extern NSString * _Nonnull const AWARE_PREFERENCES_FREQUENCY_HZ_ROTATION;


@interface Rotation : AWAREMotionSensor <AWARESensorDelegate>

@end

@interface AWARERotationCoreDataHandler : BaseCoreDataHandler
+ (AWARERotationCoreDataHandler * _Nonnull)shared;
@end
