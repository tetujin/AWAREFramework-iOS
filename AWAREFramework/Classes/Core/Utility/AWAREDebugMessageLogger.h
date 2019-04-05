//
//  AWAREDebugMessageLogger.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/12/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWAREStudy.h"

typedef enum: NSInteger {
    DebugTypeUnknown = 0,
    DebugTypeInfo = 1,
    DebugTypeError = 2,
    DebugTypeWarn = 3,
    DebugTypeCrash = 4
} DebugType;


@interface AWAREDebugMessageLogger : NSObject

NS_ASSUME_NONNULL_BEGIN

@property (strong, nonatomic, readonly) NSString * KEY_DEBUG_TIMESTAMP;
@property (strong, nonatomic, readonly) NSString * KEY_DEBUG_DEVICE_ID;
@property (strong, nonatomic, readonly) NSString * KEY_DEBUG_EVENT;
@property (strong, nonatomic, readonly) NSString * KEY_DEBUG_TYPE;
@property (strong, nonatomic, readonly) NSString * KEY_DEBUG_LABEL;
@property (strong, nonatomic, readonly) NSString * KEY_DEBUG_NETWORK;
@property (strong, nonatomic, readonly) NSString * KEY_DEBUG_DEVICE;
@property (strong, nonatomic, readonly) NSString * KEY_DEBUG_OS;
@property (strong, nonatomic, readonly) NSString * KEY_DEBUG_APP_VERSION;
@property (strong, nonatomic, readonly) NSString * KEY_DEBUG_BATTERY;
@property (strong, nonatomic, readonly) NSString * KEY_DEBUG_BATTERY_STATE;

@property (strong, nonatomic, readonly) NSString * KEY_APP_VERSION;
@property (strong, nonatomic, readonly) NSString * KEY_OS_VERSION;
@property (strong, nonatomic, readonly) NSString * KEY_APP_INSTALL;


- (instancetype) initWithAwareStudy:(AWAREStudy *) study;
- (void) saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *) label;

NS_ASSUME_NONNULL_END

@end
