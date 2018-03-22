//
//  FitbitData.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/01/21.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface FitbitData : AWARESensor <AWARESensorDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>


// - (void) getSensorDataWithSetting:(NSArray *) settings;



- (void) getCaloriesWithStart:(NSDate*)start
                          end:(NSDate *)end
                       period:(NSString *)period
                  detailLevel:(NSString *)detailLevel;

- (void) getStepsWithStart:(NSDate*)start
                       end:(NSDate *)end
                    period:(NSString *)period
               detailLevel:(NSString *)detailLevel;

- (void) getHeartrateWithStart:(NSDate*)start
                           end:(NSDate *)end
                        period:(NSString *)period
                   detailLevel:(NSString *)detailLevel;

- (void) getSleepWithStart:(NSDate*)start
                       end:(NSDate *)end
                    period:(NSString *)period
               detailLevel:(NSString *)detailLevel;

+ (NSDate *) getLastSyncSteps;
+ (NSDate *) getLastSyncCalories;
+ (NSDate *) getLastSyncHeartrate;
+ (NSDate *) getLastSyncSleep;

+ (void) setLastSyncSteps:(NSDate *)date;
+ (void) setLastSyncCalories:(NSDate *)date;
+ (void) setLastSyncHeartrate:(NSDate *)date;
+ (void) setLastSyncSleep:(NSDate *)date;

@end
