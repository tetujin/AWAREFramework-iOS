//
//  Steps.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/31/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
// http://pinkstone.co.uk/how-to-access-the-step-counter-and-pedometer-data-in-ios-9/
//

#import "Pedometer.h"
#import "AWAREKeys.h"
#import "TCQMaker.h"
#import "EntityIOSPedometer+CoreDataClass.h"

NSString * const AWARE_PREFERENCES_STATUS_PEDOMETER    = @"status_ios_pedometer";
NSString * const AWARE_PREFERENCES_FREQUENCY_PEDOMETER = @"frequency_ios_pedometer";

@implementation Pedometer {
    NSString* KEY_DEVICE_ID;
    NSString* KEY_TIMESTAMP; //begin
    NSString* KEY_END_TIMESTAMP; //end
    NSString* KEY_FREQUENCY_SECOND;
    NSString* KEY_NUMBER_OF_STEPS;
    NSString* KEY_DISTANCE;
    NSString* KEY_CURRENT_PACE;
    NSString* KEY_CURRENT_CADENCE;
    NSString* KEY_FLOORS_ASCENDED;
    NSString* KEY_FLOORS_DESCENDED;
    
    NSString * KEY_TIMESTAMP_OF_LAST_UPDATE;
    
    NSDate * lastUpdate;
    
    NSTimer * timer;
    
    int frequencySec;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    
    KEY_DEVICE_ID        = @"device_id";
    KEY_TIMESTAMP        = @"timestamp";
    KEY_END_TIMESTAMP    = @"end_timestamp";
    KEY_FREQUENCY_SECOND = @"frequency_second";
    KEY_NUMBER_OF_STEPS  = @"number_of_steps";
    KEY_DISTANCE         = @"distance";
    KEY_CURRENT_PACE     = @"current_pace";
    KEY_CURRENT_CADENCE  = @"current_cadence";
    KEY_FLOORS_ASCENDED  = @"floors_ascended";
    KEY_FLOORS_DESCENDED = @"floors_descended";
    
    KEY_TIMESTAMP_OF_LAST_UPDATE = @"key_plugin_sensor_pedometer_last_update_timestamp";
    
    AWAREStorage * storage = nil;
    if(dbType == AwareDBTypeCSV){
        NSArray * header = @[KEY_DEVICE_ID,
                             KEY_TIMESTAMP,
                             KEY_END_TIMESTAMP,
                             KEY_FREQUENCY_SECOND,
                             KEY_NUMBER_OF_STEPS,
                             KEY_DISTANCE,
                             KEY_CURRENT_PACE,
                             KEY_CURRENT_CADENCE,
                             KEY_FLOORS_ASCENDED,
                             KEY_FLOORS_DESCENDED];
        NSArray * headerTypes  = @[@(CSVTypeText),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeInteger),@(CSVTypeInteger)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_PEDOMETER headerLabels:header headerTypes:headerTypes];
    }else if (dbType == AwareDBTypeSQLite){
        storage = [[SQLiteStorage alloc] initWithStudy:study
                                            sensorName:@"plugin_ios_pedometer"
                                            entityName:@"EntityIOSPedometer"
                                            insertCallBack:^(NSDictionary *data,
                                                             NSManagedObjectContext *childContext,
                                                             NSString *entity) {
                                                EntityIOSPedometer* entityPedometer = (EntityIOSPedometer *)[NSEntityDescription
                                                                                                    insertNewObjectForEntityForName:entity
                                                                                                    inManagedObjectContext:childContext];
                                                
                                                entityPedometer.device_id        = [data objectForKey:@"device_id"];
                                                entityPedometer.timestamp        = [data objectForKey:@"timestamp"];
                                                entityPedometer.end_timestamp    = [data objectForKey:@"end_timestamp"];
                                                entityPedometer.frequency_second = [data objectForKey:@"frequency_second"];
                                                entityPedometer.number_of_steps  = [data objectForKey:@"number_of_steps"];
                                                entityPedometer.distance         = [data objectForKey:@"distance"];
                                                entityPedometer.current_pace     = [data objectForKey:@"current_pace"];
                                                entityPedometer.current_cadence  = [data objectForKey:@"current_cadence"];
                                                entityPedometer.floors_ascended  = [data objectForKey:@"floors_ascended"];
                                                entityPedometer.floors_descended = [data objectForKey:@"floors_descended"];
                }];
    }else{
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_PEDOMETER];
    }

    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_PEDOMETER
                             storage:storage];

    if (self) {
        frequencySec = 60*10;
    }
    return self;
}


