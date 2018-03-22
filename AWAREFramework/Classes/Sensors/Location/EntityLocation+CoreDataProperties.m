//
//  EntityLocation+CoreDataProperties.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityLocation+CoreDataProperties.h"

@implementation EntityLocation (CoreDataProperties)

@dynamic accuracy;
@dynamic device_id;
@dynamic double_altitude;
@dynamic double_bearing;
@dynamic double_latitude;
@dynamic double_longitude;
@dynamic double_speed;
@dynamic label;
@dynamic provider;
@dynamic timestamp;

@end
