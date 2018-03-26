//
//  LocalTextStorageHelper.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/16/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "LocalFileStorageHelper.h"
#import "AWAREKeys.h"

@implementation LocalFileStorageHelper {
    // A key for a sensor upload marker
    NSString * KEY_SENSOR_UPLOAD_MARK;
    // A key for a losted length
    NSString * KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH;
    
    // A file size
    uint64_t fileSize;
    // A sensor name
    NSString * sensorName;
    
    NSMutableArray * bufferArray;
    // A buffer size for an array list
    int bufferSize;
    
    // A Debug sensor
    AWAREDebugMessageLogger * dmLogger;
    
    // A state of file lock
    bool isLock;
    
    // Losted text length
    int lostedTextLength;
    
    NSInteger latestTextLength;
    
    BOOL isCSVExport;
    
    NSArray * csvHeader;
}


- (instancetype)initWithStorageName:(NSString *)name{
    if (self = [super init]) {
        // default lock state is false
        isLock = NO;
        // set sensor name
        sensorName = name;
        // make an original upload marker for each sensor
        KEY_SENSOR_UPLOAD_MARK = [NSString stringWithFormat:@"key_sensor_upload_mark_%@", sensorName];
        // make an original losted text length marker for each sensor
        KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH = [NSString stringWithFormat:@"key_sensor_upload_losted_text_length_%@", sensorName];
        // init buffer array
        bufferArray = [[NSMutableArray alloc] init];
//        _bufferArray = bufferArray;
        // init size of buffer
        bufferSize = 0;
        // last text length
        latestTextLength = 0;
        // csv export state
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        isCSVExport = [userDefaults boolForKey:SETTING_CSV_EXPORT_STATE];
        
        // create new local storage with sensor name
        [self createNewFile:sensorName csvExport:isCSVExport];
    }
    return self;
}


///////////////////////////////////////////////////
///////////////////////////////////////////////////

- (void) setCSVHeader:(NSArray *) headers{
    csvHeader = headers;
}

- (NSData *) getCSVData {
    NSString  * csvFilePath = [self getFilePathWithName:sensorName csvExport:YES];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:csvFilePath];
    if (!fileHandle) {
        NSLog(@"[%@] AWARE can not handle the file.", [self getSensorName]);
        return nil;
    }
    NSData *csvData = [fileHandle readDataToEndOfFile];
    [fileHandle closeFile];
    return csvData;
}

/**
 * Save data to the local storage with NSArray
 * @param   NSArray A sensor data(NSDictionary) as NSArray
 * @return A resulat of data storing
 */
- (bool) saveDataWithArray:(NSArray*) array {
    if (array == nil) {
        return false;
    }
    bool result = false;
    for (NSDictionary *dic in array) {
        result = [self saveData:dic];
    }
    return result;
}


/**
 * Save data with NSDictionary
 * @param data NSDictionary : A sensor data as a NSDictionary
 * @return A result of data storing
 */
- (bool) saveData:(NSDictionary *) data {
    return [self saveData:data toLocalFile:[self getSensorName]];
}



/**
 * Save data with a NSDictionary and a sensor(storage) name
 * @param data NSDictionary  A sensor data as a NSDictionary
 * @param fileName NSString      A sensor name
 * @return A result of data storing
 */
