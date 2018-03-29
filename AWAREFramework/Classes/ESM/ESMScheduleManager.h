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

@property BOOL debug;

- (BOOL) addSchedule:(ESMSchedule *)schedule;
- (BOOL) deleteScheduleWithId:(NSString *)scheduleId;
- (BOOL) deleteAllSchedules;
- (NSArray *) getValidSchedules;
- (NSArray *) getValidSchedulesWithDatetime:(NSDate *)datetime;


- (void) setNotificationSchedules ;
- (NSArray *) getNotificationSchedules;
- (void) removeNotificationSchedules;
- (void) refreshNotificationSchedules;

@end
