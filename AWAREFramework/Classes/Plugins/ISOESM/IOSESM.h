//
//  IOSESM.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 10/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "ESMSchedule.h"

@interface IOSESM : AWARESensor <AWARESensorDelegate>

extern NSString * const AWARE_PREFERENCES_STATUS_PLUGIN_IOS_ESM;
extern NSString * const AWARE_PREFERENCES_PLUGIN_IOS_ESM_TABLE_NAME;
extern NSString * const AWARE_PREFERENCES_PLUGIN_IOS_ESM_CONFIG_URL;

// - (BOOL) setWebESMsWithSchedule:(ESMSchedule *) esmSchedule;
- (BOOL) setScheduledESM:(ESMSchedule *)esmSchedule;
// - (void) setWebESMsWithArray:(NSArray *) webESMArray;

- (BOOL) startSensorWithURL:(NSString *)urlStr tableName:(NSString *)table;

/////////////////////////////////////////////////////////
- (NSArray *) getValidESMSchedulesWithDatetime:(NSDate *) datetime;
- (NSArray *) getScheduledESMs;
- (void) saveESMAnswerWithTimestamp:(NSNumber * )timestamp
                           deviceId:(NSString *) deviceId
                            esmJson:(NSString *) esmJson
                         esmTrigger:(NSString *) esmTrigger
             esmExpirationThreshold:(NSNumber *) esmExpirationThreshold
             esmUserAnswerTimestamp:(NSNumber *) esmUserAnswerTimestamp
                      esmUserAnswer:(NSString *) esmUserAnswer
                          esmStatus:(NSNumber *) esmStatus;
- (NSString *) convertNSArraytoJsonStr:(NSArray *)array;
- (void) setNotificationSchedules;
- (void) setScheduledESMs:(NSArray *)ESMArray;

- (void) removeNotificationSchedules;
- (void) refreshNotifications;

/////////////////////////////////
+ (BOOL) isAppearedThisSection;
+ (void) setAppearedState:(BOOL)state;
+ (void) setTableVersion:(int)version;
+ (int)  getTableVersion;

@end
