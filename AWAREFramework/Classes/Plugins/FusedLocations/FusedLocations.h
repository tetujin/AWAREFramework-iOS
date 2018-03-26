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
#import "AWAREKeys.h"

extern NSString * const AWARE_PREFERENCES_STATUS_GOOGLE_FUSED_LOCATION;
extern NSString * const AWARE_PREFERENCES_ACCURACY_GOOGLE_FUSED_LOCATION;
extern NSString * const AWARE_PREFERENCES_FREQUENCY_GOOGLE_FUSED_LOCATION;

@interface FusedLocations : AWARESensor <AWARESensorDelegate, CLLocationManagerDelegate>

@property int intervalSec;
@property int accuracyMeter;
@property CLLocationAccuracy accuracy;

@end
