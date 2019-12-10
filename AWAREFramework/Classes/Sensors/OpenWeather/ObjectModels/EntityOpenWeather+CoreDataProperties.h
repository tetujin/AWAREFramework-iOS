//
//  EntityOpenWeather+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/22/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityOpenWeather.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityOpenWeather (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSString *city;
@property (nullable, nonatomic, retain) NSNumber *temperature;
@property (nullable, nonatomic, retain) NSNumber *temperature_max;
@property (nullable, nonatomic, retain) NSNumber *temperature_min;
@property (nullable, nonatomic, retain) NSString *unit;
@property (nullable, nonatomic, retain) NSNumber *humidity;
@property (nullable, nonatomic, retain) NSNumber *pressure;
@property (nullable, nonatomic, retain) NSNumber *wind_speed;
@property (nullable, nonatomic, retain) NSNumber *wind_degrees;
@property (nullable, nonatomic, retain) NSNumber *cloudiness;
@property (nullable, nonatomic, retain) NSNumber *weather_icon_id;
@property (nullable, nonatomic, retain) NSNumber *rain;
@property (nullable, nonatomic, retain) NSNumber *snow;
@property (nullable, nonatomic, retain) NSNumber *sunrise;
@property (nullable, nonatomic, retain) NSNumber *sunset;
@property (nullable, nonatomic, retain) NSString *weather_description;

@end

NS_ASSUME_NONNULL_END
