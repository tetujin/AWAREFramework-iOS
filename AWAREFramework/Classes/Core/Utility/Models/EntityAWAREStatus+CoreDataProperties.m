//
//  EntityAWAREStatus+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/11/06.
//
//

#import "EntityAWAREStatus+CoreDataProperties.h"

@implementation EntityAWAREStatus (CoreDataProperties)

+ (NSFetchRequest<EntityAWAREStatus *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntityAWAREStatus"];
}

@dynamic timestamp;
@dynamic datetime;
@dynamic tz;
@dynamic info;
@dynamic device_id;

@end
