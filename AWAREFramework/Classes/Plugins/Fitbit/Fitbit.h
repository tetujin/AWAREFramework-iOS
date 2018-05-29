//
//  Fitbit.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/01/15.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

extern NSInteger const AWARE_ALERT_FITBIT_MOVE_TO_LOGIN_PAGE;

@interface Fitbit : AWARESensor <AWARESensorDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate, UIAlertViewDelegate>

- (void) loginWithOAuth2WithClientId:(NSString *)clientId apiSecret:(NSString *)apiSecret;
- (void) refreshToken;
- (void) getData:(id)sender;
- (void) downloadTokensFromFitbitServer;
- (BOOL) handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

+ (void) setFitbitAccessToken:(NSString *)accessToken;
+ (void) setFitbitRefreshToken:(NSString *)refreshToken;
+ (void) setFitbitUserId:(NSString *)userId;
// + (void) setFibitTokenType:(NSString *)tokenType;
+ (void) setFitbitCode:(NSString *)code;
+ (void) setFitbitApiSecret:(NSString *) apiSecret;
+ (void) setFitbitClientId:(NSString *) clientId;
    
+ (NSString *) getFitbitAccessToken;
+ (NSString *) getFitbitRefreshToken;
+ (NSString *) getFitbitClientId;
+ (NSString *) getFitbitApiSecret;
+ (NSString *) getFitbitTokenType;
+ (NSString *) getFitbitCode;
+ (NSString *) getFitbitUserId;

+ (NSString *) getFitbitApiSecretForUI:(bool)forUI;
+ (NSString *) getFitbitClientIdForUI:(bool)forUI;

+ (void)clearAllSettings;

@end
