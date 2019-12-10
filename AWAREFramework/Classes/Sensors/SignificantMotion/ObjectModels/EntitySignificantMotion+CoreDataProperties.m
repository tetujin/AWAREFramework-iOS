//
//  EntitySignificantMotion+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/07/31.
//
//

#import "EntitySignificantMotion+CoreDataProperties.h"

@implementation EntitySignificantMotion (CoreDataProperties)

+ (NSFetchRequest<EntitySignificantMotion *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntitySignificantMotion"];
}

@dynamic timestamp;
@dynamic device_id;
@dynamic is_moving;

@end
