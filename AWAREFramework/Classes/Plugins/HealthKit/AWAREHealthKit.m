//
//  AWAREHealthKit.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/1/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  http://jademind.com/blog/posts/healthkit-api-tutorial/
//

#import <HealthKit/HealthKit.h>

#import "AWAREHealthKit.h"
#import "AWAREUtils.h"
#import "TCQMaker.h"

#import "AWAREHealthKitWorkout.h"
#import "AWAREHealthKitCategory.h"
#import "AWAREHealthKitQuantity.h"

#import "Screen.h"

NSString * const AWARE_PREFERENCES_STATUS_HEALTHKIT = @"status_health_kit";
NSString * const AWARE_PREFERENCES_PLUGIN_HEALTHKIT_FREQUENCY = @"frequency_health_kit";
NSString * const AWARE_PREFERENCES_PLUGIN_HEALTHKIT_PREPERIOD_DAYS = @"preperiod_days_health_kit";


@implementation AWAREHealthKit{
    NSTimer       * timer;
    HKHealthStore * healthStore;
    Screen * screen;
    bool isAuthorized;
    NSDate * fetchEndDate;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    JSONStorage * storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_HEALTH_KIT];
    self = [super initWithAwareStudy:study sensorName:SENSOR_HEALTH_KIT storage:storage];
    if( self != nil ){
        healthStore       = [[HKHealthStore alloc] init];
        _awareHKWorkout   = [[AWAREHealthKitWorkout  alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
        _awareHKCategory  = [[AWAREHealthKitCategory alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
        _awareHKQuantity  = [[AWAREHealthKitQuantity alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
        _awareHKHeartRate = [[AWAREHealthKitQuantity alloc] initWithAwareStudy:study
                                                                        dbType:dbType
                                                                    sensorName:[NSString stringWithFormat:@"%@_heartrate", SENSOR_HEALTH_KIT]
                                                                    entityName:@"EntityHealthKitQuantityHR"];
        _awareHKSleep = [[AWAREHealthKitCategory alloc] initWithAwareStudy:study
                                                                    dbType:dbType
                                                                sensorName:[NSString stringWithFormat:@"%@_sleep", SENSOR_HEALTH_KIT]
                                                                entityName:@"EntityHealthKitCategorySleep"];
        _fetchIntervalSecond = 60 * 30;
        _preperiodDays = 0;
        isAuthorized = NO;
        screen = [[Screen alloc] initWithAwareStudy:study dbType:dbType];
        [screen.storage setStore:NO];
        fetchEndDate = NULL;
        // self.storage = _awareHKHeartRate.storage;
    }
    return self;
}


- (void) requestAuthorizationToAccessHealthKit {
    [self requestAuthorizationWithAllDataTypes:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"requestAuthorizationWithAllDataTypes -> %d: %@", success, error);
    }];
}

-(void)requestAuthorizationWithDataTypes:(NSSet *)dataTypes completion:(void (^)(BOOL, NSError * _Nullable))completion {
    if(NSClassFromString(@"HKHealthStore") && [HKHealthStore isHealthDataAvailable])
    {
        // Request access
        [healthStore requestAuthorizationToShareTypes:nil
                                            readTypes:dataTypes
                                           completion:^(BOOL success, NSError *error) {
            self->isAuthorized = YES;
            completion(success, error);
                                           }];
    }
}

-(void)requestAuthorizationWithAllDataTypes:(void (^)(BOOL, NSError * _Nullable))completion{
    [self requestAuthorizationWithDataTypes:[self dataTypesToRead] completion:completion];
}

- (void) requestAuthorizationToAccessHealthKi {
    [self requestAuthorizationWithDataTypes:[self dataTypesToRead] completion:^(BOOL success, NSError *error) {
        self->isAuthorized = YES;
    }];
}

- (void) createTable {
    if (self.isDebug) NSLog(@"[%@] create table!", [self getSensorName]);
    [_awareHKWorkout   createTable];
    [_awareHKCategory  createTable];
    [_awareHKQuantity  createTable];
    [_awareHKHeartRate createTable];
    [_awareHKSleep     createTable];
}

- (void)setParameters:(NSArray *)parameters{
    _fetchIntervalSecond = [self getSensorSetting:parameters
                               withKey:[NSString stringWithFormat:@"frequency_%@", SENSOR_HEALTH_KIT]];
    
    double preDays = [self getSensorSetting:parameters withKey:AWARE_PREFERENCES_PLUGIN_HEALTHKIT_PREPERIOD_DAYS];
    if (preDays > 0) {
        _preperiodDays = (int)preDays;
    }
}


- (BOOL)startSensor {
    
    if (!isAuthorized && [self isDebug]) {
        NSLog(@"[AWARE][HealthKit] Please make sure that this application is authorized to access HeakthKit by using `-requestAuthorizationWithDataTypes:completion` or `-requestAuthorizationWithAllDataTypes:completion`.");
    }
    
    if(_fetchIntervalSecond <= 0){
        _fetchIntervalSecond = 60 * 30; // 30 min
    }
    // [self requestAuthorizationToAccessHealthKit];
    
    [screen stopSensor];
    [screen startSensor];
    
    if (screen != nil) {
        __weak typeof(self) weakSelf = self;
        [screen setSensorEventHandler:^(AWARESensor * _Nonnull sensor,
                                        NSDictionary<NSString *,id> * _Nullable data) {
            if (data!=nil) {
                NSNumber * state = [data objectForKey:@"screen_status"];
                if (state!=nil && weakSelf!=nil) {
                    if (state.intValue == 3){
                        [weakSelf readAllData];
                    }
                }
            }
        }];
    }
    return YES;
}

- (BOOL)stopSensor{
    if (screen != nil) {
        [screen stopSensor];
    }
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    if (_awareHKWorkout.storage != nil){
        [_awareHKWorkout.storage saveBufferDataInMainThread:YES];
    }
    if (_awareHKCategory.storage != nil) {
        [_awareHKCategory.storage saveBufferDataInMainThread:YES];
    }
    if (_awareHKQuantity.storage != nil) {
        [_awareHKCategory.storage saveBufferDataInMainThread:YES];
    }
    if (_awareHKHeartRate.storage != nil){
        [_awareHKHeartRate.storage saveBufferDataInMainThread:YES];
    }
    if(_awareHKSleep.storage != nil) {
        [_awareHKSleep.storage saveBufferDataInMainThread:YES];
    }
      
    [self setSensingState:NO];
    return YES;
}

- (void)startSyncDB{
    [_awareHKWorkout  startSyncDB];
    [_awareHKCategory startSyncDB];
    [_awareHKQuantity startSyncDB];
    [_awareHKHeartRate.storage setSyncProcessCallback:self.storage.syncProcessCallback];
    [_awareHKHeartRate startSyncDB];
    [_awareHKSleep     startSyncDB];
    [super startSyncDB];
}

- (void)stopSyncDB{
    [_awareHKWorkout   stopSyncDB];
    [_awareHKCategory  stopSyncDB];
    [_awareHKQuantity  stopSyncDB];
    
    [_awareHKHeartRate stopSyncDB];
    [_awareHKSleep     stopSyncDB];
    [super stopSyncDB];
}

- (NSDate * _Nullable) getLastRecordTimeWithHKDataType:(NSString * _Nonnull)type{
    NSString * key = [NSString stringWithFormat:@"plugin_healthkit_timestamp_%@",type];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSDate * lastRecordTime = (NSDate *)[defaults objectForKey:key];
    // NSLog(@"[GET] %@ %@", type, lastRecordTime);
    return lastRecordTime;
}

- (void) setLastRecordTime:(NSDate * _Nullable)date withHKDataType:(NSString * _Nonnull)type{
    // NSLog(@"[SET] %@ %@", type, date);
    NSString * key = [NSString stringWithFormat:@"plugin_healthkit_timestamp_%@",type];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:date forKey:key];
    [defaults synchronize];
}

- (void)setLastFetchTimeForAll:(NSDate * _Nullable)date{
    NSSet* quantities = [self dataTypesToRead];
    for (HKQuantityType * set in quantities) {
        if(set.identifier == nil){
            continue;
        }
        [self setLastRecordTime:date withHKDataType:set.identifier];
    }
}

- (void) setEndFetchDate:(NSDate * _Nullable) date {
    fetchEndDate = date;
}

- (void) readAllData {
    NSSet* types = [self dataTypesToRead];
    [self readDataWithDataTypes:types];
}

- (void) readDataWithDataTypes: (NSSet *) types {
    for (HKQuantityType * set in types) {
        if(set.identifier == nil){
            continue;
        }
    
        // Set your start and end date for your query of interest
        NSDate * startDate = [self getLastRecordTimeWithHKDataType:set.identifier];
        NSDate * endDate = fetchEndDate;
        if (endDate == nil) {
            endDate = [NSDate date];
        }
        
        if (startDate == nil){
            NSCalendar * calendar   = [NSCalendar currentCalendar];
            NSInteger    components = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay;
            if (_preperiodDays > 0) {
                NSDate * preDate = [NSDate dateWithTimeIntervalSinceNow:-1*60*60*24*_preperiodDays];
                NSDateComponents* comp  = [calendar components:components fromDate:preDate];
                startDate = [calendar dateFromComponents:comp];
            }else{
                NSDate * preDate = [NSDate dateWithTimeIntervalSinceNow:-1*60*60*24];
                NSDateComponents* comp  = [calendar components:components fromDate:preDate];
                startDate = [calendar dateFromComponents:comp];
            }
        }
        
        HKQuery * query = [self getQueryWithSampleType:set start:startDate end:endDate];
        // NSLog(@"%@ (%@ - %@)", set.identifier, startDate, endDate);
        if(self->healthStore != nil){
            [self->healthStore executeQuery:query];
        }
        
//        double gapDays = (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) / (60*60*24);
//        if (gapDays > 0) {
//            for(int i=0; i<gapDays-1; i++){
//                NSDate * adjustedEndDate   = [startDate  dateByAddingTimeInterval:60*60*24*(i+1)];
//                NSDate * adjustedStartDate = [startDate  dateByAddingTimeInterval:60*60*24*i];
//                // NSLog(@"[%d] %@ (%@ - %@)",i, set.identifier, adjustedStartDate, adjustedEndDate);
//
//                HKQuery * query = [self getQueryWithSampleType:set start:adjustedStartDate end:adjustedEndDate];
//                if(self->healthStore != nil){
//                    [self->healthStore executeQuery:query];
//                }
//            }
//        } else{
//            HKQuery * query = [self getQueryWithSampleType:set start:startDate end:endDate];
//            // NSLog(@"%@ (%@ - %@)", set.identifier, startDate, endDate);
//            if(self->healthStore != nil){
//                [self->healthStore executeQuery:query];
//            }
//        }
    }
}


- (HKQuery * _Nonnull) getQueryWithSampleType:(HKSampleType *)set
                                        start:(NSDate *)start
                                          end:(NSDate *)end{
    // Create a predicate to set start/end date bounds of the query
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:start
                                                               endDate:end
                                                               options:HKQueryOptionStrictStartDate];

    // Create a sort descriptor for sorting by start date
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:set //sampleType
                                                                 predicate:predicate
                                                                     limit:HKObjectQueryNoLimit
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query,
                                                                             NSArray *results,
                                                                             NSError *error) {
        NSString * objectId = query.objectType.identifier;
        if (objectId == nil) return;
        @try {
            if(!error && results){
                /// Quantity
                NSSet * quantityTypes = [self getDataQuantityTypes];
                if([quantityTypes containsObject:query.objectType]){
                    // HKQuantityTypeIdentifierHeartRate
                    if (results != nil && results.count > 0) {
                        
                        if ([objectId isEqualToString:HKQuantityTypeIdentifierHeartRate]){
                            [self->_awareHKHeartRate saveQuantityData:results];
                        }else{
                            [self->_awareHKQuantity saveQuantityData:results];
                        }
                    
                        HKQuantitySample * lastSample = (HKQuantitySample *)results.lastObject;
                        [self setLastRecordTime:lastSample.endDate withHKDataType:query.objectType.identifier];
                    }
                }

                /// Catogory
                NSSet * dataCatogoryTypes = [self getDataCategoryTypes];
                if([dataCatogoryTypes containsObject:query.objectType]){
                    if (results != nil && results.count > 0) {
                        
                        if ([objectId isEqualToString:HKCategoryTypeIdentifierSleepAnalysis]){
                            [self->_awareHKSleep saveCategoryData:results];
                        }else{
                            [self->_awareHKCategory saveCategoryData:results];
                        }
                        
                        HKCategorySample * lastSample = (HKCategorySample *)results.lastObject;
                        [self setLastRecordTime:lastSample.endDate withHKDataType:query.objectType.identifier];
                    }
                }

                /// Workout
                NSSet * dataWorkoutTypes = [self getDataWorkoutTypes];
                if([dataWorkoutTypes containsObject:query.objectType]){
                    
                    if (results != nil && results.count > 0) {
                        
                        [self->_awareHKWorkout saveWorkoutData:results];
                        
                        HKWorkout * lastSample = (HKWorkout *)results.lastObject;
                        [self setLastRecordTime:lastSample.endDate withHKDataType:query.objectType.identifier];
                    }
                }

                //////////////////////// Correlation //////////////////////////////
                // NSSet * dataCorrelationTypes = [self getDataCorrelationTypes];
                // if([dataCorrelationTypes containsObject:query.sampleType]){
                //    // https://developer.apple.com/reference/healthkit/hkcorrelation
                //    for(HKCorrelation *sample in results)
                //    {
                //        // ?
                //        NSLog(@"%@", sample.objects);
                //    }
                // }
                // https://developer.apple.com/reference/healthkit
                
            }else{
                NSLog(@"[%@] Error: %@", [self getSensorName], error.debugDescription);
            }
        } @catch (NSException *exception) {
            NSString * message = [NSString stringWithFormat:@"[%@] %@", [self getSensorName], exception.debugDescription];
            NSLog(@"%@", message);
        } @finally {

        }
    }];
    
    return sampleQuery;
}


// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet *)allDataTypesToRead {
    NSSet * characteristicTypesSet = [self characteristicDataTypesToRead];
    NSSet * otherTypesSet          = [self dataTypesToRead];
    
    return [otherTypesSet setByAddingObjectsFromSet: characteristicTypesSet];
}

// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet *)characteristicDataTypesToRead {
    NSMutableSet* dataTypesSet = [[NSMutableSet alloc] init];
    
    // CharacteristicType
    HKCharacteristicType *characteristicType;
    characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex];
    [dataTypesSet addObject:characteristicType];
    characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBloodType];
    [dataTypesSet addObject:characteristicType];
    characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
    [dataTypesSet addObject:characteristicType];
    characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierFitzpatrickSkinType];
    [dataTypesSet addObject:characteristicType];
    characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierWheelchairUse];
    [dataTypesSet addObject:characteristicType];
    
    if (@available(iOS 14.0, *)) {
        characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierActivityMoveMode];
        [dataTypesSet addObject:characteristicType];
    }
    
    return dataTypesSet;
}


- (NSSet *) getDataQuantityTypes{
    NSMutableSet* dataTypesSet = [[NSMutableSet alloc] init];
    
    // Body Measurements
    [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex]];
    [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyFatPercentage]];
    [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight]];
    [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]];
    [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierLeanBodyMass]];
    if (@available(iOS 11.0, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierWaistCircumference]]; // Length,                      Discrete
    }
    if (@available(iOS 16.0, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierAppleSleepingWristTemperature]]; // Temperature,                 Discrete
    }


    // Fitness
    for (HKQuantityTypeIdentifier identifier in @[
        HKQuantityTypeIdentifierStepCount,                           // Scalar(Count),               Cumulative
        HKQuantityTypeIdentifierDistanceWalkingRunning,              // Length,                      Cumulative
        HKQuantityTypeIdentifierDistanceCycling,                     // Length,                      Cumulative
        HKQuantityTypeIdentifierDistanceWheelchair,                  // Length,                      Cumulative
        HKQuantityTypeIdentifierBasalEnergyBurned,                   // Energy,                      Cumulative
        HKQuantityTypeIdentifierActiveEnergyBurned,                  // Energy,                      Cumulative
        HKQuantityTypeIdentifierFlightsClimbed,                      // Scalar(Count),               Cumulative
        HKQuantityTypeIdentifierNikeFuel,                            // Scalar(Count),               Cumulative
        HKQuantityTypeIdentifierAppleExerciseTime,                   // Time                         Cumulative
    ]){
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:identifier]];
    }
    if (@available(iOS 11.0, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierPushCount]];          // Scalar(Count),               Cumulative
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceSwimming]];   // Length,                      Cumulative
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierSwimmingStrokeCount]];// Scalar(Count),               Cumulative
    }
    if (@available(iOS 11.0, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierVO2Max]];  // ml/(kg*min)                  Discrete
    }
    if (@available(iOS 11.2, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceDownhillSnowSports]];  // Length,                      Cumulative
    }
    if (@available(iOS 13, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:    HKQuantityTypeIdentifierAppleStandTime]];          // Time,                        Cumulative
    }
    if (@available(iOS 14, *)) {
        for (HKQuantityTypeIdentifier identifier in @[
            HKQuantityTypeIdentifierWalkingSpeed,// 14.0                       // m/s,                         Discrete
            HKQuantityTypeIdentifierWalkingDoubleSupportPercentage,// 14.0     // Scalar(Percent, 0.0 - 1.0),  Discrete
            HKQuantityTypeIdentifierWalkingAsymmetryPercentage,// 14.0         // Scalar(Percent, 0.0 - 1.0),  Discrete
            HKQuantityTypeIdentifierWalkingStepLength,// 14.0                  // Length,                      Discrete
            HKQuantityTypeIdentifierSixMinuteWalkTestDistance,// 14.0          // Length,                      Discrete
            HKQuantityTypeIdentifierStairAscentSpeed,// 14.0                   // m/s,                         Discrete
            HKQuantityTypeIdentifierStairDescentSpeed,// 14.0                  // m/s                     Discrete
        ]){
            [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:identifier]];
        }
    }
    if (@available(iOS 14.5, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier: HKQuantityTypeIdentifierAppleMoveTime]]; // 14.5                      // Time,                        Cumulative
    }
    if (@available(iOS 15.0, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierAppleWalkingSteadiness]]; // 15.0          // Scalar(Percent, 0.0 - 1.0),  Discrete
    }
    if (@available(iOS 16.0, *)) {
        for (HKQuantityTypeIdentifier identifier in @[
            HKQuantityTypeIdentifierRunningStrideLength,  // 16.0              // Length,                      Discrete
            HKQuantityTypeIdentifierRunningVerticalOscillation,// 16.0       // Length,                      Discrete
            HKQuantityTypeIdentifierRunningGroundContactTime,// 16.0         // Time,                        Discrete
            HKQuantityTypeIdentifierRunningPower,// 16.0                     // Power                        Discrete
            HKQuantityTypeIdentifierRunningSpeed,// 16.0                     // m/s,                         Discrete

        ]){
            [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:identifier]];
        }
    }
    
    // Vitals
    for (HKQuantityTypeIdentifier identifier in @[
        HKQuantityTypeIdentifierHeartRate,// 8.0                         // Scalar(Count)/Time,          Discrete
        HKQuantityTypeIdentifierBodyTemperature,// 8.0                   // Temperature,                 Discrete
        HKQuantityTypeIdentifierBasalBodyTemperature,// 9.0              // Basal Body Temperature,      Discrete
        HKQuantityTypeIdentifierBloodPressureSystolic,// 8.0             // Pressure,                    Discrete
        HKQuantityTypeIdentifierBloodPressureDiastolic,// 8.0            // Pressure,                    Discrete
        HKQuantityTypeIdentifierRespiratoryRate,// 8.0                   // Scalar(Count)/Time,          Discrete
    ]){
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:identifier]];
    }
    if (@available(iOS 11.0, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierRestingHeartRate]]; // 11.0 // Scalar(Count)/Time,          Discrete
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierWalkingHeartRateAverage]]; // 11.0         // Scalar(Count)/Time,          Discrete
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRateVariabilitySDNN]]; // 11.0        // Time (ms                Discrete
    }
    if (@available(iOS 16.0, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRateRecoveryOneMinute]]; // 16.0       // Scalar(Count)/Time,          Discrete
    }
    

    // Results
    for (HKQuantityTypeIdentifier identifier in @[
        HKQuantityTypeIdentifierOxygenSaturation, // 8.0                  // Scalar(Percent, 0.0 - 1.0),  Discrete
        HKQuantityTypeIdentifierPeripheralPerfusionIndex, // 8.0          // Scalar(Percent, 0.0 - 1.0),  Discrete
        HKQuantityTypeIdentifierBloodGlucose, // 8.0                      // Mass/Volume,                 Discrete
        HKQuantityTypeIdentifierNumberOfTimesFallen, // 8.0               // Scalar(Count            Cumulative
        HKQuantityTypeIdentifierElectrodermalActivity, // 8.0             // Conductance,                 Discrete
        HKQuantityTypeIdentifierInhalerUsage, // 8.0                      // Scalar(Count            Cumulative
        HKQuantityTypeIdentifierBloodAlcoholContent, // 8.0               // Scalar(Percent, 0.0 - 1.0),  Discrete
        HKQuantityTypeIdentifierForcedVitalCapacity, // 8.0               // Volume,                      Discrete
        HKQuantityTypeIdentifierForcedExpiratoryVolume1, // 8.0           // Volume,                      Discrete
        HKQuantityTypeIdentifierPeakExpiratoryFlowRate, // 8.0            // Volume/Time,                 Discrete
    ]){
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:identifier]];
    }
    if (@available(iOS 11.0, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierInsulinDelivery]]; // 11.0                  // Pharmacology (IU)            Cumulative
    }
    if (@available(iOS 13.0, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierEnvironmentalAudioExposure]];// 13.0       // Pressure,                    DiscreteEquivalentContinuousLevel
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeadphoneAudioExposure]];// 13.0           // Pressure,                    DiscreteEquivalentContinuousLevel
    }
    if (@available(iOS 15.0, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierNumberOfAlcoholicBeverages]];
    }

    


    // Nutrition
    for (HKQuantityTypeIdentifier identifier in @[
        HKQuantityTypeIdentifierDietaryFatTotal,// 8.0                   // Mass,   Cumulative
        HKQuantityTypeIdentifierDietaryFatPolyunsaturated,// 8.0         // Mass,   Cumulative
        HKQuantityTypeIdentifierDietaryFatMonounsaturated,// 8.0         // Mass,   Cumulative
        HKQuantityTypeIdentifierDietaryFatSaturated,// 8.0               // Mass,   Cumulative
        HKQuantityTypeIdentifierDietaryCholesterol,// 8.0                // Mass,   Cumulative
        HKQuantityTypeIdentifierDietarySodium,// 8.0                     // Mass,   Cumulative
        HKQuantityTypeIdentifierDietaryCarbohydrates,// 8.0              // Mass,   Cumulative
        HKQuantityTypeIdentifierDietaryFiber,// 8.0                      // Mass,   Cumulative
        HKQuantityTypeIdentifierDietarySugar,// 8.0                      // Mass,   Cumulative
        HKQuantityTypeIdentifierDietaryEnergyConsumed,// 8.0             // Energy, Cumulative
        HKQuantityTypeIdentifierDietaryProtein,// 8.0                    // Mass,   Cumulative

        HKQuantityTypeIdentifierDietaryVitaminA,// 8.0                   // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryVitaminB6,// 8.0                  // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryVitaminB12,// 8.0                 // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryVitaminC,// 8.0                   // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryVitaminD,// 8.0                   // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryVitaminE,// 8.0                   // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryVitaminK,// 8.0                   // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryCalcium,// 8.0                    // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryIron,// 8.0                       // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryThiamin,// 8.0                    // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryRiboflavin,// 8.0                 // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryNiacin,// 8.0                     // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryFolate,// 8.0                     // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryBiotin,// 8.0                     // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryPantothenicAcid,// 8.0            // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryPhosphorus,// 8.0                 // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryIodine,// 8.0                     // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryMagnesium,// 8.0                  // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryZinc,// 8.0                       // Mass, Cumulative
        HKQuantityTypeIdentifierDietarySelenium,// 8.0                   // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryCopper,// 8.0                     // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryManganese,// 8.0                  // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryChromium,// 8.0                   // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryMolybdenum ,//8.0                 // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryChloride,// 8.0                   // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryPotassium,// 8.0                  // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryCaffeine,// 8.0                   // Mass, Cumulative
        HKQuantityTypeIdentifierDietaryWater,// 9.0                      // Volume, Cumulative
        HKQuantityTypeIdentifierUVExposure,// 9.0                        // Scalar(Count), Discrete
    ]){
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:identifier]];
    }
    if (@available(iOS 16.0, *)) {
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierAtrialFibrillationBurden]];// 16.0         // Scalar(Percent, 0.0 - 1.0),  Discrete
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierUnderwaterDepth]];// 16.0                  // Length, Discrete
        [dataTypesSet addObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierWaterTemperature]];// 16.0                 // Temperature, Discrete
    }
    
    return dataTypesSet;
}

