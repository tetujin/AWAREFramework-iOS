//
//  AWAREHealthKitWorkout.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2016/12/21.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREHealthKitWorkout.h"
#import "AWAREUtils.h"
#import "TCQMaker.h"

@implementation AWAREHealthKitWorkout{
    NSString* KEY_DEVICE_ID;
    NSString* KEY_TIMESTAMP;
    NSString* KEY_DATA_TYPE;
    NSString* KEY_DATA_TYPE_ID;
    NSString* KEY_VALUE;
    NSString* KEY_UNIT;
    NSString* KEY_END;
    NSString* KEY_DEVICE;
    NSString* KEY_LABLE;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = [[JSONStorage alloc] initWithStudy:study sensorName:[NSString stringWithFormat:@"%@_workout",SENSOR_HEALTH_KIT]];
    self = [super initWithAwareStudy:study
                          sensorName:[NSString stringWithFormat:@"%@_workout",SENSOR_HEALTH_KIT]
                             storage:storage];
    if(self){
        KEY_DEVICE_ID     = @"device_id";
        KEY_TIMESTAMP     = @"timestamp";
        KEY_DATA_TYPE_ID  = @"type_id";
        KEY_DATA_TYPE     = @"type";
        KEY_VALUE         = @"value";
        KEY_UNIT          = @"unit";
        KEY_END           = @"timestamp_end";
        KEY_DEVICE        = @"device";
        KEY_LABLE         = @"label";
    }
    return self;
}

- (void) createTable{
    if( self.isDebug ) NSLog(@"[%@] create table!", [self getSensorName]);
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

- (void) saveWorkoutData:(NSArray *)data{
    // https://developer.apple.com/reference/healthkit/hkworkout
    for(HKWorkout *sample in data) {
        NSLog(@"%@", sample.debugDescription);
        NSLog(@"%@", sample.startDate);
        NSLog(@"%@", sample.endDate);
        NSLog(@"%f", sample.duration);
        NSLog(@"%@", sample.totalDistance);
        NSLog(@"%@", sample.totalEnergyBurned);
        NSLog(@"%ld", sample.workoutActivityType);
        for(HKWorkoutEvent * event in sample.workoutEvents){
            NSLog(@"%@", event);
        }
    }
}

@end
