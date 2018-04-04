//
//  EntityESMSchedule+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2018/04/04.
//
//

#import "EntityESMSchedule+CoreDataProperties.h"

@implementation EntityESMSchedule (CoreDataProperties)

+ (NSFetchRequest<EntityESMSchedule *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntityESMSchedule"];
}

@dynamic contexts;
@dynamic end_date;
@dynamic expiration_threshold;
@dynamic fire_hour;
@dynamic interface;
@dynamic noitification_body;
@dynamic notification_title;
@dynamic randomize_esm;
@dynamic randomize_schedule;
@dynamic schedule_id;
@dynamic start_date;
@dynamic temporary;
@dynamic timer;
@dynamic repeat;
@dynamic esms;
@dynamic months;
@dynamic weekdays;

@end