- (NSSet *) getDataCategoryTypes{
     NSMutableSet* dataTypesSet = [[NSMutableSet alloc] init];
    
    for (HKCategoryTypeIdentifier identifier in @[
                                                  HKCategoryTypeIdentifierSleepAnalysis,
                                                  HKCategoryTypeIdentifierAppleStandHour,
                                                  HKCategoryTypeIdentifierCervicalMucusQuality,
                                                  HKCategoryTypeIdentifierOvulationTestResult,
                                                  HKCategoryTypeIdentifierMenstrualFlow,
                                                  HKCategoryTypeIdentifierIntermenstrualBleeding,
                                                  HKCategoryTypeIdentifierSexualActivity
                                                ]) {
        [dataTypesSet addObject:[HKCategoryType categoryTypeForIdentifier:identifier]];
    }

    if (@available(iOS 10.0, *)) {
        [dataTypesSet addObject:[HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierMindfulSession]];
    }

    if (@available(iOS 12.2, *)) {
        [dataTypesSet addObject:[HKCategoryType categoryTypeForIdentifier: HKCategoryTypeIdentifierHighHeartRateEvent]];
        [dataTypesSet addObject:[HKCategoryType categoryTypeForIdentifier: HKCategoryTypeIdentifierLowHeartRateEvent]];
        [dataTypesSet addObject:[HKCategoryType categoryTypeForIdentifier: HKCategoryTypeIdentifierIrregularHeartRhythmEvent]];
    }

    if (@available(iOS 13, *)) {
        [dataTypesSet addObject:[HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierAudioExposureEvent]];
        [dataTypesSet addObject:[HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierToothbrushingEvent]];
    }

    
    if (@available(iOS 13.6, *)) {
        for (HKCategoryTypeIdentifier identifier in @[
                                                        HKCategoryTypeIdentifierAbdominalCramps,
                                                        HKCategoryTypeIdentifierAcne,
                                                        HKCategoryTypeIdentifierAppetiteChanges,
                                                        HKCategoryTypeIdentifierBloating,
                                                        HKCategoryTypeIdentifierBreastPain,
                                                        HKCategoryTypeIdentifierChestTightnessOrPain,
                                                        HKCategoryTypeIdentifierChills,
                                                        HKCategoryTypeIdentifierConstipation,
                                                        HKCategoryTypeIdentifierCoughing,
                                                        HKCategoryTypeIdentifierDiarrhea,
                                                        HKCategoryTypeIdentifierDizziness,
                                                        HKCategoryTypeIdentifierFainting,
                                                        HKCategoryTypeIdentifierFatigue,
                                                        HKCategoryTypeIdentifierFever,
                                                        HKCategoryTypeIdentifierGeneralizedBodyAche,
                                                        HKCategoryTypeIdentifierHeadache,
                                                        HKCategoryTypeIdentifierHeartburn,
                                                        HKCategoryTypeIdentifierHotFlashes,
                                                        HKCategoryTypeIdentifierLossOfSmell,
                                                        HKCategoryTypeIdentifierLossOfTaste,
                                                        HKCategoryTypeIdentifierLowerBackPain,
                                                        HKCategoryTypeIdentifierMoodChanges,
                                                        HKCategoryTypeIdentifierNausea,
                                                        HKCategoryTypeIdentifierPelvicPain,
                                                        HKCategoryTypeIdentifierRapidPoundingOrFlutteringHeartbeat,
                                                        HKCategoryTypeIdentifierRunnyNose,
                                                        HKCategoryTypeIdentifierShortnessOfBreath,
                                                        HKCategoryTypeIdentifierSinusCongestion,
                                                        HKCategoryTypeIdentifierSkippedHeartbeat,
                                                        HKCategoryTypeIdentifierSleepChanges,
                                                        HKCategoryTypeIdentifierSoreThroat,
                                                        HKCategoryTypeIdentifierVomiting,
                                                        HKCategoryTypeIdentifierWheezing]){
            [dataTypesSet addObject:[HKCategoryType categoryTypeForIdentifier:identifier]];
        }
    }
    
    if (@available(iOS 14.0, *)) {
        for (HKCategoryTypeIdentifier identifier in @[
            HKCategoryTypeIdentifierEnvironmentalAudioExposureEvent,
            HKCategoryTypeIdentifierHandwashingEvent,
            HKCategoryTypeIdentifierBladderIncontinence,
            HKCategoryTypeIdentifierDrySkin,
            HKCategoryTypeIdentifierHairLoss,
            HKCategoryTypeIdentifierMemoryLapse,
            HKCategoryTypeIdentifierNightSweats,
            HKCategoryTypeIdentifierVaginalDryness
        ]){
            [dataTypesSet addObject:[HKCategoryType categoryTypeForIdentifier:identifier]];
        }
    }
    if (@available(iOS 14.2, *)) {
        [dataTypesSet addObject:[HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierHeadphoneAudioExposureEvent]];
    }
    
    if (@available(iOS 14.3, *)) {
        for (HKCategoryTypeIdentifier identifier in @[
                                  HKCategoryTypeIdentifierPregnancy,
                                  HKCategoryTypeIdentifierLactation,               // HKCategoryValue
                                  HKCategoryTypeIdentifierContraceptive,                    // HKCategoryValueContraceptive
                                  HKCategoryTypeIdentifierLowCardioFitnessEvent
                                                    ]){
            [dataTypesSet addObject:[HKCategoryType categoryTypeForIdentifier:identifier]];
        }
    }
    
    
    if (@available(iOS 15.0, *)) {
        for (HKCategoryTypeIdentifier identifier in @[
            HKCategoryTypeIdentifierPregnancyTestResult,
            HKCategoryTypeIdentifierProgesteroneTestResult,
            HKCategoryTypeIdentifierAppleWalkingSteadinessEvent
        ]){
            [dataTypesSet addObject:[HKCategoryType categoryTypeForIdentifier:identifier]];
        }
    }

    if (@available(iOS 16.0, *)) {
        for (HKCategoryTypeIdentifier identifier in @[
            HKCategoryTypeIdentifierPersistentIntermenstrualBleeding,
            HKCategoryTypeIdentifierProlongedMenstrualPeriods,
            HKCategoryTypeIdentifierIrregularMenstrualCycles,
            HKCategoryTypeIdentifierInfrequentMenstrualCycles,
        ]){
            [dataTypesSet addObject:[HKCategoryType categoryTypeForIdentifier:identifier]];
        }
    }
    
    return dataTypesSet;
}

