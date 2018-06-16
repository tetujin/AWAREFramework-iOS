//
//  EntitySensorWifi+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2018/06/15.
//
//

#import "EntitySensorWifi+CoreDataProperties.h"

@implementation EntitySensorWifi (CoreDataProperties)

+ (NSFetchRequest<EntitySensorWifi *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"EntitySensorWifi"];
}

@dynamic bssid;
@dynamic device_id;
@dynamic mac_address;
@dynamic ssid;
@dynamic timestamp;

@end
