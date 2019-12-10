//
//  CSVStorage.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/04/01.
//

#import "CSVStorage.h"
#import "BRLineReader.h"
#import "SyncExecutor.h" 

@implementation CSVStorage{
    NSArray * headerTypes;
    NSArray * headerLabels;
    NSString * FILE_EXTENSION;
    NSString * KEY_STORAGE_CSV_SYNC_POSITION;
    BRLineReader * brReader;
    int retryCurrentCount;
    int retryLimit;
}

- (instancetype)initWithStudy:(AWAREStudy *)study sensorName:(NSString *)name headerLabels:(NSArray *)hLabels headerTypes:(NSArray <NSNumber *> *)hTypes{
    self = [super initWithStudy:study sensorName:name];
    if (self!=nil) {
        FILE_EXTENSION = @"csv";
        retryCurrentCount = 0;
        retryLimit = 3;
        KEY_STORAGE_CSV_SYNC_POSITION = [NSString stringWithFormat:@"aware.storage.csv.sync.position.%@",self.sensorName];
        [self createLocalStorageWithName:name type:FILE_EXTENSION];
        headerLabels = hLabels;
        headerTypes = hTypes;
        
        if (headerLabels!=nil) {
            [self setCSVHeader:headerLabels];
        }
        if (headerTypes!=nil && headerLabels!=nil) {
            if (headerTypes.count != headerLabels.count) {
                NSLog(@"[%@] A length of header(%tu) and type(%tu) are different.", self.sensorName, headerLabels.count, headerTypes.count);
            }
        }
    }
    return self;
}

/**
 Set CSV Header

 @param headerArray A CSV Header Array
 */
- (void) setCSVHeader:(NSArray *) headerArray {
    NSNumber * fileSize = [self getFileSizeWithName:self.sensorName type:FILE_EXTENSION];
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
        NSString * filePath = [self getFilePathWithName:self.sensorName type:FILE_EXTENSION];
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
    
    if(self.buffer == nil){
        if (self.isDebug) { NSLog(@"[%@] The buffer object is null", self.sensorName);}
        self.buffer = [[NSMutableArray alloc] init];
    }
    
    if (dataArray != nil) {
        [self.buffer addObjectsFromArray:dataArray];
    }
    
    if (self.buffer.count < self.getBufferSize) {
        return YES;
    }
    if (self.buffer.count == 0) {
        NSLog(@"[%@] The length of buffer is zero.", self.sensorName);
        return YES;
    }
    
    return [self saveBufferDataInMainThread:YES];

}

- (BOOL)saveBufferDataInMainThread:(BOOL)saveInMainThread{
    NSArray * copiedArray = [self.buffer copy];
    NSMutableString * lines = [[NSMutableString alloc] init];
    for (NSDictionary * dict in copiedArray) {
        [lines appendFormat:@"%@\n",[self convertDictionaryToCSVLine:dict withHeader:headerLabels]];
    }
    [self.buffer removeAllObjects];
    
    NSString * path = [self getFilePathWithName:self.sensorName type:FILE_EXTENSION];
    
    [self appendLine:lines withFilePath:path];
    
    return YES;
}


- (void)startSyncStorageWithCallBack:(SyncProcessCallBack)callback{
    self.syncProcessCallBack = callback;
    [self startSyncStorage];
}

/**
 Start to sync the CSV Storage
 */
- (void)startSyncStorage {
    
    NSString* formatedSensorData = [self getJSONFormatData];
    SyncExecutor *executor = [[SyncExecutor alloc] initWithAwareStudy:self.awareStudy sensorName:self.sensorName];
    
    if (formatedSensorData!=nil) {
        [executor syncWithData:[formatedSensorData dataUsingEncoding:NSUTF8StringEncoding] callback:^(NSDictionary *result) {
            if (result!=nil) {
                NSNumber * size = [self getFileSizeWithName:self.sensorName type:self->FILE_EXTENSION];
                if (size != nil) { }
                NSNumber * success = [result objectForKey:@"result"];
                if (success.intValue == 1) {
                    if( self->brReader == nil ){
                        [self resetPosition];
                        if (self.isDebug) NSLog(@"[%@] Done",self.sensorName);
                        if (self.isDebug) NSLog(@"[%@] Try to clear the local database", self.sensorName);
                        [self clearLocalStorageWithName:self.sensorName type:self->FILE_EXTENSION];
                        [self dataSyncIsFinishedCorrectly];
                        [self setCSVHeader:self->headerLabels];
                    }else{
                        if (self.isDebug) NSLog(@"[%@] Next: %lul/%@",self.sensorName, (unsigned long)[self getPosition], size);
                        [self performSelector:@selector(startSyncStorage) withObject:nil afterDelay:self.syncTaskIntervalSecond];
                    }
                }else{
                    if (self->retryCurrentCount < self.retryLimit) {
                        if (self.isDebug) NSLog(@"[%@] Retry (%d)",self.sensorName, self->retryCurrentCount);
                        self->retryCurrentCount++;
                        [self performSelector:@selector(startSyncStorage) withObject:nil afterDelay:self.syncTaskIntervalSecond];
                    }else{
                        if (self.isDebug) NSLog(@"[%@] End sync process doue to much error HTTP sessions.",self.sensorName);
                        [self dataSyncIsFinishedCorrectly];
                    }
                }
            }
        }];
    }
}

