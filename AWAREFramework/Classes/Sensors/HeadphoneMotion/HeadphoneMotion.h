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


@end

@interface AWAREHeadphoneMotionCoreDataHandler : BaseCoreDataHandler
+ (AWAREHeadphoneMotionCoreDataHandler * _Nonnull)shared;
@end

NS_ASSUME_NONNULL_END
