//
//  Telephony.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/19/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <CoreTelephony/CoreTelephonyDefines.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTCellularData.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <AddressBookUI/AddressBookUI.h>

extern NSString* const AWARE_PREFERENCES_STATUS_CALLS;

extern NSString* const KEY_CALLS_TIMESTAMP;
extern NSString* const KEY_CALLS_DEVICEID;
extern NSString* const KEY_CALLS_CALL_TYPE;
extern NSString* const KEY_CALLS_CALL_DURATION;
extern NSString* const KEY_CALLS_TRACE;


@interface Calls : AWARESensor <AWARESensorDelegate, ABPeoplePickerNavigationControllerDelegate>

@property (strong, nonatomic) CTCallCenter *callCenter;

-(BOOL)startSensor;

@end
