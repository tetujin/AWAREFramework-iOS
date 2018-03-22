//
//  AWAREEsmUtils.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/24/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWARESchedule.h"

@interface AWAREEsmUtils : NSObject


+ (void) saveEsmObjects:(AWARESchedule *) schedule withTimestamp:(NSNumber *)timestamp;



+ (bool) checkRadioBtnToLikert:(NSDictionary *) dic;

+ (NSMutableDictionary *) getEsmFormatDictionary:(NSMutableDictionary *)originalDic
                                    withTimesmap:(NSNumber *)unixtime
                                         devieId:(NSString*) deviceId;

+ (NSString* ) convertArrayToCSVFormat:(NSArray *) array;

@end
