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

@implementation AWAREHealthKit{
    NSTimer * timer;
    HKHealthStore *healthStore;
    
    AWAREHealthKitWorkout * awareHKWorkout;
    AWAREHealthKitCategory * awareHKCategory;
    AWAREHealthKitQuantity * awareHKQuantity;
    
    double frequency;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = [[AWAREStorage alloc] initWithStudy:study sensorName:SENSOR_HEALTH_KIT];
    self = [super initWithAwareStudy:study sensorName:SENSOR_HEALTH_KIT storage:storage];
    if(self!=nil){

        // Add your HealthKit code here
        healthStore = [[HKHealthStore alloc] init];
        
//        [self setTypeAsPlugin];
//        [self addDefaultSettingWithBool:@NO key:[NSString stringWithFormat:@"status_%@",SENSOR_HEALTH_KIT] desc:@"true or false to activate or deactivate accelerometer sensor."];
//        [self addDefaultSettingWithNumber:@(60*60) key:[NSString stringWithFormat:@"frequency_%@",SENSOR_HEALTH_KIT] desc:@"Sensing Frequency (second) of HealthKit sensor. Defualt frequecy is 1hour(3600sec)"];
//
        awareHKWorkout = [[AWAREHealthKitWorkout alloc] initWithAwareStudy:study dbType:dbType];
        awareHKCategory = [[AWAREHealthKitCategory alloc] initWithAwareStudy:study dbType:dbType];
        awareHKQuantity = [[AWAREHealthKitQuantity alloc] initWithAwareStudy:study dbType:dbType];
        
        frequency = 60 * 30; // 30min
    }
    return self;
}


- (void) requestAuthorizationToAccessHealthKit{
    if(NSClassFromString(@"HKHealthStore") && [HKHealthStore isHealthDataAvailable])
    {
        // Request access
        [healthStore requestAuthorizationToShareTypes:nil
                                            readTypes:[self dataTypesToRead]
                                           completion:^(BOOL success, NSError *error) {

                                               if(success == YES)
                                               {
                                                   // ...
                                                   [self readAllDate];
                                               }
                                               else
                                               {
                                                   // Determine if it was an error or if the
                                                   // user just canceld the authorization request
                                               }

                                           }];
    }
}


- (void) createTable{
    // Send a table create query
    // NSLog(@"[%@] create table!", [self getSensorName]);
    [awareHKWorkout  createTable];
    [awareHKCategory createTable];
    [awareHKQuantity createTable];
}

- (void)setParameters:(NSArray *)parameters{
    frequency = [self getSensorSetting:parameters withKey:[NSString stringWithFormat:@"frequency_%@", SENSOR_HEALTH_KIT]];
    if(frequency < 0){
        frequency = 60 * 60; // 1 hour
    }
}


- (BOOL)startSensor{
    
    [self requestAuthorizationToAccessHealthKit];
    
    [self readAllDate];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:frequency
                                             target:self
                                           selector:@selector(readAllDate)
                                           userInfo:nil
                                            repeats:YES];
    [self setSensingState:YES];
    return YES;
}

- (BOOL)stopSensor{
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    [self setSensingState:NO];
    // healthStore = nil;
    return YES;
}


//////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

- (void)startSyncDB{
    [awareHKWorkout startSyncDB];
    [awareHKCategory startSyncDB];
    [awareHKQuantity startSyncDB];
    [super startSyncDB];
}

- (void)stopSyncDB{
    [awareHKWorkout stopSyncDB];
    [awareHKCategory stopSyncDB];
    [awareHKQuantity stopSyncDB];
    [super stopSyncDB];
}

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

- (void) readAllDate {
    // Set your start and end date for your query of interest
    NSDate * startDate = [self getLastUpdate];
    //NSDate * startDate =  [NSDate dateWithTimeIntervalSinceNow:-60*60*24]; // <- test
    NSDate * endDate = [NSDate new];

    NSLog(@"[%@] %@ <---> %@", [self getSensorName], startDate, endDate);

    NSSet* quantities = [self dataTypesToRead];
    for (HKQuantityType * set in quantities) {
        if(set.identifier == nil){
            continue;
        }
        // Create a predicate to set start/end date bounds of the query
        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];

        // Create a sort descriptor for sorting by start date
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:YES];

        HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:set //sampleType
                                                                     predicate:predicate
                                                                         limit:HKObjectQueryNoLimit
                                                               sortDescriptors:@[sortDescriptor]
                                                                resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {

                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        [self setLatestValue:[NSString stringWithFormat:@"Last update: %@", [NSDate new]]];
                                                                    });

                                                                    @try {
                                                                        if(!error && results)
                                                                        {
                                                                            //////////////////////// Quantity //////////////////////////////
                                                                            NSSet * quantityTypes = [self getDataQuantityTypes];
                                                                            if([quantityTypes containsObject:query.objectType]){
                                                                                [self->awareHKQuantity saveQuantityData:results];
                                                                            }

                                                                            //////////////////////// Catogory //////////////////////////////////
                                                                            NSSet * dataCatogoryTypes    = [self getDataCategoryTypes];
                                                                            if([dataCatogoryTypes containsObject:query.objectType]){
                                                                                [self->awareHKCategory saveCategoryData:results];

                                                                            }

                                                                            ///////////////////////// Workout  /////////////////////////////////
                                                                            NSSet * dataWorkoutTypes     = [self getDataWorkoutTypes];
                                                                            if([dataWorkoutTypes containsObject:query.objectType]){
                                                                                [self->awareHKWorkout saveWorkoutData:results];
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
//                                                                        [self saveDebugEventWithText:message type:DebugTypeError label:@""];
                                                                    } @finally {

                                                                    }

                                                                }];
        if(healthStore != nil){
            // Execute the query
            [healthStore executeQuery:sampleQuery];
        }else{
//            [self saveDebugEventWithText:@"ERROR in HealthKit Sensor" type:DebugTypeInfo label:@"HealthKit object is nil."];
        }

        [self setLastUpdate:endDate];

    }
}


// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet *)allDataTypesToRead {
    NSSet* characteristicTypesSet = [self characteristicDataTypesToRead];
    NSSet* otherTypesSet = [self dataTypesToRead];
    
    return [otherTypesSet setByAddingObjectsFromSet: characteristicTypesSet];
}

// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet *)characteristicDataTypesToRead {
    NSMutableSet* dataTypesSet = [[NSMutableSet alloc] init];
    
//    // CharacteristicType
//    HKCharacteristicType *characteristicType;
//    characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex];
//    [dataTypesSet addObject:characteristicType];
//    characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBloodType];
//    [dataTypesSet addObject:characteristicType];
//    characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
//    [dataTypesSet addObject:characteristicType];
//    characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierFitzpatrickSkinType];
//    [dataTypesSet addObject:characteristicType];
    
    return dataTypesSet;
}


- (NSSet *) getDataQuantityTypes{
    NSMutableSet* dataTypesSet = [[NSMutableSet alloc] init];
    
//    // QuantityType
    HKQuantityType *quantityType;
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyFatPercentage];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierLeanBodyMass];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalEnergyBurned];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierNikeFuel];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyTemperature];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalBodyTemperature];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierRespiratoryRate];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierOxygenSaturation];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierPeripheralPerfusionIndex];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierNumberOfTimesFallen];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierElectrodermalActivity];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierInhalerUsage];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodAlcoholContent];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierForcedVitalCapacity];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierForcedExpiratoryVolume1];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierPeakExpiratoryFlowRate];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFatTotal];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFatPolyunsaturated];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFatMonounsaturated];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFatSaturated];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCholesterol];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietarySodium];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCarbohydrates];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFiber];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietarySugar];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryProtein];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminA];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminB6];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminB12];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminC];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminD];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminE];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminK];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCalcium];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryIron];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryThiamin];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryRiboflavin];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryNiacin];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFolate];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryBiotin];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryPantothenicAcid];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryPhosphorus];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryIodine];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryMagnesium];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryZinc];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietarySelenium];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCopper];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryManganese];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryChromium];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryMolybdenum];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryChloride];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryPotassium];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCaffeine];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierUVExposure];
    [dataTypesSet addObject:quantityType];
    
    return dataTypesSet;
}

- (NSSet *) getDataCategoryTypes{
     NSMutableSet* dataTypesSet = [[NSMutableSet alloc] init];
    
//    // CategoryType
    HKCategoryType *categoryType;
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    [dataTypesSet addObject:categoryType];
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierAppleStandHour];
    [dataTypesSet addObject:categoryType];
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierCervicalMucusQuality];
    [dataTypesSet addObject:categoryType];
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierOvulationTestResult];
    [dataTypesSet addObject:categoryType];
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierMenstrualFlow];
    [dataTypesSet addObject:categoryType];
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierIntermenstrualBleeding];
    [dataTypesSet addObject:categoryType];
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSexualActivity];
    [dataTypesSet addObject:categoryType];

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
    [dataTypesSet addObject:corrType];
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


//////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

- (NSDate *) getLastUpdate {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate * lastUpdate =  [userDefaults objectForKey:@"plugin_health_kit_last_update_timestamp"];
    if(lastUpdate == nil){
        return [[NSDate new] dateByAddingTimeInterval:-1*60*60*24*7]; // 7 days before
    }else{
        return lastUpdate;
    }
}

- (void) setLastUpdate :(NSDate *) date {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:date forKey:@"plugin_health_kit_last_update_timestamp"];
}

@end
