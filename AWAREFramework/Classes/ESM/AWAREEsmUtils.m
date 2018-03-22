//
//  AWAREEsmUtils.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/24/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  This class provies utilites of esm
//

#import "AWAREEsmUtils.h"
#import "ESM.h"
#import "AWAREKeys.h"

@implementation AWAREEsmUtils

/**
 * Save esm objects to a main local storage
 * @param AWARESchedule     an AWARESchedule object
 * @param NSNumber          a timestamp as NSNumber
 */
+ (void) saveEsmObjects:(AWARESchedule *) schedule
          withTimestamp:(NSNumber *)timestamp {
    // ESM Objects
    ESM *esm = [[ESM alloc] initWithAwareStudy:nil
                                    sensorName:SENSOR_ESMS
                                  dbEntityName:nil
                                        dbType:AwareDBTypeTextFile];
    //SensorName:SENSOR_ESMS withAwareStudy:nil
    NSMutableArray* mulitEsm = schedule.esmObject.esms;
    NSNumber * unixtime = timestamp;
    NSString * deviceId = [esm getDeviceId];
    
    for ( SingleESMObject * singleEsm in mulitEsm ) {
        
        // Check esm_ios object
        // if case of ( esm_type==4[Likert Scale] && radio_button.count > 0 ) => change esm_type to 2[Radio Button]
        BOOL result = [self checkRadioBtnToLikert:singleEsm.esmObject];
        if (result) {
            NSLog(@"--- change esm type");
            [singleEsm.esmObject setObject:@2 forKey:KEY_ESM_TYPE];
        }else{
            NSLog(@"----- ");
        }
        
        NSMutableDictionary *dic = [self getEsmFormatDictionary:(NSMutableDictionary *)singleEsm.esmObject
                                                   withTimesmap:unixtime
                                                        devieId:deviceId];
        [dic setObject:deviceId forKey:@"device_id"];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:@"0" forKey:KEY_ESM_STATUS]; // status is new
        
        [esm saveData:dic];
        // NSLog(@"%@",dic);
    }
}


+ (bool) checkRadioBtnToLikert:(NSDictionary * )dic {
    NSNumber * esmType = (NSNumber *)[dic objectForKey:@"esm_type"];
    NSArray* array = (NSArray *)[dic objectForKey:@"esm_radios"];
    NSString* className = NSStringFromClass([array class]);
    if ( [className isEqualToString:@"__NSCFArray"] && array != nil && esmType != nil) {
        if (array.count > 0 && [esmType isEqualToNumber:@4]) {
            return YES;
        }
    }
    return NO;
}


+ (NSMutableDictionary *) getEsmFormatDictionary:(NSMutableDictionary *)originalDic
                                    withTimesmap:(NSNumber *)unixtime
                                         devieId:(NSString*) deviceId{
    // make base dictionary from SingleEsmObject with device ID and timestamp
//    SingleESMObject *singleObject = [[SingleESMObject alloc] init];
    NSMutableDictionary * dic = [SingleESMObject getEsmDictionaryWithDeviceId:deviceId
                                                                 timestamp:[unixtime doubleValue]
                                                                      type:@0
                                                                     title:@""
                                                              instructions:@""
                                                                    submit:@""
                                                       expirationThreshold:@0
                                                                   trigger:@""];
    // init array objects to NSString object
    [dic setObject:@"" forKey:KEY_ESM_RADIOS];
    [dic setObject:@"" forKey:KEY_ESM_CHECKBOXES];
    [dic setObject:@"" forKey:KEY_ESM_QUICK_ANSWERS];
    
    // add existing data to base dictionary of an esm
    for (id key in [originalDic keyEnumerator]) {
        //        NSLog(@"Key: %@ => Value:%@" , key, [originalDic objectForKey:key]);
        if([key isEqualToString:KEY_ESM_RADIOS]){
            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_RADIOS];
        }else if([key isEqualToString:KEY_ESM_CHECKBOXES]){
            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_CHECKBOXES];
        }else if([key isEqualToString:KEY_ESM_QUICK_ANSWERS]){
            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_QUICK_ANSWERS];
        }else{
            NSObject *object = [originalDic objectForKey:key];
            if (object == nil) {
                object = @"";
            }
            [dic setObject:object forKey:key];
        }
    }
    return dic;
}


/**
 * Convert a NSArray to a JSON format NSString. An aware server doesn't support 
 * array object, therefore we have to convert an array object.
 * 
 * @param NSArray   A NSArray object (e.g., labels for esm such as esm_type radios, checkboxes, and quick answer).
 * @return NSString A NSString object which is a json format
 */
+ (NSString* ) convertArrayToCSVFormat:(NSArray *) array {
    if (array == nil || array.count == 0){
        return @"";
    }
    
    NSError * error;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    NSString* jsonString = [[NSString alloc] initWithData:jsondata encoding:NSUTF8StringEncoding];
    if ([jsonString isEqualToString:@""] || jsonString == nil) {
        return @"[]";
    }
    
    return jsonString;
}


@end
