//
//  Fitbit.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/01/15.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

extern NSString * _Nonnull const AWARE_PREFERENCES_STATUS_FITBIT;

extern NSInteger const AWARE_ALERT_FITBIT_MOVE_TO_LOGIN_PAGE;

@interface Fitbit : AWARESensor <AWARESensorDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

NS_ASSUME_NONNULL_BEGIN

@property (nullable) UIViewController * viewController;

- (void) loginWithOAuth2WithClientId:(NSString *)clientId apiSecret:(NSString *)apiSecret;
- (void) refreshToken;
- (void) getData:(id)sender;
- (void) downloadTokensFromFitbitServer;
- (BOOL) handleURL:(NSURL * _Nullable)url sourceApplication:(NSString * _Nullable)sourceApplication annotation:(id _Nullable)annotation;

typedef void (^FitbitLoginCompletionHandler) (NSDictionary <NSString * , id > * _Nonnull tokens);
- (void) requestLoginWithUIViewController:(UIViewController * _Nullable) viewController completion:(FitbitLoginCompletionHandler _Nullable)handler;
+ (bool) isNeedLogin;

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

NS_ASSUME_NONNULL_END

@end
