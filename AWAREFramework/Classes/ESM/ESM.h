//
//  ESM.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/22.
//

#import <UIKit/UIKit.h>
#import "AWARESensor.h"

typedef enum: NSInteger {
    AwareESMTypeNone        = 0,
    AwareESMTypeText        = 1,
    AwareESMTypeRadio       = 2,
    AwareESMTypeCheckbox    = 3,
    AwareESMTypeLikertScale = 4,
    AwareESMTypeQuickAnswer = 5,
    AwareESMTypeScale       = 6,
    AwareESMTypeDateTime    = 7,
    AwareESMTypePAM         = 8,
    AwareESMTypeNumeric     = 9,
    AwareESMTypeWeb         = 10,
    AwareESMTypeDate        = 11,
    AwareESMTypeTime        = 12,
    AwareESMTypeClock       = 13,
    AwareESMTypePicture     = 14,
    AwareESMTypeAudio       = 15,
    AwareESMTypeVideo       = 16
} AwareESMType;

@interface ESM:AWARESensor <AWARESensorDelegate>

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType;

@end
