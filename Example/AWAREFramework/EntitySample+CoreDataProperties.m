//
//  EntitySample+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2018/05/21.
//
//

#import "EntitySample+CoreDataProperties.h"

@implementation EntitySample (CoreDataProperties)

+ (NSFetchRequest<EntitySample *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntitySample"];
}

@dynamic device_id;
@dynamic label;
@dynamic timestamp;
@dynamic value;

@end