- (void) createTable{
    // Send a table create query
    if ([self isDebug]) {
        NSLog(@"[%@] create table!", [self getSensorName]);
    }
    
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:KEY_END_TIMESTAMP    type:TCQTypeReal    default:@"0"];
    [tcqMaker addColumn:KEY_FREQUENCY_SECOND type:TCQTypeInteger default:@"0"];
    [tcqMaker addColumn:KEY_NUMBER_OF_STEPS  type:TCQTypeInteger default:@"0"];
    [tcqMaker addColumn:KEY_DISTANCE         type:TCQTypeReal    default:@"0"];
    [tcqMaker addColumn:KEY_CURRENT_PACE     type:TCQTypeReal    default:@"0"];
    [tcqMaker addColumn:KEY_CURRENT_CADENCE  type:TCQTypeReal    default:@"0"];
    [tcqMaker addColumn:KEY_FLOORS_ASCENDED  type:TCQTypeInteger default:@"0"];
    [tcqMaker addColumn:KEY_FLOORS_DESCENDED type:TCQTypeInteger default:@"0"];
    [self.storage createDBTableOnServerWithTCQMaker:tcqMaker];
}

- (void)setParameters:(NSArray *)parameters{
    if (parameters != nil) {
        double frequency = [self getSensorSetting:parameters withKey:AWARE_PREFERENCES_FREQUENCY_PEDOMETER ];
        if(frequency > 0){
            frequencySec = frequency;
        }
    }
}

- (BOOL)startSensor {
    // Check a pedometer sensor
    if (![CMPedometer isStepCountingAvailable]) {
        if (self.isDebug) {
            NSLog(@"[%@] Your device is not support this sensor.", [self getSensorName]);
        }
        return NO;
    }else{
        if (self.isDebug) {
            NSLog(@"[%@] start sensor!", [self getSensorName]);
        }
    }
    
    // Initialize a pedometer sensor
    if (!_pedometer) {
        _pedometer = [[CMPedometer alloc]init];
    }

    timer = [NSTimer scheduledTimerWithTimeInterval:frequencySec
                                             target:self
                                           selector:@selector(getPedometerData:)
                                           userInfo:nil
                                            repeats:YES];
    [timer fire];
    
    [self setSensingState:YES];
    
    return NO;
}

- (BOOL)stopSensor{
    [_pedometer stopPedometerUpdates];
    _pedometer = nil;
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    [self setSensingState:NO];
    return NO;
}

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

- (void) getPedometerData:(id)sender{
    NSDate * now = [NSDate new];
    NSDate * fromDate = [self getLastUpdate];
    
    // TEST
    // fromDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-1*60*60*60];
    
    double gap = now.timeIntervalSince1970 - fromDate.timeIntervalSince1970;
    
    for(int i=1; i<gap/frequencySec; i++){
        NSDate   * toDate = [fromDate dateByAddingTimeInterval:frequencySec];
        
        if ([CMPedometer isStepCountingAvailable]) {
            [_pedometer queryPedometerDataFromDate:fromDate
                                            toDate:toDate
                                       withHandler:^(CMPedometerData * _Nullable pedometerData,
                                                     NSError * _Nullable error) {
                                           if(pedometerData != nil){
                                               // NSLog(@"[%@]-[%@]: %@", pedometerData.startDate, pedometerData.endDate, pedometerData.numberOfSteps);
                                               [self savePedometerData:pedometerData error:error];
                                           }
                                           if (error != nil) NSLog(@"%@", error.debugDescription);
                                       }];
        }
        [self setLastUpdateWithDate:toDate];
        fromDate = toDate;
    }
    // [self setLastUpdateWithDate:[now dateByAddingTimeInterval:-10*frequencySec]]; // <- test
}


