//
//  AWAREDebugMessageLogger.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/12/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREDebugMessageLogger.h"
#import "AWAREStudy.h"
#import "AWAREUtils.h"
#import "EntityDebug.h"
#import "JSONStorage.h"

@implementation AWAREDebugMessageLogger{
    JSONStorage * storage;
    AWAREStudy * awareStudy;
}

- (instancetype)init {
    NSLog(@"Please use -initWithAwareStudy for the initialization");
    // [[NSException exceptionWithName:@"" reason:@"" userInfo:nil] raise];
    return [self initWithAwareStudy:[[AWAREStudy alloc] initWithReachability:YES]];
}

- (instancetype) initWithAwareStudy:(AWAREStudy *) study {
    self = [super init];
    if(self != nil){
        // localStorage = [[LocalFileStorageHelper alloc] initWithStorageName:@"aware_debug"];
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"aware_debug"];
        awareStudy = study;
        _KEY_DEBUG_TIMESTAMP = @"timestamp";
        _KEY_DEBUG_DEVICE_ID = @"device_id";
        _KEY_DEBUG_EVENT = @"event";
        _KEY_DEBUG_TYPE = @"type";
        _KEY_DEBUG_LABEL= @"label";
        _KEY_DEBUG_NETWORK = @"network";
        _KEY_DEBUG_DEVICE = @"device";
        _KEY_DEBUG_OS = @"os";
        _KEY_DEBUG_APP_VERSION = @"app_version";
        _KEY_DEBUG_BATTERY = @"battery";
        _KEY_DEBUG_BATTERY_STATE = @"battery_state";
        
        _KEY_APP_VERSION = @"key_application_history_app_version";
        _KEY_OS_VERSION = @"key_application_history_os_version";
        _KEY_APP_INSTALL = @"key_application_history_app_install";
    }
    return self;
}

- (void) saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *) label {
    if (eventText == nil) eventText = @"";
    if (label == nil){
        eventText = @"";
        label = @"";
    }
    NSString * osVersion = [[UIDevice currentDevice] systemVersion];
    NSString * deviceName = [AWAREUtils deviceName];
    NSString * appVersion = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    if(build != nil){
        appVersion = [appVersion stringByAppendingFormat:@"(%@)", build];
    }
    NSNumber * battery = [NSNumber numberWithInt:[[UIDevice currentDevice] batteryLevel] * 100];
    NSNumber * batterySate = [NSNumber numberWithInteger:[UIDevice currentDevice].batteryState];
    NSString * deviceId = [awareStudy getDeviceId];
    if (deviceId == nil || [deviceId isEqualToString:@""]) {
        deviceId = [AWAREUtils getSystemUUID];
    }
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:_KEY_DEBUG_DEVICE_ID];
    [dict setObject:deviceId forKey:_KEY_DEBUG_DEVICE_ID];
    [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:_KEY_DEBUG_TIMESTAMP];
    [dict setObject:eventText forKey:_KEY_DEBUG_EVENT];
    [dict setObject:[NSNumber numberWithInteger:type] forKey:_KEY_DEBUG_TYPE];
    [dict setObject:label forKey:_KEY_DEBUG_LABEL];
    NSString * network = [awareStudy getNetworkReachabilityAsText];
    if(network != nil){
        [dict setObject:network forKey:_KEY_DEBUG_NETWORK];
    }else{
        [dict setObject:@"unknown" forKey:_KEY_DEBUG_NETWORK];
    }
    [dict setObject:appVersion forKey:_KEY_DEBUG_APP_VERSION];
    [dict setObject:deviceName forKey:_KEY_DEBUG_DEVICE];
    [dict setObject:osVersion forKey:_KEY_DEBUG_OS];
    [dict setObject:battery forKey:_KEY_DEBUG_BATTERY];
    [dict setObject:batterySate forKey:_KEY_DEBUG_BATTERY_STATE];
    
    // [localStorage saveData:dict];
    [storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
}


@end
