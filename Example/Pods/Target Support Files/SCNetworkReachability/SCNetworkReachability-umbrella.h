#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SCReachabilityFlagsParser.h"
#import "SCReachabilityRefBuilder.h"
#import "SCReachabilityScheduler.h"
#import "SCNetworkReachability.h"
#import "SCNetworkStatus.h"

FOUNDATION_EXPORT double SCNetworkReachabilityVersionNumber;
FOUNDATION_EXPORT const unsigned char SCNetworkReachabilityVersionString[];

