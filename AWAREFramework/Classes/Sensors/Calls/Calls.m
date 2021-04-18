//
//  Telephony.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/19/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  http://www.awareframework.com/communication/
//  https://developer.apple.com/library/ios/documentation/ContactData/Conceptual/AddressBookProgrammingGuideforiPhone/Chapters/QuickStart.html#//apple_ref/doc/uid/TP40007744-CH2-SW1
//

#import "Calls.h"
#import "AWAREUtils.h"
#import "EntityCall.h"

NSString* const AWARE_PREFERENCES_STATUS_CALLS = @"status_calls";

NSString* const KEY_CALLS_TIMESTAMP = @"timestamp";
NSString* const KEY_CALLS_DEVICEID = @"device_id";
NSString* const KEY_CALLS_CALL_TYPE = @"call_type";
NSString* const KEY_CALLS_CALL_DURATION = @"call_duration";
NSString* const KEY_CALLS_TRACE = @"trace";

@implementation Calls {
    NSDate * start;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"calls"];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[KEY_CALLS_TIMESTAMP, KEY_CALLS_DEVICEID, KEY_CALLS_CALL_TYPE, KEY_CALLS_CALL_DURATION, KEY_CALLS_TRACE];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeText)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:@"calls" headerLabels:header headerTypes:headerTypes];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:@"calls" entityName:NSStringFromClass([EntityCall class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            
                                            EntityCall* callData = (EntityCall *)[NSEntityDescription
                                                                                  insertNewObjectForEntityForName:entity
                                                                                  inManagedObjectContext:childContext];
                                            callData.device_id = [data objectForKey:KEY_CALLS_DEVICEID];
                                            callData.timestamp = [data objectForKey:KEY_CALLS_TIMESTAMP];
                                            callData.call_type = [data objectForKey:KEY_CALLS_CALL_TYPE];
                                            callData.call_duration = [data objectForKey:KEY_CALLS_CALL_DURATION];
                                            callData.trace = [data objectForKey:KEY_CALLS_TRACE];
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:@"calls" storage:storage];
    if (self!=nil) {
        // [self setCSVHeader:
    }
    return self;
}


- (void) createTable{
    if([self isDebug]){
        NSLog(@"[%@] Create Telephony Sensor Table", [self getSensorName]);
    }
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:KEY_CALLS_CALL_TYPE type:TCQTypeInteger default:@"0"];
    [maker addColumn:KEY_CALLS_CALL_DURATION type:TCQTypeInteger default:@"0"];
    [maker addColumn:KEY_CALLS_TRACE type:TCQTypeText default:@"''"];
    [self.storage createDBTableOnServerWithTCQMaker:maker];
}

- (void)setParameters:(NSArray *)parameters{
    
}

-(BOOL)startSensor{
    if (_callObserver == nil) {
        _callObserver = [[CXCallObserver alloc] init];
        [_callObserver setDelegate:self queue:nil];
    }
    [self setSensingState:YES];
    return YES;
}



-(BOOL) stopSensor{
    _callObserver = nil;
    
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    
    [self setSensingState:NO];
    return YES;
}

- (void)callObserver:(nonnull CXCallObserver *)callObserver callChanged:(nonnull CXCall *)call {
    
    if (self->start == nil) self->start = [NSDate new];

    // one of the Android’s call types (1 – incoming, 2 – outgoing, 3 – missed)
    if ( (call.hasEnded   == true && call.isOutgoing == false) || // incoming end
         (call.hasEnded   == true && call.isOutgoing == true) )
    {   // outgoing end
        if (self.isDebug) NSLog(@"Disconnected");
        [self saveCallEventWithType:@4 callChanged:call];
    }
    
    if (call.isOutgoing == true && call.hasConnected == false && call.hasEnded == false) {
        if (self.isDebug) NSLog(@"Dialing");
        [self saveCallEventWithType:@3 callChanged:call];
    }
    
    if (call.isOutgoing == false && call.hasConnected == false && call.hasEnded == false) {
        if (self.isDebug) NSLog(@"Incoming");
        [self saveCallEventWithType:@1 callChanged:call];
    }
    
    if (call.hasConnected == true && call.hasEnded == false) {
        if (self.isDebug) NSLog(@"Connected");
        [self saveCallEventWithType:@2 callChanged:call];
    }
}

- (void) saveCallEventWithType:(nonnull NSNumber *)callType callChanged:(nonnull CXCall *)call{
    
    NSString * callId = [call.UUID UUIDString];
    NSString * callTypeStr = @"Unknown";
    int duration = 0;
    
    if ([callType isEqual:@1]) {
        // start
        self->start = [NSDate new];
        callTypeStr = @"Incoming";
    } else if ([callType isEqual:@2]){
        duration = [[NSDate new] timeIntervalSinceDate:self->start];
        self->start = [NSDate new];
        callTypeStr = @"Connected";
    } else if ([callType isEqual:@3]){
        self->start = [NSDate new];
        callTypeStr = @"Dialing";
    } else if ([callType isEqual:@4]){
        callTypeStr = @"Disconnected";
        duration = [[NSDate new] timeIntervalSinceDate:self->start];
        self->start = [NSDate new];
    }

    if ([self isDebug]) {
        NSLog(@"[%@] Call Duration is %d seconds @ [%@]", [super getSensorName], duration, callTypeStr);
    }
    
    NSNumber *durationValue = [NSNumber numberWithInt:duration];
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_CALLS_TIMESTAMP];
    [dict setObject:[super getDeviceId] forKey:KEY_CALLS_DEVICEID];
    [dict setObject:callType forKey:KEY_CALLS_CALL_TYPE];
    [dict setObject:durationValue forKey:KEY_CALLS_CALL_DURATION];
    [dict setObject:callId forKey:KEY_CALLS_TRACE];
    if (self.label != nil) {
        [dict setObject:self.label forKey:@"label"];
    }else{
        [dict setObject:@"" forKey:@"label"];
    }

    // [super saveData:dict];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
    [super setLatestData:dict];

    // Set latest sensor data
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"YYYY-MM-dd HH:mm"];
    NSString * dateStr = [timeFormat stringFromDate:[NSDate new]];
    NSString * latestData = [NSString stringWithFormat:@"%@ [%@] %d seconds",dateStr, callTypeStr, duration];
    [super setLatestValue: latestData];

    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, dict);
    }

    // Broadcast a notification
    // http://www.awareframework.com/communication/
    // [NOTE] On the Andoind AWARE client, when the ACTION_AWARE_USER_NOT_IN_CALL and ACTION_AWARE_USER_IN_CALL are called?
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict forKey:EXTRA_DATA];
    if ([callType isEqual:@1]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_CALL_RINGING
                                                            object:nil
                                                          userInfo:userInfo];
    } else if ([callType isEqual:@2]){
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_CALL_ACCEPTED
                                                            object:nil
                                                          userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_USER_IN_CALL
                                                            object:nil
                                                          userInfo:userInfo];
    } else if ([callType isEqual:@3]){
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_CALL_MADE
                                                            object:nil
                                                          userInfo:userInfo];
    } else if ([callType isEqual:@4]){
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_CALL_MISSED
                                                            object:nil
                                                          userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_USER_NOT_IN_CALL
                                                            object:nil
                                                          userInfo:userInfo];
    }
}

@end
