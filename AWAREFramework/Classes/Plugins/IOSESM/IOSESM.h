//
//  IOSESM.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 10/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "EntityESMSchedule+CoreDataClass.h"

@interface IOSESM : AWARESensor <AWARESensorDelegate, NSURLSessionDelegate>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const AWARE_PREFERENCES_STATUS_PLUGIN_IOS_ESM;
extern NSString * const AWARE_PREFERENCES_PLUGIN_IOS_ESM_TABLE_NAME;
extern NSString * const AWARE_PREFERENCES_PLUGIN_IOS_ESM_CONFIG_URL;

@property NSString * url;
@property NSString * table;

- (void) setViewController:(UIViewController *) vc;

typedef void (^ESMConfigurationSetupCompleteHandler)(void);
typedef void (^ESMConfigurationSetupErrorHandler)(NSError *  _Nullable error);

- (BOOL) startSensorWithURL:(NSString *)urlStr;
- (BOOL) startSensorWithURL:(NSString *)urlStr completionHandler:(ESMConfigurationSetupCompleteHandler _Nullable)handler;
- (void) setErrorHandler:(ESMConfigurationSetupErrorHandler _Nullable)handler;

+ (BOOL) hasESMAppearedInThisSession;
+ (void) setESMAppearedState:(BOOL)state;

NS_ASSUME_NONNULL_END

@end
