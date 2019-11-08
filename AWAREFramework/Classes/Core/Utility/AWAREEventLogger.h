//
//  AWARELog.h
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/11/06.
//

#import <Foundation/Foundation.h>
#import "AWARESensor.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWAREEventLogger : AWARESensor

+ (AWAREEventLogger * _Nonnull) shared;

- (BOOL) logEvent:(NSDictionary <NSString *, id> * _Nonnull) event;

@end

NS_ASSUME_NONNULL_END
