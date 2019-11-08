//
//  PushNotification.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 5/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface PushNotification : AWARESensor

// - (void) savePushNotificationDeviceToken:(NSString * _Nonnull) token;
- (void) savePushNotificationDeviceTokenWithData:(NSData * _Nonnull) data;
- (NSString * _Nullable) getPushNotificationToken;
@end
