//
//  TCQMaker.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/3/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum: NSInteger {
    TCQTypeText = 0,
    TCQTypeInteger = 1,
    TCQTypeReal = 2,
    TCQTypeBlob = 3
} TCQColumnType;

@interface TCQMaker : NSObject


- (BOOL) addColumn:(NSString *)header type:(TCQColumnType)columnType default:(NSString*) defaultValue;
- (NSString *) getDefaudltTableCreateQuery;
- (NSString *) getTableCreateQueryWithUniques:(NSArray *)uniques;

@end
