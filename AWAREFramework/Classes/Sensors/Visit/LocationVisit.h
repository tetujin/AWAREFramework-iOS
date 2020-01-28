//
//  VisitLocations.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <CoreLocation/CoreLocation.h>

extern NSString * _Nonnull const AWARE_PREFERENCES_STATUS_IOS_LOCATION_VISIT;

@interface LocationVisit : AWARESensor <AWARESensorDelegate, CLLocationManagerDelegate>

@end
