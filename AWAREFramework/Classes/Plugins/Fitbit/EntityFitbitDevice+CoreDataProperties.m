//
//  EntityFitbitDevice+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2017/01/15.
//
//

#import "EntityFitbitDevice+CoreDataProperties.h"

@implementation EntityFitbitDevice (CoreDataProperties)

+ (NSFetchRequest<EntityFitbitDevice *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EntityFitbitDevice"];
}

@dynamic timestamp;
@dynamic device_id;
@dynamic fitbit_id;
@dynamic fitbit_version;
@dynamic fitbit_battery;
@dynamic fitbit_mac;
@dynamic fitbit_last_sync;

@end
