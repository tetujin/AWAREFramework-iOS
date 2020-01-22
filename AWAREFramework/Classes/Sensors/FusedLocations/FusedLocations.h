//
//  FusedLocations.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/18/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <CoreLocation/CoreLocation.h>
#import "FusedLocations.h"
#import "Locations.h"
#import "AWAREKeys.h"

extern NSString * const AWARE_PREFERENCES_STATUS_GOOGLE_FUSED_LOCATION;
extern NSString * const AWARE_PREFERENCES_ACCURACY_GOOGLE_FUSED_LOCATION;
extern NSString * const AWARE_PREFERENCES_FREQUENCY_GOOGLE_FUSED_LOCATION;

@interface FusedLocations : AWARESensor <AWARESensorDelegate, CLLocationManagerDelegate>

@property Locations * locationSensor;

@property BOOL saveAll;

/// interval (second)
@property int intervalSec;

/// meter
@property int distanceFilter;
@property CLLocationAccuracy accuracy;

- (BOOL) startSensorWithInterval:(double)intervalSecond;
- (BOOL) startSensorWithInterval:(double)intervalSecond accuracy:(CLLocationAccuracy)accuracy;
- (BOOL) startSensorWithInterval:(double)intervalSecond accuracy:(CLLocationAccuracy)accuracy distanceFilter:(int)fiterMeter;

@end
