//
//  JSONStorage.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import "JSONStorage.h"
#import "SyncExecutor.h"

@implementation JSONStorage{
    int lostedTextLength;
    int latestTextLength;
    NSString * KEY_SENSOR_UPLOAD_MARK;
    NSString * KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH;
    int retryCurrentCount;
}

- (instancetype)initWithStudy:(AWAREStudy *)study sensorName:(NSString *)name{
    self = [super initWithStudy:study sensorName:name];
    if (self!=nil) {
        KEY_SENSOR_UPLOAD_MARK = [NSString stringWithFormat:@"KEY_SENSOR_UPLOAD_MARK_%@",name];
        KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH = [NSString stringWithFormat:@"KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH_%@",name];
        // [self removeLocalStorageWithName:name type:@"json"];
        [self createLocalStorageWithName:name type:@"json"];
        self.retryLimit = 3;
        retryCurrentCount = 0;
    }
    return self;
}

- (BOOL)saveDataWithDictionary:(NSDictionary *)dataDict buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread{
    return [self saveDataWithArray:@[dataDict] buffer:isRequiredBuffer saveInMainThread:saveInMainThread];
}

- (BOOL)saveDataWithArray:(NSArray *)dataArray buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread{

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
    
    NSMutableString * lines = nil;
    NSError*error=nil;
    NSData*d=nil;
    if (isRequiredBuffer) {
        d = [NSJSONSerialization dataWithJSONObject:self.buffer options:2 error:&error];
    }else{
        d = [NSJSONSerialization dataWithJSONObject:dataArray options:2 error:&error];
    }
    
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
    
    NSString * path = [self getFilePathWithName:self.sensorName type:@"json"];
    
    [self appendLine:lines withFilePath:path];
    
    return YES;
}

//////////////////////////////////////////

- (void)startSyncStorageWithCallBack:(SyncProcessCallBack)callback{
    self.syncProcessCallBack = callback;
    [self startSyncStorage];
}

