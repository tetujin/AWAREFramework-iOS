//
//  EntityIOSPedometer+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2019/03/15.
//
//

#import "EntityIOSPedometer+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityIOSPedometer (CoreDataProperties)

+ (NSFetchRequest<EntityIOSPedometer *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSNumber *timestamp;
@property (nullable, nonatomic, copy) NSNumber *end_timestamp;
@property (nullable, nonatomic, copy) NSNumber *frequency_second;
@property (nullable, nonatomic, copy) NSNumber *number_of_steps;
@property (nullable, nonatomic, copy) NSNumber *distance;
@property (nullable, nonatomic, copy) NSNumber *current_pace;
@property (nullable, nonatomic, copy) NSNumber *current_cadence;
@property (nullable, nonatomic, copy) NSNumber *floors_ascended;
@property (nullable, nonatomic, copy) NSNumber *floors_descended;

@end

NS_ASSUME_NONNULL_END
