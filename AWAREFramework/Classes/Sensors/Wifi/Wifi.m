//
//  Wifi.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//


#import "Wifi.h"
#import "EntityWifi.h"
#import <ifaddrs.h>
#import <net/if.h>
#import <SystemConfiguration/CaptiveNetwork.h>
// #import <MMLanScan/MMDevice.h>
#import "AWAREKeys.h"
#import "SensorWifi.h"

NSString* const AWARE_PREFERENCES_STATUS_WIFI = @"status_wifi";
NSString* const AWARE_PREFERENCES_FREQUENCY_WIFI = @"frequency_wifi";

@implementation Wifi{
    NSTimer * sensingTimer;
    double sensingInterval;
    SensorWifi * sensorWifi;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_WIFI];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp",@"device_id",@"bssid",@"ssid",@"security",@"frequency",@"rssi",@"label"];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeText),@(CSVTypeText),@(CSVTypeText),@(CSVTypeInteger),@(CSVTypeInteger),@(CSVTypeText)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_WIFI headerLabels:header headerTypes:headerTypes];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_WIFI entityName:NSStringFromClass([EntityWifi class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            
                                            EntityWifi* entityWifi = (EntityWifi *)[NSEntityDescription
                                                                                    insertNewObjectForEntityForName:entity
                                                                                    inManagedObjectContext:childContext];
                                            entityWifi.device_id = [data objectForKey:@"device_id"];
                                            entityWifi.timestamp = [data objectForKey:@"timestamp"];
                                            entityWifi.bssid = [data objectForKey:@"bssid"];//finalBSSID;
                                            entityWifi.ssid = [data objectForKey:@"ssid"];//ssid;
                                            entityWifi.security = [data objectForKey:@"security"];// @"";
                                            entityWifi.frequency = [data objectForKey:@"frequency"];//@0;
                                            entityWifi.rssi = [data objectForKey:@"rssi"]; //@0;
                                            entityWifi.label = [data objectForKey:@"label"];//@"";
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_WIFI
                             storage:storage];
    if (self) {
        sensingInterval = 60.0f; // 60sec. = 1min.
        // self.lanScanner = [[MMLANScanner alloc] initWithDelegate:self];
        sensorWifi = [[SensorWifi alloc] initWithAwareStudy:study dbType:dbType];
    }
    return self;
}


- (void) createTable {
    // Send a create table query
    if ([self isDebug]) {
        NSLog(@"[%@] Create Table", [self getSensorName]);
    }
    NSString *query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "bssid text default '',"
    "ssid text default '',"
    "security text default '',"
    "frequency integer default 0,"
    "rssi integer default 0,"
    "label text default ''";
    [self.storage createDBTableOnServerWithQuery:query];
    
    if(sensorWifi!=nil){
        [sensorWifi createTable];
    }
}

- (void) setSensorEventHandler:(SensorEventHandler)handler{
    if (sensorWifi != nil) {
        [sensorWifi setSensorEventHandler:handler];
    }
}

- (void)setSensingIntervalWithMinute:(double)minute{
    sensingInterval = minute * 60.0f;
}
    
- (void) setSensingIntervalWithSecond:(double)second{
    sensingInterval = second;
}
    
- (void)setParameters:(NSArray *)parameters{
    // Get a sensing frequency
    if (parameters != nil) {
        double frequency = [self getSensorSetting:parameters withKey:@"frequency_wifi"];
        if(frequency > 0){
            sensingInterval = frequency;
        }
    }
}

- (void)startSyncDB{
    if(sensorWifi!=nil) [sensorWifi startSyncDB];
    [super startSyncDB];
}
    
- (void)stopSyncDB{
    if(sensorWifi!=nil) [sensorWifi stopSyncDB];
    [super stopSyncDB];
}
    
- (BOOL)startSensor {
    return [self startSensorWithInterval:sensingInterval];
}

- (BOOL)startSensorWithInterval:(double) interval{
    /// Set and start a data upload interval
    if([self isDebug]){
        NSLog(@"[%@] Start Wifi Sensor", [self getSensorName]);
    }
    if (sensingTimer != nil) {
        [sensingTimer invalidate];
        sensingTimer = nil;
    }
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                    target:self
                                                  selector:@selector(getWifiInfo)
                                                  userInfo:nil
                                                   repeats:YES];
    [self getWifiInfo];
    [self setSensingState:YES];
    
    return YES;
}


- (BOOL)stopSensor{
    /// Stop a sensing timer
    if (sensingTimer != nil) {
        [sensingTimer invalidate];
        sensingTimer = nil;
    }
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    [self setSensingState:NO];
    return YES;
}
    
