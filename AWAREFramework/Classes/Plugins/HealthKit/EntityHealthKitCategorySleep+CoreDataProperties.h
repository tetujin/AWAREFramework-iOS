//
//  EntityHealthKitCategorySleep+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2019/04/05.
//
//

#import "EntityHealthKitCategorySleep+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityHealthKitCategorySleep (CoreDataProperties)

+ (NSFetchRequest<EntityHealthKitCategorySleep *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *device;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *label;
@property (nullable, nonatomic, copy) NSString *metadata;
@property (nullable, nonatomic, copy) NSString *source;
@property (nullable, nonatomic, copy) NSNumber *timestamp;
@property (nullable, nonatomic, copy) NSNumber *timestamp_start;
@property (nullable, nonatomic, copy) NSNumber *timestamp_end;
@property (nullable, nonatomic, copy) NSString *type;
@property (nullable, nonatomic, copy) NSNumber *value;

@end

NS_ASSUME_NONNULL_END
