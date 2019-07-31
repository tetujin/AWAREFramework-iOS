//
//  SignificantMotion.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2019/07/31.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "AWARESensor.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString* const ACTION_AWARE_SIGNIFICANT_MOTION_START;
extern NSString* const ACTION_AWARE_SIGNIFICANT_MOTION_END;
extern NSString * _Nonnull const AWARE_PREFERENCES_STATUS_SIGNIFICANT_MOTION;

@interface SignificantMotion : AWARESensor

typedef void (^SignificantMotionStartHandler)(void);
typedef void (^SignificantMotionEndHandler)(void);

@property (readonly) BOOL CURRENT_SIGMOTION_STATE;

- (void) setSignificantMotionStartHandler:(SignificantMotionStartHandler)handler;
- (void) setSignificantMotionEndHandler:(SignificantMotionEndHandler)handler;

@end

NS_ASSUME_NONNULL_END