- (void)startSyncStorage {
    NSMutableString* sensorData = [self getSensorDataForPost];
    NSString* formatedSensorData = [self fixJsonFormat:sensorData];
    // NSLog(@"%@",formatedSensorData);
    SyncExecutor *executor = [[SyncExecutor alloc] initWithAwareStudy:self.awareStudy sensorName:self.sensorName];
    if (formatedSensorData!=nil) {
        [executor syncWithData:[formatedSensorData dataUsingEncoding:NSUTF8StringEncoding] callback:^(NSDictionary *result) {
            if (result!=nil) {
                NSNumber * success = [result objectForKey:@"result"];
                if (success.intValue == 1) {
                    if(self->latestTextLength < [self getMaxDataLength]){
                        if (self.isDebug) NSLog(@"[%@] Done",self.sensorName);
                        [self clearLocalStorageWithName:self.sensorName type:@"json"];
                        if (self.isDebug) NSLog(@"[%@] Try to clear the local database", self.sensorName);
                        [self resetMark];
                        [self dataSyncIsFinishedCorrectly];
                    }else{
                        [self setNextMark];
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

- (void) dataSyncIsFinishedCorrectly {
    retryCurrentCount = 0;
}

- (void)cancelSyncStorage {
    NSLog(@"Please overwirte -cancelSyncStorage");
}

///////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Get sensor data for post
 * @return sensor data for post as a text
 *
 * NOTE:
 * This method returns unformated(JSON) text.
 * For example,
 *   tamp":0,"device_id":"xxxx-xxxx-xx","value":"1234"},
 *   {"timestamp":1,"device_id":"xxxx-xxxx-xx","value":"1234"},
 *   {"timestamp":"2","device_i
 *
 * For getting formated(JSON) text, you should use -fixJsonFormat:clipedText method with the unformated text
 * The method covert a formated JSON text from the unformated text.
 * For example,
 *   {"timestamp":1,"device_id":"xxxx-xxxx-xx","value":"1234"}
 */
- (NSMutableString *) getSensorDataForPost {
  
    NSInteger maxLength = [self getMaxDataLength];
    NSInteger seek = maxLength * [self getMarker];
    NSString * path = [self getFilePathWithName:self.sensorName type:@"json"];
    NSMutableString *data = nil;
    
    // Handle the file
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!fileHandle) {
        NSString * message = [NSString stringWithFormat:@"[%@] AWARE can not handle the file.", self.sensorName];
        NSLog(@"%@", message);
        return Nil;
    }
    
    if (self.isDebug) NSLog(@"[%@] Seek point => %ld", self.sensorName, seek);
    
    // Set seek point with losted text
    if (seek > [self getLostedTextLength]) {
        NSInteger seekPointWithLostedText = seek-[self getLostedTextLength];
        if (seekPointWithLostedText < 0) {
            seekPointWithLostedText = seek;
        }
        [fileHandle seekToFileOffset:seekPointWithLostedText];
    }else{
        [fileHandle seekToFileOffset:seek];
    }
    
    // Clip text with max length
    NSData *clipedData = [fileHandle readDataOfLength:maxLength];
    [fileHandle closeFile];
    
    // Make NSString from NSData object
    data = [[NSMutableString alloc] initWithData:clipedData encoding:NSUTF8StringEncoding];
    
    latestTextLength = (int)data.length;
    
    return data;
}


/**
 * Convert an unformated JSON text to a formated JSON text.
 * @param   NSString    An unformated JSON text
 * @return  NSString    A formated JSON text
 *
 * For example,
 * [Before: Unformated JSON Text]
 *   tamp":0,"device_id":"xxxx-xxxx-xx","value":"1234"},
 *   {"timestamp":1,"device_id":"xxxx-xxxx-xx","value":"1234"},
 *   {"timestamp":"2","device_i
 *
 * [After: Formated JSON Text]
 *   {"timestamp":1,"device_id":"xxxx-xxxx-xx","value":"1234"}
 *
 * NOTE: The lotest text length is stored after success to data upload by -setLostedTextLength:length.
 */
- (NSMutableString *) fixJsonFormat:(NSMutableString *) clipedText {
    // head
    if ([clipedText hasPrefix:@"{"]) {
    }else{
        NSRange rangeOfExtraText = [clipedText rangeOfString:@"{"];
        if (rangeOfExtraText.location == NSNotFound) {
            // NSLog(@"[HEAD] There is no extra text");
        }else{
            // NSLog(@"[HEAD] There is some extra text!");
            NSRange deleteRange = NSMakeRange(0, rangeOfExtraText.location);
            [clipedText deleteCharactersInRange:deleteRange];
        }
    }
    
    // tail
    if ([clipedText hasSuffix:@"}"]){
    }else{
        NSRange rangeOfExtraText = [clipedText rangeOfString:@"}" options:NSBackwardsSearch];
        if (rangeOfExtraText.location == NSNotFound) {
            // NSLog(@"[TAIL] There is no extra text");
            lostedTextLength = 0;
        }else{
            // NSLog(@"[TAIL] There is some extra text!");
            NSRange deleteRange = NSMakeRange(rangeOfExtraText.location+1, clipedText.length-rangeOfExtraText.location-1);
            [clipedText deleteCharactersInRange:deleteRange];
            lostedTextLength = (int)deleteRange.length;
        }
    }
    [clipedText insertString:@"[" atIndex:0];
    [clipedText appendString:@"]"];
    // NSLog(@"%@", clipedText);
    return clipedText;
}



//////////////////////////////////////
//////////////////////////////////////

- (uint64_t) getFileSize{
    return [self getFileSizeWithName:self.sensorName];
}

- (uint64_t) getFileSizeWithName:(NSString*) name {
    NSString * path = [self getFilePathWithName:name type:@"json"];
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
}

- (NSInteger) getMaxDataLength {
    return self.awareStudy.getMaximumByteSizeForDataUpload;
}

///////////////////////////////////////
///////////////////////////////////////

/**
 * Set a next progress maker to local default storage
 */
- (void) setNextMark {
    if(self.isDebug) NSLog(@"[%@] Line length is %llu", self.sensorName, [self getFileSize]);
    [self setMarker:[self getMarker]+1];
    [self setLostedTextLength:lostedTextLength];
}

/**
 * Reset a progress maker with zero(0)
 */
- (void) resetMark {
    [self setMarker:0];
    [self setLostedTextLength:0];
}


/**
 * Get a current progress marker for data upload from local default storage.
 * @return int A current progress maker for data upload
 */
- (int) getMarker {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber * number = [NSNumber numberWithInteger:[userDefaults integerForKey:KEY_SENSOR_UPLOAD_MARK]];
    return number.intValue;
}


- (void) setMarker:(int) intMarker {
    if (intMarker <= 0) {
        intMarker = 0;
    }
    NSNumber * number = [NSNumber numberWithInt:intMarker];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:number.integerValue forKey:KEY_SENSOR_UPLOAD_MARK];
}



////////////////////////////////////////////////
////////////////////////////////////////////////

- (int) getLostedTextLength{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber * number = [NSNumber numberWithInteger:[userDefaults integerForKey:KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH]];
    return number.intValue;
}

- (void) setLostedTextLength:(int)lostedTextLength {
    NSNumber * number = [NSNumber numberWithInt:lostedTextLength];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:number.integerValue forKey:KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH];
}

@end
