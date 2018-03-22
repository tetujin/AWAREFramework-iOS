//
//  EntityFitbitData+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2017/01/15.
//
//

#import "EntityFitbitData+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityFitbitData (CoreDataProperties)

+ (NSFetchRequest<EntityFitbitData *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *timestamp;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *fitbit_id;
@property (nullable, nonatomic, copy) NSString *fitbit_data_type;
@property (nullable, nonatomic, copy) NSString *fitbit_data;

@end

NS_ASSUME_NONNULL_END
