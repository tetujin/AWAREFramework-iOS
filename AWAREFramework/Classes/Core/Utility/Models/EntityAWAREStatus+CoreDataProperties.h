//
//  EntityAWAREStatus+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2019/11/06.
//
//

#import "EntityAWAREStatus+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityAWAREStatus (CoreDataProperties)

+ (NSFetchRequest<EntityAWAREStatus *> *)fetchRequest;

@property (nonatomic) double timestamp;
@property (nullable, nonatomic, copy) NSString *datetime;
@property (nonatomic) int64_t tz;
@property (nullable, nonatomic, copy) NSString *info;
@property (nullable, nonatomic, copy) NSString *device_id;

@end

NS_ASSUME_NONNULL_END
