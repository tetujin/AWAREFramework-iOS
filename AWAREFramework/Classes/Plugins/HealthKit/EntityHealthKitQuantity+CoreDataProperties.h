//
//  EntityHealthKitQuantity+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2019/03/17.
//
//

#import "EntityHealthKitQuantity+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityHealthKitQuantity (CoreDataProperties)

+ (NSFetchRequest<EntityHealthKitQuantity *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *device;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *label;
@property (nullable, nonatomic, copy) NSString *metadata;
@property (nullable, nonatomic, copy) NSString *source;
@property (nullable, nonatomic, copy) NSNumber *timestamp;
@property (nullable, nonatomic, copy) NSNumber *timestamp_end;
@property (nullable, nonatomic, copy) NSString *type;
@property (nullable, nonatomic, copy) NSNumber *value;
@property (nullable, nonatomic, copy) NSString *unit;

@end

NS_ASSUME_NONNULL_END
