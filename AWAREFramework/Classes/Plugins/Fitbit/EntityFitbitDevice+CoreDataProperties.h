//
//  EntityFitbitDevice+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2017/01/15.
//
//

#import "EntityFitbitDevice+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityFitbitDevice (CoreDataProperties)

+ (NSFetchRequest<EntityFitbitDevice *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *timestamp;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *fitbit_id;
@property (nullable, nonatomic, copy) NSString *fitbit_version;
@property (nullable, nonatomic, copy) NSString *fitbit_battery;
@property (nullable, nonatomic, copy) NSString *fitbit_mac;
@property (nullable, nonatomic, copy) NSString *fitbit_last_sync;

@end

NS_ASSUME_NONNULL_END
