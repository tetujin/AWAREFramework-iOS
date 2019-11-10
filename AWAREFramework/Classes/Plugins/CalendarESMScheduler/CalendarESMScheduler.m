//
//  CalendarESMScheduler.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/04/05.
//

#import "CalendarESMScheduler.h"
#import "Calendar.h"
#import "ESMScheduleManager.h"
#import "ESMSchedule.h"
#import <UserNotifications/UserNotifications.h>

NSString * const AWARE_PREFERENCES_STATUS_CALENDAR_ESM = @"status_plugin_esm_scheduler";

@implementation CalendarESMScheduler{
    Calendar * calendar;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study sensorName:@"plugin_calendar_esm_scheduler" storage:nil];
    
    if (self!=nil) {
    }
    
    return self;
}

- (BOOL)startSensor{
    
    if ([self isDebug]) {
        [self showPendingNotifications];
        [self showDeliveredNotifications];
    }
    
    calendar = [[Calendar alloc] init];

     __block typeof(self) blockSelf = self;
    // https://borkwarellc.wordpress.com/2010/09/06/block-retain-cycles/
    // http://d.hatena.ne.jp/peccu/20120606/arc
    
    [calendar setCalendarEventsHandler:^(AWARESensor *sensor, NSArray<EKEvent *> *events) {
        if (events != nil) {
            
            ESMScheduleManager * esmManager = [ESMScheduleManager sharedESMScheduleManager];
            [esmManager deleteAllSchedules];

            
            for (EKEvent * event in events) {
                if (event == nil) continue;
                if (event.calendar == nil) continue;
                if (event.calendar.title == nil) continue;
                if (event.title == nil) continue;
                
                if([event.calendar.title hasPrefix:@"AWARE"]){
                    if ( [event.title hasPrefix:@"ESM"] ){
                        
                        NSString * notes = event.notes;
                        NSString * trigger = event.title;
                        
                        NSDate * begin = event.startDate;
                        NSDate * end = event.endDate;
                        ESMSchedule * schedule = [[ESMSchedule alloc] init];
                        schedule.startDate = begin;
                        schedule.endDate = end;
                        schedule.notificationTitle = trigger;
                        schedule.expirationThreshold = @0;
                        schedule.repeat = NO;
                        
                        
                        /////////////// generate UNNotification ////////////
                        NSCalendar * cal = [NSCalendar currentCalendar];
                        NSDateComponents * componetns = [cal components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:begin];
                        [schedule addTimer:componetns];
                        UNNotificationTrigger * notificationTrigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:componetns repeats:NO];
                        
                        if (blockSelf.isDebug) {
                            NSLog(@"[CalendarESMScheduler] Set ESM Notification at %ld:%ld",(long)componetns.hour, (long)componetns.minute);
                        }
                        
                        UNMutableNotificationContent * notificationContent = [[UNMutableNotificationContent alloc] init];
                        notificationContent.title = trigger;
                        notificationContent.badge = @1;
                        notificationContent.sound = [UNNotificationSound defaultSound];
                        notificationContent.categoryIdentifier = PLUGIN_CALENDAR_ESM_SCHEDULER_NOTIFICATION_CATEGORY;
                        
                        // NOTE: Notification ID should use an unified ID
                        NSString * notificationId = [NSString stringWithFormat:@"%@_%zd_%zd_%@",PLUGIN_CALENDAR_ESM_SCHEDULER_NOTIFICATION_ID, componetns.hour, componetns.minute, trigger];
                        UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:notificationId content:notificationContent trigger:notificationTrigger];
                        
                        UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
                        
                        [center removePendingNotificationRequestsWithIdentifiers:@[notificationId]];
                        [center removeDeliveredNotificationsWithIdentifiers:@[notificationId]];
                        
                        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                            if(error != nil){
                                NSLog(@"[CalendarESMScheduler] Error: %@", error.debugDescription);
                            }
                        }];
                        ///////////////////////////////////////////
                        
                        if (notes!=nil) {
                            NSData * data = [notes dataUsingEncoding:NSUTF8StringEncoding];
                            NSArray * esms = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                            for (NSDictionary * esm in esms) {
                                ESMItem * item = [[ESMItem alloc] initWithConfiguration:esm];
                                [schedule addESM:item];
                            }
                        }
                        [esmManager addSchedule:schedule withNotification:NO];
                    }
                }
            }
        }
    }];
    
    calendar.sensingEventHour = 24;
    [calendar.storage setStore:NO];
    [calendar startSensor];
    
    [self setSensingState:YES];
    
    return YES;
}

- (BOOL)stopSensor{
    if (calendar!=nil) {
        [calendar stopSensor];
    }
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    [self setSensingState:NO];
    return YES;
}

- (void)startSyncDB{
    
}

- (void)stopSyncDB{

}

- (void) showPendingNotifications{
    UNUserNotificationCenter * notificationCenter = [UNUserNotificationCenter currentNotificationCenter];

    [notificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        if (requests!=nil) {
            NSLog(@"pending: %tu", requests.count);
            for (UNNotificationRequest * request in requests) {
                NSLog(@"[%@] %@",request.identifier, request.trigger);
            }
        }
    }];
}

- (void)showDeliveredNotifications{
    UNUserNotificationCenter * notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    [notificationCenter getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
        if (notificationCenter!=nil) {
            NSLog(@"delivered: %tu", notifications.count);
            for (UNNotification * notification in notifications) {
                NSLog(@"[%@] %@", notification.request.identifier, notification.request.trigger);
            }
        }
    }];
}

@end
