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
    NSString* KEY_GOOGLE_PHONENUMBER;
    NSString* KEY_GOOGLE_BLOB_PICTURE;
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
        KEY_GOOGLE_NAME         = @"name";
        KEY_GOOGLE_EMAIL        = @"email";
        KEY_GOOGLE_BLOB_PICTURE = @"blob_picture";
        KEY_GOOGLE_PHONENUMBER  = @"phonenumber";
    }
    return self;
}

- (void)setParameters:(NSArray *)parameters{
    // TODO
}

- (void) createTable
{
    // Send a table create query
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:KEY_GOOGLE_NAME    type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_GOOGLE_EMAIL   type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_GOOGLE_PHONENUMBER  type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_GOOGLE_BLOB_PICTURE   type:TCQTypeBlob default:@"null"];
    [self.storage createDBTableOnServerWithTCQMaker:tcqMaker];
}

- (void)setClientId:(NSString *)clientId
{
    GOOGLE_LOGIN_CLIENT_ID = clientId;
}

+ (void) setUserNameEncryption:(BOOL)state{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:state forKey:@"encryption_name_sha1"];
    [defaults synchronize];
}

+ (void) setEmailEncryption:(BOOL)state{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:state forKey:@"encryption_email_sha1"];
    [defaults synchronize];
}

+ (void) setPhonenumberEncryption:(BOOL)state{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:state forKey:@"encryption_phonenumber_sha1"];
    [defaults synchronize];
}

- (BOOL)startSensor
{
    // NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if (GOOGLE_LOGIN_CLIENT_ID == nil) {
        NSLog(@"[Error] Google Login ClientID is null. please ClientID.");
        return NO;
    }
    [GIDSignIn sharedInstance].clientID = GOOGLE_LOGIN_CLIENT_ID;
    
    if([self isNeedLogin]){
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_GOOGLE_LOGIN_REQUEST
                                                            object:nil
                                                          userInfo:nil];
    }
    
    NSString * name = [GoogleLogin getUserName];
    NSString * email = [GoogleLogin getEmail];
    if (name != nil && email != nil) {
        [self setLatestValue:[NSString stringWithFormat:@"%@ (%@)", name, email]];
    }
    
    [self setSensingState:YES];
    
    return YES;
}

- (BOOL)stopSensor
{
    [self setSensingState:NO];
    if (self.storage != nil){
        [self.storage saveBufferDataInMainThread:YES];
    }
    return YES;
}

/////////////////////////////////////////////////////

- (BOOL)isNeedLogin{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * email = [defaults objectForKey:@"GOOGLE_EMAIL"];
    if(email == nil){
        return YES;
    }else{
        return NO;
    }
}

//////////////////////////////////////////////////////

- (void)setGoogleAccountWithUserName:(NSString *)name
                               email:(NSString *)email
                         phonenumber:(NSString *)phonenumber
                             picture:(NSData *)picture{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:name        forKey:@"GOOGLE_NAME"];
    [defaults setObject:email       forKey:@"GOOGLE_EMAIL"];
    [defaults setObject:phonenumber forKey:@"GOOGLE_PHONENUMBER"];
    if (picture!=nil) {
        [defaults setObject:picture     forKey:@"GOOGLE_PICTURE"];
    }
    [defaults synchronize];
    [self saveStoredGoogleUserInfo];
}

+ (void) deleteGoogleAccountFromLocalStorage
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"GOOGLE_NAME"];
    [defaults removeObjectForKey:@"GOOGLE_EMAIL"];
    [defaults removeObjectForKey:@"GOOGLE_PHONENUMBER"];
    [defaults removeObjectForKey:@"GOOGLE_PICTURE"];
    [defaults synchronize];
}

+ (NSString *) getUserName
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * name = [defaults objectForKey:@"GOOGLE_NAME"];
    if (name == nil) {
        name = @"";
    }
    return name;
}

+ (NSString *) getEmail
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * email = [defaults objectForKey:@"GOOGLE_EMAIL"];
    if (email == nil) {
        email = @"";
    }
    return email;
}

+ (NSString *) getPhonenumber
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * phonenumber = [defaults objectForKey:@"GOOGLE_PHONENUMBER"];
    if (phonenumber == nil) {
        phonenumber = @"";
    }
    return phonenumber;
}

+ (NSData *)getPicture
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSData * picture = [defaults objectForKey:@"GOOGLE_PICTURE"];
    return picture;
}

- (BOOL) saveStoredGoogleUserInfo
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * name   = [GoogleLogin getUserName];
    NSString * email  = [GoogleLogin getEmail];
    NSString * phonenumber = [GoogleLogin getPhonenumber];
    // NSData * picture = [GoogleLogin getPicture];
    
    bool isNameEncryption   = [defaults boolForKey:@"encryption_name_sha1"];
    bool isEmailEncryption  = [defaults boolForKey:@"encryption_email_sha1"];
    bool isPhonenumberEncryption = [defaults boolForKey:@"encryption_phonenumber_sha1"];
    
    if(email != nil  && isEmailEncryption) {
        email = [AWAREUtils sha1:email];
    }
    
    if(name != nil   && isNameEncryption){
        name = [AWAREUtils sha1:name];
    }
    
    if(phonenumber != nil && isPhonenumberEncryption){
        phonenumber = [AWAREUtils sha1:phonenumber];
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    [dict setObject:unixtime           forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:name               forKey:KEY_GOOGLE_NAME];
    [dict setObject:email              forKey:KEY_GOOGLE_EMAIL];
    [dict setObject:phonenumber        forKey:KEY_GOOGLE_PHONENUMBER];
    // [dic setObject:[NSNull null]      forKey:KEY_GOOGLE_BLOB_PICTURE];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
    [self setLatestData:dict];
    [self setLatestValue:[NSString stringWithFormat:@"%@ (%@)", name, email]];

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
