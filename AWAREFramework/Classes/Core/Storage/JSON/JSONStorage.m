//
//  JSONStorage.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import "JSONStorage.h"
#import "SyncExecutor.h"
#import "BRLineReader.h"

@implementation JSONStorage{
    int retryCurrentCount;
    NSString * FILE_EXTENSION;
    NSString * KEY_STORAGE_JSON_SYNC_POSITION;
    BRLineReader * brReader;
    NSUInteger undoPosition;
}

- (instancetype)initWithStudy:(AWAREStudy *)study sensorName:(NSString *)name{
    self = [super initWithStudy:study sensorName:name];
    if (self!=nil) {
        KEY_STORAGE_JSON_SYNC_POSITION = [NSString stringWithFormat:@"aware.storage.json.sync.position.%@",self.sensorName];
        FILE_EXTENSION = @"json";
        [self createLocalStorageWithName:name type:FILE_EXTENSION];
        self.retryLimit = 3;
        retryCurrentCount = 0;
    }
    return self;
}

- (BOOL)saveDataWithDictionary:(NSDictionary * _Nullable)dataDict buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread{
    return [self saveDataWithArray:@[dataDict] buffer:isRequiredBuffer saveInMainThread:saveInMainThread];
}

- (BOOL)saveDataWithArray:(NSArray * _Nullable)dataArray buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread{

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
    
    if(dataArray != nil){
        [self.buffer addObjectsFromArray:dataArray];
    }else{
        if ([self isDebug]) { NSLog(@"[%@] The data object is nil.", self.sensorName); }
        return YES;
    }
    
    if (self.saveInterval > 0 ) {
        // time based operation
        NSDate * now = [NSDate new];
        if (now.timeIntervalSince1970 < self.lastSaveTimestamp + self.saveInterval) {
            return YES;
        }else if ([self.buffer count] == 0) {
            NSLog(@"[%@] The length of buffer is zero.", self.sensorName);
            return YES;
        }else{
            if ([self isDebug]) { NSLog(@"[JSONStorage] %@: Save data by time-base trigger", self.sensorName); }
            self.lastSaveTimestamp = now.timeIntervalSince1970;
        }
    }else{
        if (self.buffer.count < self.getBufferSize) {
            return YES;
        }else if ([self.buffer count] == 0) {
            NSLog(@"[%@] The length of buffer is zero.", self.sensorName);
            return YES;
        }else{
            if ([self isDebug]) { NSLog(@"[JSONStorage] %@: buffer limit-based trigger", self.sensorName); }
        }
    }

    return [self saveBufferDataInMainThread:YES];
}


