//
//  EntityAmbientNoise+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2018/03/12.
//
//

#import "EntityAmbientNoise+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityAmbientNoise (CoreDataProperties)

+ (NSFetchRequest<EntityAmbientNoise *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSNumber *double_decibels;
@property (nullable, nonatomic, copy) NSNumber *double_frequency;
@property (nullable, nonatomic, copy) NSNumber *double_rms;
@property (nullable, nonatomic, copy) NSNumber *double_silent_threshold;
@property (nullable, nonatomic, copy) NSNumber *is_silent;
@property (nullable, nonatomic, copy) NSString *raw;
@property (nullable, nonatomic, copy) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
