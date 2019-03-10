//
//  AWAREHealthKit.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/1/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

extern NSString * const AWARE_PREFERENCES_STATUS_HEALTHKIT;
extern NSString * const AWARE_PREFERENCES_PLUGIN_HEALTHKIT_FREQUENCY;

@interface AWAREHealthKit : AWARESensor <AWARESensorDelegate>

- (void) requestAuthorizationToAccessHealthKit;

@end
