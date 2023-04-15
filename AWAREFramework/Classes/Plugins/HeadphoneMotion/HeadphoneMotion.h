//
//  HeadphoneMotion.h
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2020/10/22.
//

#import <UIKit/UIKit.h>
#import "AWAREMotionSensor.h"

@import CoreMotion;

NS_ASSUME_NONNULL_BEGIN

@interface HeadphoneMotion : AWAREMotionSensor <CMHeadphoneMotionManagerDelegate>

extern NSString * _Nonnull const AWARE_PREFERENCES_STATUS_PLUGIN_HEADPHONE_MOTION;
//extern NSString * _Nonnull const AWARE_PREFERENCES_FREQUENCY_LINEAR_ACCELEROMETER;
//extern NSString * _Nonnull const AWARE_PREFERENCES_FREQUENCY_HZ_LINEAR_ACCELEROMETER;

@end

@interface AWAREHeadphoneMotionCoreDataHandler : BaseCoreDataHandler
+ (AWAREHeadphoneMotionCoreDataHandler * _Nonnull)shared;
@end

NS_ASSUME_NONNULL_END
