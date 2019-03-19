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

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                            dbType:(AwareDBType)dbType
                        sensorName:(NSString *)sensorName
                        entityName:(NSString *)entityName;

- (void)saveQuantityData:(NSArray <HKQuantitySample *> * _Nonnull)data;

@end
