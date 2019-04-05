//
//  EntityHealthKitQuantity+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/04/05.
//
//

#import "EntityHealthKitQuantity+CoreDataProperties.h"

@implementation EntityHealthKitQuantity (CoreDataProperties)

+ (NSFetchRequest<EntityHealthKitQuantity *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntityHealthKitQuantity"];
}

@dynamic device;
@dynamic device_id;
@dynamic label;
@dynamic metadata;
@dynamic source;
@dynamic timestamp;
@dynamic timestamp_end;
@dynamic type;
@dynamic unit;
@dynamic value;

@end
