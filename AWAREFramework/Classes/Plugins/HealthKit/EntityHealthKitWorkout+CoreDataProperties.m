//
//  EntityHealthKitWorkout+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/09/19.
//
//

#import "EntityHealthKitWorkout+CoreDataProperties.h"

@implementation EntityHealthKitWorkout (CoreDataProperties)

+ (NSFetchRequest<EntityHealthKitWorkout *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntityHealthKitWorkout"];
}

@dynamic device_id;
@dynamic timestamp;
@dynamic timestamp_end;
@dynamic activity_type;
@dynamic activity_type_name;
@dynamic duration;
@dynamic total_distance;
@dynamic total_energy_burned;
@dynamic metadata;
@dynamic events;
@dynamic label;
@dynamic device;

@end
