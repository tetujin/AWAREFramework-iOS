//
//  EntityProximity+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/20/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityProximity.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityProximity (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *double_proximity;
@property (nullable, nonatomic, retain) NSNumber *accuracy;
@property (nullable, nonatomic, retain) NSString *label;

@end

NS_ASSUME_NONNULL_END
