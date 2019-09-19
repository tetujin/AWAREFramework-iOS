//
//  EntityHealthKitQuantityHR+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/04/05.
//
//

#import "EntityHealthKitQuantityHR+CoreDataProperties.h"

@implementation EntityHealthKitQuantityHR (CoreDataProperties)

+ (NSFetchRequest<EntityHealthKitQuantityHR *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntityHealthKitQuantityHR"];
}

@dynamic device;
@dynamic device_id;
@dynamic label;
@dynamic metadata;
@dynamic source;
@dynamic timestamp;
@dynamic timestamp_start;
@dynamic timestamp_end;
@dynamic type;
@dynamic unit;
@dynamic value;

@end
