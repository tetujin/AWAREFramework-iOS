//
//  AWAREDevice.m
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/11/21.
//

#import "AWAREDevice.h"

@implementation AWAREDevice

@synthesize isOperationLocked;

- (instancetype)initWithAwareStudy:(AWAREStudy *)study {
    return [self initWithAwareStudy:study dbType:AwareDBTypeSQLite];
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    NSString * sensorName = @"aware_device";
    AWAREStorage * storage  = [[JSONStorage alloc] initWithStudy:study sensorName:sensorName];
    self = [super initWithAwareStudy:study sensorName:sensorName storage:storage];
    if (self!=nil) {
        isOperationLocked = false;
    }
    return self;
}

- (void)createTable{
    // preparing for insert device information
    NSString * query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "board text default '',"
    "brand text default '',"
    "device text default '',"
    "build_id text default '',"
    "hardware text default '',"
    "manufacturer text default '',"
    "model text default '',"
    "product text default '',"
    "serial text default '',"
    "release text default '',"
    "release_type text default '',"
    "sdk text default '',"
    "label text default '', "
    "UNIQUE (device_id)";
    
    if (self.storage != nil && !self.isOperationLocked){
        if (self.storage.tableCreateCallback != nil) {
            [self.storage createDBTableOnServerWithQuery:query
                                              completion:self.storage.tableCreateCallback];
        }else{
            [self.storage createDBTableOnServerWithQuery:query];
        }
    }
}

- (BOOL) insertDeviceId:(NSString *)deviceId
                   name:(NSString *)deviceName{
    
    // preparing for insert device information
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString * machine = [NSString stringWithCString:systemInfo.machine  encoding:NSUTF8StringEncoding];
    NSString * release = [NSString stringWithCString:systemInfo.release  encoding:NSUTF8StringEncoding];
    NSString * version = [NSString stringWithCString:systemInfo.version encoding:NSUTF8StringEncoding];
    
    NSString * systemVersion = [[UIDevice currentDevice] systemVersion];
    NSString * localizeModel = [[UIDevice currentDevice] localizedModel];
    NSString * model = [[UIDevice currentDevice] model];
    NSString * manufacturer = @"Apple";
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setValue:deviceId        forKey:@"device_id"];
    [data setValue:unixtime        forKey:@"timestamp"];
    [data setValue:manufacturer    forKey:@"board"];
    [data setValue:model           forKey:@"brand"];
    [data setValue:deviceName      forKey:@"device"];
    [data setValue:version         forKey:@"build_id"];
    [data setValue:machine         forKey:@"hardware"];
    [data setValue:manufacturer    forKey:@"manufacturer"];
    [data setValue:model           forKey:@"model"];
    [data setValue:deviceName      forKey:@"product"];
    [data setValue:version         forKey:@"serial"];
    [data setValue:release         forKey:@"release"];
    [data setValue:localizeModel   forKey:@"release_type"];
    [data setValue:systemVersion   forKey:@"sdk"];
    [data setValue:deviceName      forKey:@"label"];
    
    if (self.label != nil && ![self.label  isEqual: @""]) {
        [data setValue:deviceName forKey:self.label];
    }
    
    if (self.storage != nil && !isOperationLocked) {
        [self.storage saveDataWithDictionary:data buffer:NO saveInMainThread:YES];
    }
    
    return NO;
}

- (void)startSyncDB{
    if(self.storage != nil && !isOperationLocked){
        [self.storage startSyncStorage];
    }
}

- (void)lockOperation{
    isOperationLocked = YES;
}

- (void)unlockOperation{
    isOperationLocked = NO;
}

@end
