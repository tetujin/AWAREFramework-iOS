//
//  AWAREStorage.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import "AWAREStorage.h"
#import "DBTableCreator.h"

@implementation AWAREStorage{
//    bool isOnlyWifi;
//    bool isOnlyBatteryCharging;
    bool isStorageLocked;
    
    bool isSyncing;
    bool isDebug;
    
    int bufferSize;
}

@synthesize buffer;
@synthesize awareStudy;
@synthesize sensorName;

- (instancetype _Nullable ) initWithStudy:(AWAREStudy *_Nullable) study sensorName:(NSString*_Nullable)name{
    self = [super init];
    if (self!=nil) {
        self.awareStudy = study;
        self.sensorName = name;
//        isOnlyWifi = study.getDataUploadStateInWifi;
//        isOnlyBatteryCharging = study.getDataUploadStateWithOnlyBatterChargning;
        isStorageLocked = NO;
        isSyncing = NO;
        bufferSize = 0;
        self.buffer = [[NSMutableArray alloc] init];
    }
    return self;
}

//////////////////////////////
- (BOOL)isLock {
    return isStorageLocked;
}

- (void)lock {
    isStorageLocked = YES;
}

- (void)unlock {
    isStorageLocked = NO;
}

//////////////////////////////

//- (void)allowsCellularAccess {
//    isOnlyWifi = NO;
//}
//
//- (void)allowsDateUploadWithoutBatteryCharging {
//    isOnlyBatteryCharging = NO;
//}
//
//- (void)forbidCellularAccess {
//    isOnlyWifi = YES;
//}
//
//- (void)forbidDatauploadWithoutBatteryCharging {
//    isOnlyBatteryCharging = YES;
//}
//
//- (bool)isSyncWithOnlyWifi {
//    return isOnlyWifi;
//}
//
//- (bool)isSyncWithOnlyBatteryCharging {
//    return isOnlyBatteryCharging;
//}
//
//- (bool)isSyncing {
//    return isSyncing;
//}

//////////////////////////////////

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

- (void)trackDebugEvents {
    isDebug = YES;
}

- (void)untrackDebugEvents {
    isDebug = NO;
}

- (bool)isTrackDebugEvents {
    return isDebug;
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
            // NSLog(@"[%@] Failed to create the file.", fileName);
            return NO;
        }else{
            // NSLog(@"[%@] Create the file.", fileName);
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



//////////////////////////

- (void)createDBTableOnServerWithTCQMaker:(TCQMaker *)tcqMaker {
    if (tcqMaker!=nil) {
        DBTableCreator * creator = [[DBTableCreator alloc] initWithAwareStudy:awareStudy sensorName:sensorName];
        [creator createTable:tcqMaker.getDefaudltTableCreateQuery];
    }
}

- (void) createDBTableOnServerWithQuery:(NSString *)query{
    if (query != nil) {
        DBTableCreator * creator = [[DBTableCreator alloc] initWithAwareStudy:awareStudy sensorName:sensorName];
        [creator createTable:query];
    }
}

- (void) createDBTableOnServerWithQuery:(NSString *)query tableName:(NSString *) table {
    if (query != nil) {
        DBTableCreator * creator = [[DBTableCreator alloc] initWithAwareStudy:awareStudy sensorName:table];
        [creator createTable:query];
    }
}

//////////////////////////////////////////

- (void)startSyncStorage {
    NSLog(@"Please orverwrite -startSyncStorage");
}

- (void)cancelSyncStorage {
    NSLog(@"Please overwirte -cancelSyncStorage");
}

- (BOOL)saveDataWithArray:(NSArray * _Nullable)dataArray buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread {
    NSLog(@"Please overwrite -saveDataWithArrray:buffer:saveInMainThread");
    return YES;
}


- (BOOL)saveDataWithDictionary:(NSDictionary * _Nullable)dataDict buffer:(BOOL)isRequiredBuffer saveInMainThread:(BOOL)saveInMainThread {
    NSLog(@"Please overwrite -saveDataWithDict:buffer:saveInMainThread");
    return YES;
}




@end
