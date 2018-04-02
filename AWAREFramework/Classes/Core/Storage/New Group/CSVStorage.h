//
//  CSVStorage.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/04/01.
//

#import <Foundation/Foundation.h>
#import "AWAREStorage.h"

@interface CSVStorage : AWAREStorage

// - (void) setCSVHeader:(NSArray *) headerArray;
- (instancetype)initWithStudy:(AWAREStudy *)study sensorName:(NSString *)name withHeader:(NSArray *) headerArray;

@end
