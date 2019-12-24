//
//  SyncExecutor.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import <Foundation/Foundation.h>
#import "AWAREStudy.h"

@protocol AWARESyncExecutorDelegate <NSObject>
NS_ASSUME_NONNULL_BEGIN
typedef void (^SyncExecutorCallback)(NSDictionary * _Nullable result);
@property SyncExecutorCallback _Nullable executorCallback;
@property (readonly) NSURLSession         * _Nullable session;
@property (readonly) NSURLSessionDataTask * _Nullable dataTask;
@property BOOL debug;
- (instancetype _Nonnull ) initWithAwareStudy:(AWAREStudy * _Nonnull)study sensorName:(NSString * _Nonnull)name;
- (void)syncWithData:(NSData * _Nonnull)data callback:(SyncExecutorCallback _Nullable)callback;
NS_ASSUME_NONNULL_END
@end

@interface SyncExecutor : NSObject <AWARESyncExecutorDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property int timeoutIntervalForRequest;
@property int maximumConnectionsPerHost;
@property int timeoutIntervalForResource;

- (BOOL) isSyncing;

@end
