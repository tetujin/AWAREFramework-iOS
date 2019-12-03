//
//  bluetooth.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/24/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>

extern NSString* const AWARE_PREFERENCES_STATUS_BLUETOOTH;
extern NSString* const AWARE_PREFERENCES_FREQUENCY_BLUETOOTH;

@interface Bluetooth : AWARESensor <AWARESensorDelegate>

@property (nonatomic) int scanInterval;
@property (nonatomic) int scanDuration;

- (void) remoteAllTargetServiceUUIDs;
- (NSArray <CBUUID *> *) getTargetServiceUUIDs;
- (void) addTargetServiceUUIDs:(NSArray <CBUUID *>*) uuids;
- (void) setTargetServiceUUIDs:(NSArray <CBUUID *>*) uuids;
- (void) addTargetServiceUUID: (CBUUID *)uuid;
- (void) setTargetServiceUUID: (CBUUID *)uuid;
- (void) setWellKnownTargetServiceUUIDs;


@end
