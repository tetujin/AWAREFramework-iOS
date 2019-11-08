//
//  EntityEventLog+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/11/06.
//
//

#import "EntityEventLog+CoreDataProperties.h"

@implementation EntityEventLog (CoreDataProperties)

+ (NSFetchRequest<EntityEventLog *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntityEventLog"];
}

@dynamic timestamp;
@dynamic device_id;
@dynamic log_message;

@end
