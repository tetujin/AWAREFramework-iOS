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

@import CallKit;

extern NSString* _Nonnull const AWARE_PREFERENCES_STATUS_CALLS;

extern NSString* _Nonnull const KEY_CALLS_TIMESTAMP;
extern NSString* _Nonnull const KEY_CALLS_DEVICEID;
extern NSString* _Nonnull const KEY_CALLS_CALL_TYPE;
extern NSString* _Nonnull const KEY_CALLS_CALL_DURATION;
extern NSString* _Nonnull const KEY_CALLS_TRACE;

@interface Calls : AWARESensor <AWARESensorDelegate, ABPeoplePickerNavigationControllerDelegate, CXCallObserverDelegate>

@property (strong, nonatomic, nullable) CXCallObserver *callObserver;

-(BOOL)startSensor;

@end
