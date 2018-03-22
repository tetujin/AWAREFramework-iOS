//
//  Timezone.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

extern NSString* const AWARE_PREFERENCES_STATUS_TIMEZONE;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_TIMEZONE;

@interface Timezone : AWARESensor <AWARESensorDelegate>

- (BOOL) startSensor;
- (BOOL) startSensorWithInterval:(double)interval;

@end
