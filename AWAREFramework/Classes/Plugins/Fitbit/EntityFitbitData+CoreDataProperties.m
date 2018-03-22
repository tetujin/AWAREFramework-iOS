//
//  EntityFitbitData+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2017/01/15.
//
//

#import "EntityFitbitData+CoreDataProperties.h"

@implementation EntityFitbitData (CoreDataProperties)

+ (NSFetchRequest<EntityFitbitData *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EntityFitbitData"];
}

@dynamic timestamp;
@dynamic device_id;
@dynamic fitbit_id;
@dynamic fitbit_data_type;
@dynamic fitbit_data;

@end
