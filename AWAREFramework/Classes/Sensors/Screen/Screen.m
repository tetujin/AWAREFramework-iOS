//
//  Screen.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//


/**
 * I referenced following source code for detecting screen lock/unlock events. Thank you very much!
 * http://stackoverflow.com/questions/706344/lock-unlock-events-iphone
 * http://stackoverflow.com/questions/6114677/detect-if-iphone-screen-is-on-off
 */

#import "Screen.h"
#import "notify.h"
#import "EntityScreen.h"

NSString * const AWARE_PREFERENCES_STATUS_SCREEN  = @"status_screen";

@implementation Screen {
    int _notifyTokenForDidChangeLockStatus;
    int _notifyTokenForDidChangeDisplayStatus;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_SCREEN];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp",@"device_id",@"screen_status"];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_SCREEN withHeader:header];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_SCREEN entityName:NSStringFromClass([EntityScreen class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            
                                            EntityScreen* entityScreen = (EntityScreen *)[NSEntityDescription
                                                                                          insertNewObjectForEntityForName:entity
                                                                                          inManagedObjectContext:childContext];
                                            
                                            entityScreen.device_id = [data objectForKey:@"device_id"];
                                            entityScreen.timestamp = [data objectForKey:@"timestamp"];
                                            entityScreen.screen_status = [data objectForKey:@"screen_status"];
                                            
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_SCREEN
                             storage:storage];
    if (self) {
        
    }
    return self;
}


- (void) createTable{
    if([self isDebug]){
        NSLog(@"[%@] Create Table", [self getSensorName]);
    }
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "screen_status integer default 0";
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void)setParameters:(NSArray *)parameters{
    
}

- (BOOL) startSensor{
    if ([self isDebug]) {
        NSLog(@"[%@] Start Screen Sensor", [self getSensorName]);
    }
    [self registerAppforDetectLockState];
    [self registerAppforDetectDisplayStatus];
    return YES;
}

- (BOOL) stopSensor {
    // Stop a sync timer
    [self unregisterAppforDetectDisplayStatus];
    [self unregisterAppforDetectLockState];
    return YES;
}

- (void)saveDummyData {
    [self saveScreenEvent:0];
}

/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////



-(void)registerAppforDetectLockState {
    NSString * head = @"com.apple.springboard";
    NSString * tail = @".lockstate";
    
    notify_register_dispatch((char *)[head stringByAppendingString:tail].UTF8String, &_notifyTokenForDidChangeLockStatus,dispatch_get_main_queue(), ^(int token) {
        
        uint64_t state = UINT64_MAX;
        notify_get_state(token, &state);
        
        int awareScreenState = 0;
        
        if(state == 0) {
            if ([self isDebug]) {
                NSLog(@"unlock device");
//                [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"(3) Unlock at %@",[self nsdate2FormattedTime:[NSDate new]]]
//                                                  soundFlag:NO];
            }
            awareScreenState = 3;
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_SCREEN_UNLOCKED
                                                                object:nil
                                                              userInfo:nil];
        } else {
            if ([self isDebug]) {
                NSLog(@"lock device");
                // [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"(2) Lock at %@",[self nsdate2FormattedTime:[NSDate new]]]
//                                                  soundFlag:NO];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_SCREEN_LOCKED
                                                                object:nil
                                                              userInfo:nil];
            awareScreenState = 2;
        }
        
        NSLog(@"lockstate = %llu", state);

        [self saveScreenEvent:awareScreenState];
        
        [self setLatestValue:[NSString stringWithFormat:@"%@", [NSNumber numberWithInt:awareScreenState]]];
        
        /** ============ Codes for TextFile DB ==============  */
//        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:[NSNumber numberWithInt:awareScreenState] forKey:@"screen_status"]; // int
//        [self saveData:dic];
        
    });
}


- (void) registerAppforDetectDisplayStatus {
    NSString * head = @"com.apple.iokit.hid.";
    NSString * tail = @".displayStatus";
    
    notify_register_dispatch((char *)[head stringByAppendingString:tail].UTF8String, &_notifyTokenForDidChangeDisplayStatus,dispatch_get_main_queue(), ^(int token) {
        
        uint64_t state = UINT64_MAX;
        notify_get_state(token, &state);
        
        int awareScreenState = 0;
        
        if(state == 0) {
            NSLog(@"screen off");
            /** 
             -------------------------------------------------------------------------------------------
              If you need to check an action of screen status(off), please use the following code.
              The following code sends notifications when the screen status is changed in the debug mode.
             -------------------------------------------------------------------------------------------
             */
//            if ([self isDebug]) {
//                [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"(0) Screen Off at %@", [self nsdate2FormattedTime:[NSDate new]]] soundFlag:NO];
//            }
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_SCREEN_OFF
                                                                object:nil
                                                              userInfo:nil];
            awareScreenState = 0;
        } else {
            NSLog(@"screen on");
            /**
             -------------------------------------------------------------------------------------------
             If you need to check an action of screen status(on), please use the following code.
             The following codes send notifications when the screen status is changed in the debug mode.
             -------------------------------------------------------------------------------------------
             */
//            if ([self isDebug]) {
//                [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"(1) Screen On at %@", [self nsdate2FormattedTime:[NSDate new]]] soundFlag:NO];
//            }
            awareScreenState = 1;
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_SCREEN_ON
                                                                object:nil
                                                              userInfo:nil];
            
        }
        [self saveScreenEvent:awareScreenState];
        
        [self setLatestValue:[NSString stringWithFormat:@"%@", [NSNumber numberWithInt:awareScreenState]]];
    });
}


- (void) saveScreenEvent:(int) state {
    /**  ======= Codes for TextFile DB ======= */
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:[NSNumber numberWithInt:state] forKey:@"screen_status"]; // int
    // [self saveData:dict];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
    [self setLatestData:dict];
    
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, dict);
    }
}

-(void) unregisterAppforDetectLockState {
    //    notify_suspend(_notifyTokenForDidChangeLockStatus);
    uint32_t result = notify_cancel(_notifyTokenForDidChangeLockStatus);

    if (result == NOTIFY_STATUS_OK) {
        NSLog(@"[screen] OK --> %d", result);
    } else {
        NSLog(@"[screen] NO --> %d", result);
    }
}

- (void) unregisterAppforDetectDisplayStatus {
    //    notify_suspend(_notifyTokenForDidChangeDisplayStatus);
    uint32_t result = notify_cancel(_notifyTokenForDidChangeDisplayStatus);
    if (result == NOTIFY_STATUS_OK) {
        NSLog(@"[screen] OK ==> %d", result);
    } else {
        NSLog(@"[screen] NO ==> %d", result);
    }
}

-(NSString*)nsdate2FormattedTime:(NSDate*)date{
    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
    // [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    [formatter setDateFormat:@"HH:mm:ss"];
    return [formatter stringFromDate:date];
}

@end
