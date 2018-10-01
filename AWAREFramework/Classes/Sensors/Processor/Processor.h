//
//  Processor.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREMotionSensor.h"
#import "AWAREKeys.h"
#import <mach/mach.h>

extern NSString* const AWARE_PREFERENCES_STATUS_PROCESSOR;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_PROCESSOR;

@interface Processor : AWAREMotionSensor <AWARESensorDelegate>

+ (float) getDeviceCpuUsage;
+ (float) getCpuUsage;
+ (long) getMemory;

@end
