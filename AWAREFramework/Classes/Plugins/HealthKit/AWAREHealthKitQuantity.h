//
//  AWAREHealthKitQuantity.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2016/12/21.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <HealthKit/HealthKit.h>

@interface AWAREHealthKitQuantity : AWARESensor

NS_ASSUME_NONNULL_BEGIN

- (instancetype)initWithAwareStudy:(AWAREStudy * _Nullable)study
                            dbType:(AwareDBType)dbType
                        sensorName:(NSString * _Nullable)sensorName
                        entityName:(NSString * _Nullable)entityName;

- (void)saveQuantityData:(NSArray <HKQuantitySample *> * _Nonnull)data;

NS_ASSUME_NONNULL_END

@end
