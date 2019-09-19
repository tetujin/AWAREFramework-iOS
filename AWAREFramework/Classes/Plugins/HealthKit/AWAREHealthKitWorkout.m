//
//  AWAREHealthKitWorkout.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2016/12/21.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
// Edit

#import "AWAREHealthKitWorkout.h"
#import "AWAREUtils.h"
#import "TCQMaker.h"

@import CoreData;

@implementation AWAREHealthKitWorkout{
    NSString* KEY_DEVICE_ID;
    NSString* KEY_TIMESTAMP;
    NSString* KEY_START;
    NSString* KEY_END;
    NSString* KEY_DEVICE;
    NSString* KEY_LABLE;
    NSString* KEY_WORKOUT_ACTIVITY_TYPE;
    NSString* KEY_WORKOUT_ACTIVITY_TYPE_NAME;
    NSString* KEY_DURATION;
    NSString* KEY_TOTAL_DISTANCE ;
    NSString* KEY_TOTAL_ENERGY_BURNED ;
    NSString* KEY_METADATA;
    NSString* KEY_EVENTS;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    NSString * storageName = [NSString stringWithFormat:@"%@_workout",SENSOR_HEALTH_KIT];
    
    AWAREStorage * storage = nil;
     if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study
                                          sensorName:storageName];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study
                                            sensorName:storageName
                                            entityName:@"EntityHealthKitWorkout"
                                        insertCallBack:^(NSDictionary *data,
                                                         NSManagedObjectContext *childContext,
                                                         NSString *entityName) {
                                            NSManagedObject * entity = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                                                     inManagedObjectContext:childContext];
                                            [entity setValuesForKeysWithDictionary:data];
                                        }];
    }

    self = [super initWithAwareStudy:study sensorName:storageName storage:storage];
    if(self){
        KEY_DEVICE_ID     = @"device_id";
        KEY_TIMESTAMP     = @"timestamp";
        KEY_START         = @"timestamp_start";
        KEY_END           = @"timestamp_end";
        
        KEY_WORKOUT_ACTIVITY_TYPE   = @"activity_type";
        KEY_WORKOUT_ACTIVITY_TYPE_NAME = @"activity_type_name";
        KEY_DURATION       = @"duration";
        KEY_TOTAL_DISTANCE = @"total_distance";
        KEY_TOTAL_ENERGY_BURNED = @"total_energy_burned";
        KEY_METADATA      = @"metadata";
        KEY_EVENTS        = @"events";
        
        KEY_DEVICE        = @"device";
        KEY_LABLE         = @"label";
    }
    return self;
}

