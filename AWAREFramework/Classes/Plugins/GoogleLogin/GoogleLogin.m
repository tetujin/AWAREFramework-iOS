//
//  GoogleLogin.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/6/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "GoogleLogin.h"
#import "AWAREKeys.h"
#import "AWAREUtils.h"
#import "TCQMaker.h"

@implementation GoogleLogin {
    NSString* KEY_GOOGLE_NAME;
    NSString* KEY_GOOGLE_EMAIL;
    NSString* KEY_GOOGLE_BLOB_PICTURE;
    NSString* KEY_GOOGLE_PHONENUMBER;
    NSString* KEY_GOOGLE_USER_ID;
    NSString* GOOGLE_LOGIN_CLIENT_ID;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                            dbType:(AwareDBType)dbType
{
    return [self initWithAwareStudy:study dbType:dbType clientId:nil];
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                            dbType:(AwareDBType)dbType
                          clientId:(NSString*) clientId
{
    AWAREStorage * storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_GOOGLE_LOGIN];
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_GOOGLE_LOGIN
                             storage:storage];
    if (self) {
        GOOGLE_LOGIN_CLIENT_ID  = clientId;
        if(clientId==nil){
            GOOGLE_LOGIN_CLIENT_ID = @"513561083200-em3srmsc40a2q6cuh8o2hguvhd1umfll.apps.googleusercontent.com";
        }
        KEY_GOOGLE_USER_ID      = @"user_id";
        KEY_GOOGLE_NAME         = @"name";
        KEY_GOOGLE_EMAIL        = @"email";
        KEY_GOOGLE_BLOB_PICTURE = @"blob_picture";
        KEY_GOOGLE_PHONENUMBER  = @"phonenumber";
    }
    return self;
}

- (void) createTable
{
    // Send a table create query
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:KEY_GOOGLE_USER_ID type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_GOOGLE_NAME    type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_GOOGLE_EMAIL   type:TCQTypeText default:@"''"];
    [self.storage createDBTableOnServerWithTCQMaker:tcqMaker];
}

- (void)setClientId:(NSString *)clientId
{
    GOOGLE_LOGIN_CLIENT_ID = clientId;
}

+ (void) setNameEncryption:(BOOL)state{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:state forKey:@"encryption_name_sha1"];
    [defaults synchronize];
}

+ (void) setEmailEncryption:(BOOL)state{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:state forKey:@"encryption_email_sha1"];
    [defaults synchronize];
}

+ (void) setisUserIdEncryption:(BOOL)state{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:state forKey:@"encryption_user_id_sha1"];
    [defaults synchronize];
}

- (BOOL)startSensor
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if (GOOGLE_LOGIN_CLIENT_ID == nil) {
        NSLog(@"[Error] Google Login ClientID is null. please ClientID.");
        return NO;
    }
    [GIDSignIn sharedInstance].clientID = GOOGLE_LOGIN_CLIENT_ID;
    
    NSString * userId = [defaults objectForKey:@"GOOGLE_ID"];
    if(userId == nil){
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_GOOGLE_LOGIN_REQUEST
                                                            object:nil
                                                          userInfo:nil];
    }
    
    [self setSensingState:YES];
    
    return YES;
}

- (BOOL)stopSensor
{
    [self setSensingState:NO];
    return YES;
}

/////////////////////////////////////////////////////

- (BOOL)isNeedLogin{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * userId = [defaults objectForKey:@"GOOGLE_ID"];
    if(userId == nil){
        return YES;
    }else{
        return NO;
    }
}

//////////////////////////////////////////////////////

- (void) setGoogleAccountWithUserId:(NSString *)userId
                               name:(NSString* )name
                              email:(NSString *)email
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:userId  forKey:@"GOOGLE_ID"];
    [defaults setObject:name    forKey:@"GOOGLE_NAME"];
    [defaults setObject:email   forKey:@"GOOGLE_EMAIL"];
    [defaults synchronize];
    [self saveStoredGoogleUserInfo];
}

+ (void) deleteGoogleAccountFromLocalStorage
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"GOOGLE_ID"];
    [defaults removeObjectForKey:@"GOOGLE_NAME"];
    [defaults removeObjectForKey:@"GOOGLE_EMAIL"];
    [defaults synchronize];
}

+ (NSString *) getGoogleUserId
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * userId = [defaults objectForKey:@"GOOGLE_ID"];
    return userId;
}

+ (NSString *) getGoogleUserName
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * name = [defaults objectForKey:@"GOOGLE_NAME"];
    return name;
}

+ (NSString *) getGoogleUserEmail
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * email = [defaults objectForKey:@"GOOGLE_EMAIL"];
    return email;
}

- (BOOL) saveStoredGoogleUserInfo
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * userId = [defaults objectForKey:@"GOOGLE_ID"];
    NSString * name   = [defaults objectForKey:@"GOOGLE_NAME"];
    NSString * email  = [defaults objectForKey:@"GOOGLE_EMAIL"];
    
    bool isNameEncryption   = [defaults boolForKey:@"encryption_name_sha1"];
    bool isEmailEncryption  = [defaults boolForKey:@"encryption_email_sha1"];
    bool isUserIdEncryption = [defaults boolForKey:@"encryption_user_id_sha1"];
    
    if(email == nil || userId == nil || name == nil){
        return NO;
    }
    
    if(email != nil  && isEmailEncryption) {
        email = [AWAREUtils sha1:email];
    }
    
    if(name != nil   && isNameEncryption){
        name = [AWAREUtils sha1:name];
    }
    
    if(userId != nil && isUserIdEncryption){
        userId = [AWAREUtils sha1:userId];
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    [dict setObject:unixtime           forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:userId             forKey:KEY_GOOGLE_USER_ID];
    [dict setObject:name               forKey:KEY_GOOGLE_NAME];
    [dict setObject:email              forKey:KEY_GOOGLE_EMAIL];
    // [dic setObject:[NSNull null]      forKey:KEY_GOOGLE_BLOB_PICTURE];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
    [self setLatestData:dict];

    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_GOOGLE_LOGIN_SUCCESS
                                                        object:nil
                                                      userInfo:nil];
    
    return YES;
}

//////////////////////////////////////////////////////
-(BOOL) getBoolFromSettings:(NSArray *)settings
                    withKey:(NSString * )key
{
    if (settings == nil) return NO;
    
    for (NSDictionary * setting in settings) {
        if ([[setting objectForKey:@"setting"] isEqualToString:key]) {
            BOOL value = [[setting objectForKey:@"value"] boolValue];
            return value;
        }
    }
    return NO;
}


@end
