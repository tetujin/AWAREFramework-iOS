//
//  AWAREAccelerometerOM+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2019/12/05.
//
//

#import "AWAREAccelerometerOM+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface AWAREAccelerometerOM (CoreDataProperties)

+ (NSFetchRequest<AWAREAccelerometerOM *> *)fetchRequest;

@property (nonatomic) int16_t accuracy;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nonatomic) double double_values_0;
@property (nonatomic) double double_values_1;
@property (nonatomic) double double_values_2;
@property (nullable, nonatomic, copy) NSString *label;
@property (nonatomic) int64_t timestamp;
@property (nullable, nonatomic, retain) AWAREAccelerometerIndexOM *index;

@end

NS_ASSUME_NONNULL_END
