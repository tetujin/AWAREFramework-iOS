//
//  EntityESMSchedule+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2018/03/27.
//
//

#import "EntityESMSchedule+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityESMSchedule (CoreDataProperties)

+ (NSFetchRequest<EntityESMSchedule *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *context;
@property (nullable, nonatomic, copy) NSDate *end_date;
@property (nullable, nonatomic, copy) NSNumber *expiration_threshold;
@property (nullable, nonatomic, copy) NSNumber *fire_hour;
@property (nullable, nonatomic, copy) NSNumber *interface;
@property (nullable, nonatomic, copy) NSString *noitification_body;
@property (nullable, nonatomic, copy) NSString *notification_title;
@property (nullable, nonatomic, copy) NSNumber *randomize_esm;
@property (nullable, nonatomic, copy) NSNumber *randomize_schedule;
@property (nullable, nonatomic, copy) NSString *schedule_id;
@property (nullable, nonatomic, copy) NSDate *start_date;
@property (nullable, nonatomic, copy) NSNumber *temporary;
@property (nullable, nonatomic, retain) NSSet<EntityESM *> *esms;

@end

@interface EntityESMSchedule (CoreDataGeneratedAccessors)

- (void)addEsmsObject:(EntityESM *)value;
- (void)removeEsmsObject:(EntityESM *)value;
- (void)addEsms:(NSSet<EntityESM *> *)values;
- (void)removeEsms:(NSSet<EntityESM *> *)values;

@end

NS_ASSUME_NONNULL_END
