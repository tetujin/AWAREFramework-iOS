//
//  EntityESMAnswerHistory+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2018/04/02.
//
//

#import "EntityESMAnswerHistory+CoreDataProperties.h"

@implementation EntityESMAnswerHistory (CoreDataProperties)

+ (NSFetchRequest<EntityESMAnswerHistory *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntityESMAnswerHistory"];
}

@dynamic fire_hour;
@dynamic schedule_id;
@dynamic timestamp;

@end
