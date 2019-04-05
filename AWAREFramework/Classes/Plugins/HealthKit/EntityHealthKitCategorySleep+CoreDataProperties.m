//
//  EntityHealthKitCategorySleep+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/04/05.
//
//

#import "EntityHealthKitCategorySleep+CoreDataProperties.h"

@implementation EntityHealthKitCategorySleep (CoreDataProperties)

+ (NSFetchRequest<EntityHealthKitCategorySleep *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntityHealthKitCategorySleep"];
}

@dynamic device;
@dynamic device_id;
@dynamic label;
@dynamic metadata;
@dynamic source;
@dynamic timestamp;
@dynamic timestamp_end;
@dynamic type;
@dynamic value;

@end
