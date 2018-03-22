//
//  EntityCall+CoreDataProperties.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityCall+CoreDataProperties.h"

@implementation EntityCall (CoreDataProperties)

@dynamic timestamp;
@dynamic device_id;
@dynamic call_type;
@dynamic call_duration;
@dynamic trace;

@end
