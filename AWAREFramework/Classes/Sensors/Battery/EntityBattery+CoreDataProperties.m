//
//  EntityBattery+CoreDataProperties.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityBattery+CoreDataProperties.h"

@implementation EntityBattery (CoreDataProperties)

@dynamic battery_status;
@dynamic battery_level;
@dynamic timestamp;
@dynamic device_id;
@dynamic battery_scale;
@dynamic battery_voltage;
@dynamic battery_temperature;
@dynamic battery_adaptor;
@dynamic battery_health;
@dynamic battery_technology;

@end
