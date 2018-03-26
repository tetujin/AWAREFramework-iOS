//
//  Memory.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/23/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface Memory : AWARESensor <AWARESensorDelegate>

@property double intervalSec;

- (BOOL) startSensor;
- (BOOL) startSensorWithInterval:(double)interval;

@end
