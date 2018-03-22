//
//  BatteryDischarge.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface BatteryDischarge : AWARESensor <AWARESensorDelegate>

- (void) saveBatteryDischargeEventWithStartTimestamp:(NSNumber *) startTimestamp
                                        endTimestamp:(NSNumber *) endTimestamp
                                   startBatteryLevel:(NSNumber *) startBatteryLevel
                                     endBatteryLevel:(NSNumber *) endBatteryLevel;
@end
