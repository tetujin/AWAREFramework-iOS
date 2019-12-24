//
//  AWAREUtils.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/23/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

@interface AWAREUtils : NSObject

NS_ASSUME_NONNULL_BEGIN

+ (BOOL) getAppState;
+ (BOOL) isForeground;
+ (BOOL) isBackground;

// Device information
+ (float) getCurrentOSVersionAsFloat;
+ (NSString * _Nullable) getSystemUUID;
+ (NSString *) deviceName;

// Date Controller
+ (NSNumber *) getUnixTimestamp:(NSDate * _Nullable)nsdate;
+ (NSDate *) getTargetNSDate:(NSDate * _Nullable) nsDate
                        hour:(int)hour
                     nextDay:(BOOL)nextDay;
+ (NSDate *) getTargetNSDate:(NSDate * _Nullable)nsDate
                       hour:(int)hour
                     minute:(int)minute
                     second:(int)second
                    nextDay:(BOOL)nextDay;

// Hash Methods
+ (NSString *) sha1:(NSString*)input;
+ (NSString *) sha1:(NSString*)input debug:(BOOL)debug;

+ (NSString *) md5:(NSString*)input;

// Format checker
+ (BOOL) validateEmailWithString:(NSString * _Nullable)str;

+ (BOOL) checkURLFormat:(NSString * _Nullable)urlStr;

+ (NSDictionary * _Nullable) getDictionaryFromURLParameter:(NSURL *)url;

+ (NSString *)stringByAddingPercentEncoding:(NSString *)string;
+ (NSString *)stringByAddingPercentEncoding:(NSString *)string unreserved:(NSString*)unreserved;

+ (void) sendLocalPushNotificationWithTitle:(NSString * _Nullable)title
                                       body:(NSString * _Nullable)body
                               timeInterval:(double)timeInterval
                                    repeats:(BOOL)repeats;

+ (void) sendLocalPushNotificationWithTitle:(NSString * _Nullable)title
                                       body:(NSString * _Nullable)body
                               timeInterval:(double)timeInterval
                                    repeats:(BOOL)repeats
                                 identifier:(NSString * _Nullable)identifier
                                      clean:(BOOL)clean;

+ (void) sendLocalPushNotificationWithTitle:(NSString * _Nullable)title
                                        body:(NSString * _Nullable)body
                                timeInterval:(double)timeInterval
                                     repeats:(BOOL)repeats
                                  identifier:(NSString * _Nullable)identifier
                                       clean:(BOOL)clean
                                sound:(UNNotificationSound * _Nullable)sound;

NS_ASSUME_NONNULL_END

@end
