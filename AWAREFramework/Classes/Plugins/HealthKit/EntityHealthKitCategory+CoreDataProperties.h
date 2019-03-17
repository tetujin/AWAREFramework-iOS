//
//  EntityHealthKitCategory+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2019/03/17.
//
//

#import "EntityHealthKitCategory+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityHealthKitCategory (CoreDataProperties)

+ (NSFetchRequest<EntityHealthKitCategory *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSNumber *timestamp;
@property (nullable, nonatomic, copy) NSString *device;
@property (nullable, nonatomic, copy) NSString *type;
@property (nullable, nonatomic, copy) NSNumber *timestamp_end;
@property (nullable, nonatomic, copy) NSNumber *value;
@property (nullable, nonatomic, copy) NSString *label;
@property (nullable, nonatomic, copy) NSString *metadata;
@property (nullable, nonatomic, copy) NSString *source;

@end

NS_ASSUME_NONNULL_END
