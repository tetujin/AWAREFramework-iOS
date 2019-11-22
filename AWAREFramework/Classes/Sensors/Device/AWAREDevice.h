//
//  AWAREDevice.h
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/11/21.
//

#import <Foundation/Foundation.h>
#import "AWARESensor.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWAREDevice : AWARESensor<NSURLSessionDelegate>

@property (readonly) BOOL isOperationLocked;
- (void) lockOperation;
- (void) unlockOperation;

- (BOOL) insertDeviceId:(NSString * _Nonnull)deviceId name:(NSString * _Nonnull)deviceName;

@end

NS_ASSUME_NONNULL_END
