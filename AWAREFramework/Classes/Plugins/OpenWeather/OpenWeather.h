//
//  WeatherData.h
//  VQR
//
//  Created by Yuuki Nishiyama on 2014/12/02.
//  Copyright (c) 2014年 tetujin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "AWARESensor.h"

extern NSString * const AWARE_PREFERENCES_STATUS_OPENWEATHER;
extern NSString * const AWARE_PREFERENCES_OPENWEATHER_FREQUENCY;
extern NSString * const AWARE_PREFERENCES_OPENWEATHER_API_KEY;


@interface OpenWeather : AWARESensor <AWARESensorDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property double frequencyMin;
@property NSString * apiKey;

@end
