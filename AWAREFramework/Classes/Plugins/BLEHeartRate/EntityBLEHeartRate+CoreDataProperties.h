//
//  EntityBLEHeartRate+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/22/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityBLEHeartRate.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityBLEHeartRate (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSString *label;
@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSNumber *heartrate;
@property (nullable, nonatomic, retain) NSNumber *rr;
@property (nullable, nonatomic, retain) NSNumber *location;
@property (nullable, nonatomic, retain) NSString *manufacturer;
@property (nullable, nonatomic, retain) NSNumber *rssi;

@end

NS_ASSUME_NONNULL_END