- (bool) saveData:(NSDictionary *)data toLocalFile:(NSString *)fileName{
    
    if (isLock) {
//        NSLog(@"[%@] This sensor is Locked now!", [self getSensorName]);
        return NO;
    }
    
    if(bufferArray == nil){
        bufferArray = [[NSMutableArray alloc] init];
    }
    
    [bufferArray addObject:data];
    
    if ( bufferArray.count >  bufferSize) {
        
        NSMutableString* lines = [[NSMutableString alloc] init];
        
        if (isCSVExport) {
            for (NSDictionary *dict in bufferArray) {
                if(csvHeader != nil){
                    for (NSString *key in csvHeader) {
                        NSObject * d = [dict objectForKey:key];
                         [lines appendFormat:@"%@,", d.description];
                    }
                }else{
                    NSNumber * timestamp = [dict objectForKey:@"timestamp"];
                    [lines appendFormat:@"%@,",timestamp];
                    
                    NSString * device_id = [dict objectForKey:@"device_id"];
                    [lines appendFormat:@"%@,",device_id];
                    
                    NSArray *keys = [dict allKeys];
                    keys = [keys sortedArrayUsingComparator:^(id o1, id o2) {
                        return [o1 compare:o2];
                    }];
                    
                    for(NSString * key in keys){
                        if(![key isEqualToString:@"timestamp"] &&
                           ![key isEqualToString:@"device_id"]){
                            NSObject * d = [dict objectForKey:key];
                            [lines appendFormat:@"%@,", d.description];
                        }
                    }
                }
                [lines deleteCharactersInRange:NSMakeRange(lines.length-1, 1)];
                [lines appendString:@"\n"];
                // NSLog(@"%@", lines);
            }

        }else{
            NSError*error=nil;
            NSData*d=[NSJSONSerialization dataWithJSONObject:bufferArray options:2 error:&error];
            if (!error) {
                lines = [[NSMutableString alloc] initWithData:d encoding:NSUTF8StringEncoding];
            } else {
                NSString * errorStr = [NSString stringWithFormat:@"[%@] %@", [self getSensorName], [error localizedDescription]];
                // [AWAREUtils sendLocalNotificationForMessage:errorStr soundFlag:YES];
                [self saveDebugEventWithText:errorStr type:DebugTypeError label:@""];
                return NO;
            }
            // remove head and tail object ([]) TODO check
            NSRange deleteRangeHead = NSMakeRange(0, 1);
            [lines deleteCharactersInRange:deleteRangeHead];
            NSRange deleteRangeTail = NSMakeRange(lines.length-1, 1);
            [lines deleteCharactersInRange:deleteRangeTail];
            // append "," to the tail of object
            // [lines appendFormat:@","];
            [lines appendFormat:@",\n"];
            //        NSLog(@"%@", jsonstr);
            
        }
        // save the data to local storage
        [self appendLine:lines];
        // init buffer array
        [bufferArray removeAllObjects];
    }
    return YES;
}


/**
 * Append a line to a local storage
 * @param NSString A JSON format (like) sensor data
 * @return A result of data storing
 */
- (BOOL) appendLine:(NSString *) line {
    if (!line) {
        NSLog(@"[%@] Line is null", [self getSensorName] );
        return NO;
    }
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:[self getFilePath]];
    if (fh == nil) { // no
        NSString * fileName = [self getSensorName];
        NSString* debugMassage = [NSString stringWithFormat:@"[%@] ERROR: AWARE can not handle the file.", fileName];
        [self saveDebugEventWithText:debugMassage type:DebugTypeError label:fileName];
        return NO;
    }else{
        NSMutableString * header = nil;
        NSInteger fSize  = [fh seekToEndOfFile];
        
        /////////////////////////////////////////////////////
        // Only CSV
        if( isCSVExport && fSize == 0 && csvHeader != nil ){
            header = [[NSMutableString alloc] init];
            for (NSString * columnName in csvHeader) {
                [header appendFormat:@"%@,", columnName];
            }
            [header deleteCharactersInRange:NSMakeRange(header.length-1, 1)];
            [header appendString:@"\n"];
        }
        if(header != nil){
            line = [NSString stringWithFormat:@"%@%@",header,line];
            // line = [NSString stringWithFormat:@"%@%@\n",header,line];
        }
        //////////////////////////////////////////////////////////
        
        NSData * tempdataLine = [line dataUsingEncoding:NSUTF8StringEncoding];
        [fh writeData:tempdataLine];
        [fh synchronizeFile];
        [fh closeFile];
        return YES;
    }
    return YES;
}



//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

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
    
    if (isCSVExport) {
        return nil; //TODO
    }
    
    NSInteger maxLength = [self getMaxDateLength];
    NSInteger seek = [self getMarker] * maxLength;
    NSString * path = [self getFilePath];
    NSMutableString *data = nil;
    
    // Handle the file
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!fileHandle) {
        NSString * message = [NSString stringWithFormat:@"[%@] AWARE can not handle the file.", [self getSensorName]];
        // NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeError label:@""];
        return Nil;
    }
    
    NSLog(@"[%@] Seek point => %ld", [ self getSensorName], seek);
    
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
    
    latestTextLength = data.length;
    
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
    return [self getFileSizeWithName:sensorName];
}

- (uint64_t) getFileSizeWithName:(NSString*) name {
    NSString * path = [self getFilePathWithName:name csvExport:isCSVExport];
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
}

