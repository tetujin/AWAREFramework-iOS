//
//  AWAREHealthKitQuantity.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2016/12/21.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREHealthKitQuantity.h"
#import "AWAREUtils.h"
#import "TCQMaker.h"

@implementation AWAREHealthKitQuantity{
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
                          sensorName:[NSString stringWithFormat:@"%@_quantity",SENSOR_HEALTH_KIT]
                        dbEntityName:nil
                              dbType:AwareDBTypeTextFile];
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
    [tcqMaker addColumn:KEY_UNIT      type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_DEVICE    type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_LABLE     type:TCQTypeText default:@"''"];
    
    NSString *query = [tcqMaker getDefaudltTableCreateQuery];
    [super createTable:query];
}

- (void)saveQuantityData:(NSArray *)data{
//    for(HKQuantitySample *samples in data)
//    {
//        HKSampleType * type = samples.sampleType;
//        if([self isDebug]) NSLog(@"%@",type);
//
//        NSMutableString * quantityStr = [[NSMutableString alloc] initWithString:[samples.quantity description]];
//        NSArray * array = [quantityStr componentsSeparatedByString:@" "];
//        NSNumber * value = @0;
//        NSString * unit = @"";
//        if (array.count > 1) {
//            if(array[0] != nil){
//                value = @([array[0] doubleValue]);
//            }
//            if(array[1] != nil){
//                unit = array[1];
//            }
//        }
//
//        // NSLog(@"%@", samples.device.model);
//        // NSLog(@"%@", samples.device.name);
//        // NSLog(@"%@", samples.device.hardwareVersion);
//        // NSLog(@"%@", samples.device.firmwareVersion);
//        // NSLog(@"%@", samples.device.manufacturer);
//        // NSLog(@"%@", samples.device.softwareVersion);
//
//        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
//        [dict setObject:[AWAREUtils getUnixTimestamp:samples.startDate] forKey:KEY_TIMESTAMP];
//        [dict setObject:[AWAREUtils getUnixTimestamp:samples.endDate] forKey:KEY_END];
//        [dict setObject:[self getDeviceId] forKey:KEY_DEVICE_ID];
//        [dict setObject:type.identifier forKey:KEY_DATA_TYPE];
//        [dict setObject:value forKey:KEY_VALUE];
//        [dict setObject:unit forKey:KEY_UNIT];
//        if(samples.device == nil){
//            [dict setObject:@"unknown" forKey:KEY_DEVICE];
//        }else{
//            [dict setObject:samples.device.model forKey:KEY_DEVICE];
//        }
//        [dict setObject:@"" forKey:KEY_LABLE];
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self saveData:dict];
//            [self setLatestData:dict];
//            NSString * message = [NSString stringWithFormat:@"[date:%@][type:%@][value:%@][unit:%@]",samples.startDate,type,value,unit];
//            [self setLatestValue:message];
//        });
//    }
}

@end
