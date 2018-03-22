//
//  Network.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"

extern NSString * const AWARE_PREFERENCES_STATUS_NETWORK_EVENTS;

@interface Network : AWARESensor <AWARESensorDelegate>

- (BOOL)startSensor;

@end
