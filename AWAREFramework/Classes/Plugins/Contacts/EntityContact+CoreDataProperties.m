//
//  EntityContact+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2017/02/04.
//
//

#import "EntityContact+CoreDataProperties.h"

@implementation EntityContact (CoreDataProperties)

+ (NSFetchRequest<EntityContact *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EntityContact"];
}

@dynamic timestamp;
@dynamic device_id;
@dynamic name;
@dynamic phone_numbers;
@dynamic emails;
@dynamic groups;
@dynamic sync_date;

@end
