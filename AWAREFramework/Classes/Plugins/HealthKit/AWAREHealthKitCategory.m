//
//  AWAREHealthKitCategory.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2016/12/21.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREHealthKitCategory.h"
#import "AWAREHealthKit.h"
#import "AWAREUtils.h"
#import "TCQMaker.h"
@import CoreData;

@implementation AWAREHealthKitCategory{
    NSString * KEY_DEVICE_ID;
    NSString * KEY_TIMESTAMP;
    NSString * KEY_DATA_TYPE;
    NSString * KEY_VALUE;
    NSString * KEY_UNIT;
    NSString * KEY_METADATA;
    NSString * KEY_START;
    NSString * KEY_END;
    NSString * KEY_DEVICE;
    NSString * KEY_SOURCE;
    NSString * KEY_LABLE;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    NSString * sensorName = [NSString stringWithFormat:@"%@_category", SENSOR_HEALTH_KIT];
    NSString * entityName = @"EntityHealthKitCategory";
    return [self initWithAwareStudy:study
                             dbType:dbType
                         sensorName:sensorName entityName:entityName];
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                            dbType:(AwareDBType)dbType
                        sensorName:(NSString *)sensorName
                        entityName:(NSString *)entityName{
    
    AWAREStorage * storage = nil;
    
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:sensorName];
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
        KEY_END       = @"timestamp_end";
        KEY_START     = @"timestamp_start";
        KEY_DEVICE    = @"device";
        KEY_METADATA  = @"metadata";
        KEY_SOURCE    = @"source";
        KEY_LABLE     = @"label";
    }
    return self;
}

- (void) createTable {
    if (self.isDebug) { NSLog(@"[%@] create table!", self.getSensorName); }
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:KEY_START     type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:KEY_END       type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:KEY_DATA_TYPE type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_VALUE     type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:KEY_DEVICE    type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_METADATA  type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_SOURCE    type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_LABLE     type:TCQTypeText default:@"''"];
    [self.storage createDBTableOnServerWithQuery:[tcqMaker getDefaudltTableCreateQuery]];
}

- (void) saveCategoryData:(NSArray <HKCategorySample *> * _Nonnull) data {
    if (data.count == 0) {
        return;
    } else {
        NSMutableArray * buffer = [[NSMutableArray alloc] init];
        
        for(HKCategorySample * sample in data){
            
            NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
            
            [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_TIMESTAMP];
            /// start
            [dict setObject:[AWAREUtils getUnixTimestamp:sample.startDate] forKey:KEY_START];
            /// end
            [dict setObject:[AWAREUtils getUnixTimestamp:sample.endDate]   forKey:KEY_END];
            /// device_id
            [dict setObject:[self getDeviceId] forKey:KEY_DEVICE_ID];
            
            /// data type
            if(sample.sampleType != nil){
                [dict setObject:sample.categoryType.identifier forKey:KEY_DATA_TYPE];
            }else{
                [dict setObject:@"" forKey:KEY_DATA_TYPE];
            }
            
            /// value
            [dict setObject:@(sample.value) forKey:KEY_VALUE];
            
            /// device
            if(sample.device == nil){
                [dict setObject:@"unknown" forKey:KEY_DEVICE];
            }else{
                [dict setObject:sample.device.description forKey:KEY_DEVICE];
            }
            
            /// metadata
            [dict setObject:@"" forKey:KEY_METADATA];
            if (sample.metadata != nil) {
                NSError * e = nil;
                NSData * md = [NSJSONSerialization dataWithJSONObject:sample.metadata
                                                              options:NSJSONWritingPrettyPrinted
                                                                error:&e];
                if(e != nil){
                    if (self.isDebug) NSLog(@"%@", e.debugDescription);
                }else{
                    NSString * medataStr = [[NSString alloc] initWithData:md
                                                                 encoding:NSUTF8StringEncoding];
                    if (medataStr != nil){
                        [dict setObject:medataStr forKey:KEY_METADATA];
                    }
                }
            }
            
            /// source
            [dict setObject:@"" forKey:KEY_SOURCE];
            if (sample.sourceRevision != nil) {
                NSMutableDictionary * sourceDict = [[NSMutableDictionary alloc] init];
                // sample.sourceRevision.operatingSystemVersion.majorVersion
                [sourceDict setObject:@"" forKey:@"productType"];
                if (@available(iOS 11.0, *)) {
                    NSString * pt = sample.sourceRevision.productType;
                    if (pt != nil) [sourceDict setObject:pt forKey:@"productType"];
                }
                [sourceDict setObject:sample.sourceRevision.source.name forKey:@"name"];
                [sourceDict setObject:sample.sourceRevision.source.bundleIdentifier forKey:@"bundleId"];
                NSError * e  = nil;
                NSData  * sd = [NSJSONSerialization dataWithJSONObject:sourceDict
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:&e];
                NSString * ss = [[NSString alloc] initWithData:sd encoding:NSUTF8StringEncoding];
                [dict setObject:ss forKey:KEY_SOURCE];
            }
            
            // label
            [dict setObject:@"" forKey:KEY_LABLE];
            
            [buffer addObject:dict];
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.storage saveDataWithArray:buffer buffer:NO saveInMainThread:NO];
            
            if (buffer.count > 0) {
                NSDictionary * sample = buffer.lastObject;
                NSString * message = [NSString stringWithFormat:@"[date:%@][type:%@][value:%@]",
                                      sample[self->KEY_TIMESTAMP],
                                      sample[self->KEY_DATA_TYPE],
                                      sample[self->KEY_VALUE]];
                [self setLatestValue:message];
                [self setLatestData:sample];
            }
        });
        
        
    }
}

@end
