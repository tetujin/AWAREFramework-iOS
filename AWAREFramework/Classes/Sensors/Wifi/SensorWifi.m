//
//  SensorWifi.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/06/15.
//

#import "SensorWifi.h"
#import "EntitySensorWifi+CoreDataClass.h"

@implementation SensorWifi

- (instancetype) initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON){
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"sensor_wifi"];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp",@"device_id",@"mac_address",@"bssid",@"ssid"];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeText),@(CSVTypeText),@(CSVTypeText)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:@"sensor_wifi" headerLabels:header headerTypes:headerTypes];
    }else{ // SQLite
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:@"sensor_wifi" entityName:NSStringFromClass([EntitySensorWifi class]) insertCallBack:^(NSDictionary *dataDict, NSManagedObjectContext *childContext, NSString *entity) {
            
            EntitySensorWifi* entityWifi = (EntitySensorWifi *)[NSEntityDescription
                                                    insertNewObjectForEntityForName:entity
                                                    inManagedObjectContext:childContext];
            entityWifi.device_id = [dataDict objectForKey:@"device_id"];
            entityWifi.timestamp = [dataDict objectForKey:@"timestamp"];
            entityWifi.mac_address = [dataDict objectForKey:@"mac_address"];
            entityWifi.bssid = [dataDict objectForKey:@"bssid"];
            entityWifi.ssid = [dataDict objectForKey:@"ssid"];
        }];
    }
    
    self = [super initWithAwareStudy:study sensorName:@"sensor_wifi" storage:storage];
    if(self != nil){
        
    }

    return self;
}
    
    
- (void)createTable{
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:@"mac_address" type:TCQTypeText default:@"''"];
    [maker addColumn:@"bssid" type:TCQTypeText default:@"''"];
    [maker addColumn:@"ssid" type:TCQTypeText default:@"''"];
    [self.storage createDBTableOnServerWithTCQMaker:maker];
}
    
- (void) saveConnectedWifiInfo {
    // Get wifi information
    //http://www.heapoverflow.me/question-how-to-get-wifi-ssid-in-ios9-after-captivenetwork-is-depracted-and-calls-for-wif-31555640
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSString *bssid = @"";
        NSString *ssid = @"";
        
        if (info[@"BSSID"]) {
            bssid = info[@"BSSID"];
        }
        if(info[@"SSID"]){
            ssid = info[@"SSID"];
        }
        
        NSMutableString *finalBSSID = [[NSMutableString alloc] init];
        NSArray *arrayOfBssid = [bssid componentsSeparatedByString:@":"];
        for(int i=0; i<arrayOfBssid.count; i++){
            NSString *element = [arrayOfBssid objectAtIndex:i];
            if(element.length == 1){
                [finalBSSID appendString:[NSString stringWithFormat:@"0%@:",element]];
            }else if(element.length == 2){
                [finalBSSID appendString:[NSString stringWithFormat:@"%@:",element]];
            }else{
                //            NSLog(@"error");
            }
        }
        if (finalBSSID.length > 0) {
            //        NSLog(@"%@",finalBSSID);
            [finalBSSID deleteCharactersInRange:NSMakeRange([finalBSSID length]-1, 1)];
        } else{
            //        NSLog(@"error");
        }
        
        [self setLatestValue:[NSString stringWithFormat:@"%@ (%@)",ssid, finalBSSID]];
        
        // Save sensor data to the local database.
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:unixtime forKey:@"timestamp"];
        [dict setObject:[self getDeviceId] forKey:@"device_id"];
        [dict setObject:finalBSSID forKey:@"bssid"]; //text
        [dict setObject:ssid forKey:@"ssid"]; //text
        [dict setObject:@"" forKey:@"security"]; //text
        [dict setObject:@0 forKey:@"frequency"];//int
        [dict setObject:@0 forKey:@"rssi"]; //int
        [dict setObject:@"" forKey:@"label"]; //text
        
        [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:NO];
        
        [self setLatestData:dict];
        
        if ([self isDebug])  NSLog(@"%@ (%@)",ssid, finalBSSID);
        
        SensorEventHandler handler = [self getSensorEventHandler];
        if (handler!=nil) {
            handler(self, dict);
        }
    }
}
    
    
@end
