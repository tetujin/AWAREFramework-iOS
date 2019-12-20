//
//  RemotePushNotificationManager.h
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/12/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PushNotificationProvider : NSObject  <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

typedef void (^PNPSessionCompletionHandler)(bool result, NSData * _Nullable data, NSError * _Nullable error);

@property (readonly) NSURLSession* _Nullable session;
@property (readonly) NSURLSessionDataTask* _Nullable dataTask;

- (void) registerToken:(NSString *)token
              deviceId:(NSString *)deviceId
             serverURL:(NSString *)url
            completion:(PNPSessionCompletionHandler _Nullable)completion;

- (void) unregisterTokenWithDeviceId:(NSString *)deviceId
                           serverURL:(NSURL *)url
                          completion:(PNPSessionCompletionHandler _Nullable)completion;
@end

NS_ASSUME_NONNULL_END
