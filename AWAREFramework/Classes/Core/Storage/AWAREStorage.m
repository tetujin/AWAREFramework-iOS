//
//  AWAREStorage.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import "AWAREStorage.h"
#import "DBTableCreator.h"

@implementation AWAREStorage{
    bool isStorageLocked;
    bool isSyncing;
    bool isDebug;
    bool isStore;
    int bufferSize;
}

@synthesize buffer;
@synthesize awareStudy;
@synthesize sensorName;
@synthesize retryLimit;
@synthesize syncTaskIntervalSecond;
@synthesize syncProcessCallBack;
@synthesize lastSaveTimestamp;
@synthesize saveInterval;
@synthesize tableCreatecallBack;

- (instancetype _Nullable ) initWithStudy:(AWAREStudy *_Nullable) study sensorName:(NSString*_Nullable)name{
    self = [super init];
    if (self!=nil) {
        self.awareStudy = study;
        self.sensorName = name;
        isStorageLocked = NO;
        isSyncing = NO;
        isStore = YES;
        bufferSize = 0;
        retryLimit = 0;
        lastSaveTimestamp = 0;
        saveInterval = 0;
        syncTaskIntervalSecond = 1;
        self.buffer = [[NSMutableArray alloc] init];
    }
    return self;
}


/**
 Return an accessibility of a lock state

 @return An accessibility of a lock state
 */
- (BOOL)isLock {
    return isStorageLocked;
}


/**
 Lock an accessibility of a lock state
 */
- (void)lock {
    isStorageLocked = YES;
}


/**
 Unlock an acessibility of lock state
 */
- (void)unlock {
    isStorageLocked = NO;
}


- (nullable NSDictionary *) getLatestData {
    return @{};
}

/////////////////////////////////

- (int)getBufferSize {
    return bufferSize;
}

- (void)setBufferSize:(int)size {
    bufferSize = size;
}

- (bool) isDebug{
    return isDebug;
}

- (void) setDebug:(BOOL)status{
    isDebug = status;
}

//////////////////////////

-(BOOL)createLocalStorageWithName:(NSString*) fileName type:(NSString *) type {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * file = @"";
    file = [NSString stringWithFormat:@"%@.%@",fileName,type];
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
    }
    return NO;
}

-(BOOL)removeLocalStorageWithName:(NSString*) fileName type:(NSString *)type{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * file = @"";
    file = [NSString stringWithFormat:@"%@.%@",fileName,type];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:file];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) { // yes
        NSError * error = nil;
        BOOL result = [manager removeItemAtPath:path error:&error];
        if (!result) {
            if (error!=nil) {
                NSLog(@"[%@] %@", self.sensorName, error.debugDescription);
            }
            if(isDebug) NSLog(@"[%@] Failed to create the file.", fileName);
            return NO;
        }else{
            if(isDebug) NSLog(@"[%@] Create the file.", fileName);
            return YES;
        }
    }
    return NO;
}

- (BOOL) appendLine:(NSString *) line withFilePath:(NSString *)path{
    if (!line) {
        NSLog(@"[%@] Error: The line is empty", self.sensorName );
        return NO;
    }
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (fh == nil) { // no
        NSString* debugMassage = [NSString stringWithFormat:@"[%@] Error: AWARE can not handle the file", self.sensorName];
        NSLog(@"%@",debugMassage);
        return NO;
    }else{
        [fh seekToEndOfFile];
        NSData * tempdataLine = [line dataUsingEncoding:NSUTF8StringEncoding];
        [fh writeData:tempdataLine];
        [fh synchronizeFile];
        [fh closeFile];
        return YES;
    }
    return YES;
}


///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////


- (bool) clearLocalStorageWithName:(NSString*) fileName type:(NSString *)type{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * file = [NSString stringWithFormat:@"%@.%@",fileName, type];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:file];
    if ([manager fileExistsAtPath:path]) { // yes
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        [fileHandle truncateFileAtOffset:0];
        [fileHandle synchronizeFile];
        [fileHandle closeFile];
        if(self.isDebug)NSLog(@"[%@] Sensor data was cleared successfully", fileName);
        return YES;
    }else{
        if(isDebug)NSLog(@"[%@] The file is not exist.", fileName);
        [self createLocalStorageWithName:fileName type:type];
        return NO;
    }
    return NO;
}




//////////////////////////////////
- (NSString *) getFilePathWithName:(NSString *) fileName type:(NSString *)type{
    NSArray  * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * file =  [NSString stringWithFormat:@"%@.%@",fileName,type];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:file];
    return path;
}

- (NSNumber *)getFileSizeWithName:(NSString *)fileName type:(NSString *)type{
    NSString *path = [self getFilePathWithName:fileName type:type];
    NSFileManager *man = [NSFileManager defaultManager];
    NSError * error = nil;
    NSDictionary *attribute = [man attributesOfItemAtPath:path error: &error];
    if (error == nil) {
        NSNumber *fileSize = [attribute objectForKey:NSFileSize];
        return fileSize;
    }else{
        NSLog(@"%@", error.debugDescription);
    }
    return nil;
}


