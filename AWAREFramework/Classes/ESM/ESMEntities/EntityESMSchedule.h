//
//  EntityESMSchedule.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/19/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EntityESM;

NS_ASSUME_NONNULL_BEGIN

@interface EntityESMSchedule : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

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

NS_ASSUME_NONNULL_END

#import "EntityESMSchedule+CoreDataProperties.h"
