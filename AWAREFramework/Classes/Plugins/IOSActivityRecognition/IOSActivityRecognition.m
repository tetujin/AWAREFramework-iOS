//
//  IOSActivityRecognition.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 9/19/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "IOSActivityRecognition.h"
#import "EntityIOSActivityRecognition+CoreDataClass.h"


NSString * const AWARE_PREFERENCES_STATUS_IOS_ACTIVITY_RECOGNITION    = @"status_plugin_ios_activity_recognition";
NSString * const AWARE_PREFERENCES_FREQUENCY_IOS_ACTIVITY_RECOGNITION = @"frequency_plugin_ios_activity_recognition";
NSString * const AWARE_PREFERENCES_LIVE_MODE_IOS_ACTIVITY_RECOGNITION = @"status_plugin_ios_activity_recognition_live";

@implementation IOSActivityRecognition {
    CMMotionActivityManager *motionActivityManager;
    NSString * KEY_TIMESTAMP_OF_LAST_UPDATE;
    NSTimer * timer;
    
    /* stationary,walking,running,automotive,cycling,unknown */
    NSString * ACTIVITY_NAME_STATIONARY;
    NSString * ACTIVITY_NAME_WALKING;
    NSString * ACTIVITY_NAME_RUNNING;
    NSString * ACTIVITY_NAME_AUTOMOTIVE;
    NSString * ACTIVITY_NAME_CYCLING;
    NSString * ACTIVITY_NAME_UNKNOWN;
    NSString * CONFIDENCE;
    NSString * ACTIVITIES;
    NSString * LABEL;
    CMMotionActivity * latestActivity;
    
    int disposableCount;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    ACTIVITIES = @"activities";
    CONFIDENCE = @"confidence";
    ACTIVITY_NAME_STATIONARY = @"stationary";
    ACTIVITY_NAME_WALKING    = @"walking";
    ACTIVITY_NAME_RUNNING    = @"running";
    ACTIVITY_NAME_AUTOMOTIVE = @"automotive";
    ACTIVITY_NAME_CYCLING    = @"cycling";
    ACTIVITY_NAME_UNKNOWN    = @"unknown";
    LABEL = @"label";
    
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_IOS_ACTIVITY_RECOGNITION];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp", @"device_id", ACTIVITIES,CONFIDENCE,ACTIVITY_NAME_STATIONARY,ACTIVITY_NAME_WALKING,ACTIVITY_NAME_RUNNING,ACTIVITY_NAME_AUTOMOTIVE,ACTIVITY_NAME_CYCLING,ACTIVITY_NAME_UNKNOWN,LABEL];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeTextJSONArray),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeText)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_IOS_ACTIVITY_RECOGNITION headerLabels:header headerTypes:headerTypes];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_IOS_ACTIVITY_RECOGNITION entityName:NSStringFromClass([EntityIOSActivityRecognition class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            
                                            EntityIOSActivityRecognition * entityActivity = (EntityIOSActivityRecognition *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                                                                                          inManagedObjectContext:childContext];
                                            entityActivity.device_id  = [data objectForKey:@"device_id"];
                                            entityActivity.timestamp  = [data objectForKey:@"timestamp"];
                                            entityActivity.confidence = [data objectForKey:self->CONFIDENCE];
                                            entityActivity.activities = [data objectForKey:self->ACTIVITIES];
                                            entityActivity.label      = [data objectForKey:self->LABEL];
                                            entityActivity.stationary = [data objectForKey:self->ACTIVITY_NAME_STATIONARY];
                                            entityActivity.walking    = [data objectForKey:self->ACTIVITY_NAME_WALKING];
                                            entityActivity.running    = [data objectForKey:self->ACTIVITY_NAME_RUNNING];
                                            entityActivity.automotive = [data objectForKey:self->ACTIVITY_NAME_AUTOMOTIVE];
                                            entityActivity.cycling    = [data objectForKey:self->ACTIVITY_NAME_CYCLING];
                                            entityActivity.unknown    = [data objectForKey:self->ACTIVITY_NAME_UNKNOWN];
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_IOS_ACTIVITY_RECOGNITION
                             storage:storage];
    
    if (self) {
        motionActivityManager = [[CMMotionActivityManager alloc] init];
        KEY_TIMESTAMP_OF_LAST_UPDATE = @"key_sensor_ios_activity_recognition_last_update_timestamp";
        _sensingInterval = 60*3; // 3 min
        disposableCount = 0;
        _sensingMode = IOSActivityRecognitionModeLive;
        _confidenceFilter = CMMotionActivityConfidenceLow;
    }
    return self;
}

