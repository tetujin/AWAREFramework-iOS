//
//  EntityOpenWeather+CoreDataProperties.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/22/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityOpenWeather+CoreDataProperties.h"

@implementation EntityOpenWeather (CoreDataProperties)

@dynamic timestamp;
@dynamic device_id;
@dynamic city;
@dynamic temperature;
@dynamic temperature_max;
@dynamic temperature_min;
@dynamic unit;
@dynamic humidity;
@dynamic pressure;
@dynamic wind_speed;
@dynamic wind_degrees;
@dynamic cloudiness;
@dynamic weather_icon_id;
@dynamic rain;
@dynamic snow;
@dynamic sunrise;
@dynamic sunset;
@dynamic weather_description;

@end
