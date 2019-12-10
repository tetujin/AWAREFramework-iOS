//
//  EntityLocation+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityLocation.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityLocation (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *accuracy;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *double_altitude;
@property (nullable, nonatomic, retain) NSNumber *double_bearing;
@property (nullable, nonatomic, retain) NSNumber *double_latitude;
@property (nullable, nonatomic, retain) NSNumber *double_longitude;
@property (nullable, nonatomic, retain) NSNumber *double_speed;
@property (nullable, nonatomic, retain) NSString *label;
@property (nullable, nonatomic, retain) NSString *provider;
@property (nullable, nonatomic, retain) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
