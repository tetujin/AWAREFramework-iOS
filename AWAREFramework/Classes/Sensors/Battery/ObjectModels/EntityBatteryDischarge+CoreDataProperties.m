//
//  EntityBatteryDischarge+CoreDataProperties.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityBatteryDischarge+CoreDataProperties.h"

@implementation EntityBatteryDischarge (CoreDataProperties)

@dynamic timestamp;
@dynamic device_id;
@dynamic battery_start;
@dynamic battery_end;
@dynamic double_end_timestamp;

@end
