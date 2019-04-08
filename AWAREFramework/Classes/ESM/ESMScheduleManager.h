//
//  ESMScheduleManager.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/27.
//

#import <Foundation/Foundation.h>
#import "ESMSchedule.h"
#import "ESMItem.h"

@interface ESMScheduleManager : NSObject

+ (ESMScheduleManager * _Nonnull) sharedESMScheduleManager;

@property BOOL debug;

typedef void (^NotificationRemoveCompleteHandler)(void);

- (BOOL) setScheduleByConfig:(NSArray <NSDictionary * > * _Nonnull) config;
- (BOOL) addSchedule:(ESMSchedule * _Nonnull)schedule;
- (BOOL) addSchedule:(ESMSchedule * _Nonnull)schedule withNotification:(BOOL)notification;
- (BOOL) deleteScheduleWithId:(NSString * _Nonnull)scheduleId;
- (BOOL) deleteAllSchedules;
- (BOOL) deleteAllSchedulesWithNotification:(BOOL)notification;
- (NSArray * _Nonnull) getValidSchedules;
- (NSArray * _Nonnull) getValidSchedulesWithDatetime:(NSDate * _Nonnull)datetime;

- (BOOL) removeAllSchedulesFromDB;
- (BOOL) removeAllESMHitoryFromDB;

- (void) removeAllNotifications;
- (void) removeESMNotificationsWithHandler:(NotificationRemoveCompleteHandler _Nullable)handler;
- (void) refreshESMNotifications;

- (BOOL) saveESMAnswerWithTimestamp:(NSNumber * _Nonnull) timestamp
                           deviceId:(NSString * _Nonnull) deviceId
                            esmJson:(NSString * _Nonnull) esmJson
                         esmTrigger:(NSString * _Nonnull) esmTrigger
             esmExpirationThreshold:(NSNumber * _Nonnull) esmExpirationThreshold
             esmUserAnswerTimestamp:(NSNumber * _Nonnull) esmUserAnswerTimestamp
                      esmUserAnswer:(NSString * _Nonnull) esmUserAnswer
                          esmStatus:(NSNumber * _Nonnull) esmStatus;

@end
