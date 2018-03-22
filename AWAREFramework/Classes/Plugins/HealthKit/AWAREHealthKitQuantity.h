//
//  AWAREHealthKitQuantity.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2016/12/21.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
// #import <HealthKit/HealthKit.h>

@interface AWAREHealthKitQuantity : AWARESensor


- (void) saveQuantityData:(NSArray *) data;

@end
