//
//  PushNotificationResponder.h
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/12/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PushNotificationResponder : NSObject

- (void) responseWithPayload:(NSDictionary<NSString *, id> *) payload;

@property (nonnull) NSString * helpMessageTitle;
@property (nonnull) NSString * helpMessageBody;

@end


@interface AWARESilentPNPayload : NSObject

- (instancetype)initWithPayload:(NSDictionary<NSString *, id> * _Nonnull) payload;
@property (readonly) double version;
@property (readonly, nullable) NSArray <NSDictionary<NSString *, id> *> * operations;

@end

NS_ASSUME_NONNULL_END
