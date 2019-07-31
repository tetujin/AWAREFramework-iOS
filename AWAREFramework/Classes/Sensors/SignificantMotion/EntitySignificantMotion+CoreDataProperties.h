//
//  EntitySignificantMotion+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2019/07/31.
//
//

#import "EntitySignificantMotion+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntitySignificantMotion (CoreDataProperties)

+ (NSFetchRequest<EntitySignificantMotion *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *timestamp;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSNumber *is_moving;

@end

NS_ASSUME_NONNULL_END
