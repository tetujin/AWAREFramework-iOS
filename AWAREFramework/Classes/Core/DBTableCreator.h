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

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                        sensorName:(NSString *)name
                      dbEntityName:(NSString *)entity;

- (void) createTable:(NSString*) query;
- (void) createTable:(NSString *)query withTableName:(NSString*) tableName;

@end
