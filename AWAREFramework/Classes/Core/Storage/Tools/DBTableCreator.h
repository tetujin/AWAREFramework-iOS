//
//  DBTableCreator.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2018/03/12.
//  Copyright © 2018 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWAREStudy.h"

@interface DBTableCreator : NSObject <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

typedef void (^TableCreateCallBack)(bool result, NSData * data, NSError * error);

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                        sensorName:(NSString *)name;

- (void) createTable:(NSString*) query;
- (void) createTable:(NSString *)query withTableName:(NSString*) tableName;

- (void) setCallback:(TableCreateCallBack)callback;

@end
