//
//  PushNotification.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 5/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

extern NSString * _Nonnull const AWARE_PREFERENCES_STATUS_PUSH_NOTIFICATION;
extern NSString * _Nonnull const AWARE_PREFERENCES_SERVER_PUSH_NOTIFICATION;

@interface PushNotification : AWARESensor

- (void) savePushNotificationDeviceTokenWithData:(NSData * _Nonnull) data;
- (void) savePushNotificationDeviceToken:(NSString* _Nonnull) token;
- (NSString * _Nonnull) hexadecimalStringFromData:(NSData * _Nonnull)data;

- (NSString * _Nullable) getPushNotificationToken;

- (NSString * _Nullable) getRemoteServerURL;
- (void) setRemoteServerURL:(NSString * _Nullable)url;

- (void) uploadToken:(NSString * _Nonnull)token toProvider:(NSString * _Nonnull)serverURL;
- (void) uploadToken:(NSString * _Nonnull)token toProvider:(NSString * _Nonnull)serverURL forcefully:(BOOL)forcefully;

@end
