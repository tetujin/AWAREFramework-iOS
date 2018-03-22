//
//  EntityBluetooth+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityBluetooth.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityBluetooth (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSString *label;
@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSString *bt_address;
@property (nullable, nonatomic, retain) NSString *bt_name;
@property (nullable, nonatomic, retain) NSNumber *bt_rssi;

@end

NS_ASSUME_NONNULL_END