- (void) getWifiInfo {
    
//    NSLog(@"get wifi info");
//    if([self isWiFiEnabled]){
//        if([self isDebug]) NSLog(@"Wifi on");
//    }else{
//        if([self isDebug]) NSLog(@"Wifi off");
//    }
    
    [self broadcastRequestScan];
    [self broadcastScanStarted];

    // [self.lanScanner start];
    // [self.lanScanner performSelector:@selector(stop) withObject:nil afterDelay:10];
    
    // save current connected wifi information
    [sensorWifi saveConnectedWifiInfo];
}
    
- (NSString *) getLatestValue {
    return [sensorWifi getLatestValue];
}

- (void) broadcastDetectedNewDevice{
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_NEW_DEVICE
                                                        object:nil
                                                      userInfo:nil];
}
    
- (void) broadcastScanStarted{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_SCAN_STARTED
                                                        object:nil
                                                      userInfo:nil];
}
    
- (void) broadcastScanEnded{
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_SCAN_ENDED
                                                        object:nil
                                                      userInfo:nil];
}
    
- (void) broadcastRequestScan{
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_REQUEST_SCAN
                                                        object:nil
                                                      userInfo:nil];
}
    
    
- (BOOL) isWiFiEnabled {
    
    NSCountedSet * cset = [NSCountedSet new];
    
    struct ifaddrs *interfaces;
    
    if( ! getifaddrs(&interfaces) ) {
        for( struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
            if ( (interface->ifa_flags & IFF_UP) == IFF_UP ) {
                [cset addObject:[NSString stringWithUTF8String:interface->ifa_name]];
            }
        }
    }
    
    return [cset countForObject:@"awdl0"] > 1 ? YES : NO;
}
    
- (NSDictionary *) wifiDetails {
    return
    (__bridge NSDictionary *)
    CNCopyCurrentNetworkInfo(
                             CFArrayGetValueAtIndex( CNCopySupportedInterfaces(), 0)
                             );
}
    
    
- (void)lanScanDidFailedToScan {
    if ([self isDebug]) NSLog(@"lanScanDidFailedToScan");
}
    
//- (void)lanScanDidFindNewDevice:(MMDevice *)device {
//    
//    [self broadcastDetectedNewDevice];
//    
//    NSString * hostname = @"";
//    if(device.hostname != nil){
//        hostname = device.hostname;
//    }
//    
//    NSString * macAddress = @"";
//    if(device.macAddress != nil){
//        macAddress = device.macAddress;
//    }
//    
//    NSString * brand = @"";
//    if(device.brand != nil){
//        brand = device.brand;
//    }
//    
//    // Save sensor data to the local database.
//    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
//    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
//    [dict setObject:unixtime forKey:@"timestamp"];
//    [dict setObject:[self getDeviceId] forKey:@"device_id"];
//    [dict setObject:macAddress forKey:@"bssid"]; //text
//    [dict setObject:hostname forKey:@"ssid"]; //text
//    [dict setObject:@"" forKey:@"security"]; //text
//    [dict setObject:@0 forKey:@"frequency"];//int
//    [dict setObject:@0 forKey:@"rssi"]; //int
//    [dict setObject:brand forKey:@"label"]; //text
//    
//    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
//    [self setLatestData:dict];
//    
//    if ([self isDebug])  NSLog(@"%@ (%@)", hostname, macAddress);
//    
//    SensorEventHandler handler = [self getSensorEventHandler];
//    if (handler!=nil) {
//        handler(self, dict);
//    }
//}

//- (void)lanScanDidFinishScanningWithStatus:(MMLanScannerStatus)status {
//    switch (status) {
//        case MMLanScannerStatusFinished:
//            if ([self isDebug]) NSLog(@"wifi scan: finish");
//            // [self.lanScanner stop];
//            [self broadcastScanEnded];
//            break;
//        case MMLanScannerStatusCancelled:
//            if ([self isDebug])  NSLog(@"wifi scan: canceled");
//            // [self.lanScanner stop];
//            [self broadcastScanEnded];
//            break;
//        default:
//            // NSLog(@"other");
//            break;
//    }
//}

//- (void)lanScanProgressPinged:(float)pingedHosts from:(NSInteger)overallHosts{
//    // NSLog(@"%f/%d = %f",pingedHosts, overallHosts, pingedHosts/overallHosts);
//    // [self.progressView setProgress:(float)pingedHosts/overallHosts];
//}
    
@end
