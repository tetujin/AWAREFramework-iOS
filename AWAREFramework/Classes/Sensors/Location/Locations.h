//
//  Locations.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <CoreLocation/CoreLocation.h>
#import "AWAREKeys.h"

extern NSString * _Nonnull const AWARE_PREFERENCES_STATUS_LOCATION_GPS;
extern NSString * _Nonnull const AWARE_PREFERENCES_FREQUENCY_GPS;
extern NSString * _Nonnull const AWARE_PREFERENCES_MIN_GPS_ACCURACY;

@interface Locations : AWARESensor <AWARESensorDelegate, CLLocationManagerDelegate>

@property (nullable) CLLocation * lastLocation;

@property BOOL saveAll;

@property (nullable) CLLocationManager * locationManager;
@property(weak, nonatomic, nullable) id<CLLocationManagerDelegate> locationManagerDelegate;

- (BOOL) startSensor;
- (BOOL) startSensorWithInterval:(double)interval;
- (BOOL) startSensorWithAccuracy:(double)accuracyMeter;
- (BOOL) startSensorWithInterval:(double)interval accuracy:(double)accuracyMeter;

// - (void) saveLocation:(CLLocation *)location;
// - (void) saveAuthorizationStatus:(CLAuthorizationStatus)status;

@end
