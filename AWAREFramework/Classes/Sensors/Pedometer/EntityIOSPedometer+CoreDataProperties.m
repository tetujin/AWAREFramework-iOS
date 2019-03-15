//
//  EntityIOSPedometer+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/03/15.
//
//

#import "EntityIOSPedometer+CoreDataProperties.h"

@implementation EntityIOSPedometer (CoreDataProperties)

+ (NSFetchRequest<EntityIOSPedometer *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntityIOSPedometer"];
}

@dynamic device_id;
@dynamic timestamp;
@dynamic end_timestamp;
@dynamic frequency_second;
@dynamic number_of_steps;
@dynamic distance;
@dynamic current_pace;
@dynamic current_cadence;
@dynamic floors_ascended;
@dynamic floors_descended;

@end