- (void) createTable{
    
    // creata original table
    NSString *query = [[NSString alloc] init];

    // https://developer.apple.com/reference/coremotion/cmmotionactivity?language=objc
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:ACTIVITIES               type:TCQTypeText    default:@"''"  ];   // e.g., stationary,cycling
    [tcqMaker addColumn:CONFIDENCE               type:TCQTypeInteger default:@"-1"];   // -1=Unknown; 0=Low(low); 1=Medium(good); 2=High(high)
    [tcqMaker addColumn:ACTIVITY_NAME_STATIONARY type:TCQTypeInteger default:@"0" ];   // 0 or 1
    [tcqMaker addColumn:ACTIVITY_NAME_WALKING    type:TCQTypeInteger default:@"0" ];   // 0 or 1
    [tcqMaker addColumn:ACTIVITY_NAME_RUNNING    type:TCQTypeInteger default:@"0" ];   // 0 or 1
    [tcqMaker addColumn:ACTIVITY_NAME_AUTOMOTIVE type:TCQTypeInteger default:@"0" ];   // 0 or 1
    [tcqMaker addColumn:ACTIVITY_NAME_CYCLING    type:TCQTypeInteger default:@"0" ];   // 0 or 1
    [tcqMaker addColumn:ACTIVITY_NAME_UNKNOWN    type:TCQTypeInteger default:@"0" ];   // 0 or 1
    [tcqMaker addColumn:LABEL                    type:TCQTypeText    default:@"''"  ];
    
    query = [tcqMaker getDefaudltTableCreateQuery];
    /* stationary,walking,running,automotive,cycling,unknown */
    
    [self.storage createDBTableOnServerWithQuery:query];
}


-(void)setParameters:(NSArray *)parameters{
    
    double frequency = [self getSensorSetting:parameters withKey:@"frequency_plugin_ios_activity_recognition"];
    if (frequency > 0) {
        _sensingInterval = frequency;
    }
    
    int liveMode = [self getSensorSetting:parameters withKey:@"status_plugin_ios_activity_recognition_live"];
    
    if(liveMode == 1){
        _sensingMode = IOSActivityRecognitionModeLive;
    }else{
        _sensingMode = IOSActivityRecognitionModeHistory;
    }
}

- (BOOL)startSensor{
    return [self startSensorWithConfidenceFilter:_confidenceFilter mode:IOSActivityRecognitionModeHistory interval:_sensingInterval disposableLimit:0];
}

- (BOOL) startSensorAsLiveModeWithFilterLevel:(CMMotionActivityConfidence) filterLevel {
    return [self startSensorWithConfidenceFilter:filterLevel mode:IOSActivityRecognitionModeLive interval:_sensingInterval disposableLimit:0];
}

- (BOOL) startSensorAsHistoryModeWithFilterLevel:(CMMotionActivityConfidence)filterLevel interval:(double) interval{
    return [self startSensorWithConfidenceFilter:filterLevel mode:IOSActivityRecognitionModeHistory interval:interval disposableLimit:0];
}

