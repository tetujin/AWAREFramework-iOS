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

@property (readonly, atomic, weak) NSURLSession* session;

@property BOOL debug;

typedef void (^SyncExecutorCallBack)(NSDictionary *result);

// - (NSURLSession *)getSessionWithSensorName:(NSString * )name;

- (instancetype) initWithAwareStudy:(AWAREStudy *)study sensorName:(NSString *)name;
- (void)syncWithData:(NSData *)data callback:(SyncExecutorCallBack)callback;

- (BOOL) isSyncing;

@end
