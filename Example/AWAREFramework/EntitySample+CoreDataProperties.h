//
//  EntitySample+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2018/05/21.
//
//

#import "EntitySample+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntitySample (CoreDataProperties)

+ (NSFetchRequest<EntitySample *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *label;
@property (nonatomic) double timestamp;
@property (nonatomic) int64_t value;

@end

NS_ASSUME_NONNULL_END
