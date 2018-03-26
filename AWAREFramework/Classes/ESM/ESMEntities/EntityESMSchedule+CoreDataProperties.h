//
//  EntityESMSchedule+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/19/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityESMSchedule.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityESMSchedule (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *end_date;
@property (nullable, nonatomic, retain) NSNumber *expiration_threshold;
@property (nullable, nonatomic, retain) NSNumber *fire_hour;
@property (nullable, nonatomic, retain) NSNumber *interface;
@property (nullable, nonatomic, retain) NSString *noitification_body;
@property (nullable, nonatomic, retain) NSString *notification_title;
@property (nullable, nonatomic, retain) NSNumber *randomize_schedule;
@property (nullable, nonatomic, retain) NSNumber *randomize_esm;
@property (nullable, nonatomic, retain) NSString *schedule_id;
@property (nullable, nonatomic, retain) NSDate *start_date;
@property (nullable, nonatomic, retain) NSString *context;
@property (nullable, nonatomic, retain) NSNumber *temporary;
@property (nullable, nonatomic, retain) NSSet<EntityESM *> *esms;

@end

@interface EntityESMSchedule (CoreDataGeneratedAccessors)

- (void)addEsmsObject:(EntityESM *)value;
- (void)removeEsmsObject:(EntityESM *)value;
- (void)addEsms:(NSSet<EntityESM *> *)values;
- (void)removeEsms:(NSSet<EntityESM *> *)values;

@end

NS_ASSUME_NONNULL_END
