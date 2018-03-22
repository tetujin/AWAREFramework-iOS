//
//  SQLiteSyncExecutor.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2018/03/12.
//  Copyright © 2018 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWAREUploader.h"
#import "AWAREStudy.h"
#import <CoreData/CoreData.h>

@interface SQLiteSyncExecutor: NSObject <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property NSManagedObjectContext *mainQueueManagedObjectContext;
@property NSManagedObjectContext *writeQueueManagedObjectContext;

- (instancetype) initWithAwareStudy:(AWAREStudy *)study sensorName:(NSString *)name dbEntityName:(NSString *)entity;

- (void)sync:(NSString *)name fource:(bool)fource;

- (bool)isUploading;

- (void) cancelSyncProcess;

- (void) resetMark;

@end

