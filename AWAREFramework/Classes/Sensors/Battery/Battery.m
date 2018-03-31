//
//  Battery.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
//http://stackoverflow.com/questions/9515479/monitor-and-detect-if-the-iphone-is-plugged-in-and-charging-wifi-connected-when
//https://developer.apple.com/library/ios/samplecode/BatteryStatus/Introduction/Intro.html
//

#import "Battery.h"
#import "BatteryCharge.h"
#import "BatteryDischarge.h"

#import "EntityBattery.h"
#import "EntityBatteryCharge.h"
#import "EntityBatteryDischarge.h"

@implementation Battery {
    NSString* BATTERY_DISCHARGERES;
    NSString* BATTERY_CHARGERES;
    
    NSString* KEY_LAST_BATTERY_EVENT;
    NSString* KEY_LAST_BATTERY_EVENT_TIMESTAMP;
    NSString* KEY_LAST_BATTERY_LEVEL;
    
    // A battery charge sensor
    BatteryCharge * batteryChargeSensor;
    // A battery discharge sensor
    BatteryDischarge * batteryDischargeSensor;
    
    NSTimer * timer;
    NSInteger previousBatteryLevel;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName: SENSOR_BATTERY];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_BATTERY entityName:NSStringFromClass([EntityBattery class]) insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
            EntityBattery* batteryData = (EntityBattery *)[NSEntityDescription
                                                           insertNewObjectForEntityForName:entity
                                                           inManagedObjectContext:childContext];
            
            batteryData.device_id = [data objectForKey:@"device_id"];
            batteryData.timestamp = [data objectForKey:@"timestamp"];
            batteryData.battery_status = [data objectForKey:@"battery_status"];
            batteryData.battery_level = [data objectForKey:@"battery_level"];
            batteryData.battery_scale = [data objectForKey:@"battery_scale"];
            batteryData.battery_voltage = [data objectForKey:@"battery_voltage"];
            batteryData.battery_temperature = [data objectForKey:@"battery_temperature"];
            batteryData.battery_adaptor = [data objectForKey:@"battery_adaptor"];
            batteryData.battery_health = [data objectForKey:@"battery_health"];
            batteryData.battery_technology = [data objectForKey:@"battery_technology"];
        }];
    }
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_BATTERY
                             storage:storage];
    if (self) {
        BATTERY_DISCHARGERES = @"battery_discharges";
        BATTERY_CHARGERES = @"battery_charges";
        
        // keys for local storage
        KEY_LAST_BATTERY_EVENT = @"key_last_battery_event";
        KEY_LAST_BATTERY_EVENT_TIMESTAMP = @"key_last_battery_event_timestamp";
        KEY_LAST_BATTERY_LEVEL = @"key_last_battery_level";
        
        _intervalSecond = 60.0;
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if (![userDefaults integerForKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP]) {
            [userDefaults setInteger:UIDeviceBatteryStateUnknown forKey:KEY_LAST_BATTERY_EVENT];
            [userDefaults setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
            [userDefaults setInteger:[UIDevice currentDevice].batteryLevel*100 forKey:KEY_LAST_BATTERY_LEVEL];
        }
//        [self setCSVHeader:@[@"timestamp",@"device_id",@"battery_status",@"battery_level",@"battery_scale",@"battery_voltage", @"battery_temperature",@"battery_adaptor",@"battery_health",@"battery_technology"]];
        
        // Get default information from local storage
        batteryChargeSensor = [[BatteryCharge alloc] initWithAwareStudy:study dbType:dbType];
//        [batteryChargeSensor setCSVHeader:@[@"timestamp",@"device_id",@"battery_start",@"battery_end",@"double_end_timestamp"]];
        
        batteryDischargeSensor = [[BatteryDischarge alloc] initWithAwareStudy:study dbType:dbType];
        
//        [batteryDischargeSensor setCSVHeader:@[@"timestamp",@"device_id",@"battery_start",@"battery_end",@"double_end_timestamp"]];
        
        previousBatteryLevel = [UIDevice currentDevice].batteryLevel*100;
        
        [self batteryLevelChanged:nil];
    }
    return self;
}


- (void) createTable{
    // Send a create table queries (battery_level, battery_charging, and battery_discharging)
    [self createBatteryTable];
    [batteryChargeSensor createTable];
    [batteryDischargeSensor createTable];
}

