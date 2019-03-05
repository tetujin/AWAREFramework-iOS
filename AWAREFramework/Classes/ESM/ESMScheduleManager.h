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

- (BOOL) addSchedule:(ESMSchedule *)schedule;
- (BOOL) addSchedule:(ESMSchedule *)schedule withNotification:(BOOL)notification;
- (BOOL) deleteScheduleWithId:(NSString *)scheduleId;
- (BOOL) deleteAllSchedules;
- (BOOL) deleteAllSchedulesWithNotification:(BOOL)notification;
- (NSArray *) getValidSchedules;
- (NSArray *) getValidSchedulesWithDatetime:(NSDate *)datetime;

- (BOOL) removeAllSchedulesFromDB;
- (BOOL) removeAllESMHitoryFromDB;

- (void) removeAllNotifications;
- (void) removeESMNotificationsWithHandler:(NotificationRemoveCompleteHandler)handler;
- (void) refreshESMNotifications;

@end