- (void) createTable{
    if( self.isDebug ) NSLog(@"[%@] create table!", [self getSensorName]);
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:KEY_START       type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:KEY_END         type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:KEY_WORKOUT_ACTIVITY_TYPE      type:TCQTypeInteger default:@"0"];
    [tcqMaker addColumn:KEY_WORKOUT_ACTIVITY_TYPE_NAME type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_DURATION    type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:KEY_TOTAL_DISTANCE             type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:KEY_TOTAL_ENERGY_BURNED type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:KEY_METADATA    type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_EVENTS      type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_DEVICE      type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:KEY_LABLE       type:TCQTypeText default:@"''"];
    NSString *query = [tcqMaker getDefaudltTableCreateQuery];
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void) saveWorkoutData:(NSArray <HKWorkout *> * _Nonnull)data{
    // https://developer.apple.com/reference/healthkit/hkworkout
    for(HKWorkout *sample in data) {
        
        NSMutableDictionary * data = [[NSMutableDictionary alloc] init];
        
        [data setValue:[self getDeviceId] forKey:KEY_DEVICE_ID];
        [data setValue:[AWAREUtils getUnixTimestamp:[NSDate new]]     forKey:KEY_TIMESTAMP];
        [data setValue:[AWAREUtils getUnixTimestamp:sample.startDate] forKey:KEY_START];
        [data setValue:[AWAREUtils getUnixTimestamp:sample.endDate]   forKey:KEY_END];
        if (sample.device != nil && sample.device.model != nil) {
            [data setValue:sample.device.description forKey:KEY_DEVICE];
        }
        [data setValue:@(sample.duration) forKey:KEY_DURATION];
        if (sample.totalDistance != nil) {
            [data setValue:@([sample.totalDistance doubleValueForUnit:[HKUnit meterUnit]])
                    forKey:KEY_TOTAL_DISTANCE];
        }
        if (sample.totalEnergyBurned != nil) {
            [data setValue:@([sample.totalEnergyBurned doubleValueForUnit:[HKUnit kilocalorieUnit]])
                    forKey:KEY_TOTAL_ENERGY_BURNED];
        }
        [data setValue:@(sample.workoutActivityType)
                forKey:KEY_WORKOUT_ACTIVITY_TYPE];
        [data setValue:[self getWorkoutActivityTypeAsString:sample.workoutActivityType]
                forKey:KEY_WORKOUT_ACTIVITY_TYPE_NAME];
        NSMutableDictionary * metadata = [[NSMutableDictionary alloc] init];
        if (sample.metadata != nil) {
            for (NSString * key in sample.metadata) {
                // NSLog(@"%@:%@",key, [sample.metadata objectForKey:key] );
                NSObject * value = [sample.metadata objectForKey:key];
                [metadata setValue:value.description forKey:key];

            }
        }
        NSError * error = nil;
        NSData * json = [NSJSONSerialization dataWithJSONObject:metadata
                                                        options:0
                                                          error:&error];
        if (error != nil) {
            NSLog(@"[%@] %@", [self getSensorName], error.debugDescription);
        }else{
            if (json!=nil) {
                NSString * jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
                if (jsonString != nil) {
                    [data setValue:jsonString forKey:KEY_METADATA];
                }
            }
        }
        
        if (self.storage != nil){
            [self.storage saveDataWithDictionary:data buffer:NO saveInMainThread:YES];
        }
    }
}

- (NSString * _Nonnull) getWorkoutEventTypeAsString:(HKWorkoutEventType) type{
    switch (type) {
        case HKWorkoutEventTypePause:
            return @"pause";
        case HKWorkoutEventTypeResume:
            return @"resume";
        case HKWorkoutEventTypeLap:
            return @"lap";
        case HKWorkoutEventTypeMarker:
            return @"marker";
        case HKWorkoutEventTypeMotionPaused:
            return @"motion_paused";
        case HKWorkoutEventTypeMotionResumed:
            return @"motion_resumed";
        case HKWorkoutEventTypeSegment:
            return @"segment";
        default:
            return @"unknown";
    }
}

- (NSString * _Nonnull) getWorkoutActivityTypeAsString:(HKWorkoutActivityType) type {
    switch (type) {
        case HKWorkoutActivityTypeRunning:
            return @"running";
        case HKWorkoutActivityTypeGolf:
            return @"golf";
        case HKWorkoutActivityTypeHiking:
            return @"hiking";
        case HKWorkoutActivityTypeDance:
            return @"dance";
        case HKWorkoutActivityTypeYoga:
            return @"yoga";
        case HKWorkoutActivityTypeSoccer:
            return @"soccer";
        case HKWorkoutActivityTypeRowing:
            return @"rowing";
        case HKWorkoutActivityTypeTennis:
            return @"tennis";
        case HKWorkoutActivityTypeStairs:
            return @"stairs";
        case HKWorkoutActivityTypeBowling:
            return @"bowling";
        case HKWorkoutActivityTypeCycling:
            return @"cycling";
        case HKWorkoutActivityTypeFishing:
            return @"fishing";
        case HKWorkoutActivityTypeWalking:
            return @"walking";
        case HKWorkoutActivityTypePilates:
            return @"pilates";
        case HKWorkoutActivityTypeBaseball:
            return @"baseball";
        case HKWorkoutActivityTypeBadminton:
            return @"badminton";
        case HKWorkoutActivityTypeGymnastics:
            return @"gymnastics";
        case HKWorkoutActivityTypeSwimming:
            return @"swimming";
        case HKWorkoutActivityTypeBasketball:
            return @"basketball";
        case HKWorkoutActivityTypeSnowSports:
            return @"snow_sports";
        case HKWorkoutActivityTypeHandCycling:
            return @"hand_cycling";
        case HKWorkoutActivityTypeTableTennis:
            return @"table_tennis";
        case HKWorkoutActivityTypeCoreTraining:
            return @"core_training";
        case HKWorkoutActivityTypeSnowboarding:
            return @"snowboarding";
        case HKWorkoutActivityTypeStepTraining:
            return @"step_training";
        case HKWorkoutActivityTypeOther:
            return @"other";
        default:
            return @"---";
    }
}

