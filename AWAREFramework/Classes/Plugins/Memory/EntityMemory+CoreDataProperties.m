//
//  EntityMemory+CoreDataProperties.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/22/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityMemory+CoreDataProperties.h"

@implementation EntityMemory (CoreDataProperties)

@dynamic timestamp;
@dynamic device_id;
@dynamic mem_used;
@dynamic mem_free;
@dynamic mem_total;

@end
