//
//  TCQMaker.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/3/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "TCQMaker.h"

@implementation TCQMaker{
    NSMutableString * query;
}

- (instancetype) init {
    self = [super init];
    if(self != nil){
        query = [[NSMutableString alloc] init];
        [query appendString:
            @"_id integer primary key autoincrement,"
            "timestamp real default 0,"
            "device_id text default ''" ];
    }
    return self;
}

- (BOOL) addColumn:(NSString *)header type:(TCQColumnType)columnType default:(NSString*) defaultValue {
    NSString * type = @"";
    switch (columnType) {
        case TCQTypeText:
            type = @"text";
            break;
        case TCQTypeInteger:
            type = @"integer";
            break;
        case TCQTypeReal:
            type = @"real";
            break;
        case TCQTypeBlob:
            type = @"blob";
            break;
        default:
            NSLog(@"Coulumn Type Error: Your selected type (%zd) is not valid.", columnType);
            return NO;
            break;
    }
    [query appendFormat:@",%@ %@ default %@", header, type, defaultValue];
    return YES;
}


- (NSString *) getTableCreateQueryWithUniques:(NSArray *)uniques{
    if(uniques != nil){
        NSMutableString * uniqueKeys = [[NSMutableString alloc] init];
        for (NSString * key in uniques) {
            [uniqueKeys appendFormat:@"%@,", key];
        }
        [uniqueKeys deleteCharactersInRange:NSMakeRange(uniqueKeys.length-1, 1)];
        [query appendFormat:@",UNIQUE (%@)", uniqueKeys];
    }
    return query;
}


- (NSString *) getDefaudltTableCreateQuery{
    // return [self getTableCreateQueryWithUniques:@[@"timestamp", @"device_id"]];
    return [self getTableCreateQueryWithUniques:nil];
}


//query = @"_id integer primary key autoincrement,"
//"timestamp real default 0,"
//"device_id text default '',"
//"double_values_0 real default 0,"
//"double_values_1 real default 0,"
//"double_values_2 real default 0,"
//"accuracy integer default 0,"
//"label text default ''"

@end
