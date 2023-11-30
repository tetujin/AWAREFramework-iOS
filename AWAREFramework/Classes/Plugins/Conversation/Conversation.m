//
//  StudentLife.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/21/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//
//

/**
 This plugin was developed as a collaboration between Cornell and Dartmouth College for the StudentLife project (http://studentlife.cs.dartmouth.edu/ ) and later extended to support the converstations start/end at the Center for Ubiquitous Computing at the University of Oulu.
 */

#import "Conversation.h"
#import "AWAREKeys.h"
#import "EntityConversation+CoreDataClass.h"

NSString * const AWARE_PREFERENCES_STATUS_CONVERSATION = @"status_plugin_studentlife_audio";

@interface Conversation ()
@end

@implementation Conversation{
    NSString * KEY_TIMESTAMP;
    NSString * KEY_DEVICE_ID;
    NSString * KEY_DATATYPE;
    NSString * KEY_DOUBLE_ENERGY;
    NSString * KEY_INFERENCE;
    NSString * KEY_BLOB_FEATURE;
    NSString * KEY_DOUBLE_CONVO_START;
    NSString * KEY_DOUBLE_CONVO_END;
    
    NSTimer * timer;
    
    NSNumber * DATA_TYPE_INFERENCE;
    NSNumber * DATA_TYPE_FEATURE;
    NSNumber * DATA_TYPE_CONVO;
}
    
    
- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    
    if (dbType == AwareDBTypeCSV) {
        storage = [[CSVStorage alloc] initWithStudy:study
                                         sensorName:SENSOR_PLUGIN_STUDENTLIFE_AUDIO
                                       headerLabels:@[@"timestamp",@"device_id",@"datatype",@"double_energy",@"inference",@"blob_feature",@"double_convo_start",@"double_convo_end"]
                                        headerTypes:@[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeInteger),@(CSVTypeReal),@(CSVTypeInteger),@(CSVTypeBlob), @(CSVTypeReal), @(CSVTypeReal)]];
    }else if (dbType == AwareDBTypeJSON){
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_STUDENTLIFE_AUDIO];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study
                                            sensorName:SENSOR_PLUGIN_STUDENTLIFE_AUDIO
                                            entityName:NSStringFromClass([EntityConversation class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            EntityConversation * conversation = (EntityConversation *)[NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:childContext];
                                            
                                            conversation.timestamp = [data objectForKey:self->KEY_TIMESTAMP];
                                            conversation.device_id = [data objectForKey:self->KEY_DEVICE_ID];
                                            conversation.datatype = [data objectForKey:self->KEY_DATATYPE];
                                            conversation.double_energy = [data objectForKey:self->KEY_DOUBLE_ENERGY];
                                            conversation.inference = [data objectForKey:self->KEY_INFERENCE];// 0:Silence, 1:Voice, 2:Noise, 3:Unknown
//                                            conversation.blob_feature = [data objectForKey:self->KEY_BLOB_FEATURE];
                                            conversation.double_convo_start = [data objectForKey:self->KEY_DOUBLE_CONVO_START];
                                            conversation.double_convo_end = [data objectForKey:self->KEY_DOUBLE_CONVO_END];
        }];
    }
    
    self = [super initWithAwareStudy:study sensorName:SENSOR_PLUGIN_STUDENTLIFE_AUDIO storage:storage];
    if (self != nil) {
        [self initKeys];
        _conversationsDelay = 3;
        _conversationsOffDudy = 1;
    }
    return self;
}


- (void) initKeys{
    KEY_TIMESTAMP = @"timestamp";
    KEY_DEVICE_ID = @"device_id";
    KEY_DATATYPE = @"datatype";
    KEY_DOUBLE_ENERGY = @"double_energy";
    KEY_INFERENCE = @"inference";
    KEY_BLOB_FEATURE = @"blob_feature";
    KEY_DOUBLE_CONVO_START = @"double_convo_start";
    KEY_DOUBLE_CONVO_END = @"double_convo_end";
    
    DATA_TYPE_INFERENCE = @0;
    DATA_TYPE_FEATURE = @1;
    DATA_TYPE_CONVO = @2;
}

- (void) createTable{
    NSMutableString * query = [[NSMutableString alloc] init];
    [query appendFormat:@"_id integer primary key autoincrement,"];
    [query appendFormat:@"%@ real default 0," , KEY_TIMESTAMP];
    [query appendFormat:@"%@ text default '',", KEY_DEVICE_ID];
    
    [query appendFormat:@"%@ integer default 0," , KEY_DATATYPE];
    [query appendFormat:@"%@ real default 0,"    , KEY_DOUBLE_ENERGY];
    [query appendFormat:@"%@ integer default -1,", KEY_INFERENCE];
    [query appendFormat:@"%@ blob default null,",KEY_BLOB_FEATURE];
    [query appendFormat:@"%@ double default 0," , KEY_DOUBLE_CONVO_START];
    [query appendFormat:@"%@ double default 0" , KEY_DOUBLE_CONVO_END];
//    [query appendString:@"UNIQUE (timestamp,device_id)"];
    
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void)setParameters:(NSArray *)parameters{
    int delay = [self getSensorSetting:parameters withKey:@"plugin_conversations_delay"];
    if (delay > 0) {
        _conversationsDelay = delay;
    }
    
    int off_duty = [self getSensorSetting:parameters withKey:@"plugin_conversations_off_duty"];
    if (off_duty > 0) {
        _conversationsOffDudy = off_duty;
    }
    
    int length = [self getSensorSetting:parameters withKey:@"plugin_conversations_length"];
    if (length > 0){
        _conversationsLength = length;
    }

}


