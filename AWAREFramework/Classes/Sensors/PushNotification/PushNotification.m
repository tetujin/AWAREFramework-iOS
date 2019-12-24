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
#import "PushNotificationProvider.h"
@import AudioToolbox;

NSString * const AWARE_PREFERENCES_STATUS_PUSH_NOTIFICATION = @"status_push_notification";
NSString * const AWARE_PREFERENCES_SERVER_PUSH_NOTIFICATION = @"plugin_push_notification_server";

@implementation PushNotification{
    NSString * KEY_PUSH_DEVICE_ID;
    NSString * KEY_PUSH_TIMESTAMP;
    NSString * KEY_PUSH_TOKEN;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if(dbType == AwareDBTypeSQLite){
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:@"push_notification" entityName:NSStringFromClass([EntityPushNotification class])
                                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                                            EntityPushNotification * entityPush = (EntityPushNotification *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                                                                                          inManagedObjectContext:childContext];
                                                            entityPush.device_id = [data objectForKey:self->KEY_PUSH_DEVICE_ID];
                                                            entityPush.timestamp = [data objectForKey:self->KEY_PUSH_TIMESTAMP];
                                                            entityPush.token = [data objectForKey:self->KEY_PUSH_TOKEN];
                                                        }];
    }else{
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"push_notification"];
    }
    
    self = [super initWithAwareStudy:study
                           sensorName:@"push_notification"
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
    if(parameters != nil){
        NSString * serverURL = [self getSettingAsStringFromSttings:parameters withKey:AWARE_PREFERENCES_SERVER_PUSH_NOTIFICATION];
        [self setRemoteServerURL:serverURL];
    }
}

- (NSString *) getRemoteServerURL {
    return [NSUserDefaults.standardUserDefaults objectForKey:AWARE_PREFERENCES_SERVER_PUSH_NOTIFICATION];
}

- (void) setRemoteServerURL:(NSString *)url{
    if (url != nil) {
        [NSUserDefaults.standardUserDefaults setObject:url forKey:AWARE_PREFERENCES_SERVER_PUSH_NOTIFICATION];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

- (BOOL)startSensor{
    // [self performSelector:@selector(startSyncDB) withObject:nil afterDelay:3];
    [self setSensingState:YES];
    NSString * serverURL = [self getRemoteServerURL];
    NSString * token     = [self getPushNotificationToken];
    if (serverURL != nil && token != nil) {
        [self uploadToken:token toProvider:serverURL];
    }
    
//    NSURL    * url    = [[NSBundle mainBundle] URLForResource:@"AWAREFramework" withExtension:@"bundle"];
//    NSBundle * bundle = [NSBundle bundleWithURL:url];
//    NSString * path   = [bundle pathForResource:@"silent" ofType:@"mp3"];

    return YES;
}

- (void) uploadToken:(NSString * _Nonnull)token toProvider:(NSString * _Nonnull)serverURL{
    // [self setPNTokenStateOnServer:serverURL withToken:token state:NO]; //TODO
    if (![self existPNTokenOnServer:serverURL withToken:token]) {
        PushNotificationProvider * pnManager = [[PushNotificationProvider alloc] init];
        [pnManager registerToken:token deviceId:[self getDeviceId] serverURL:serverURL
                      completion:^(bool result, NSData * _Nullable data, NSError * _Nullable error) {
            if (self.isDebug) {
                NSString * message = @"";
                if (data != nil) {
                    message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                }
                NSLog(@"[PushNotification] %d, %@, %@", result, message ,error);
            }
            if(result){
                [self setPNTokenStateOnServer:serverURL withToken:token state:YES];
            }else{
                [self setPNTokenStateOnServer:serverURL withToken:token state:NO];
            }
        }];
    }
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


- (NSString *) getPushNotificationToken {
    return [NSUserDefaults.standardUserDefaults objectForKey:KEY_APNS_TOKEN];
}

- (BOOL) existPNTokenOnServer:(NSString * _Nonnull)url withToken:(NSString * _Nonnull)token{
    NSString * key = [NSString stringWithFormat:@"%@_EXIST_ON_REMOTE_SERVER",AWARE_PREFERENCES_SERVER_PUSH_NOTIFICATION];
    NSDictionary * remoteServerState = (NSDictionary *)[NSUserDefaults.standardUserDefaults objectForKey:key];
    if (remoteServerState != nil) {
        NSString * storedURL = [remoteServerState objectForKey:@"url"];
        if (storedURL != nil && [storedURL isEqualToString:url]) {
            NSNumber * state = [remoteServerState objectForKey:@"state"];
            if (state!=nil && state.boolValue == YES) {
                NSString * storedToken = [remoteServerState objectForKey:@"token"];
                if ([storedToken isEqualToString:token]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void) setPNTokenStateOnServer:(NSString * _Nonnull)url withToken:(NSString * _Nonnull)token state:(BOOL)state{
    NSString * key = [NSString stringWithFormat:@"%@_EXIST_ON_REMOTE_SERVER",AWARE_PREFERENCES_SERVER_PUSH_NOTIFICATION];
    [NSUserDefaults.standardUserDefaults setObject:@{@"state":@(state),@"url":url,@"token":token} forKey:key];
    [NSUserDefaults.standardUserDefaults synchronize];
}


@end
