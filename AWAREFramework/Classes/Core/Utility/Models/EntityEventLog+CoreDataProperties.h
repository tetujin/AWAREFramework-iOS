//
//  EntityEventLog+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2019/11/06.
//
//

#import "EntityEventLog+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityEventLog (CoreDataProperties)

+ (NSFetchRequest<EntityEventLog *> *)fetchRequest;

@property (nonatomic) double timestamp;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *log_message;

@end

NS_ASSUME_NONNULL_END
