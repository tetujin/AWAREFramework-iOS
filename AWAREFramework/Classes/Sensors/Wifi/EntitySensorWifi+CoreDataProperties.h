//
//  EntitySensorWifi+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2018/06/15.
//
//

#import "EntitySensorWifi+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntitySensorWifi (CoreDataProperties)

+ (NSFetchRequest<EntitySensorWifi *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *bssid;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *mac_address;
@property (nullable, nonatomic, copy) NSString *ssid;
@property (nullable, nonatomic, copy) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
