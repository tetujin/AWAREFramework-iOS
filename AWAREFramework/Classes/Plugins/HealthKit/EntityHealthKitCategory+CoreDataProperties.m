//
//  EntityHealthKitCategory+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/04/05.
//
//

#import "EntityHealthKitCategory+CoreDataProperties.h"

@implementation EntityHealthKitCategory (CoreDataProperties)

+ (NSFetchRequest<EntityHealthKitCategory *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntityHealthKitCategory"];
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
@dynamic value;

@end
