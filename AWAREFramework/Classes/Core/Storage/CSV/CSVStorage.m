//
//  CSVStorage.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/04/01.
//

#import "CSVStorage.h"

@implementation CSVStorage{
    NSArray * header;
    NSString * type;
}

- (instancetype)initWithStudy:(AWAREStudy *)study sensorName:(NSString *)name withHeader:(NSArray *) headerArray {
    self = [super initWithStudy:study sensorName:name];
    if (self!=nil) {
        type = @"csv";
       [self createLocalStorageWithName:name type:type];
        header = headerArray;
        if (header!=nil) {
            [self setCSVHeader:header];
        }
    }
    return self;
}

- (void) setCSVHeader:(NSArray *) headerArray {
    NSNumber * fileSize = [self getFileSizeWithName:self.sensorName type:type];
    if (fileSize != nil && fileSize.intValue == 0) {
        NSMutableString * headerLine = [[NSMutableString alloc] init];
        for (NSString * head in headerArray ) {
            [headerLine appendFormat:@"%@,",head];
        }
        if (headerLine.length > 0) {
            NSRange deleteRangeTail = NSMakeRange(headerLine.length-1, 1);
            [headerLine  deleteCharactersInRange:deleteRangeTail];
            [headerLine appendString:@"\n"];
        }
        NSString * filePath = [self getFilePathWithName:self.sensorName type:type];
        [self appendLine:headerLine withFilePath:filePath];
    }
}

- (BOOL)saveDataWithDictionary:(NSDictionary *)dataDict buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread{
    return [self saveDataWithArray:@[dataDict] buffer:isRequiredBuffer saveInMainThread:saveInMainThread];
}

- (BOOL)saveDataWithArray:(NSArray *)dataArray buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread{
    
    if (!self.isStore) {
        return NO;
    }
    
    if (!saveInMainThread) {
        // NSLog(@"[%@] JSONStorage only support a data storing in the main thread. Threfore, the data is stored in the main-thread.", self.sensorName);
    }
    
    if (isRequiredBuffer) {
        [self.buffer addObjectsFromArray:dataArray];
        if (self.buffer.count < self.getBufferSize) {
            return YES;
        }
        if (self.buffer == 0) {
            NSLog(@"[%@] The length of buffer is zero.", self.sensorName);
            return YES;
        }
    }
    
    NSMutableString * lines = [[NSMutableString alloc] init];
    if (!isRequiredBuffer) {
        for (NSDictionary * dict in dataArray) {
            [lines appendFormat:@"%@\n",[self convertDictionaryToCSVLine:dict withHeader:header]];
        }
    } else {
        for (NSDictionary * dict in self.buffer) {
            [lines appendFormat:@"%@\n",[self convertDictionaryToCSVLine:dict withHeader:header]];
        }
    }
    
    [self.buffer removeAllObjects];
    
    NSString * path = [self getFilePathWithName:self.sensorName type:type];
    
    [self appendLine:lines withFilePath:path];
    
    return YES;
}

- (void)cancelSyncStorage {
    NSLog(@"Please overwirte -cancelSyncStorage");
}


- (NSString *) convertDictionaryToCSVLine:(NSDictionary *)dict withHeader:(NSArray *)header{
    NSMutableString * csvLine = [[NSMutableString alloc] init];
    for (NSString * head in header) {
        NSObject * value = [dict objectForKey:head];
        if (value!=nil) {
            [csvLine appendFormat:@"%@,",value];
        }
    }
    if (csvLine.length > 0) {
        NSRange deleteRangeTail = NSMakeRange(csvLine.length-1, 1);
        [csvLine deleteCharactersInRange:deleteRangeTail];
    }
    return csvLine;
}

@end
