//
//  GoogleLogin.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/6/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface GoogleLogin : AWARESensor <AWARESensorDelegate>

//- (void) saveName:(NSString* )name
//        withEmail:(NSString *)email
//      phoneNumber:(NSString*) phonenumber;

//- (void) saveWithUserID:(NSString *)userID
//                   name:(NSString* )name
//                  email:(NSString *)email;

extern NSString * const GOOGLE_LOGIN_CLIENT_ID;

- (void) setGoogleAccountWithUserId:(NSString *)userId
                               name:(NSString* )name
                              email:(NSString *)email;

+ (void) deleteGoogleAccountFromLocalStorage;
+ (NSString *) getGoogleAccountId;
+ (NSString *) getGoogleAccountName;
+ (NSString *) getGoogleAccountEmail;

@end
