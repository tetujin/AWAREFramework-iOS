//
//  Labels.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 3/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "Labels.h"
#import "AWAREKeys.h"
#import "EntityLabel.h"

@implementation Labels {
    NSString * KEY_LABELS_TIMESTAMP;
    NSString * KEY_LABELS_DEVICE_ID;
    NSString * KEY_LABELS_LABEL;
    NSString * KEY_LABELS_KEY;
    NSString * KEY_LABELS_TYPE;
    NSString * KEY_LABELS_NOTIFICATION_BODY;
    NSString * KEY_LABELS_ANSWERED_TIMESTAMP;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_LABELS
                        dbEntityName:NSStringFromClass([EntityLabel class])
                              dbType:dbType];
    if (self) {
        KEY_LABELS_TIMESTAMP = @"timestamp";
        KEY_LABELS_DEVICE_ID = @"device_id";
        KEY_LABELS_LABEL = @"label";
        KEY_LABELS_KEY = @"key";
        KEY_LABELS_TYPE = @"type";
        KEY_LABELS_NOTIFICATION_BODY = @"notification_body";
        KEY_LABELS_ANSWERED_TIMESTAMP = @"answered_timestamp";
        [self setCSVHeader:@[KEY_LABELS_TIMESTAMP, KEY_LABELS_DEVICE_ID, KEY_LABELS_LABEL, KEY_LABELS_TYPE, KEY_LABELS_NOTIFICATION_BODY, KEY_LABELS_ANSWERED_TIMESTAMP]];
    }
    return self;
}

- (void) createTable{
    NSMutableString * query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", KEY_LABELS_TIMESTAMP]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_LABELS_DEVICE_ID]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',",KEY_LABELS_LABEL]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_LABELS_TYPE]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_LABELS_KEY]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_LABELS_NOTIFICATION_BODY]];
    [query appendString:[NSString stringWithFormat:@"%@ double default 0,", KEY_LABELS_ANSWERED_TIMESTAMP]];
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    [super createTable:query];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
//    [self createTable];
//    [AWAREUtils sendLocalNotificationForMessage:@"Swipe and edit your label"
//                                          title:@"What is your current circumstances?"
//                                      soundFlag:NO
//                                       category:SENSOR_LABELS_TYPE_TEXT
//                                       fireDate:[NSDate new]
//                                 repeatInterval:NSCalendarUnitHour
//                                       userInfo:[NSDictionary dictionaryWithObject:@"hello" forKey:@"key"]
//                                iconBadgeNumber:1];
//
//    [AWAREUtils sendLocalNotificationForMessage:@"Are you hungry now?"
//                                          title:nil
//                                      soundFlag:NO
//                                       category:SENSOR_LABELS_TYPE_BOOLEAN
//                                       fireDate:[NSDate new]
//                                 repeatInterval:NSCalendarUnitHour
//                                       userInfo:[NSDictionary dictionaryWithObject:@"hungry" forKey:@"key"]
//                                iconBadgeNumber:1];
    return  YES;
}

+ (BOOL) stopSensor {
    [self cancelAllScheduledNotification];
    return YES;
}



//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////


+ (void) cancelAllScheduledNotification {
    for (UILocalNotification *notification in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if([notification.category isEqualToString:SENSOR_LABELS_TYPE_BOOLEAN]) {
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }else if ([notification.category isEqualToString:SENSOR_LABELS_TYPE_TEXT]){
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
    }
}


+ (void) sendYesNoQuestionWithNotificationMessage:(NSString *)message
                                            title:(NSString*)title
                                        soundFlag:(bool) flag
                                         fireDate:(NSDate *) fireDate
                                   repeatInterval:(NSCalendarUnit) calendarUnit
                                         userInfo:(NSDictionary *)userInfo
                                  iconBadgeNumber:(NSInteger) iconNumber {
    [AWAREUtils sendLocalNotificationForMessage:message
                                          title:title
                                      soundFlag:flag
                                       category:SENSOR_LABELS_TYPE_BOOLEAN
                                       fireDate:fireDate
                                 repeatInterval:calendarUnit
                                       userInfo:userInfo
                                iconBadgeNumber:iconNumber];
}

+ (void) sendEditLabelRequestWithNotificationMessage:(NSString *)message
                                          title:(NSString*)title
                                      soundFlag:(bool) flag
                                       fireDate:(NSDate *) fireDate
                                 repeatInterval:(NSCalendarUnit) calendarUnit
                                       userInfo:(NSDictionary *)userInfo
                                iconBadgeNumber:(NSInteger) iconNumber {
        [AWAREUtils sendLocalNotificationForMessage:message
                                              title:title
                                          soundFlag:flag
                                           category:SENSOR_LABELS_TYPE_TEXT
                                           fireDate:fireDate
                                     repeatInterval:calendarUnit
                                           userInfo:userInfo
                                    iconBadgeNumber:iconNumber];
}


//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
- (void) saveLabel:(NSString *) label
           withKey:(NSString *) key
              type:(NSString *) type
              body:(NSString *) notificationBody
       triggerTime:(NSDate *) triggerTime
      answeredTime:(NSDate *) answeredTime {
    
    if (label == nil) label = @"";
    if (key == nil) label = @"";
    if (type == nil) label = @"";
    if (notificationBody == nil) notificationBody = @"";
    if (triggerTime == nil) triggerTime = [NSDate new];
    if (answeredTime == nil) answeredTime = [NSDate new];
    
//    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
//    [query setObject:[AWAREUtils getUnixTimestamp:triggerTime] forKey:KEY_LABELS_TIMESTAMP];
//    [query setObject:[self getDeviceId] forKey:KEY_LABELS_DEVICE_ID];
//    [query setObject:label forKey:KEY_LABELS_LABEL];
//    [query setObject:key forKey:KEY_LABELS_KEY];
//    [query setObject:type forKey:KEY_LABELS_TYPE];
//    [query setObject:notificationBody forKey:KEY_LABELS_NOTIFICATION_BODY];
//    [query setObject:[AWAREUtils getUnixTimestamp:answeredTime] forKey:KEY_LABELS_ANSWERED_TIMESTAMP];
//    [self saveData:query];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        EntityLabel * data = (EntityLabel *)[NSEntityDescription insertNewObjectForEntityForName:[self getEntityName]
                                                                            inManagedObjectContext:[self getSensorManagedObjectContext]];
        data.device_id = [self getDeviceId];
        data.timestamp = [AWAREUtils getUnixTimestamp:triggerTime];
        data.label = label;
        data.type = type;
        data.key = key;
        data.notification_body = notificationBody;
        data.answered_timestamp = [AWAREUtils getUnixTimestamp:answeredTime];
        [self saveDataToDB];
    });

}


@end