- (BOOL)startSensor{
    
    __block typeof(self) blockSelf = self;
    self.pipeline = [[AudioPipeline alloc] init];
    [self.pipeline setAudioInterfaceEventHandler:^(int inference, double energy, long timestamp, long sync_id) {
        [blockSelf saveAudioInference:inference energy:energy timestamp:timestamp sync_id:sync_id];
    }];
    [self.pipeline setConversationEventHandler:^(long startTime, long endTime) {
        [blockSelf saveConversationInfo:startTime endTime:endTime];
    }];
    [self.pipeline setConversationStartEventHandler:^(long startTime) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_PLUGIN_CONVERSATIONS_START"
                                                            object:nil
                                                          userInfo:nil];
    }];
    [self.pipeline setConversationEndEventHandler:^(long endTime) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_PLUGIN_CONVERSATIONS_END"
                                                            object:nil
                                                          userInfo:nil];
    }];
    
    if (_conversationsDelay>0) {
        [self.pipeline setTimeOfDutyCycleOffBySecond:_conversationsDelay * 60];
    }

    if (_conversationsOffDudy > 0) {
        [self.pipeline setTimeOfDutyCycleOffInConversationBySecond:_conversationsOffDudy * 60];
    }
    
    [self setSensingState:YES];
    [self.pipeline startPipeline];
    return YES;
}

- (BOOL) stopSensor {
    [self.pipeline stopPipeline];
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    [self setSensingState:NO];
    return YES;
}

/// AudioInferenceRecorder accesss following methods for saving the sensor data.
-(void)saveAudioInference: (int)inference_int energy:(double)energy timestamp:(long)timestamp sync_id:(long) sync_id {
    NSMutableDictionary *audioData = [[NSMutableDictionary alloc] init];
    [audioData setObject:[NSNumber numberWithLongLong:timestamp] forKey:KEY_TIMESTAMP];
    [audioData setObject:[self getDeviceId] forKey:KEY_DEVICE_ID];
    [audioData setObject:DATA_TYPE_INFERENCE forKey:KEY_DATATYPE];
    [audioData setObject:[NSNumber numberWithDouble:energy] forKey:KEY_DOUBLE_ENERGY];
    [audioData setObject:[NSNumber numberWithInt:inference_int] forKey:KEY_INFERENCE];// 0:Silence, 1:Voice, 2:Noise, 3:Unknown
    [audioData setObject:[NSNull new] forKey:KEY_BLOB_FEATURE];
    [audioData setObject:@0 forKey:KEY_DOUBLE_CONVO_START];
    [audioData setObject:@0 forKey:KEY_DOUBLE_CONVO_END];
    NSString * message = [NSString stringWithFormat:@"[type=%d], [energy=%f], [ts=%ld], [sync_id=%ld]", inference_int, energy, timestamp, sync_id];
    if (self.isDebug) {
        NSLog(@"save audio inference: %@", message);
    }
    [self setLatestValue:message];
    [self setLatestData:audioData];
    [self.storage saveDataWithDictionary:audioData buffer:NO saveInMainThread:YES];
}


-(void)saveConversationInfo: (long)startTime endTime:(long)endTime {
    NSMutableDictionary *audioData = [[NSMutableDictionary alloc] init];
    [audioData setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_TIMESTAMP];
    [audioData setObject:[self getDeviceId] forKey:KEY_DEVICE_ID];
    [audioData setObject:DATA_TYPE_CONVO forKey:KEY_DATATYPE];
    [audioData setObject:@0 forKey:KEY_DOUBLE_ENERGY];
    [audioData setObject:@(-1) forKey:KEY_INFERENCE];// 0:Silence, 1:Voice, 2:Noise, 3:Unknown
    [audioData setObject:[NSNull new] forKey:KEY_BLOB_FEATURE];
    [audioData setObject:[NSNumber numberWithLongLong:startTime] forKey:KEY_DOUBLE_CONVO_START];
    [audioData setObject:[NSNumber numberWithLongLong:endTime] forKey:KEY_DOUBLE_CONVO_END];
    NSString *result = [NSString stringWithFormat:@"%ld,%ld", startTime, endTime];
    if([self isDebug]){
        NSLog(@"conversation result: %@", result);
    }
    [self setLatestValue:result];
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, audioData);
    }
    [self.storage saveDataWithDictionary:audioData buffer:NO saveInMainThread:YES];
}

@end
