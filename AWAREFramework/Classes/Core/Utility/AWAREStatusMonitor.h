//
//  AWAREStatusMonitor.h
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/10/31.
//

#import <Foundation/Foundation.h>
#import "AWARESensor.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWAREStatusMonitor : AWARESensor

+ (AWAREStatusMonitor * _Nonnull) shared;

- (void) activateWithCheckInterval:(double)intervalSec;
- (void) deactivate;

- (void) checkStatusWithType:(int)trigger;

@end

NS_ASSUME_NONNULL_END
