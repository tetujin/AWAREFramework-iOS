//
//  SampleSensor.m
//  AWAREFramework_Example
//
//  Created by Yuuki Nishiyama on 2018/05/21.
//  Copyright © 2018 tetujin. All rights reserved.
//

#import "SampleSensor.h"
#import "EntitySample+CoreDataClass.h"

@implementation SampleSensor{
    NSTimer * timer;
    int i;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    i = 0;
    storage = [[SQLiteStorage alloc] initWithStudy:study
                                        sensorName:@"sample_table"
                                        entityName:NSStringFromClass([EntitySample class])
                                         dbHandler:ExternalCoreDataHandler.sharedHandler
                                    insertCallBack:^(NSDictionary *dataDict, NSManagedObjectContext *childContext, NSString *entity) {
                                        
                                        EntitySample * entitySample = (EntitySample *)[NSEntityDescription
                                                                                                  insertNewObjectForEntityForName:entity
                                                                                                  inManagedObjectContext:childContext];
                                        entitySample.device_id = [self getDeviceId];
                                        entitySample.timestamp = [[dataDict objectForKey:@"timestamp"] doubleValue];
                                        entitySample.value = [[dataDict objectForKey:@"value"] intValue];
                                        entitySample.label = [dataDict objectForKey:@"label"];
    }];
    self = [super initWithAwareStudy:study sensorName:@"sample_table" storage:storage];
    if (self) {
        
    }
    
    return self;
}

- (void) createTable {
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:@"label" type:TCQTypeText default:@"''"];
    [maker addColumn:@"value" type:TCQTypeInteger default:@"0"];
    [self.storage createDBTableOnServerWithTCQMaker:maker];
}

- (BOOL)startSensor{
    timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
         // dispatch_async(dispatch_get_main_queue(), ^{
            i++;
            NSLog(@"%d", i);
            [self.storage saveDataWithDictionary:@{@"device_id":[self getDeviceId],
                                                   @"timestamp":@([NSDate new].timeIntervalSince1970*1000),
                                                   @"value":@(0),
                                                   @"label":@""}
                                          buffer:NO
                                saveInMainThread:YES];
        // });
    }];
    [timer fire];
    
    return YES;
}

- (BOOL)stopSensor{
    return YES;
}

@end
