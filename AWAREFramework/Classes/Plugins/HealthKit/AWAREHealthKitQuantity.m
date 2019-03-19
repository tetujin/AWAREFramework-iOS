//
//  AWAREHealthKitQuantity.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2016/12/21.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <HealthKit/HealthKit.h>

#import "AWAREHealthKitQuantity.h"
#import "AWAREUtils.h"
#import "TCQMaker.h"
#import "AWAREHealthKit.h"

@import CoreData;

@implementation AWAREHealthKitQuantity{
    NSString * KEY_DEVICE_ID;
    NSString * KEY_TIMESTAMP;
    NSString * KEY_DATA_TYPE;
    NSString * KEY_VALUE;
    NSString * KEY_UNIT;
    NSString * KEY_END;
    NSString * KEY_DEVICE;
    NSString * KEY_LABLE;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    NSString * sensorName = [NSString stringWithFormat:@"%@_quantity",SENSOR_HEALTH_KIT];
    NSString * entityName = @"EntityHealthKitQuantity";
    return [self initWithAwareStudy:study dbType:dbType
                         sensorName:sensorName
                         entityName:entityName];
}

-  (instancetype)initWithAwareStudy:(AWAREStudy *)study
                             dbType:(AwareDBType)dbType
                         sensorName:(NSString *)sensorName
                         entityName:(NSString *)entityName{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study
                                          sensorName:sensorName];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study
                                            sensorName:sensorName
                                            entityName:entityName
                                        insertCallBack:^(NSDictionary *data,
                                                         NSManagedObjectContext *childContext,
                                                         NSString *entityName) {
                                            NSManagedObject * entity = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                                                     inManagedObjectContext:childContext];
                                            [entity setValuesForKeysWithDictionary:data];
                                        }];
    }
    self = [super initWithAwareStudy:study sensorName:sensorName storage:storage];
    
    if(self){
        KEY_DEVICE_ID = @"device_id";
        KEY_TIMESTAMP = @"timestamp";
        KEY_DATA_TYPE = @"type";
        KEY_VALUE     = @"value";
        KEY_UNIT      = @"unit";
        KEY_END       = @"timestamp_end";
        KEY_DEVICE    = @"device";
        KEY_LABLE     = @"label";
    }
    return self;
}

- (void) createTable{
    if (self.isDebug) NSLog(@"[%@] create table!", [self getSensorName]);
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:KEY_END       type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:KEY_DATA_TYPE type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_VALUE     type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:KEY_UNIT      type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_DEVICE    type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_LABLE     type:TCQTypeText default:@"''"];
    NSString *query = [tcqMaker getDefaudltTableCreateQuery];
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void)saveQuantityData:(NSArray <HKQuantitySample *> * _Nonnull) data {
    
    if (data.count == 0) {
        return;
    } else {
        NSMutableArray * buffer = [[NSMutableArray alloc] init];
        
        HKQuantitySample * sample = data.firstObject;
        NSDate * lastFetchDate = [AWAREHealthKit getLastFetchDataWithDataType:sample.sampleType.identifier];
        if (lastFetchDate==nil) {
            lastFetchDate = [NSDate dateWithTimeIntervalSince1970:-1*60*60*24];
        }
        
        for(HKQuantitySample * sample in data) {
            HKSampleType     * type = sample.sampleType;
            if([self isDebug]) NSLog(@"%@",type);
            
            if (sample.startDate.timeIntervalSince1970 > lastFetchDate.timeIntervalSince1970) {
                NSMutableString * quantityStr = [[NSMutableString alloc] initWithString:[sample.quantity description]];
                NSArray  * array = [quantityStr componentsSeparatedByString:@" "];
                NSString * unit  = @"";
                
                NSNumber * value = @0;
                if (array.count > 1) {
                    if(array[0] != nil) value = @([array[0] doubleValue]);
                    if(array[1] != nil) unit  = array[1];
                }
                
                NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
                [dict setObject:[AWAREUtils getUnixTimestamp:sample.startDate] forKey:KEY_TIMESTAMP];
                [dict setObject:[AWAREUtils getUnixTimestamp:sample.endDate]   forKey:KEY_END];
                [dict setObject:[self getDeviceId] forKey:KEY_DEVICE_ID];
                [dict setObject:type.identifier    forKey:KEY_DATA_TYPE];
                [dict setObject:value forKey:KEY_VALUE];
                [dict setObject:unit  forKey:KEY_UNIT];
                if(sample.device == nil){
                    [dict setObject:@"unknown" forKey:KEY_DEVICE];
                }else{
                    [dict setObject:sample.device.model forKey:KEY_DEVICE];
                }
                [dict setObject:@"" forKey:KEY_LABLE];
                [buffer addObject:dict];
                
                // save the last fetch timestamp with a identifier
                if (sample.endDate != nil && type.identifier != nil) {
                    [AWAREHealthKit setLastFetchData:sample.endDate
                                        withDataType:type.identifier];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.storage saveDataWithArray:buffer buffer:NO saveInMainThread:NO];
            if (buffer.count > 0) {
                NSDictionary * lastObj = buffer.lastObject;
                [self setLatestData:lastObj];
                NSString * message = [NSString stringWithFormat:@"[date:%@][type:%@][value:%@][unit:%@]",
                                      lastObj[self->KEY_TIMESTAMP],
                                      lastObj[self->KEY_DATA_TYPE],
                                      lastObj[self->KEY_VALUE],
                                      lastObj[self->KEY_UNIT]];
                [self setLatestValue:message];
            }
        });
        
    }
}

@end