- (NSInteger) getMaxDateLength {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger length = [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
    return length;
}

///////////////////////////////////////
///////////////////////////////////////

/**
 * Set a next progress maker to local default storage
 */
- (void) setNextMark {
    NSLog(@"[%@] Line length is %llu", [self getSensorName], [self getFileSize]);
    if(latestTextLength < [self getMaxDateLength]){
        [self setMarker:0];
        [self setLostedTextLength:0];
    }else{
        [self setMarker:[self getMarker]+1];
        [self setLostedTextLength:lostedTextLength];
    }
}

/**
 * Reset a progress maker with zero(0)
 */
- (void) resetMark {
    [self setMarker:0];
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


/**
 * Set a current progress marker for data upload to local default storage.
 * @param   int   A progress marker for data upload
 */
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



//////////////////////////////////////////////
///////////////////////////////////////////////

/**
 * Get a file path of a text file based storage on iOS device
 * [NOTE] 
 * This method return a path with a sensor name which is from -getSensorName method.
 * If you want to use special name, you should use -getFilePathWithName:name method.
 * @return NSString     A file path of a text file based storage
 */
- (NSString *) getFilePath {
    return [self getFilePathWithName:[self getSensorName] csvExport:isCSVExport];
}


/**
 * Get a file path of a text file based storage on iOS device
 * @param   NSString    A name for a text file based storage
 * @return  NSString    A file path of a text file based storage
 */
- (NSString *) getFilePathWithName:(NSString *) fileName csvExport:(BOOL) csvExport{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * file = @"";
    if (csvExport) {
        file = [NSString stringWithFormat:@"%@.csv",fileName];
    }else{
        file = [NSString stringWithFormat:@"%@.json",fileName];
    }
    NSString * path = [documentsDirectory stringByAppendingPathComponent:file];
    return path;
}

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////


/**
 * Create a new text file as a local storage.
 * @param   NSString  A file name of local storage
 * @return  A result of data storing
 */
- (BOOL)createNewFile:(NSString *)fileName{
    return [self createNewFile:fileName csvExport:isCSVExport];
}

-(BOOL)createNewFile:(NSString*) fileName csvExport:(BOOL)csvExport {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * file = @"";
    if (csvExport) {
        file = [NSString stringWithFormat:@"%@.csv",fileName];
    }else{
        file = [NSString stringWithFormat:@"%@.json",fileName];
    }
    NSString * path = [documentsDirectory stringByAppendingPathComponent:file];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) { // yes
        BOOL result = [manager createFileAtPath:path
                                       contents:[NSData data]
                                     attributes:nil];
        if (!result) {
            // NSLog(@"[%@] Failed to create the file.", fileName);
            return NO;
        }else{
            // NSLog(@"[%@] Create the file.", fileName);
            return YES;
        }
    }else{
        // NSLog(@"[%@] file is existed", fileName);
    }
    return NO;
}


///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
/**
 * Clear data from a local storage with a file name
 * @param   NSString    A file name for a local storage
 * @return  A result of data clearing
 */
- (bool)clearFile:(NSString *)fileName{
    // return [self createNewFile:fileName csvExport:isCSVExport];
    return [self clearFile:fileName csvExport:isCSVExport];
}

- (bool) clearFile:(NSString *) fileName csvExport:(BOOL)csvExport {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * file = @"";
    if (csvExport) {
        file = [NSString stringWithFormat:@"%@.csv",fileName];
    }else{
        file = [NSString stringWithFormat:@"%@.json",fileName];
    }
    
    NSString * path = [documentsDirectory stringByAppendingPathComponent:file];
    if ([manager fileExistsAtPath:path]) { // yes
        bool result = [@"" writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
        if (result) {
            NSLog(@"[%@] Correct to clear sensor data.", fileName);
            return YES;
        }else{
            NSLog(@"[%@] Error to clear sensor data.", fileName);
            return NO;
        }
    }else{
        NSLog(@"[%@] The file is not exist.", fileName);
        [self createNewFile:fileName];
        return NO;
    }
    return NO;
}




////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

/// Utils

- (void) trackDebugEventsWithDMLogger:(AWAREDebugMessageLogger *) logger {
    dmLogger = logger;
}

- (bool)saveDebugEventWithText:(NSString *)eventText
                          type:(NSInteger)type
                         label:(NSString *)label{
    if (dmLogger != nil) {
        [dmLogger saveDebugEventWithText:eventText type:type label:label];
        return  YES;
    }
    return NO;
}



- (NSString *) getSensorName {
    if (sensorName == nil) {
        return @"";
    }
    return sensorName;
}


- (void)setBufferSize:(int)size{
    if (size >= 0 ) {
        bufferSize = size;
    }else{
        bufferSize = 0;
    }
}

@end
