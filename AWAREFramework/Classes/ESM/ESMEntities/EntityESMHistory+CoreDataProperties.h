//
//  EntityESMHistory+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/19/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityESMHistory.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityESMHistory (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *original_fire_date;
@property (nullable, nonatomic, retain) NSNumber *fire_date;
@property (nullable, nonatomic, retain) NSString *schedule_id;
@property (nullable, nonatomic, retain) NSNumber *randomize;
@property (nullable, nonatomic, retain) NSNumber *expiration_threshold;
@property (nullable, nonatomic, retain) NSString *trigger;

@end

NS_ASSUME_NONNULL_END
