//
//  EntityContact+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2017/02/04.
//
//

#import "EntityContact+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityContact (CoreDataProperties)

+ (NSFetchRequest<EntityContact *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *timestamp;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *phone_numbers;
@property (nullable, nonatomic, copy) NSString *emails;
@property (nullable, nonatomic, copy) NSString *groups;
@property (nullable, nonatomic, copy) NSNumber *sync_date;

@end

NS_ASSUME_NONNULL_END