- (BOOL) startSensorWithConfidenceFilter:(CMMotionActivityConfidence) filterLevel
                                    mode:(IOSActivityRecognitionMode)mode
                                interval:(double) interval
                         disposableLimit:(int)limit{
    [self setSensingState:YES];
    // history mode
    if( mode == IOSActivityRecognitionModeHistory){
        [self getMotionActivity:nil];
        timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                 target:self
                                               selector:@selector(getMotionActivity:)
                                               userInfo:nil
                                                repeats:YES];
        // live mode
    }else if( mode == IOSActivityRecognitionModeLive ){
        /** motion activity */
        if([CMMotionActivityManager isActivityAvailable]){
            motionActivityManager = [CMMotionActivityManager new];
            [motionActivityManager startActivityUpdatesToQueue:[NSOperationQueue new]
                                                   withHandler:^(CMMotionActivity *activity) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                           NSDictionary * data = [self toDictionary:activity];
                                                            if (data != nil) {
                                                                // [self saveData:data];
                                                                [self.storage saveDataWithDictionary:data buffer:NO saveInMainThread:YES];
                                                            }
                                                        });
                                                   }];

        }else{
            return NO;
        }
    // disposable mode
    }else if(mode == IOSActivityRecognitionModeDisposable){
        /** motion activity */
        if([CMMotionActivityManager isActivityAvailable]){
            // NSLog(@"Start iOS Activity Recognition Plugin as disposable mode (limit=%d)",limit);
            motionActivityManager = [CMMotionActivityManager new];
            [motionActivityManager startActivityUpdatesToQueue:[NSOperationQueue new]
                                                   withHandler:^(CMMotionActivity *activity) {
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           if (activity != nil) {
                                                               NSDictionary * activityDict = [self toDictionary:activity];
                                                               [self.storage saveDataWithDictionary:activityDict buffer:NO saveInMainThread:YES];
                                                               // [self addMotionActivity:activity];
                                                               NSString * message = [NSString stringWithFormat:@"[%d] disposable mode: %@", self->disposableCount, activity.debugDescription];
                                                               if (self.isDebug) {
                                                                   NSLog(@"%@", message);
                                                               }
                                                               if(self->disposableCount < limit){
                                                                   self->disposableCount++;
                                                               }else{
                                                                   [self->motionActivityManager stopActivityUpdates];
                                                                   self->disposableCount = 0;
                                                                   if([self isDebug]){
                                                                       NSLog(@"Stop iOS Activity Recognition Plugin as disposable mode");
                                                                       // [AWAREUtils sendLocalNotificationForMessage:message soundFlag:NO];
                                                                   }
                                                               }
                                                           }
                                                       });
                                                   }];
            
        }else{
            return NO;
        }
    }
    return YES;
}

- (BOOL)stopSensor{
    // Stop and remove a motion sensor
    [motionActivityManager stopActivityUpdates];
    motionActivityManager = nil;
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    [self setSensingState:NO];
    return YES;
}

- (void)changedBatteryState{
    [self getMotionActivity:nil];
}


//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

- (void) getMotionActivity:(id)sender{
    
//     NSOperationQueue *operationQueueUpdate = [NSOperationQueue new]; // [NSOperationQueue mainQueue];
    NSOperationQueue *operationQueueUpdate = [NSOperationQueue mainQueue];

    if([CMMotionActivityManager isActivityAvailable]){
        // from data
        NSDate * fromDate = [self getLastUpdate];
        // NSDate * fromDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:-7*24 nextDay:NO];
        // to date
        NSDate * toDate = [NSDate new];
        motionActivityManager = [CMMotionActivityManager new];
        [motionActivityManager queryActivityStartingFromDate:fromDate toDate:toDate toQueue:operationQueueUpdate withHandler:^(NSArray<CMMotionActivity *> * _Nullable activities, NSError * _Nullable error) {
            if (activities!=nil && error==nil) {
                NSMutableArray * array = [[NSMutableArray alloc] init];
                for (CMMotionActivity * activity in activities) {
                    NSDictionary * dict = [self toDictionary:activity];
                    if (dict!=nil) {
                        [array addObject:dict];
                    }
                    self->latestActivity = activity;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    // NSLog(@"[%@] %ld records", [self getSensorName], array.count);
                    // [self saveDataWithArray:array];
                    [self.storage saveDataWithArray:array buffer:NO saveInMainThread:YES];
                    if (self->latestActivity != nil) {
                        NSDictionary * activityDict = [self toDictionary:self->latestActivity];
                        if (activityDict != nil) {
                            [self setLatestValue:[activityDict objectForKey:self->ACTIVITIES]];
                            [self setLatestData:activityDict];
                            
                            NSDictionary * userInfo = [NSDictionary dictionaryWithObject:activityDict
                                                                                  forKey:EXTRA_DATA];
                            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_IOS_ACTIVITY_RECOGNITION
                                                                                object:nil
                                                                              userInfo:userInfo];
                        }
                    }
                });
                
                [self setLastUpdateWithDate:toDate];
                
                if ([self isDebug]) {
                    NSInteger count = activities.count;
                    NSString * message = [NSString stringWithFormat:@"iOS Activity Recognition Sensor is called by a timer (%ld activites)" ,count];
                    NSLog(@"%@",message);
                }
            }
        }];
    }
}


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////


