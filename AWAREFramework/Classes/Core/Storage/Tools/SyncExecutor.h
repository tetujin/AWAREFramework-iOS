//
//  SyncExecutor.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import <Foundation/Foundation.h>
#import "AWAREStudy.h"

@interface SyncExecutor : NSObject <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property int timeoutIntervalForRequest;
@property int HTTPMaximumConnectionsPerHost;
@property int timeoutIntervalForResource;

//@property (readonly, atomic, weak) NSURLSession* _Nullable session;
@property (readonly) NSURLSession* _Nullable session;
@property (readonly) NSURLSessionDataTask* _Nullable dataTask;

@property BOOL debug;

typedef void (^SyncExecutorCallback)(NSDictionary * _Nullable result);

@property SyncExecutorCallback _Nullable executorCallback;

- (instancetype _Nonnull ) initWithAwareStudy:(AWAREStudy * _Nonnull)study sensorName:(NSString * _Nonnull)name;
- (void)syncWithData:(NSData * _Nonnull)data callback:(SyncExecutorCallback _Nullable)callback;

- (BOOL) isSyncing;

@end
