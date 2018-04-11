//
//  CSVStorage.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/04/01.
//

#import <Foundation/Foundation.h>
#import "AWAREStorage.h"

typedef enum: NSInteger {
    CSVTypeUnknown = 0,
    CSVTypeText    = 1,
    CSVTypeInteger = 2,
    CSVTypeReal    = 3,
    CSVTypeBlob    = 4,
    CSVTypeTextJSONArray = 5
} CSVColumnType;

@interface CSVStorage : AWAREStorage

- (instancetype)initWithStudy:(AWAREStudy *)study sensorName:(NSString *)name headerLabels:(NSArray *)hLabels headerTypes:(NSArray <NSNumber *> *)hTypes;

@end
