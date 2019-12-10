//
//  EntityWifi+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/21/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityWifi.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityWifi (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSString *bssid;
@property (nullable, nonatomic, retain) NSString *security;
@property (nullable, nonatomic, retain) NSString *ssid;
@property (nullable, nonatomic, retain) NSNumber *frequency;
@property (nullable, nonatomic, retain) NSNumber *rssi;
@property (nullable, nonatomic, retain) NSString *label;

@end

NS_ASSUME_NONNULL_END
