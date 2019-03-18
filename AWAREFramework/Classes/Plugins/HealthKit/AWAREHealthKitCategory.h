//
//  AWAREHealthKitCategory.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2016/12/21.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <HealthKit/HealthKit.h>

@interface AWAREHealthKitCategory : AWARESensor

- (void)saveCategoryData:(NSArray <HKCategorySample *> * _Nonnull)data;

@end
