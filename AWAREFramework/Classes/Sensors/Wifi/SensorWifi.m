//
//  SensorWifi.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/06/15.
//

#import "SensorWifi.h"
#import "EntitySensorWifi+CoreDataClass.h"
#import <CommonCrypto/CommonDigest.h>

NSString* _Nonnull const AWARE_PREFERENCES_WIFI_INFO_ANONYMIZATION = @"wifi_info_anonymization";

@implementation SensorWifi {
    bool bssidAnonymizationState;
}

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
    
    bssidAnonymizationState = [self getAnonymizationState];
    
    return self;
}

- (void) setAnonymizationState:(bool)state {
    bssidAnonymizationState = state;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:state forKey:AWARE_PREFERENCES_WIFI_INFO_ANONYMIZATION];
    [defaults synchronize];
}

- (bool) getAnonymizationState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:AWARE_PREFERENCES_WIFI_INFO_ANONYMIZATION];
}

// データのハッシュを生成するメソッド
- (NSString *)generateSHA256Hash:(NSString *)input {
    const char *data = [input cStringUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];

    CC_SHA256(data, (CC_LONG)strlen(data), digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }

    return output;
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
        
        NSString * anonymizedBSSID = @"";
        NSString * anonymizedSSID = @"";
        if (bssidAnonymizationState){
            if ([finalBSSID isEqualToString:@""]) { // NO WIFI CONNECTION
                anonymizedBSSID = @"";
                anonymizedSSID = @"";
            }else{
                anonymizedBSSID =  [self generateSHA256Hash:finalBSSID];
                anonymizedSSID =  [self generateSHA256Hash:ssid];
            }
        }
        
        // Save sensor data to the local database.
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:unixtime forKey:@"timestamp"];
        [dict setObject:[self getDeviceId] forKey:@"device_id"];
        if (bssidAnonymizationState) {
            [dict setObject:anonymizedBSSID forKey:@"bssid"]; //text
            [dict setObject:anonymizedSSID forKey:@"ssid"]; //text
        }else{
            [dict setObject:finalBSSID forKey:@"bssid"]; //text
            [dict setObject:ssid forKey:@"ssid"]; //text
        }
        [dict setObject:@"" forKey:@"security"]; //text
        [dict setObject:@0 forKey:@"frequency"];//int
        [dict setObject:@0 forKey:@"rssi"]; //int
        if (self.label != nil) {
            [dict setObject:self.label forKey:@"label"];
        }else{
            [dict setObject:@"" forKey:@"label"];
        }
        
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
