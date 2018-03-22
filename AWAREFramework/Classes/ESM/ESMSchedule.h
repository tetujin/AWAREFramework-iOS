//
//  ESMSchedule.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESMSchedule : NSObject

@property (strong, nonatomic) NSString* identifier;
@property (strong, nonatomic) NSMutableArray * scheduledESMs;
@property (strong, nonatomic) NSMutableArray * fireDates;
@property (strong, nonatomic) NSArray * fireHours;
@property (nonatomic) NSCalendarUnit interval;
@property (strong, nonatomic) NSString* title;
@property (strong, nonatomic) NSString* body;
@property (strong, nonatomic) NSString* category;
@property (nonatomic) NSInteger icon;
@property (nonatomic) NSInteger timeoutSecond;
@property (strong, nonatomic) NSNumber *  randomizeSchedule;
@property (strong, nonatomic) NSArray  *  context;
@property (strong, nonatomic) NSNumber *  expiration;
@property (strong, nonatomic) NSDate *  startDate;
@property (strong, nonatomic) NSDate *  endDate;
@property (strong, nonatomic) NSNumber * interface;

- (instancetype)initWithIdentifier:(NSString*)esmIdentifier;

- (instancetype)initWithIdentifier:(NSString *)esmIdentifier
                     scheduledESMs:(NSMutableArray *) esms
                             fireHours:(NSArray *) hours
                             title:(NSString *) notificationTitle
                              body:(NSString *) notificationBody
                          interval:(NSCalendarUnit) interval
                          category:(NSString *) notificationCategory
                              icon:(NSInteger) iconNumber;

- (instancetype)initWithIdentifier:(NSString *)esmIdentifier
                     scheduledESMs:(NSMutableArray *) esms
                             fireHours:(NSArray *) hours
                             title:(NSString *) notificationTitle
                              body:(NSString *) notificationBody
                          interval:(NSCalendarUnit) interval
                          category:(NSString *) notificationCategory
                              icon:(NSInteger) iconNumber
                           timeout:(NSInteger) second;


- (instancetype)initWithIdentifier:(NSString *)esmIdentifier
                     scheduledESMs:(NSMutableArray *) esms
                             fireHours:(NSArray *) hours
                             title:(NSString *) notificationTitle
                              body:(NSString *) notificationBody
                          interval:(NSCalendarUnit) interval
                          category:(NSString *) notificationCategory
                              icon:(NSInteger) iconNumber
                           timeout:(NSInteger) second
                 randomizeSchedule:(NSNumber *) randomizeSchedule
                           context:(NSArray  *) context
                         startDate:(NSDate *) start
                           endDate:(NSDate *) end;

- (instancetype)initWithIdentifier:(NSString *)esmIdentifier
                     scheduledESMs:(NSMutableArray *) esms
                         fireHours:(NSArray *) hours
                             title:(NSString *) notificationTitle
                              body:(NSString *) notificationBody
                          interval:(NSCalendarUnit) interval
                          category:(NSString *) notificationCategory
                              icon:(NSInteger) iconNumber
                           timeout:(NSInteger) second
                 randomizeSchedule:(NSNumber *) randomizeSchedule
                           context:(NSArray  *) context
                         startDate:(NSDate *) start
                           endDate:(NSDate *) end
                         interface:(NSNumber *)interface;

// esms
- (void) addESM:(NSDictionary *) esm;
- (void) addESMs:(NSArray *) esms;
// fire dates
- (void) addFireDate:(NSDate *) date;
- (void) addFireDates:(NSArray*) dates;

- (BOOL) startScheduledESM;
- (BOOL) stopScheduledESM;

@end
