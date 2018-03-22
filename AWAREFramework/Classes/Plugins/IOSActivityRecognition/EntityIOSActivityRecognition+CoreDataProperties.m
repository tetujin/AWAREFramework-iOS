//
//  EntityIOSActivityRecognition+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 9/19/16.
//
//

#import "EntityIOSActivityRecognition+CoreDataProperties.h"

@implementation EntityIOSActivityRecognition (CoreDataProperties)

+ (NSFetchRequest<EntityIOSActivityRecognition *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EntityIOSActivityRecognition"];
}

@dynamic activities;
@dynamic automotive;
@dynamic confidence;
@dynamic cycling;
@dynamic device_id;
@dynamic label;
@dynamic running;
@dynamic stationary;
@dynamic timestamp;
@dynamic unknown;
@dynamic walking;

@end
