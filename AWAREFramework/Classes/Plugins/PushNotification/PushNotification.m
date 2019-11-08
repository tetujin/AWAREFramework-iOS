//
//  PushNotification.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 5/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "PushNotification.h"
#import "AWAREUtils.h"
#import "AWAREKeys.h"
#import "EntityPushNotification.h"

@implementation PushNotification{
    NSString * KEY_PUSH_DEVICE_ID;
    NSString * KEY_PUSH_TIMESTAMP;
    NSString * KEY_PUSH_TOKEN;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if(dbType == AwareDBTypeSQLite){
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:@"push_notification_device_tokens" entityName:NSStringFromClass([EntityPushNotification class])
                                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                                            EntityPushNotification * entityPush = (EntityPushNotification *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                                                                                          inManagedObjectContext:childContext];
                                                            entityPush.device_id = [data objectForKey:self->KEY_PUSH_DEVICE_ID];
                                                            entityPush.timestamp = [data objectForKey:self->KEY_PUSH_TIMESTAMP];
                                                            entityPush.token = [data objectForKey:self->KEY_PUSH_TOKEN];
                                                        }];
    }else{
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"push_notification_device_tokens"];
    }
    
    self = [super initWithAwareStudy:study
                           sensorName:@"push_notification_device_tokens"
                              storage:storage];
    if(self != nil){
        KEY_PUSH_DEVICE_ID = @"device_id";
        KEY_PUSH_TIMESTAMP = @"timestamp";
        KEY_PUSH_TOKEN = @"token";
    }
    return self;
}


- (void)createTable{
    if([self isDebug]) NSLog(@"[%@] Send a create table query", [self getSensorName]);
    NSMutableString *query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", KEY_PUSH_TIMESTAMP]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_PUSH_DEVICE_ID]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_PUSH_TOKEN]];
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void)setParameters:(NSArray *)parameters{
    
}

- (BOOL)startSensor{
    [self performSelector:@selector(startSyncDB) withObject:nil afterDelay:3];
    [self setSensingState:YES];
    return YES;
}

- (void) savePushNotificationDeviceTokenWithData:(NSData *)data{
    [self savePushNotificationDeviceToken:[self hexadecimalStringFromData:data]];
}

- (NSString * _Nonnull)hexadecimalStringFromData:(NSData * _Nonnull)data
{
    NSUInteger dataLength = data.length;
    if (dataLength == 0) {
        return nil;
    }

    const unsigned char *dataBuffer = data.bytes;
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x", dataBuffer[i]];
    }
    return [hexString copy];
}

/// Save a push notification token. The data format should be String.
/// @param token A push notification token (String)
- (void) savePushNotificationDeviceToken:(NSString*) token {
    if (token == nil) return;
    
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self savePushNotificationDeviceToken:token];
        });
    }else{
        NSString * storedToken = [self getPushNotificationToken];
        if (storedToken!=nil) {
            if ([storedToken isEqualToString:token]) {
                if([self isDebug]) NSLog(@"[%@] The Push Notification Token is already stored",self.getSensorName);
                return;
            }else{
                if([self isDebug]) NSLog(@"[%@] The Push Notification Token is updated",self.getSensorName);
            }
        }
        
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_PUSH_TIMESTAMP];
        [dict setObject:[self getDeviceId] forKey:KEY_PUSH_DEVICE_ID];
        [dict setObject:token forKey:KEY_PUSH_TOKEN];
        
        // [self saveData:dict];
        [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
        [self setLatestData:dict];
        
        // Save the token to user default
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:token forKey:KEY_APNS_TOKEN];
        [defaults synchronize];
        
        SensorEventHandler handler = [self getSensorEventHandler];
        if (handler!=nil) {
            handler(self, dict);
        }
    }
}

/**
 * Save a stored device token fro push notification
 * @return An existance of device token for push notification
 */
- (BOOL) saveStoredPushNotificationDeviceToken {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceToken = [defaults objectForKey:KEY_APNS_TOKEN];
    if (deviceToken != nil) {
        [self savePushNotificationDeviceToken:deviceToken];
        return YES;
    }
    return NO;
}

- (void)saveDummyData{
    [self saveStoredPushNotificationDeviceToken];
}

- (NSString *) getPushNotificationToken {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceToken = [defaults objectForKey:KEY_APNS_TOKEN];
    return deviceToken;
}

@end
