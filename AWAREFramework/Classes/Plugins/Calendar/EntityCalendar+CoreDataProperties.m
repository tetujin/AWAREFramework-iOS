//
//  EntityCalendar+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2017/12/28.
//
//

#import "EntityCalendar+CoreDataProperties.h"

@implementation EntityCalendar (CoreDataProperties)

+ (NSFetchRequest<EntityCalendar *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EntityCalendar"];
}

@dynamic account_name;
@dynamic begin;
@dynamic calendar_description;
@dynamic calendar_id;
@dynamic calendar_name;
@dynamic device_id;
@dynamic end;
@dynamic event_id;
@dynamic location;
@dynamic owner_account;
@dynamic status;
@dynamic timestamp;
@dynamic title;
@dynamic all_day;
@dynamic note;

@end
