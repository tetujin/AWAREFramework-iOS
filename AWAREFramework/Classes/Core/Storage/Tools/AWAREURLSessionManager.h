//
//  AWARESessionConfigManager.h
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2020/05/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWAREURLSessionManager : NSObject

+ (AWAREURLSessionManager * _Nonnull)shared;

- (void) addURLSession:(NSURLSession * _Nonnull)urlSession;
- (NSURLSession * _Nullable) getURLSession:(NSString * _Nonnull) sessionIdentifier;

@end

NS_ASSUME_NONNULL_END
