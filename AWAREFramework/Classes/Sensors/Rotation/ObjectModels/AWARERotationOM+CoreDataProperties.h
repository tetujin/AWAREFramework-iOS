//
//  AWARERotationOM+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2019/12/10.
//
//

#import "AWARERotationOM+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface AWARERotationOM (CoreDataProperties)

+ (NSFetchRequest<AWARERotationOM *> *)fetchRequest;

@property (nonatomic) int16_t accuracy;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nonatomic) double double_values_0;
@property (nonatomic) double double_values_1;
@property (nonatomic) double double_values_2;
@property (nullable, nonatomic, copy) NSString *label;
@property (nonatomic) int64_t timestamp;
@property (nonatomic) double double_values_3;

@end

NS_ASSUME_NONNULL_END