//typedef NS_ENUM(NSUInteger, HKWorkoutActivityType) {
//    HKWorkoutActivityTypeAmericanFootball = 1,
//    HKWorkoutActivityTypeArchery,
//    HKWorkoutActivityTypeAustralianFootball,
//    HKWorkoutActivityTypeBadminton,
//    HKWorkoutActivityTypeBaseball,
//    HKWorkoutActivityTypeBasketball,
//    HKWorkoutActivityTypeBowling,
//    HKWorkoutActivityTypeBoxing, // See also HKWorkoutActivityTypeKickboxing.
//    HKWorkoutActivityTypeClimbing,
//    HKWorkoutActivityTypeCricket,
//    HKWorkoutActivityTypeCrossTraining, // Any mix of cardio and/or strength training. See also HKWorkoutActivityTypeCoreTraining and HKWorkoutActivityTypeFlexibility.
//    HKWorkoutActivityTypeCurling,
//    HKWorkoutActivityTypeCycling,
//    HKWorkoutActivityTypeDance,
//    HKWorkoutActivityTypeDanceInspiredTraining API_DEPRECATED("Use HKWorkoutActivityTypeDance, HKWorkoutActivityTypeBarre or HKWorkoutActivityTypePilates", ios(8.0, 10.0), watchos(2.0, 3.0)), // This enum remains available to access older data.
//    HKWorkoutActivityTypeElliptical,
//    HKWorkoutActivityTypeEquestrianSports, // Polo, Horse Racing, Horse Riding, etc.
//    HKWorkoutActivityTypeFencing,
//    HKWorkoutActivityTypeFishing,
//    HKWorkoutActivityTypeFunctionalStrengthTraining, // Primarily free weights and/or body weight and/or accessories
//    HKWorkoutActivityTypeGolf,
//    HKWorkoutActivityTypeGymnastics,
//    HKWorkoutActivityTypeHandball,
//    HKWorkoutActivityTypeHiking,
//    HKWorkoutActivityTypeHockey, // Ice Hockey, Field Hockey, etc.
//    HKWorkoutActivityTypeHunting,
//    HKWorkoutActivityTypeLacrosse,
//    HKWorkoutActivityTypeMartialArts,
//    HKWorkoutActivityTypeMindAndBody, // Qigong, meditation, etc.
//    HKWorkoutActivityTypeMixedMetabolicCardioTraining API_DEPRECATED("Use HKWorkoutActivityTypeMixedCardio or HKWorkoutActivityTypeHighIntensityIntervalTraining", ios(8.0, 11.0), watchos(2.0, 4.0)), // This enum remains available to access older data.
//    HKWorkoutActivityTypePaddleSports, // Canoeing, Kayaking, Outrigger, Stand Up Paddle Board, etc.
//    HKWorkoutActivityTypePlay, // Dodge Ball, Hopscotch, Tetherball, Jungle Gym, etc.
//    HKWorkoutActivityTypePreparationAndRecovery, // Foam rolling, stretching, etc.
//    HKWorkoutActivityTypeRacquetball,
//    HKWorkoutActivityTypeRowing,
//    HKWorkoutActivityTypeRugby,
//    HKWorkoutActivityTypeRunning,
//    HKWorkoutActivityTypeSailing,
//    HKWorkoutActivityTypeSkatingSports, // Ice Skating, Speed Skating, Inline Skating, Skateboarding, etc.
//    HKWorkoutActivityTypeSnowSports, // Sledding, Snowmobiling, Building a Snowman, etc. See also HKWorkoutActivityTypeCrossCountrySkiing, HKWorkoutActivityTypeSnowboarding, and HKWorkoutActivityTypeDownhillSkiing.
//    HKWorkoutActivityTypeSoccer,
//    HKWorkoutActivityTypeSoftball,
//    HKWorkoutActivityTypeSquash,
//    HKWorkoutActivityTypeStairClimbing, // See also HKWorkoutActivityTypeStairs and HKWorkoutActivityTypeStepTraining.
//    HKWorkoutActivityTypeSurfingSports, // Traditional Surfing, Kite Surfing, Wind Surfing, etc.
//    HKWorkoutActivityTypeSwimming,
//    HKWorkoutActivityTypeTableTennis,
//    HKWorkoutActivityTypeTennis,
//    HKWorkoutActivityTypeTrackAndField, // Shot Put, Javelin, Pole Vaulting, etc.
//    HKWorkoutActivityTypeTraditionalStrengthTraining, // Primarily machines and/or free weights
//    HKWorkoutActivityTypeVolleyball,
//    HKWorkoutActivityTypeWalking,
//    HKWorkoutActivityTypeWaterFitness,
//    HKWorkoutActivityTypeWaterPolo,
//    HKWorkoutActivityTypeWaterSports, // Water Skiing, Wake Boarding, etc.
//    HKWorkoutActivityTypeWrestling,
//    HKWorkoutActivityTypeYoga,
//
//    HKWorkoutActivityTypeBarre              API_AVAILABLE(ios(10.0), watchos(3.0)),    // HKWorkoutActivityTypeDanceInspiredTraining
//    HKWorkoutActivityTypeCoreTraining       API_AVAILABLE(ios(10.0), watchos(3.0)),
//    HKWorkoutActivityTypeCrossCountrySkiing API_AVAILABLE(ios(10.0), watchos(3.0)),
//    HKWorkoutActivityTypeDownhillSkiing     API_AVAILABLE(ios(10.0), watchos(3.0)),
//    HKWorkoutActivityTypeFlexibility        API_AVAILABLE(ios(10.0), watchos(3.0)),
//    HKWorkoutActivityTypeHighIntensityIntervalTraining    API_AVAILABLE(ios(10.0), watchos(3.0)),
//    HKWorkoutActivityTypeJumpRope           API_AVAILABLE(ios(10.0), watchos(3.0)),
//    HKWorkoutActivityTypeKickboxing         API_AVAILABLE(ios(10.0), watchos(3.0)),
//    HKWorkoutActivityTypePilates            API_AVAILABLE(ios(10.0), watchos(3.0)),    // HKWorkoutActivityTypeDanceInspiredTraining
//    HKWorkoutActivityTypeSnowboarding       API_AVAILABLE(ios(10.0), watchos(3.0)),
//    HKWorkoutActivityTypeStairs             API_AVAILABLE(ios(10.0), watchos(3.0)),
//    HKWorkoutActivityTypeStepTraining       API_AVAILABLE(ios(10.0), watchos(3.0)),
//    HKWorkoutActivityTypeWheelchairWalkPace API_AVAILABLE(ios(10.0), watchos(3.0)),
//    HKWorkoutActivityTypeWheelchairRunPace  API_AVAILABLE(ios(10.0), watchos(3.0)),
//    HKWorkoutActivityTypeTaiChi             API_AVAILABLE(ios(11.0), watchos(4.0)),
//    HKWorkoutActivityTypeMixedCardio        API_AVAILABLE(ios(11.0), watchos(4.0)),    // HKWorkoutActivityTypeMixedMetabolicCardioTraining
//    HKWorkoutActivityTypeHandCycling        API_AVAILABLE(ios(11.0), watchos(4.0)),
//
//    HKWorkoutActivityTypeOther = 3000,
//} API_AVAILABLE(ios(8.0), watchos(2.0));

@end
