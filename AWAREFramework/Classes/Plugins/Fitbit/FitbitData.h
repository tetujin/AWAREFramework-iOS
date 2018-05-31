//
//  FitbitData.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/01/21.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface FitbitData : AWARESensor <AWARESensorDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>


typedef void (^FitbitCaloriesRequestCallback) (NSData * result,  NSString * __nullable nextSyncDate);
typedef void (^FitbitStepsRequestCallback)    (NSData * result,  NSString * __nullable nextSyncDate);
typedef void (^FitbitHeartrateRequestCallback)(NSData * result,  NSString * __nullable nextSyncDate);
typedef void (^FitbitSleepRequestCallback)    (NSData * result,  NSString * __nullable nextSyncDate);


- (void) getCaloriesWithStart:(NSString *)start
                          end:(NSString *)end
                       period:(NSString *)period
                  detailLevel:(NSString *)detailLevel
                     callback:(FitbitCaloriesRequestCallback) callback;

- (void) getStepsWithStart:(NSString *)start
                       end:(NSString *)end
                    period:(NSString *)period
               detailLevel:(NSString *)detailLevel
                  callback:(FitbitStepsRequestCallback)callback;

- (void) getHeartrateWithStart:(NSString *)start
                           end:(NSString *)end
                        period:(NSString *)period
                   detailLevel:(NSString *)detailLevel
                      callback:(FitbitHeartrateRequestCallback)callback;

- (void) getSleepWithStart:(NSString *)start
                       end:(NSString *)end
                    period:(NSString *)period
               detailLevel:(NSString *)detailLevel
                  callback:(FitbitSleepRequestCallback)callback;

+ (NSString *) getLastSyncDateSteps;
+ (NSString *) getLastSyncDateCalories;
+ (NSString *) getLastSyncDateHeartrate;
+ (NSString *) getLastSyncDateSleep;

+ (void) setLastSyncDateSteps:(NSString *)date;
+ (void) setLastSyncDateCalories:(NSString *)date;
+ (void) setLastSyncDateHeartrate:(NSString *)date;
+ (void) setLastSyncDateSleep:(NSString *)date;

+ (void) setLastSyncDate:(NSString *)date withKey:(NSString *)key;

@end
