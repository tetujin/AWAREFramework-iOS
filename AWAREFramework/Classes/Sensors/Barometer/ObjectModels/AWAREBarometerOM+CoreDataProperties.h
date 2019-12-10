//
//  AWAREBarometerOM+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2019/12/10.
//
//

#import "AWAREBarometerOM+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface AWAREBarometerOM (CoreDataProperties)

+ (NSFetchRequest<AWAREBarometerOM *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *device_id;
@property (nonatomic) double double_values_0;
@property (nullable, nonatomic, copy) NSString *label;
@property (nonatomic) int64_t timestamp;
@property (nonatomic) int16_t accuracy;

@end

NS_ASSUME_NONNULL_END
