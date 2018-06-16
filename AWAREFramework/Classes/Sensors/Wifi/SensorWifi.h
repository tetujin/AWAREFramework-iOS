//
//  SensorWifi.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/06/15.
//

#import "AWARESensor.h"

#import <SystemConfiguration/CaptiveNetwork.h>
#import <NetworkExtension/NetworkExtension.h>

@interface SensorWifi : AWARESensor <AWARESensorDelegate>

- (void) saveConnectedWifiInfo;
    
@end
