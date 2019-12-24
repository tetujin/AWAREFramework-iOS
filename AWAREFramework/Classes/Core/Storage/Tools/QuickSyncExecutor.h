//
//  QuickSyncExecutorr.h
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/12/21.
//

#import <Foundation/Foundation.h>
#import "SyncExecutor.h"

NS_ASSUME_NONNULL_BEGIN

@interface QuickSyncExecutor : NSObject <AWARESyncExecutorDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@end

NS_ASSUME_NONNULL_END
