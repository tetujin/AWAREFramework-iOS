//
//  EntityBattery+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityBattery.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityBattery (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *battery_status;
@property (nullable, nonatomic, retain) NSNumber *battery_level;
@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *battery_scale;
@property (nullable, nonatomic, retain) NSNumber *battery_voltage;
@property (nullable, nonatomic, retain) NSNumber *battery_temperature;
@property (nullable, nonatomic, retain) NSNumber *battery_adaptor;
@property (nullable, nonatomic, retain) NSNumber *battery_health;
@property (nullable, nonatomic, retain) NSString *battery_technology;

@end

NS_ASSUME_NONNULL_END
