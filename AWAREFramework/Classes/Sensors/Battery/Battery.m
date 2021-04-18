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

NSString* const AWARE_PREFERENCES_STATUS_BATTERY = @"status_battery";

@implementation Battery {
    NSString* BATTERY_DISCHARGERES;
    NSString* BATTERY_CHARGERES;
    
    NSString* KEY_LAST_BATTERY_EVENT;
    NSString* KEY_LAST_BATTERY_EVENT_TIMESTAMP;
    NSString* KEY_LAST_BATTERY_LEVEL;
    
    /// A battery charge sensor
    BatteryCharge * batteryChargeSensor;
    /// A battery discharge sensor
    BatteryDischarge * batteryDischargeSensor;
    
    NSTimer * timer;
    NSInteger previousBatteryLevel;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName: SENSOR_BATTERY];
    }else if(dbType == AwareDBTypeCSV){
    NSArray * header = @[@"timestamp",@"device_id",@"battery_status",@"battery_level",@"battery_scale",@"battery_voltage", @"battery_temperature",@"battery_adaptor",@"battery_health",@"battery_technology"];
    NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeText)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_BATTERY headerLabels:header headerTypes:headerTypes];
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
        
        /// keys for local storage
        KEY_LAST_BATTERY_EVENT = @"key_last_battery_event";
        KEY_LAST_BATTERY_EVENT_TIMESTAMP = @"key_last_battery_event_timestamp";
        KEY_LAST_BATTERY_LEVEL = @"key_last_battery_level";
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if (![userDefaults integerForKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP]) {
            [userDefaults setInteger:UIDeviceBatteryStateUnknown forKey:KEY_LAST_BATTERY_EVENT];
            [userDefaults setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
            [userDefaults setInteger:[UIDevice currentDevice].batteryLevel*100 forKey:KEY_LAST_BATTERY_LEVEL];
        }
        
        /// Get default information from local storage
        batteryChargeSensor    = [[BatteryCharge alloc] initWithAwareStudy:study dbType:dbType];
        batteryDischargeSensor = [[BatteryDischarge alloc] initWithAwareStudy:study dbType:dbType];
        
        previousBatteryLevel = [UIDevice currentDevice].batteryLevel*100;
        
        [self batteryLevelChanged:nil];
    }
    return self;
}


- (void) createTable{
    /// Create a database table (battery_level, battery_charging, and battery_discharging)
    [self createBatteryTable];
    [batteryChargeSensor createTable];
    [batteryDischargeSensor createTable];
}

- (void) createBatteryTable{
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:@"battery_status"     type:TCQTypeInteger default:@"0"];
    [maker addColumn:@"battery_level"      type:TCQTypeInteger default:@"0"];
    [maker addColumn:@"battery_scale"      type:TCQTypeInteger default:@"0"];
    [maker addColumn:@"battery_voltage"    type:TCQTypeInteger default:@"0"];
    [maker addColumn:@"battery_temperature" type:TCQTypeInteger default:@"0"];
    [maker addColumn:@"battery_adaptor"    type:TCQTypeInteger default:@"0"];
    [maker addColumn:@"battery_health"     type:TCQTypeInteger default:@"0"];
    [maker addColumn:@"battery_technology" type:TCQTypeText default:@"''"];
    [self.storage createDBTableOnServerWithTCQMaker:maker];
}

- (void) setParameters:(NSArray *)parameters{
    
}

- (BOOL) startSensor{
    return [self startSensorWithIntervalSeconds:0];
}

- (BOOL) startSensorWithSettings:(NSArray *)settings{
    return [self startSensorWithIntervalSeconds:0];
}

- (BOOL) startSensorWithIntervalMinutes:(double)intervalMin{
    return [self startSensorWithIntervalSeconds:intervalMin * 60.0];
}

- (BOOL) startSensorWithIntervalSeconds:(double)intervalSec{
    
    /// Set a battery level change event to a notification center
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryLevelChanged:)
                                                 name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    
    /// Set a battery state change event to a notification center
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryStateChanged:)
                                                 name:UIDeviceBatteryStateDidChangeNotification object:nil];
    
    if (intervalSec > 0) {
        timer = [NSTimer scheduledTimerWithTimeInterval:intervalSec
                                                 target:self
                                               selector:@selector(batteryLevelChanged:)
                                               userInfo:nil
                                                repeats:YES];
    }
    [self setSensingState:YES];
    return YES;
}



- (BOOL)stopSensor{
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIDeviceBatteryLevelDidChangeNotification
                                                object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIDeviceBatteryStateDidChangeNotification
                                                object:nil];
    if(timer != nil){
        [timer invalidate];
        timer = nil;
    }
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    if (batteryChargeSensor.storage != nil) {
        [batteryChargeSensor.storage saveBufferDataInMainThread:YES];
    }
    if (batteryDischargeSensor.storage != nil) {
        [batteryDischargeSensor.storage saveBufferDataInMainThread:YES];
    }
    [self setSensingState:NO];
    return YES;
}

- (bool)isUploading{
    if([self.storage isSyncing] || [batteryChargeSensor.storage isSyncing] || [batteryDischargeSensor.storage isSyncing]){
        return YES;
    }else{
        return NO;
    }
}


- (void)startSyncDB {
    [self.storage startSyncStorage];
    [batteryChargeSensor.storage startSyncStorage];
    [batteryDischargeSensor.storage startSyncStorage];
}

