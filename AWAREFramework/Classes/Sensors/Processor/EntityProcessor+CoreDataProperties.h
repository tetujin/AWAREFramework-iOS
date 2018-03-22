//
//  EntityProcessor+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/20/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityProcessor (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *double_idle_load;
@property (nullable, nonatomic, retain) NSNumber *double_last_idle;
@property (nullable, nonatomic, retain) NSNumber *double_last_system;
@property (nullable, nonatomic, retain) NSNumber *double_last_user;
@property (nullable, nonatomic, retain) NSNumber *double_system_load;
@property (nullable, nonatomic, retain) NSNumber *double_user_load;
@property (nullable, nonatomic, retain) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
