//
//  NTPTime.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

extern NSString * const AWARE_PREFERENCES_STATUS_NTPTIME;

@interface NTPTime : AWARESensor <AWARESensorDelegate>

@property double intervalSec;

@end
