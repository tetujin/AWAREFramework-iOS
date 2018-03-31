//
//  BasicSettings.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/12/07.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "BasicSettings.h"
#import "AWAREDelegate.h"

@implementation BasicSettings {
    AWAREStudy  * coreStudy;
    int syncInterval;
    bool isWifiOnly;
    bool isBatteryOnly;
    cleanOldDataType dbCleanType;
    AwareUIMode uiMode;
}


- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    
    AWAREStorage * storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"basic_settings"];
    self = [super initWithAwareStudy:study
                          sensorName:@"basic_settings"
                             storage:storage];
    if (self) {
        AWAREDelegate * delegate = (AWAREDelegate *)[[UIApplication sharedApplication] delegate];
        coreStudy = delegate.sharedAWARECore.sharedAwareStudy;
    }
    return self;
}


- (void)setParameters:(NSArray *)parameters {
    if (parameters != nil) {
        syncInterval  = [coreStudy getUploadIntervalAsSecond]/60;
        isWifiOnly    = [coreStudy getDataUploadStateInWifi];
        isBatteryOnly = [coreStudy getDataUploadStateWithOnlyBatterChargning];
        dbCleanType   = [coreStudy getCleanOldDataType];
        uiMode        = [coreStudy getUIMode];
        
        for (NSDictionary * dict in parameters) {
            NSString *setting = [dict objectForKey:@"setting"];
            NSString * value  = [dict objectForKey:@"value"];
            if([setting isEqualToString:@"frequency_webservice"]){
                syncInterval = [value intValue];
            }else if([setting isEqualToString:@"frequency_clean_old_data"]){
                // (0 = never, 1 = weekly, 2 = monthly, 3 = daily, 4 = always)
                switch ([value integerValue]) {
                    case cleanOldDataTypeNever:
                        dbCleanType = cleanOldDataTypeNever;
                        break;
                    case cleanOldDataTypeWeekly:
                        dbCleanType = cleanOldDataTypeWeekly;
                        break;
                    case cleanOldDataTypeMonthly:
                        dbCleanType = cleanOldDataTypeMonthly;
                        break;
                    case cleanOldDataTypeDaily:
                        dbCleanType = cleanOldDataTypeDaily;
                        break;
                    case cleanOldDataTypeAlways:
                        dbCleanType = cleanOldDataTypeAlways;
                        break;
                    default:
                        break;
                }
            }else if([setting isEqualToString:@"webservice_wifi_only"]){
                isWifiOnly = [value boolValue];
            }else if([setting isEqualToString:@"webservice_charging"]){
                isBatteryOnly = [value boolValue];
            }else if([setting isEqualToString:@"ui_mode"]){
                switch ([value integerValue]) {
                    case AwareUIModeNormal:
                        uiMode = AwareUIModeNormal;
                        break;
                    case AwareUIModeHideAll:
                        uiMode = AwareUIModeHideAll;
                        break;
                    case AwareUIModeHideSettings:
                        uiMode = AwareUIModeHideSettings;
                        break;
                    default:
                        break;
                }
            }
        }
        
        [coreStudy setUploadIntervalWithMinutue:syncInterval];
        [coreStudy setDataUploadOnlyWifi:isWifiOnly];
        [coreStudy setDataUploadOnlyBatterChargning:isBatteryOnly];
        [coreStudy setCleanOldDataType:dbCleanType];
        [coreStudy setUIMode:uiMode];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_SETTING_UI_UPDATE_REQUEST object:nil];
    }
}

@end
