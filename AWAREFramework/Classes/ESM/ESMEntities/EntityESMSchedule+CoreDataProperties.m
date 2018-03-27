//
//  EntityESMSchedule+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2018/03/27.
//
//

#import "EntityESMSchedule+CoreDataProperties.h"

@implementation EntityESMSchedule (CoreDataProperties)

+ (NSFetchRequest<EntityESMSchedule *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EntityESMSchedule"];
}

@dynamic context;
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
@dynamic esms;

@end
