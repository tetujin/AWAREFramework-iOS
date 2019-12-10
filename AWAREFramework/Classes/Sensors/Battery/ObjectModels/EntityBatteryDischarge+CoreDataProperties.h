//
//  EntityBatteryDischarge+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityBatteryDischarge.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityBatteryDischarge (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *battery_start;
@property (nullable, nonatomic, retain) NSNumber *battery_end;
@property (nullable, nonatomic, retain) NSNumber *double_end_timestamp;

@end

NS_ASSUME_NONNULL_END