- (int) convertBatteryStateValueToAndroidFromIOS:(int)state{
    
    // label       |  iOS | Android
    // -----------------------------
    // unknown     |   0  |    1
    // not_charging|   1  |    4
    // charging    |   2  |    2
    // status_full |   3  |    5
    // discharging |   -  |    3
    
    // https://developer.android.com/reference/android/os/BatteryManager#BATTERY_STATUS_CHARGING
    int androidState = 1;
    if  (state == 0) {       // ios = unknown
        androidState = 1;
    }else if (state == 1) {  // ios = unplegged
        androidState = 4;
    } else if (state == 2) { // ios = charging
        androidState = 2;
    } else if (state == 3) { // ios = full
        androidState = 5;
    }
    
    return androidState;
}

- (void)batteryLevelChanged:(NSNotification *)notification {
    
    // NSLog(@"battery status: %d",state);
    UIDevice *myDevice = [UIDevice currentDevice];
    [myDevice setBatteryMonitoringEnabled:YES];
    int state = (int)[myDevice batteryState];
    int batLeft = [myDevice batteryLevel] * 100;
    
    int batteryStatusAndroid = [self convertBatteryStateValueToAndroidFromIOS:state];
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:@(batteryStatusAndroid) forKey:@"battery_status"];
    [dict setObject:@(batLeft) forKey:@"battery_level"];
    [dict setObject:@100 forKey:@"battery_scale"];
    [dict setObject:@0 forKey:@"battery_voltage"];
    [dict setObject:@0 forKey:@"battery_temperature"];
    [dict setObject:@0 forKey:@"battery_adaptor"];
    [dict setObject:@0 forKey:@"battery_health"];
    [dict setObject:@"" forKey:@"battery_technology"];
    if (self.label != nil) {
        [dict setObject:self.label forKey:@"label"];
    }else{
        [dict setObject:@"" forKey:@"label"];
    }
    [self setLatestValue:[NSString stringWithFormat:@"%d", batLeft]];
    [self setLatestData:dict];
    
    // Broadcast
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                         forKey:EXTRA_DATA];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BATTERY_CHANGED
                                                        object:nil
                                                      userInfo:userInfo];
    
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:NO];
    
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, dict);
    }
    
}

- (void)batteryStateChanged:(NSNotification *)notification {
    /// Get current values
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger lastBatteryEvent = [userDefaults integerForKey:KEY_LAST_BATTERY_EVENT];
    NSNumber * lastBatteryEventTimestamp = [userDefaults objectForKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
    /// lastBatteryEvent = [UIDevice currentDevice].batteryLevel * 100;
    NSNumber* lastBatteryLevel = [userDefaults objectForKey:KEY_LAST_BATTERY_LEVEL];
    
    
    NSInteger currentBatteryEvent = UIDeviceBatteryStateUnknown;
    switch ([UIDevice currentDevice].batteryState) {
        case UIDeviceBatteryStateCharging:
            currentBatteryEvent = UIDeviceBatteryStateCharging;
            break;
        case UIDeviceBatteryStateFull:
            currentBatteryEvent = UIDeviceBatteryStateFull;
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BATTERY_CHARGING
                                                                object:nil
                                                              userInfo:nil];
            break;
        case UIDeviceBatteryStateUnknown:
            currentBatteryEvent = UIDeviceBatteryStateUnknown;
            break;
        case UIDeviceBatteryStateUnplugged:
            currentBatteryEvent = UIDeviceBatteryStateUnplugged;
            break;
        default:
            currentBatteryEvent = UIDeviceBatteryStateUnknown;
            break;
    };
    
    NSNumber * currentTime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    int battery = [UIDevice currentDevice].batteryLevel * 100;
    NSNumber * currentBatteryLevel = [NSNumber numberWithInt:battery];

    /// discharge event
    if (lastBatteryEvent == UIDeviceBatteryStateUnplugged &&
        currentBatteryEvent == UIDeviceBatteryStateCharging) {
        
        /// Save latest event on UserDefaults
        [userDefaults setObject:currentBatteryLevel forKey:KEY_LAST_BATTERY_LEVEL];
        [userDefaults setObject:currentTime forKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
        
        @try {
            [batteryDischargeSensor saveBatteryDischargeEventWithStartTimestamp:lastBatteryEventTimestamp
                                                                   endTimestamp:currentTime
                                                              startBatteryLevel:lastBatteryLevel
                                                                endBatteryLevel:currentBatteryLevel];
        } @catch (NSException *exception) {

        } @finally {
            
        }
        
    /// charge event
    }else if(lastBatteryEvent == UIDeviceBatteryStateCharging &&
             currentBatteryEvent == UIDeviceBatteryStateUnplugged ){
        
        /// Save battery events on UserDefaults
        [userDefaults setObject:currentBatteryLevel forKey:KEY_LAST_BATTERY_LEVEL];
        [userDefaults setObject:currentTime forKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
        
        @try {
            [batteryChargeSensor saveBatteryChargeEventWithStartTimestamp:lastBatteryEventTimestamp
                                                             endTimestamp:currentTime
                                                        startBatteryLevel:lastBatteryLevel
                                                          endBatteryLevel:currentBatteryLevel];
        } @catch (NSException *exception) {
        } @finally {
        }
    }
    switch (currentBatteryEvent) {
        case UIDeviceBatteryStateCharging:
            [userDefaults setInteger:UIDeviceBatteryStateCharging forKey:KEY_LAST_BATTERY_EVENT];
            break;
        case UIDeviceBatteryStateUnplugged:
            [userDefaults setInteger:UIDeviceBatteryStateUnplugged forKey:KEY_LAST_BATTERY_EVENT];
            break;
        default:
            break;
    }
    [userDefaults synchronize];
}

@end