- (void) createBatteryTable{
    TCQMaker * maker = [[TCQMaker alloc] init];
//    NSString *query = [[NSString alloc] init];
//    query = @"_id integer primary key autoincrement,"
//    "timestamp real default 0,"
//    "device_id text default '',"
//    "battery_status integer default 0,"
    [maker addColumn:@"battery_status" type:TCQTypeInteger default:@"0"];
//    "battery_level integer default 0,"
    [maker addColumn:@"battery_level" type:TCQTypeInteger default:@"0"];
//    "battery_scale integer default 0,"
    [maker addColumn:@"battery_scale" type:TCQTypeInteger default:@"0"];
//    "battery_voltage integer default 0,"
    [maker addColumn:@"battery_voltage" type:TCQTypeInteger default:@"0"];
//    "battery_temperature integer default 0,"
    [maker addColumn:@"battery_temperature" type:TCQTypeInteger default:@"0"];
//    "battery_adaptor integer default 0,"
    [maker addColumn:@"battery_adaptor" type:TCQTypeInteger default:@"0"];
//    "battery_health integer default 0,"
    [maker addColumn:@"battery_health" type:TCQTypeInteger default:@"0"];
//    "battery_technology text default ''";
    [maker addColumn:@"battery_technology" type:TCQTypeText default:@"''"];
    [self.storage createDBTableOnServerWithTCQMaker:maker];
}

- (void)setParameters:(NSArray *)parameters{
    
}

- (BOOL)startSensor{
    return [self startSensorWithIntervalSecond:_intervalSecond];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    return [self startSensorWithIntervalSecond:_intervalSecond];
}

- (BOOL) startSensorWithIntervalSecond:(double)intervalSecond{
    
    // Set a battery level change event to a notification center
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryLevelChanged:)
                                                 name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    
    // Set a battery state change event to a notification center
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryStateChanged:)
                                                 name:UIDeviceBatteryStateDidChangeNotification object:nil];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:intervalSecond
                                             target:self
                                           selector:@selector(batteryLevelChanged:)
                                           userInfo:nil
                                            repeats:YES];
    
    return YES;
}



- (BOOL)stopSensor{
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIDeviceBatteryStateDidChangeNotification object:nil];
//    [UIDevice currentDevice].batteryMonitoringEnabled = NO;
    if(timer != nil){
        [timer invalidate];
        timer = nil;
    }
    return YES;
}

- (bool)isUploading{
    if([self.storage isSyncing] || [batteryChargeSensor.storage isSyncing] || [batteryDischargeSensor.storage isSyncing]){
        return YES;
    }else{
        return NO;
    }
}


//////////////////////////////
//////////////////////////////

- (void)startSyncDB {
    [self.storage startSyncStorage];
    [batteryChargeSensor.storage startSyncStorage];
    [batteryDischargeSensor.storage startSyncStorage];
}


/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////

- (void)batteryLevelChanged:(NSNotification *)notification {
    
    // 0 unknown, 1 unplegged, 2 charging, 3 full
    // NSLog(@"battery status: %d",state);
    UIDevice *myDevice = [UIDevice currentDevice];
    [myDevice setBatteryMonitoringEnabled:YES];
    int state = [myDevice batteryState];
    int batLeft = [myDevice batteryLevel] * 100;
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:@(state) forKey:@"battery_status"];
    [dict setObject:@(batLeft) forKey:@"battery_level"];
    [dict setObject:@100 forKey:@"battery_scale"];
    [dict setObject:@0 forKey:@"battery_voltage"];
    [dict setObject:@0 forKey:@"battery_temperature"];
    [dict setObject:@0 forKey:@"battery_adaptor"];
    [dict setObject:@0 forKey:@"battery_health"];
    [dict setObject:@"" forKey:@"battery_technology"];
    [self setLatestValue:[NSString stringWithFormat:@"%d", batLeft]];
    [self setLatestData:dict];
    
    // Broadcast
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                         forKey:EXTRA_DATA];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BATTERY_CHANGED
                                                        object:nil
                                                      userInfo:userInfo];
    
    // NSLog(@"[Battery Sensor] %d", [NSThread isMainThread] );
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
//    [self saveData:dict];
    
}



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


