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

NSString * const GOOGLE_LOGIN_CLIENT_ID = @"513561083200-em3srmsc40a2q6cuh8o2hguvhd1umfll.apps.googleusercontent.com";

@implementation GoogleLogin {
    NSString* KEY_GOOGLE_NAME;
    NSString* KEY_GOOGLE_EMAIL;
    NSString* KEY_GOOGLE_BLOB_PICTURE;
    NSString* KEY_GOOGLE_PHONENUMBER;
    NSString* KEY_GOOGLE_USER_ID;
    
    BOOL encryptionName;
    BOOL encryptionEmail;
    BOOL encryptionUserId;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_GOOGLE_LOGIN];
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_GOOGLE_LOGIN
                             storage:storage];
    if (self) {
        KEY_GOOGLE_USER_ID = @"user_id";
        KEY_GOOGLE_NAME = @"name";
        KEY_GOOGLE_EMAIL = @"email";
        KEY_GOOGLE_BLOB_PICTURE = @"blob_picture";
        KEY_GOOGLE_PHONENUMBER = @"phonenumber";
        encryptionName = NO;
        encryptionEmail = NO;
        encryptionUserId = NO;
//        [self.storage allowsCellularAccess];
//        [self.storage allowsDateUploadWithoutBatteryCharging];
        
//        [self setCSVHeader:@[@"device_id",
//                             @"timestamp",
//                             KEY_GOOGLE_USER_ID,
//                             KEY_GOOGLE_NAME,
//                             KEY_GOOGLE_EMAIL]];
    }
    return self;
}

- (void) createTable {
    // Send a table create query
    NSLog(@"[%@] Crate table.", [self getSensorName]);
    
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:KEY_GOOGLE_USER_ID type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_GOOGLE_NAME type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_GOOGLE_EMAIL type:TCQTypeText default:@"''"];

    // [super createTable:[tcqMaker getDefaudltTableCreateQuery]];
    [self.storage createDBTableOnServerWithTCQMaker:tcqMaker];
}

- (BOOL)startSensor{
    
//    encryptionName = [self getBoolFromSettings:settings withKey:@"encryption_name_sha1"];
//    encryptionEmail = [self getBoolFromSettings:settings withKey:@"encryption_email_sha1"];
//    encryptionUserId = [self getBoolFromSettings:settings withKey:@"encryption_user_id_sha1"];
//    
//    [defaults setBool:encryptionName    forKey:@"encryption_name_sha1"];
//    [defaults setBool:encryptionEmail   forKey:@"encryption_email_sha1"];
//    [defaults setBool:encryptionUserId  forKey:@"encryption_user_id_sha1"];
//    

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * userId = [defaults objectForKey:@"GOOGLE_ID"];
    if(userId == nil){
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_GOOGLE_LOGIN_REQUEST
                                                            object:nil
                                                          userInfo:nil];
    }else{
        [self performSelector:@selector(startSyncDB) withObject:nil afterDelay:1];
    }
    
    return YES;
}

- (BOOL)stopSensor {
    return YES;
}

//////////////////////////////////////////////////////

- (void) setGoogleAccountWithUserId:(NSString *)userId
                               name:(NSString* )name
                              email:(NSString *)email {
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:userId  forKey:@"GOOGLE_ID"];
    [defaults setObject:name    forKey:@"GOOGLE_NAME"];
    [defaults setObject:email   forKey:@"GOOGLE_EMAIL"];
    [defaults synchronize];
    
    [self saveStoredGoogleAccount];
}

+ (void) deleteGoogleAccountFromLocalStorage {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"GOOGLE_ID"];
    [defaults removeObjectForKey:@"GOOGLE_NAME"];
    [defaults removeObjectForKey:@"GOOGLE_EMAIL"];
    [defaults synchronize];
}

+ (NSString *) getGoogleAccountId {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * userId = [defaults objectForKey:@"GOOGLE_ID"];
    return userId;
}

+ (NSString *) getGoogleAccountName{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * name = [defaults objectForKey:@"GOOGLE_NAME"];
    return name;
}

+ (NSString *) getGoogleAccountEmail{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * email = [defaults objectForKey:@"GOOGLE_EMAIL"];
    return email;
}

- (BOOL) saveStoredGoogleAccount {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * userId = [defaults objectForKey:@"GOOGLE_ID"];
    NSString * name = [defaults objectForKey:@"GOOGLE_NAME"];
    NSString * email = [defaults objectForKey:@"GOOGLE_EMAIL"];
    
    encryptionName   = [defaults boolForKey:@"encryption_name_sha1"];
    encryptionEmail  = [defaults boolForKey:@"encryption_email_sha1"];
    encryptionUserId = [defaults boolForKey:@"encryption_user_id_sha1"];
    
    if(email == nil || userId == nil || name == nil){
        return NO;
    }
    
    if(email != nil && encryptionEmail) {
        email = [AWAREUtils sha1:email];
    }
    
    if(name != nil && encryptionName){
        name = [AWAREUtils sha1:name];
    }
    
    if(userId != nil && encryptionUserId){
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
    // [self saveData:dict];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
    [self setLatestData:dict];
    [self performSelector:@selector(startSyncDB) withObject:0 afterDelay:3];
    return YES;
}

//////////////////////////////////////////////////////

-(BOOL) getBoolFromSettings:(NSArray *)settings withKey:(NSString * )key{
    
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