- (void) savePedometerData:(CMPedometerData * _Nullable) pedometerData
                     error:(NSError * _Nullable) error {
    NSNumber * numberOfSteps   = @0;
    NSNumber * distance        = @0;
    NSNumber * currentPace     = @0;
    NSNumber * currentCadence  = @0;
    NSNumber * floorsAscended  = @0;
    NSNumber * floorsDescended = @0;

    // step counting
    if ([CMPedometer isStepCountingAvailable]) {
        if (!pedometerData.numberOfSteps) {
            numberOfSteps = @0;
        }else{
            numberOfSteps = pedometerData.numberOfSteps;
        }
    } else {
        if (self.isDebug) NSLog(@"Step Counter not available.");
    }

    // distance (m)
    if ([CMPedometer isDistanceAvailable]) {
        if (!pedometerData.distance) {
            distance = @0;
        }else{
            distance = pedometerData.distance;
        }
    }

    if ([AWAREUtils getCurrentOSVersionAsFloat] > 9.0) {
        // pace (s/m)
        if ([CMPedometer isPaceAvailable]) {
            if (pedometerData.currentPace) {
                currentPace = pedometerData.currentPace;
                if (! currentPace) currentPace = @0;
            }
        } else {
            if (self.isDebug) NSLog(@"Pace not available.");
        }

        // cadence (steps/second)
        if ([CMPedometer isCadenceAvailable]) {
            if (pedometerData.currentCadence) {
                currentCadence = pedometerData.currentCadence;
                if(!currentCadence) currentCadence = @0;
            }
        } else {
            if (self.isDebug) NSLog(@"Cadence not available.");
        }
    }

    // flights climbed
    if ([CMPedometer isFloorCountingAvailable]) {
        if (pedometerData.floorsAscended) {
            floorsAscended = pedometerData.floorsAscended;
        }
    } else {
        if (self.isDebug) NSLog(@"Floors ascended not available.");
    }

    // floors descended
    if ([CMPedometer isFloorCountingAvailable]) {
        if (pedometerData.floorsDescended) {
            floorsDescended = pedometerData.floorsDescended;
        }
    } else {
        if (self.isDebug) NSLog(@"Floors descended not available.");
    }

    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[self getDeviceId] forKey:KEY_DEVICE_ID];
    [dict setObject:[AWAREUtils getUnixTimestamp:pedometerData.startDate] forKey:KEY_TIMESTAMP];
    [dict setObject:[AWAREUtils getUnixTimestamp:pedometerData.endDate]   forKey:KEY_END_TIMESTAMP];
    [dict setObject:@(frequencySec) forKey:KEY_FREQUENCY_SECOND];
    [dict setObject:numberOfSteps   forKey:KEY_NUMBER_OF_STEPS];
    [dict setObject:distance        forKey:KEY_DISTANCE];
    [dict setObject:currentPace     forKey:KEY_CURRENT_PACE];
    [dict setObject:currentCadence  forKey:KEY_CURRENT_CADENCE];
    [dict setObject:floorsAscended  forKey:KEY_FLOORS_ASCENDED];
    [dict setObject:floorsDescended forKey:KEY_FLOORS_DESCENDED];

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                             forKey:EXTRA_DATA];
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_PEDOMETER
                                                            object:nil
                                                          userInfo:userInfo];
        [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:NO];
        [self setLatestData:dict];
        [self setLatestValue:[NSString stringWithFormat:@"%@: %@", pedometerData.startDate,numberOfSteps]];
    });
    NSString * message = [NSString stringWithFormat:@"[%@ - %@] Steps:%d, Distance:%f, Pace:%d, Floor Ascended:%d, Floor Descended:%d",
                                                    pedometerData.startDate, pedometerData.endDate,
                                                    numberOfSteps.intValue,  distance.doubleValue,
                                                    currentPace.intValue,    floorsAscended.intValue,
                                                    floorsDescended.intValue];
    if ([self isDebug]) NSLog(@"%@", message);
    [self setLatestValue:[NSString stringWithFormat:@"%@", message]];
    
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, dict);
    }
    
}




/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
- (NSDate * ) setLastUpdateWithDate:(NSDate *)date{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSCalendar * calendar = [NSCalendar currentCalendar];
    NSInteger components = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute;
    NSDateComponents* comp = [calendar components:components fromDate:date];
    NSDate * fixedDate = [calendar dateFromComponents:comp];
    [defaults setObject:fixedDate forKey:KEY_TIMESTAMP_OF_LAST_UPDATE];
    [defaults synchronize];
    return fixedDate;
}

- (NSDate *) getLastUpdate{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate * date = [defaults objectForKey:KEY_TIMESTAMP_OF_LAST_UPDATE];
    
    if (date != nil) {
        return date;
    }else{
        // return [self setLastUpdateWithDate:[NSDate dateWithTimeIntervalSinceNow:60*60*24*7*-1]];
         return [self setLastUpdateWithDate:[NSDate new]];
    }
}


@end
