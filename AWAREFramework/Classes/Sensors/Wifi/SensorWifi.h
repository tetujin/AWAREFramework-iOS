//
//  SensorWifi.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/06/15.
//

#import "AWARESensor.h"

#import <SystemConfiguration/CaptiveNetwork.h>
#import <NetworkExtension/NetworkExtension.h>

extern NSString* _Nonnull const AWARE_PREFERENCES_WIFI_INFO_ANONYMIZATION;
extern NSString* _Nonnull const AWARE_PREFERENCES_WIFI_INFO_ANONYMIZATION_CONV_TABLE;

@interface SensorWifi : AWARESensor <AWARESensorDelegate>

- (void) saveConnectedWifiInfo;

- (void) setAnonymizationState:(bool)state;
- (bool) getAnonymizationState;


@end
