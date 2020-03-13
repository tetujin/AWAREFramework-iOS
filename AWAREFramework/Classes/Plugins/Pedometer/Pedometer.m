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

NSString * const AWARE_PREFERENCES_STATUS_PEDOMETER    = @"status_plugin_ios_pedometer";
NSString * const AWARE_PREFERENCES_FREQUENCY_PEDOMETER = @"frequency_ios_pedometer";
NSString * const AWARE_PREFERENCES_PREPERIOD_DAYS_PEDOMETER = @"preperiod_days_ios_pedometer";

@implementation Pedometer {
    NSString* KEY_DEVICE_ID;
    NSString* KEY_TIMESTAMP;
    NSString* KEY_END_TIMESTAMP;
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
    
    dispatch_semaphore_t semaphore;
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
        semaphore = dispatch_semaphore_create(0);
        frequencySec = 60; // 1min
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
        
        int preperiodDays = [self getSensorSetting:parameters withKey:AWARE_PREFERENCES_PREPERIOD_DAYS_PEDOMETER];
        if (preperiodDays > 0) {
            if (preperiodDays > 7) {
                preperiodDays = 7;
            }
            if ([self getLastFetchedDate] == nil) {
                NSDate * preperiodStartDate = [NSDate dateWithTimeIntervalSinceNow:-1*60*60*24*preperiodDays];
                
                NSCalendar * calendar   = [NSCalendar currentCalendar];
                NSInteger    components = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay;
                NSDateComponents* comp  = [calendar components:components fromDate:preperiodStartDate];
                NSDate * formattedDate      = [calendar dateFromComponents:comp];
                
                [self setLastFetchedDate:[self getFormattedDate:formattedDate]];
            }
        }else{
            if ([self getLastFetchedDate] == nil) {
                NSDate * preperiodStartDate = [NSDate new];
                NSCalendar * calendar   = [NSCalendar currentCalendar];
                NSInteger    components = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay;
                NSDateComponents* comp  = [calendar components:components fromDate:preperiodStartDate];
                NSDate * formattedDate      = [calendar dateFromComponents:comp];
                [self setLastFetchedDate:[self getFormattedDate:formattedDate]];
           }
        }
        
        
    }
}

- (BOOL)startSensor {
    // Check a pedometer sensor
    if (![CMPedometer isStepCountingAvailable]) {
        if (self.isDebug) { NSLog(@"[%@] Your device is not support this sensor.", [self getSensorName]); }
        return NO;
    }else{
        if (self.isDebug) { NSLog(@"[%@] start sensor!", [self getSensorName]); }
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
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    [self setSensingState:NO];
    return NO;
}

- (void)resetSensor{
    [super resetSensor];
    [self setLastFetchedDate:nil];
}

/////////////////////////////////////////////////////////////////
- (void) getPedometerData:(id)sender{
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        NSDate * now = [NSDate new];
        NSDate * fromDate = [self getLastFetchedDate];
        if (fromDate == nil) {
            fromDate = [self getFormattedDate:now];
        }
        
        double gap = now.timeIntervalSince1970 - fromDate.timeIntervalSince1970;
        
        NSMutableArray<CMPedometerData *> * buffer = [[NSMutableArray alloc] init];
        
        for(int i=1; i<gap/self->frequencySec; i++){
            NSDate   * toDate = [fromDate dateByAddingTimeInterval:self->frequencySec];
            // NSLog(@"[%d] %@ - %@", i, fromDate, toDate);
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self->_pedometer queryPedometerDataFromDate:fromDate
                                                toDate:toDate
                                           withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
                                               if(pedometerData != nil){
                                                   // NSLog(@"steps: %@", pedometerData.numberOfSteps);
                                                   [buffer addObject:pedometerData];
                                               }
                                                if (error != nil){
                                                    NSLog(@"%@", error.debugDescription);
                                                }
                                               
                                                dispatch_semaphore_signal(self->semaphore);
                                           }];

            });
            dispatch_semaphore_wait(self->semaphore, DISPATCH_TIME_FOREVER);
            fromDate = toDate;
            
            if (i%100==0) {
                // NSLog(@"---->[%d] %ld %@", i, buffer.count, buffer.lastObject);
                if (buffer.lastObject != nil) {
                    [self savePedometerWithArray:buffer];
                    [self setLastFetchedDate:[buffer lastObject].endDate];
                    [buffer removeAllObjects];
                }
            }
        }
        
        if (buffer.lastObject != nil) {
            [self savePedometerWithArray:buffer];
            [self setLastFetchedDate:[buffer lastObject].endDate];
            [buffer removeAllObjects];
        }
    }];

    
}

