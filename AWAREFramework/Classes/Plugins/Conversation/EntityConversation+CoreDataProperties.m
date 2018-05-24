//
//  EntityConversation+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2018/05/24.
//
//

#import "EntityConversation+CoreDataProperties.h"

@implementation EntityConversation (CoreDataProperties)

+ (NSFetchRequest<EntityConversation *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntityConversation"];
}

@dynamic timestamp;
@dynamic device_id;
@dynamic datatype;
@dynamic double_energy;
@dynamic inference;
@dynamic blob_feature;
@dynamic double_convo_start;
@dynamic double_convo_end;

@end
