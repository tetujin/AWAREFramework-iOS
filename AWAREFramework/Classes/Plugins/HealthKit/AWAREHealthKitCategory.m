//
//  AWAREHealthKitCategory.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2016/12/21.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREHealthKitCategory.h"
#import "AWAREUtils.h"
#import "TCQMaker.h"

@implementation AWAREHealthKitCategory{
    NSString* KEY_DEVICE_ID;
    NSString* KEY_TIMESTAMP;
    NSString* KEY_DATA_TYPE;
    NSString* KEY_DATA_TYPE_ID;
    NSString* KEY_VALUE;
    NSString* KEY_UNIT;
    // NSString* KEY_START;
    NSString* KEY_END;
    NSString* KEY_DEVICE;
    NSString* KEY_LABLE;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:[NSString stringWithFormat:@"%@_category",SENSOR_HEALTH_KIT]
                        dbEntityName:nil
                              dbType:AwareDBTypeJSON];
    if(self){
        KEY_DEVICE_ID = @"device_id";
        KEY_TIMESTAMP =@"timestamp";
        KEY_DATA_TYPE_ID = @"type_id";
        KEY_DATA_TYPE = @"type";
        KEY_VALUE = @"value";
        KEY_UNIT = @"unit";
        // KEY_START = @"start";
        KEY_END = @"timestamp_end";
        KEY_DEVICE = @"device";
        KEY_LABLE = @"label";
    }
    return self;
}

- (void) createTable{
    // Send a table create query
    NSLog(@"[%@] create table!", [self getSensorName]);
    
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:KEY_END       type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:KEY_DATA_TYPE type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_VALUE     type:TCQTypeReal default:@"0"];
    // [tcqMaker addColumn:KEY_UNIT      type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_DEVICE    type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_LABLE     type:TCQTypeText default:@"''"];
    
    NSString *query = [tcqMaker getDefaudltTableCreateQuery];
    [super createTable:query];
}

- (void)saveCategoryData:(NSArray *)data{
//    for(HKCategorySample *sample in data)
//    {
//        // NSLog(@"%@", sample.debugDescription);
////        NSLog(@"%@", sample.startDate);
////        NSLog(@"%@", sample.endDate);
////        NSLog(@"%@", sample.sampleType);
////        NSLog(@"%@", sample.categoryType.identifier);
////        NSLog(@"%ld", sample.value);
//
//        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
//        [dict setObject:[AWAREUtils getUnixTimestamp:sample.startDate] forKey:KEY_TIMESTAMP];
//        [dict setObject:[AWAREUtils getUnixTimestamp:sample.endDate] forKey:KEY_END];
//        [dict setObject:[self getDeviceId] forKey:KEY_DEVICE_ID];
//        if(sample.sampleType != nil){
//            [dict setObject:sample.categoryType.identifier forKey:KEY_DATA_TYPE];
//        }else{
//            [dict setObject:@"" forKey:KEY_DATA_TYPE];
//        }
//        [dict setObject:@(sample.value) forKey:KEY_VALUE];
//        // [dict setObject:unit forKey:KEY_UNIT];
//        if(sample.device == nil){
//            [dict setObject:@"unknown" forKey:KEY_DEVICE];
//        }else{
//            [dict setObject:sample.device.model forKey:KEY_DEVICE];
//        }
//        [dict setObject:@"" forKey:KEY_LABLE];
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self saveData:dict];
//            [self setLatestData:dict];
//            NSString * message = [NSString stringWithFormat:@"[date:%@][type:%@][value:%ld]",
//                                  sample.startDate,
//                                  sample.categoryType,
//                                  sample.value];
//            NSLog(@"%@", message);
//            // [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
//            [self setLatestValue:message];
//        });
//    }
}

@end