//////////////////////////

- (void)createDBTableOnServerWithTCQMaker:(TCQMaker *)tcqMaker {
    if (tcqMaker!=nil) {
        NSString * tableName = @"";
        if (self.sensorName != nil) {
            tableName = self.sensorName;
        }
        NSString * query = [tcqMaker getDefaudltTableCreateQuery];
        if (query != nil) {
            DBTableCreator * creator = [[DBTableCreator alloc] initWithAwareStudy:awareStudy sensorName:tableName ];
            [creator setCallback:self.tableCreatecallBack];
            [creator createTable:query];
        }
    }
}

- (void) createDBTableOnServerWithQuery:(NSString *)query{
    NSString * tableName = @"";
    if (self.sensorName != nil) {
        tableName = self.sensorName;
    }
    if (query != nil) {
        DBTableCreator * creator = [[DBTableCreator alloc] initWithAwareStudy:awareStudy sensorName:tableName ];
        [creator setCallback:self.tableCreatecallBack];
        [creator createTable:query];
    }
}

- (void) createDBTableOnServerWithQuery:(NSString *)query tableName:(NSString *) table {
    if (query != nil) {
        DBTableCreator * creator = [[DBTableCreator alloc] initWithAwareStudy:awareStudy sensorName:table];
        [creator setCallback:self.tableCreatecallBack];
        [creator createTable:query];
    }
}


- (void)createDBTableOnServerWithQuery:(NSString *)query completion:(TableCreateCallBack)completion{
    NSString * tableName = @"";
    if (self.sensorName != nil) {
        tableName = self.sensorName;
    }
    [self createDBTableOnServerWithQuery:query tableName:tableName  completion:completion];
}

- (void)createDBTableOnServerWithQuery:(NSString *)query tableName:(NSString *)table completion:(TableCreateCallBack)completion{
    if (query != nil) {
        DBTableCreator * creator = [[DBTableCreator alloc] initWithAwareStudy:awareStudy sensorName:table];
        [creator setCallback:completion];
        [creator createTable:query];
    }
}

//////////////////////////////////////////

- (void)startSyncStorage {
    NSLog(@"Please orverwrite -startSyncStorage");
}

- (void)startSyncStorageWithCallBack:(SyncProcessCallBack)callback{
    syncProcessCallBack = callback;
    NSLog(@"Please orverwrite -startSyncStorageWithCallBack");
}

- (void)cancelSyncStorage {
    NSLog(@"Please overwirte -cancelSyncStorage");
}

- (BOOL)saveDataWithArray:(NSArray * _Nullable)dataArray buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread {
    NSLog(@"Please overwrite -saveDataWithArrray:buffer:saveInMainThread:");
    return YES;
}

- (BOOL)saveDataWithDictionary:(NSDictionary * _Nullable)dataDict buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread {
    NSLog(@"Please overwrite -saveDataWithDict:buffer:saveInMainThread:");
    return YES;
}

- (BOOL)saveBufferDataInMainThread:(BOOL)saveInMainThread{
    return YES;
}

- (void)resetMark{
    
}

- (bool)isSyncing {
    return NO;
}

- (BOOL) isStore{
    return isStore;
}

- (void) setStore:(BOOL) state{
    isStore = state;
}

/////
- (NSArray *) fetchTodaysData{
    return [self fetchTodaysData];
}

- (void) fetchTodaysDataWithHandler:(FetchDataHandler)handler{
    NSLog(@"Please overwrite -fetchTodaysDataWithHandler method");
}

- (NSArray *) fetchDataBetweenStart:(NSDate *)start andEnd:(NSDate *)end{
    NSLog(@"Please overwrite -fetchTodaysData method");
    return @[];
}

- (void) fetchDataBetweenStart:(NSDate *)start andEnd:(NSDate *)end withHandler:(FetchDataHandler)handler{
    NSLog(@"Please overwrite -fetchDataBetweenStart:andEnd:withHandler method");
}

- (NSArray *)fetchDataFrom:(NSDate *)from to:(NSDate *)to{
    NSLog(@"Please overwrite -fetchDataFrom:to method");
    return @[];
}

- (void) fetchDataFrom:(NSDate *)from to:(NSDate *)to handler:(FetchDataHandler)handler{
    NSLog(@"This storage which you are using does not support this method. Please overwrite -fetchDataFrom:to:handler method");
}

- (void)fetchDataFrom:(NSDate *)from to:(NSDate *)to limit:(int)limit all:(bool)all handler:(LimitedDataFetchHandler)handler{
    NSLog(@"This storage which you are using does not support this method. Please overwrite -fetchDataFrom:to:limit:all:handler method");
}

- (NSDate *) getToday {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents * components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:[NSDate new]];
    NSInteger year  =  components.year;
    NSInteger month =  components.month;
    NSInteger day   =  components.day;
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd"];
    NSDate * today   = [formatter dateFromString:[NSString stringWithFormat:@"%zd/%zd/%zd", year, month, day]];
    return today;
}

@end
