//
//  Steps.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/31/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <CoreMotion/CoreMotion.h>

extern NSString * const AWARE_PREFERENCES_STATUS_PEDOMETER;
extern NSString * const AWARE_PREFERENCES_FREQUENCY_PEDOMETER;

@interface Pedometer : AWARESensor <AWARESensorDelegate>

@property (strong, nonatomic) CMPedometer* pedometer;

@end
