//
//  FitbitData.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/01/21.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface FitbitData : AWARESensor <AWARESensorDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

NS_ASSUME_NONNULL_BEGIN

typedef void (^FitbitCaloriesRequestCallback) (NSData * _Nullable result,  NSString * __nullable nextSyncDate);
typedef void (^FitbitStepsRequestCallback)    (NSData * _Nullable result,  NSString * __nullable nextSyncDate);
typedef void (^FitbitHeartrateRequestCallback)(NSData * _Nullable result,  NSString * __nullable nextSyncDate);
typedef void (^FitbitSleepRequestCallback)    (NSData * _Nullable result,  NSString * __nullable nextSyncDate);


- (void) getCaloriesWithStart:(NSString * _Nonnull)start
                          end:(NSString * _Nonnull)end
                       period:(NSString * _Nullable)period
                  detailLevel:(NSString * _Nonnull)detailLevel
                     callback:(FitbitCaloriesRequestCallback _Nullable) callback;

- (void) getStepsWithStart:(NSString * _Nonnull)start
                       end:(NSString * _Nonnull)end
                    period:(NSString * _Nullable)period
               detailLevel:(NSString * _Nonnull)detailLevel
                  callback:(FitbitStepsRequestCallback _Nullable)callback;

- (void) getHeartrateWithStart:(NSString * _Nonnull)start
                           end:(NSString * _Nonnull)end
                        period:(NSString * _Nullable)period
                   detailLevel:(NSString * _Nonnull)detailLevel
                      callback:(FitbitHeartrateRequestCallback _Nullable)callback;

- (void) getSleepWithStart:(NSString * _Nonnull)start
                       end:(NSString * _Nonnull)end
                    period:(NSString * _Nullable)period
               detailLevel:(NSString * _Nonnull)detailLevel
                  callback:(FitbitSleepRequestCallback _Nullable)callback;

+ (NSString * _Nullable) getLastSyncDateSteps;
+ (NSString * _Nullable) getLastSyncDateCalories;
+ (NSString * _Nullable) getLastSyncDateHeartrate;
+ (NSString * _Nullable) getLastSyncDateSleep;

+ (void) setLastSyncDateSteps:(NSString * _Nonnull)date;
+ (void) setLastSyncDateCalories:(NSString * _Nonnull)date;
+ (void) setLastSyncDateHeartrate:(NSString * _Nonnull)date;
+ (void) setLastSyncDateSleep:(NSString * _Nonnull)date;

+ (void) setLastSyncDate:(NSString * _Nonnull)date withKey:(NSString * _Nonnull)key;

NS_ASSUME_NONNULL_END

@end
