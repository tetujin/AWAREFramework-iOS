//
//  BatteryCharge.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface BatteryCharge : AWARESensor <AWARESensorDelegate>

- (void) saveBatteryChargeEventWithStartTimestamp:(NSNumber *) startTimestamp
                                     endTimestamp:(NSNumber *) endTimestamp
                                startBatteryLevel:(NSNumber *) startBatteryLevel
                                  endBatteryLevel:(NSNumber *) endBatteryLevel;

@end