- (NSSet *) getDataCorrelationTypes{
    NSMutableSet* dataTypesSet = [[NSMutableSet alloc] init];
    
#ifdef ENABLE_HK_DUMP_TYPE_CORR
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // CorrelationType
    HKCorrelationType *corrType;
    corrType = [HKCorrelationType correlationTypeForIdentifier:HKCorrelationTypeIdentifierBloodPressure];
    [dataTypesSet addObject:corrType];
    corrType = [HKCorrelationType correlationTypeForIdentifier:HKCorrelationTypeIdentifierFood];
    [dataTypesSet addObject:corrType];w
#endif
    
    return dataTypesSet;
}

- (NSSet *) getDataWorkoutTypes{
    NSMutableSet* dataTypesSet = [[NSMutableSet alloc] init];
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // HKWorkoutType
    HKWorkoutType *workoutType = [HKWorkoutType workoutType];
    [dataTypesSet addObject:workoutType];

    return dataTypesSet;
}


// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet *)dataTypesToRead {
    NSMutableSet* dataTypesSet = [[NSMutableSet alloc] init];
    
    NSSet * dataQuantityTypes    = [self getDataQuantityTypes];
    NSSet * dataCatogoryTypes    = [self getDataCategoryTypes];
    // NSSet * dataCorrelationTypes = [self getDataCorrelationTypes];
    NSSet * dataWorkoutTypes     = [self getDataWorkoutTypes];

    for (HKQuantityType *quantityType in dataQuantityTypes) {
        [dataTypesSet addObject:quantityType];
    }
    for (HKCategoryType *categoryType in dataCatogoryTypes){
        [dataTypesSet addObject:categoryType];
    }
#ifdef ENABLE_HK_DUMP_TYPE_CORR
    for (HKCorrelationType *corrType in dataCorrelationTypes) {
        [dataTypesSet addObject:corrType];
    }
#endif
    for(HKWorkoutType *workoutType in dataWorkoutTypes){
        [dataTypesSet addObject:workoutType];
    }
    
    return dataTypesSet;
}

- (void)resetSensor{
    [super resetSensor];
    [self setLastFetchTimeForAll:nil];
}

@end
