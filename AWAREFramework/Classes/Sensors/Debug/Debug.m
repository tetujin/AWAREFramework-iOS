//
//  Debug.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  NOTE: Don't make an instance in a AWARESensor's constructer. The operation make infinity roop.
//

//[self setCSVHeader:@[
//                     dmLogger.KEY_DEBUG_TIMESTAMP,
//                     dmLogger.KEY_DEBUG_DEVICE_ID,
//                     dmLogger.KEY_DEBUG_EVENT,
//                     dmLogger.KEY_DEBUG_TYPE,
//                     dmLogger.KEY_DEBUG_LABEL,
//                     dmLogger.KEY_DEBUG_NETWORK,
//                     dmLogger.KEY_DEBUG_APP_VERSION,
//                     dmLogger.KEY_DEBUG_DEVICE,
//                     dmLogger.KEY_DEBUG_OS,
//                     dmLogger.KEY_DEBUG_BATTERY,
//                     dmLogger.KEY_DEBUG_BATTERY_STATE
//                     ]];

#import "Debug.h"
#import "EntityDebug.h"
#import "AWAREKeys.h"
#import "AWAREDebugMessageLogger.h"

@implementation Debug {
    AWAREStudy * awareStudy;
    AWAREDebugMessageLogger * dmLogger;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"aware_debug"];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:@"aware_debug"
                                            entityName:NSStringFromClass([EntityDebug class])
                                        insertCallBack:^(NSDictionary *dataDict, NSManagedObjectContext *childContext, NSString *entity) {
                                            
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                  sensorName:@"aware_debug"
                             storage:storage];
    if (self) {
        awareStudy = study;
        dmLogger = [[AWAREDebugMessageLogger alloc] initWithAwareStudy:awareStudy];

    }
    return self;
}


- (void) createTable{
    
    NSLog(@"[%@] CreateTable!", [self getSensorName]);
    
    NSMutableString *query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", dmLogger.KEY_DEBUG_TIMESTAMP]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", dmLogger.KEY_DEBUG_DEVICE_ID]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", dmLogger.KEY_DEBUG_EVENT]];
    [query appendString:[NSString stringWithFormat:@"%@ integer default 0,", dmLogger.KEY_DEBUG_TYPE]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", dmLogger.KEY_DEBUG_LABEL]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", dmLogger.KEY_DEBUG_NETWORK]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", dmLogger.KEY_DEBUG_APP_VERSION]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", dmLogger.KEY_DEBUG_DEVICE]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", dmLogger.KEY_DEBUG_OS]];
    [query appendString:[NSString stringWithFormat:@"%@ integer default 0,", dmLogger.KEY_DEBUG_BATTERY]];
    [query appendString:[NSString stringWithFormat:@"%@ integer default 0,", dmLogger.KEY_DEBUG_BATTERY_STATE]];
    [query appendString:@"UNIQUE (timestamp,device_id)"];
//    [super createTable:query];
    [self.storage createDBTableOnServerWithQuery:query];
}


- (BOOL)startSensor{
    
    // Start a data upload timer
    if ([self isDebug]) {
        NSLog(@"[%@] Start Sensor!", [self getSensorName]);
    }
    
    // Software Update Event
    NSString* currentVersion = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    // OS Update Event
    NSString* currentOsVersion = [[UIDevice currentDevice] systemVersion];
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    // App Install event
    if (![defaults boolForKey:dmLogger.KEY_APP_INSTALL]) {
        if ([self isDebug]) {
            // NSString* message = [NSString stringWithFormat:@"AWARE iOS is installed"];
            // [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
        }
        NSString *updateInformation = [NSString stringWithFormat:@"[SOFTWARE INSTALL] %@", currentVersion];
        [self saveDebugEventWithText:updateInformation type:DebugTypeInfo label:@""];
    }else{
        // Application update event
        NSString* oldVersion = @"";
        if ([defaults stringForKey:dmLogger.KEY_APP_VERSION]) {
            oldVersion = [defaults stringForKey:dmLogger.KEY_APP_VERSION];
        }
        [defaults setObject:currentVersion forKey:dmLogger.KEY_APP_VERSION];
        
        if (![currentVersion isEqualToString:oldVersion]) {
            if ([self isDebug]) {
                NSString* message = [NSString stringWithFormat:@"AWARE iOS is updated to %@", currentVersion];
                NSLog(@"%@",message);
                // [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
            }
            NSString *updateInformation = [NSString stringWithFormat:@"[SOFTWARE UPDATE] %@", currentVersion];
            [self saveDebugEventWithText:updateInformation type:DebugTypeInfo label:@""];
        }
        
        // OS update event
        NSString* storedOsVersion = @"";
        if ([defaults stringForKey:dmLogger.KEY_OS_VERSION]) {
            storedOsVersion = [defaults stringForKey:dmLogger.KEY_OS_VERSION];
        }
        [defaults setObject:currentOsVersion forKey:dmLogger.KEY_OS_VERSION];
        
        if (![currentOsVersion isEqualToString:storedOsVersion]) {
            if ([self isDebug]) {
                NSString* message = [NSString stringWithFormat:@"OS is updated to %@", currentOsVersion];
                NSLog(@"%@",message);
                // [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
            }
            NSString *updateInformation = [NSString stringWithFormat:@"[OS UPDATE] %@", currentOsVersion];
            [self saveDebugEventWithText:updateInformation type:DebugTypeInfo label:@""];
        }
    }
    
    [defaults setBool:YES forKey:dmLogger.KEY_APP_INSTALL];
    [defaults setObject:currentVersion forKey:dmLogger.KEY_APP_VERSION];
    [defaults setObject:currentOsVersion forKey:dmLogger.KEY_OS_VERSION];
    
    // Set a buffer for reducing file access
    [self.storage setBufferSize:10];
    
    return YES;
}

- (BOOL) stopSensor{
    return YES;
}

//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////

- (void) saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *) label {
    [dmLogger saveDebugEventWithText:eventText type:type label:label];
}


@end