- (void) cancelSyncStorage {
    if (self.isDebug) NSLog(@"Please overwirte -cancelSyncStorage");
}


- (void) dataSyncIsFinishedCorrectly {
    retryCurrentCount = 0;
}


/**
 Convert a dictionary object to a CSV string oject
 
 @param dict A dictionary object which has sensor data
 @param header A header list which has header names
 @return A CSV String object
 */
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



/**
 Get JSON Format Data
 
 This method read a line one by one and convert the CSV lines to JSON Array and return it.

 @return A JSON Array Text for DB Sync
 */
- (NSString *) getJSONFormatData {
    // prepare a line reader
    NSString * path = [self getFilePathWithName:self.sensorName type:FILE_EXTENSION];
    if (brReader==nil) {
        brReader = [[BRLineReader alloc] initWithFile:path encoding:NSUTF8StringEncoding];
        [brReader setLineSearchPosition:[self getPosition]];
    }
    
    // read a line
    NSMutableString * jsonString = [[NSMutableString alloc] init];
    while (true) {
        NSString * line = [brReader readLine];
        // set current position
        [self setPosition:brReader.linesRead];
        if (line!=nil) {
            // header
            if ([line hasPrefix:@"timestamp"]) {
                continue;
            }
            // body
            [jsonString appendString:[self convertCSV2JSONWithCSVLine:line header:headerLabels types:headerTypes]];
            [jsonString appendString:@","];
            
            /// If the converted and piled data is larger than a limit, the loop is break and go to next process.
            if (jsonString.length > [self getMaxDataLength]) {
                break;
            }
        }else{
            brReader = nil;
            break;
        }
    }
    if (jsonString.length > 1) {
        // [note] remove ","
        [jsonString deleteCharactersInRange:NSMakeRange(jsonString.length-1, 1)];
        // [note] add "[" and "]" for making JSON-Array
        [jsonString insertString:@"[" atIndex:0];
        [jsonString appendString:@"]"];
        return jsonString;
    }else{
        return @"[]";
    }
}

/**
 Convert a CSV-line to a JSON-line using headers and the types.

 @note The number of elements in array lists (header and type) and
 the CSV line elements have to be the same number.
 If the number is difference, this method return "{}".
 
 @param line A CSV Line (e.g., 1234,xxxx-xxxx,123.00,label)
 @param header A header labels of the CSV line (e.g., [@"timestamp",@"device_id",@"value_1",@"label"])
 @param types A header types (which is based on the "CSVColumnType") of the header (e.g., [@(CSVTypeReal),@(CSVTypeText),@(CSVTypeReal),@(CSVTypeText)])
 @return a JSON-Object String (e.g., {"timestamp":1234, "device_id":"xxxx-xxx","value_1":123.00,"label":"label"})
 */
- (NSString *) convertCSV2JSONWithCSVLine:(NSString *)line header:(NSArray *)header types:(NSArray *)types{
    NSMutableDictionary * baseData = [[NSMutableDictionary alloc] init];
    NSArray *values = [line componentsSeparatedByString:@","];

    if (values.count == types.count && types.count == values.count) {
        for (int i=0; i<values.count; i++) {
            NSString * value = values[i];
            NSNumber * type = types[i];
            NSString * key = header[i];
            // NSLog(@"[%d] %@, %@, %@", i, key, value, type);
            if ([type isEqualToNumber:@(CSVTypeReal)]) {
                [baseData setObject:@(value.doubleValue) forKey:key];
            }else if([type isEqualToNumber:@(CSVTypeInteger)]){
                [baseData setObject:@(value.integerValue) forKey:key];
            }else if([type isEqualToNumber:@(CSVTypeText)]){
                [baseData setObject:value forKey:key];
            }else if([type isEqualToNumber:@(CSVTypeTextJSONArray)]){
                [baseData setObject:value forKey:key];
            }
        }
    }
    
    NSError * error = nil;
    NSData * data = [NSJSONSerialization dataWithJSONObject:baseData options:0 error:&error];
    if (error!=nil) {
        return @"{}";
    }
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


- (NSInteger) getMaxDataLength {
    return self.awareStudy.getMaximumByteSizeForDBSync;
}

- (void)resetMark{
    [self resetPosition];
}

- (void) setPosition:(NSUInteger) position {
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:position forKey:KEY_STORAGE_CSV_SYNC_POSITION];
    [userDefaults synchronize];
}

- (NSUInteger) getPosition{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSUInteger position = [userDefaults integerForKey:KEY_STORAGE_CSV_SYNC_POSITION];
    return position;
}

- (void) resetPosition {
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:0 forKey:KEY_STORAGE_CSV_SYNC_POSITION];
    [userDefaults synchronize];
}



@end
