//
//  EntityHealthKitCategory+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/03/17.
//
//

#import "EntityHealthKitCategory+CoreDataProperties.h"

@implementation EntityHealthKitCategory (CoreDataProperties)

+ (NSFetchRequest<EntityHealthKitCategory *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntityHealthKitCategory"];
}

@dynamic device_id;
@dynamic timestamp;
@dynamic device;
@dynamic type;
@dynamic timestamp_end;
@dynamic value;
@dynamic label;
@dynamic metadata;
@dynamic source;

@end
