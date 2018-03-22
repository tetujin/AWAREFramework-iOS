//
//  Orientation.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/22/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

extern NSString * const AWARE_PREFERENCES_STATUS_ORIENTATION;
extern NSString * const AWARE_PREFERENCES_FREQUENCY_ORIENTATION;
extern NSString * const AWARE_PREFERENCES_FREQUENCY_HZ_ORIENTATION;

@interface Orientation : AWARESensor <AWARESensorDelegate>

- (BOOL) startSensor;

@end
