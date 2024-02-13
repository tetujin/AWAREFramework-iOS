//
//  Wifi.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
// #import <MMLanScan/MMLANScanner.h>

extern NSString* _Nonnull const AWARE_PREFERENCES_STATUS_WIFI;
extern NSString* _Nonnull const AWARE_PREFERENCES_FREQUENCY_WIFI;

//@interface Wifi : AWARESensor <AWARESensorDelegate,MMLANScannerDelegate>
@interface Wifi : AWARESensor <AWARESensorDelegate>

// @property(nonatomic,strong)MMLANScanner *lanScanner;

- (void) setSensingIntervalWithMinute:(double)minute;
- (void) setSensingIntervalWithSecond:(double)second;
    
- (BOOL)startSensor;
- (BOOL)startSensorWithInterval:(double) interval;


- (void) enableAnonymization;
- (void) disableAnonymization;
- (bool) isAnonymizationEnabled;


@end