- (NSMutableDictionary * _Nonnull) convertCMPedometerToDict:(CMPedometerData * _Nonnull) pedometerData {
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
    
    // NSLog(@"%@", dict);
    
    return dict;
}

- (void) savePedometerData:(CMPedometerData * _Nonnull) pedometerData
                     error:(NSError * _Nullable) error {
    [self savePedometerWithArray: [[NSMutableArray alloc] initWithArray:@[pedometerData]]];
}

- (void) savePedometerWithArray:(NSMutableArray<CMPedometerData *> * _Nonnull) array{
        
    NSMutableArray <NSDictionary *> * buffer = [[NSMutableArray alloc] init];
    
    for (CMPedometerData * pedometerData in array) {
        
        // convert
        NSDictionary * dict = [self convertCMPedometerToDict:pedometerData];

        // add buffer
        [buffer addObject:dict];
    }

    
    dispatch_async(dispatch_get_main_queue(), ^{
        // save buffer into the local-database
        [self.storage saveDataWithArray:buffer buffer:NO saveInMainThread:NO];
        
        NSDictionary * dict =  [buffer lastObject];
        CMPedometerData * pedometerData = [array lastObject];
        if (dict!=nil && pedometerData!=nil) {
            // broadcast
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                                 forKey:EXTRA_DATA];
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_PEDOMETER
                                                                object:nil
                                                              userInfo:userInfo];
            
            // save latest value as text
            NSDateFormatter *formatter=[[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"YYYY/MM/dd HH:mm:ss"];
            [formatter setTimeZone:[NSTimeZone systemTimeZone]];
            NSString * message = [NSString stringWithFormat:@"[%@ - %@] Steps:%d, Distance:%f, Pace:%d, Floor Ascended:%d, Floor Descended:%d",
                                                            [formatter stringFromDate:pedometerData.startDate],
                                                            [formatter stringFromDate:pedometerData.endDate],
                                                            pedometerData.numberOfSteps.intValue,  pedometerData.distance.doubleValue,
                                                            pedometerData.currentPace.intValue,    pedometerData.floorsAscended.intValue,
                                                            pedometerData.floorsDescended.intValue];
            if ([self isDebug]) NSLog(@"%@", message);
            [self setLatestValue:[NSString stringWithFormat:@"%@", message]];
            
            // callback
            SensorEventHandler handler = [self getSensorEventHandler];
            if (handler!=nil) {
                handler(self, dict);
            }
            
            // save lasted data object
            [self setLatestData:dict];
        }
    });
}


/////////////////////////////////////////////////////////////////
- (void) setLastFetchedDate:(NSDate * _Nullable) date {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (date != nil) {
        [defaults setObject:[self getFormattedDate:date] forKey:KEY_TIMESTAMP_OF_LAST_UPDATE];
    }else{
        [defaults setObject:nil forKey:KEY_TIMESTAMP_OF_LAST_UPDATE];
    }
    [defaults synchronize];
}

- (NSDate * _Nonnull) getFormattedDate:(NSDate * _Nonnull) date {
    NSCalendar * calendar   = [NSCalendar currentCalendar];
    NSInteger    components = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute;
    NSDateComponents* comp  = [calendar components:components fromDate:date];
    NSDate * formattedDate      = [calendar dateFromComponents:comp];
    return formattedDate;
}

- (NSDate * _Nullable) getLastFetchedDate {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSDate * date = [defaults objectForKey:KEY_TIMESTAMP_OF_LAST_UPDATE];
    
    //dummy
//    NSDate * dummy = [[NSDate new] dateByAddingTimeInterval:-1*60*60*24*3];
//    date = dummy;
    
    if (date!=nil){
        if ( ([NSDate new].timeIntervalSince1970 - date.timeIntervalSince1970 ) > 60*60*24*7 ){
            NSDate * sevenDaysBefore = [[NSDate new] dateByAddingTimeInterval:-1*60*60*24*7];
            NSCalendar * calendar   = [NSCalendar currentCalendar];
            NSInteger    components = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay;
            NSDateComponents* comp  = [calendar components:components fromDate:sevenDaysBefore];
            date      = [calendar dateFromComponents:comp];
        }
    }
    return date;
}

@end