- (NSDictionary *) toDictionary: (CMMotionActivity *) motionActivity{
    
    // NSLog(@"%ld", motionActivity.confidence);
    
    switch (_confidenceFilter) {
        case CMMotionActivityConfidenceHigh:
            if(motionActivity.confidence == CMMotionActivityConfidenceMedium ||
               motionActivity.confidence == CMMotionActivityConfidenceLow){
                return nil;
            }
            break;
        case CMMotionActivityConfidenceMedium:
            if(motionActivity.confidence == CMMotionActivityConfidenceLow){
                return nil;
            }
            break;
        case CMMotionActivityConfidenceLow:
            break;
        default:
            break;
    }
    
    // NSLog(@"stored");
    
    NSNumber *motionConfidence = @(-1);
    if (motionActivity.confidence  == CMMotionActivityConfidenceHigh){
        motionConfidence = @2;
    }else if(motionActivity.confidence == CMMotionActivityConfidenceMedium){
        motionConfidence = @1;
    }else if(motionActivity.confidence == CMMotionActivityConfidenceLow){
        motionConfidence = @0;
    }
    
    // Motion types are refere from Google Activity Recognition
    //https://developers.google.com/android/reference/com/google/android/gms/location/DetectedActivity
    NSMutableArray * activities = [[NSMutableArray alloc] init];
    
    if (motionActivity.unknown){
        [activities addObject:ACTIVITY_NAME_UNKNOWN];
    }
    
    if (motionActivity.stationary){
        [activities addObject:ACTIVITY_NAME_STATIONARY];
    }
    
    if (motionActivity.running){
        [activities addObject:ACTIVITY_NAME_RUNNING];
    }
    
    if (motionActivity.walking){
        [activities addObject:ACTIVITY_NAME_WALKING];
    }
    
    if (motionActivity.automotive){
        [activities addObject:ACTIVITY_NAME_AUTOMOTIVE];
    }
    
    if (motionActivity.cycling){
        [activities addObject:ACTIVITY_NAME_CYCLING];
    }
    
    NSString * activitiesStr = @"";
    if (activities != nil && activities.count > 0) {
        if([NSJSONSerialization isValidJSONObject:activities]){
            NSError * error = nil;
            NSData *json = [NSJSONSerialization dataWithJSONObject:activities
                                                           options:0
                                                             error:&error];
            if (error == nil) {
                activitiesStr = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
            }
        }
    }
    
    if ([self isDebug]) {
        NSLog(@"[%@] %@ %ld", motionActivity.startDate, activitiesStr, motionActivity.confidence);
    }
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:motionActivity.startDate];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime                     forKey:@"timestamp"];
    [dict setObject:[self getDeviceId]           forKey:@"device_id"];
    [dict setObject:activitiesStr                forKey:ACTIVITIES];
    [dict setObject:motionConfidence             forKey:CONFIDENCE];
    [dict setObject:@(motionActivity.stationary) forKey:ACTIVITY_NAME_STATIONARY];   // 0 or 1
    [dict setObject:@(motionActivity.walking)    forKey:ACTIVITY_NAME_WALKING];   // 0 or 1
    [dict setObject:@(motionActivity.running)    forKey:ACTIVITY_NAME_RUNNING];   // 0 or 1
    [dict setObject:@(motionActivity.automotive) forKey:ACTIVITY_NAME_AUTOMOTIVE];   // 0 or 1
    [dict setObject:@(motionActivity.cycling)    forKey:ACTIVITY_NAME_CYCLING];   // 0 or 1
    [dict setObject:@(motionActivity.unknown)    forKey:ACTIVITY_NAME_UNKNOWN];   // 0 or 1
    [dict setObject:@""                          forKey:LABEL];
    
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, dict);
    }
    
    return dict;
}


-(NSString*)timestamp2date:(NSDate*)date{
    //[timeStampString stringByAppendingString:@"000"];   //convert to ms
    NSDateFormatter *_formatter=[[NSDateFormatter alloc]init];
    [_formatter setDateFormat:@"dd/MM/yy hh/mm/ss"];
    return [_formatter stringFromDate:date];
}

- (NSDictionary *) getActivityDicWithName:(NSString*) activityName confidence:(NSNumber *) confidence  {
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject:activityName forKey:@"activity"];
    [dic setObject:confidence forKey:@"confidence"];
    return dic;
}

- (void) setLastUpdateWithDate:(NSDate *)date{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:date forKey:KEY_TIMESTAMP_OF_LAST_UPDATE];
}

- (NSDate *) getLastUpdate {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate * date = [defaults objectForKey:KEY_TIMESTAMP_OF_LAST_UPDATE];
    if (date != nil) {
        return date;
    }else{
        return [NSDate new];
    }
}


@end
