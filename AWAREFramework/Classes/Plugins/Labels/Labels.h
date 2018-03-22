//
//  Labels.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 3/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface Labels : AWARESensor <AWARESensorDelegate>

- (void) saveLabel:(NSString* ) label
           withKey:(NSString*) key
              type:(NSString* ) type
              body:(NSString *) notificationBody
       triggerTime:(NSDate *)triggerTime
      answeredTime:(NSDate *)answeredTime;

+ (void) cancelAllScheduledNotification;

+ (void) sendYesNoQuestionWithNotificationMessage:(NSString *)message
                                            title:(NSString*)title
                                        soundFlag:(bool) flag
                                         fireDate:(NSDate *) fireDate
                                   repeatInterval:(NSCalendarUnit) calendarUnit
                                         userInfo:(NSDictionary *)userInfo
                                  iconBadgeNumber:(NSInteger) iconNumber;


+ (void) sendEditLabelRequestWithNotificationMessage:(NSString *)message
                                               title:(NSString*)title
                                           soundFlag:(bool) flag
                                            fireDate:(NSDate *) fireDate
                                      repeatInterval:(NSCalendarUnit) calendarUnit
                                            userInfo:(NSDictionary *)userInfo
                                     iconBadgeNumber:(NSInteger) iconNumber;

@end