- (BOOL)saveBufferDataInMainThread:(BOOL)saveInMainThread{
    
    NSArray * copiedArray = [self.buffer copy];
    NSMutableString * lines = nil;
    NSError * error=nil;
    NSData * d = [NSJSONSerialization dataWithJSONObject:copiedArray options:2 error:&error];

    [self.buffer removeAllObjects];
    
    if (!error) {
        lines = [[NSMutableString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    } else {
        NSString * errorStr = [NSString stringWithFormat:@"[%@] %@", self.sensorName, [error localizedDescription]];
        NSLog(@"[%@]",errorStr);
        return NO;
    }
    // NSLog(@"%@",lines);
    // remove head and tail object ([]) TODO check
    NSRange deleteRangeHead = NSMakeRange(0, 1);
    [lines deleteCharactersInRange:deleteRangeHead];
    NSRange deleteRangeTail = NSMakeRange(lines.length-1, 1);
    [lines deleteCharactersInRange:deleteRangeTail];
    [lines appendFormat:@",\n"];
    
    NSString * path = [self getFilePathWithName:self.sensorName type:FILE_EXTENSION];
    
    [self appendLine:lines withFilePath:path];
    
    return YES;
}

- (void)startSyncStorageWithCallBack:(SyncProcessCallBack)callback{
    self.syncProcessCallBack = callback;
    [self startSyncStorage];
}

- (void)startSyncStorage {
    NSString* formatedSensorData = [self getJSONFormatData];
    // NSLog(@"%@",formatedSensorData);
    SyncExecutor *executor = [[SyncExecutor alloc] initWithAwareStudy:self.awareStudy sensorName:self.sensorName];
    
    if (formatedSensorData!=nil) {
        [executor syncWithData:[formatedSensorData dataUsingEncoding:NSUTF8StringEncoding] callback:^(NSDictionary *result) {
            if (result!=nil) {
                NSNumber * success = [result objectForKey:@"result"];
                NSString * sensorName = [result objectForKey:@"name"];
                if (success.intValue == 1) {
                    if( self->brReader == nil ){
                        [self resetPosition];
                        if (self.isDebug) NSLog(@"[%@] Done",self.sensorName);
                        if (self.isDebug) NSLog(@"[%@] Try to clear the local database", self.sensorName);
                        [self clearLocalStorageWithName:self.sensorName type:self->FILE_EXTENSION];
                        [self dataSyncIsFinishedCorrectly];
                        if (self.syncProcessCallBack != nil) {
                            self.syncProcessCallBack(sensorName, AwareStorageSyncProgressComplete, 1, nil);
                        }
                    }else{
                        [self performSelector:@selector(startSyncStorage) withObject:nil afterDelay:self.syncTaskIntervalSecond];
                        if (self.syncProcessCallBack != nil) {
                            double progress = 0; // TODO
                            self.syncProcessCallBack(sensorName, AwareStorageSyncProgressContinue, progress, nil); // TODO: replay to real data
                        }
                    }
                }else{
                    [self setPosition:self->undoPosition];
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

- (void) dataSyncIsFinishedCorrectly {
    retryCurrentCount = 0;
}

- (void)cancelSyncStorage {
    if (self.isDebug) NSLog(@"Please overwirte -cancelSyncStorage");
}


- (NSString *) getJSONFormatData {
    NSString * path = [self getFilePathWithName:self.sensorName type:FILE_EXTENSION];
    if (brReader==nil) {
        brReader = [[BRLineReader alloc] initWithFile:path encoding:NSUTF8StringEncoding];
        [brReader setLineSearchPosition:[self getPosition]];
        undoPosition = [self getPosition];
    }
    NSMutableString * jsonString = [[NSMutableString alloc] init];
    while (true) {
        NSString * line = [brReader readLine];
        [self setPosition:brReader.linesRead];
        if (line!=nil) {
            [jsonString appendString:line];
            if (jsonString.length > [self getMaxDataLength]) {
                break;
            }
        }else{
            brReader = nil;
            break;
        }
    }
    if (jsonString.length > 1) {
        // [note] remove "," and "\n" 
        [jsonString deleteCharactersInRange:NSMakeRange(jsonString.length-2, 2)];
        // [note] add "[" and "]" for making JSON-Array
        [jsonString insertString:@"[" atIndex:0];
        [jsonString appendString:@"]"];
        return jsonString;
    }else{
        return @"[]";
    }
}

//- (void) remove {
//    NSString * filePath = [self getFilePathWithName:[self sensorName] type:FILE_EXTENSION];
//    NSError * error = nil;
//    NSMutableData * data = [NSMutableData dataWithContentsOfFile:filePath options:NSDataReadingMappedAlways error:&error];
//    if (error==nil) {
//        // [data resetBytesInRange:NSMakeRange(0, [self getPosition])];
//        // unsigned char zeroByte = 0;
//        [data replaceBytesInRange:NSMakeRange(0, [self getPosition]) withBytes:NULL length:0];
//        // [data rangeOfData:[@"" dataUsingEncoding:NSUTF8StringEncoding] options:nil range:NSMakeRange(0, [self getPosition])];
//
//        [data writeToFile:filePath atomically:NO];
//        [self resetPosition];
//    }else{
//        NSLog(@"[%@] %@",[self sensorName], error.debugDescription);
//    }
//}


- (NSInteger) getMaxDataLength {
    return self.awareStudy.getMaximumByteSizeForDBSync;
}

- (void)resetMark{
    [self resetPosition];
}

- (void) setPosition:(NSUInteger) position {
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:position forKey:KEY_STORAGE_JSON_SYNC_POSITION];
    [userDefaults synchronize];
}

- (NSUInteger) getStoredDataSize {
    NSString * path = [self getFilePathWithName:self.sensorName type:FILE_EXTENSION];
    NSFileManager * man = [NSFileManager defaultManager];
    NSDictionary  * attrs = [man attributesOfItemAtPath: path error: NULL];
    UInt64 result = [attrs fileSize];
    return result;
}

- (NSUInteger) getPosition{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSUInteger position = [userDefaults integerForKey:KEY_STORAGE_JSON_SYNC_POSITION];
    return position;
}

- (void) resetPosition {
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:0 forKey:KEY_STORAGE_JSON_SYNC_POSITION];
    [userDefaults synchronize];
}

@end
