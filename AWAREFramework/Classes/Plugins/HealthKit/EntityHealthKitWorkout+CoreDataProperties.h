//
//  EntityHealthKitWorkout+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2019/09/19.
//
//

#import "EntityHealthKitWorkout+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityHealthKitWorkout (CoreDataProperties)

+ (NSFetchRequest<EntityHealthKitWorkout *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *device_id;
@property (nonatomic) double timestamp;
@property (nonatomic) double timestamp_start;
@property (nonatomic) double timestamp_end;
@property (nonatomic) int64_t activity_type;
@property (nullable, nonatomic, copy) NSString *activity_type_name;
@property (nonatomic) double duration;
@property (nonatomic) double total_distance;
@property (nonatomic) double total_energy_burned;
@property (nullable, nonatomic, copy) NSString *metadata;
@property (nullable, nonatomic, copy) NSString *events;
@property (nullable, nonatomic, copy) NSString *label;
@property (nullable, nonatomic, copy) NSString *device;

@end

NS_ASSUME_NONNULL_END
