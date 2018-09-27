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

#import "ios-ntp.h"
#import "NetAssociation.h"
#import "NetworkClock.h"
#import "NSDate+NetworkClock.h"
#import "ntp-log.h"

FOUNDATION_EXPORT double ios_ntpVersionNumber;
FOUNDATION_EXPORT const unsigned char ios_ntpVersionString[];

