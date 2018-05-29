//
//  FitbitDevice.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/01/21.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface FitbitDevice : AWARESensor

typedef void (^FitbitDeviceInfoCallback)( NSString * fitbitId, NSString * fitbitVersion, NSString * fitbitBattery, NSString * fitbitMac, NSString * fitbitLastSync);

- (void) getDeviceInfoWithCallback:(FitbitDeviceInfoCallback)callback;

@end