- (void)batteryStateChanged:(NSNotification *)notification {
    // Get current values
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger lastBatteryEvent = [userDefaults integerForKey:KEY_LAST_BATTERY_EVENT];
    NSNumber * lastBatteryEventTimestamp = [userDefaults objectForKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
    // lastBatteryEvent = [UIDevice currentDevice].batteryLevel * 100;
    NSNumber* lastBatteryLevel = [userDefaults objectForKey:KEY_LAST_BATTERY_LEVEL];
    
    
    NSInteger currentBatteryEvent = UIDeviceBatteryStateUnknown;
    switch ([UIDevice currentDevice].batteryState) {
        case UIDeviceBatteryStateCharging:
            currentBatteryEvent = UIDeviceBatteryStateCharging;
//            [self sendLocalNotificationForMessage:@"Battery Charging Event" soundFlag:NO];
            break;
        case UIDeviceBatteryStateFull:
            currentBatteryEvent = UIDeviceBatteryStateFull;
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BATTERY_CHARGING
                                                                object:nil
                                                              userInfo:nil];
//            [self sendLocalNotificationForMessage:@"Battery Full Event" soundFlag:NO];
            break;
        case UIDeviceBatteryStateUnknown:
            currentBatteryEvent = UIDeviceBatteryStateUnknown;
//            [self sendLocalNotificationForMessage:@"Battery Unknown Event" soundFlag:NO];
            break;
        case UIDeviceBatteryStateUnplugged:
            currentBatteryEvent = UIDeviceBatteryStateUnplugged;
//            [self sendLocalNotificationForMessage:@"Battery Unplugged Event" soundFlag:NO];
            break;
        default:
            currentBatteryEvent = UIDeviceBatteryStateUnknown;
//            [self sendLocalNotificationForMessage:@"Battery Unknown Event" soundFlag:NO];
            break;
    };
    
    NSNumber * currentTime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    int battery = [UIDevice currentDevice].batteryLevel * 100;
    NSNumber * currentBatteryLevel = [NSNumber numberWithInt:battery];

    // discharge event
    if (lastBatteryEvent == UIDeviceBatteryStateUnplugged &&
        currentBatteryEvent == UIDeviceBatteryStateCharging) {
        
        // Save latest event on UserDefaults
        [userDefaults setObject:currentBatteryLevel forKey:KEY_LAST_BATTERY_LEVEL];
        [userDefaults setObject:currentTime forKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
        
        @try {
            [batteryDischargeSensor saveBatteryDischargeEventWithStartTimestamp:lastBatteryEventTimestamp
                                                                   endTimestamp:currentTime
                                                              startBatteryLevel:lastBatteryLevel
                                                                endBatteryLevel:currentBatteryLevel];
        } @catch (NSException *exception) {
//            [self saveDebugEventWithText:[exception debugDescription] type:DebugTypeCrash label:@"battery_discharge"];
        } @finally {
            
        }
        
    // charge event
    }else if(lastBatteryEvent == UIDeviceBatteryStateCharging &&
             currentBatteryEvent == UIDeviceBatteryStateUnplugged ){
        
        // Save battery events on UserDefaults
        [userDefaults setObject:currentBatteryLevel forKey:KEY_LAST_BATTERY_LEVEL];
        [userDefaults setObject:currentTime forKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
        
        @try {
            [batteryChargeSensor saveBatteryChargeEventWithStartTimestamp:lastBatteryEventTimestamp
                                                             endTimestamp:currentTime
                                                        startBatteryLevel:lastBatteryLevel
                                                          endBatteryLevel:currentBatteryLevel];
        } @catch (NSException *exception) {
//            [self saveDebugEventWithText:[exception debugDescription] type:DebugTypeCrash label:@"battery_charge"];
        } @finally {
        }
    }
    switch (currentBatteryEvent) {
        case UIDeviceBatteryStateCharging:
//            lastBatteryEvent = currentBatteryEvent;
            [userDefaults setInteger:UIDeviceBatteryStateCharging forKey:KEY_LAST_BATTERY_EVENT];
            break;
        case UIDeviceBatteryStateUnplugged:
//            currentBatteryEvent = UIDeviceBatteryStateUnplugged;
//            lastBatteryEvent = currentBatteryEvent;
            [userDefaults setInteger:UIDeviceBatteryStateUnplugged forKey:KEY_LAST_BATTERY_EVENT];
            break;
        default:
            break;
    }
    [userDefaults synchronize];
}

@end
