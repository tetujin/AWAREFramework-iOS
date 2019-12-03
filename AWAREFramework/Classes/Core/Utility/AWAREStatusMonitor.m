//
//  AWAREStatusMonitor.m
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/10/31.
//

#import "AWAREStatusMonitor.h"
#import "AWARECore.h"
#import "EntityAWAREStatus+CoreDataClass.h"

@import CoreData;

static AWAREStatusMonitor * shared;

@implementation AWAREStatusMonitor{
    NSTimer * timer;
}

+ (AWAREStatusMonitor * _Nonnull)shared{
    @synchronized(self){
        if (!shared){
            shared = [[AWAREStatusMonitor alloc] initWithAwareStudy:[AWAREStudy sharedStudy]];
        }
    }
    return shared;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType
{
    NSString * sensorName = @"ios_status_monitor";
    AWAREStorage * storage = nil;
    
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:sensorName];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study
                                            sensorName:sensorName
                                            entityName:@"EntityAWAREStatus"
                                        insertCallBack:^(NSDictionary *dataDict,
                                                         NSManagedObjectContext *childContext,
                                                         NSString *entity) {
            
            EntityAWAREStatus* status = (EntityAWAREStatus *)[NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:childContext];
            [status setValuesForKeysWithDictionary:dataDict];
        }];
    }
    
    return [self initWithAwareStudy:study sensorName:sensorName storage:storage];
}

- (void)createTable{
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:@"trigger"   type:TCQTypeInteger default:@"0"]; // 0=unknown, 1=local, 2=remote
    [maker addColumn:@"datetime"  type:TCQTypeText default:@"''"];
    [maker addColumn:@"tz"        type:TCQTypeReal default:@"0"]; // sec
    [maker addColumn:@"info"      type:TCQTypeText default:@"''"];
    if (self.storage != nil) {
        [self.storage createDBTableOnServerWithTCQMaker:maker];
    }
}

- (void) activateWithCheckInterval:(double)intervalSec{
    [self deactivate];
    [self checkStatusWithType:1];
    timer = [NSTimer scheduledTimerWithTimeInterval:intervalSec
                                             repeats:YES
                                               block:^(NSTimer * _Nonnull timer) {
        [self checkStatusWithType:1];
    }];
}

- (void) checkStatusWithType:(int)trigger{
    
    UIDevice * device = [UIDevice currentDevice];
    NSTimeZone * tz = NSTimeZone.systemTimeZone;
    int wifi = [AWAREStudy sharedStudy].isWifiReachable;
    int mobile = [AWAREStudy sharedStudy].isNetworkReachable;
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    NSDate * now = NSDate.new;
    
    NSMutableDictionary * data = [[NSMutableDictionary alloc] init];
    [data setObject:AWAREStudy.sharedStudy.getDeviceId forKey:@"device_id"];
    [data setObject:[AWAREUtils getUnixTimestamp:now] forKey:@"timestamp"];
    [data setObject:[format stringFromDate:now] forKey:@"datetime"];
    [data setObject:@(trigger) forKey:@"trigger"];
    [data setObject:@(tz.secondsFromGMT) forKey:@"tz"];
    
    
    NSMutableDictionary * info = [[NSMutableDictionary alloc] init];
    [info setObject:@((int)(device.batteryLevel*100.0)) forKey:@"battery"];
    [info setObject:@(device.batteryState) forKey:@"battery_status"];
    [info setObject:device.systemVersion forKey:@"os"];
    [info setObject:AWAREUtils.deviceName forKey:@"device"];
    
    [info setObject:@(AWARECore.sharedCore.isWiFiEnabled) forKey:@"mod_wifi"];
    [info setObject:@(wifi) forKey:@"network_wifi"];
    [info setObject:@(mobile) forKey:@"network_mobile"];
    [info setObject:@(NSProcessInfo.processInfo.isLowPowerModeEnabled) forKey:@"low_power"];
    [info setObject:[self getStorageInfo] forKey:@"storage"];
    
    NSString * strInfo = @"";
    NSError * error = nil;
    NSData * dataInfo = [NSJSONSerialization dataWithJSONObject:info
                                                        options:NSJSONWritingFragmentsAllowed
                                                          error:&error];
    if (dataInfo != nil && error == nil) {
        strInfo = [[NSString alloc] initWithData:dataInfo encoding:NSUTF8StringEncoding];
    }
    
    [data setObject:strInfo forKey:@"info"];
    [self.storage saveDataWithDictionary:data buffer:NO saveInMainThread:YES];
    [self setLatestData:data];
}

- (void) deactivate{
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
}

- (NSDictionary <NSString *, NSNumber *>* _Nonnull) getStorageInfo {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:nil];
    if (dictionary) {
        int GiB = 1024*1024*1024;
        float free = [[dictionary objectForKey: NSFileSystemFreeSize] floatValue]/GiB;
        float total = [[dictionary objectForKey: NSFileSystemSize] floatValue]/GiB;
        float percentage = free/total * 100.0f;
        return [[NSDictionary alloc] initWithObjects:@[@(round(free)),
                                                       @(round(total)),
                                                       @(round(total-free)),
                                                       @(round(percentage))]
                                             forKeys:@[@"free",@"total",@"used",@"percentage"]];
    }
    return [[NSDictionary alloc] init];
}

- (double) round:(float) num to:(int)decimals
{
    int tenpow = 1;
    for (; decimals; tenpow *= 10, decimals--);
    return round(tenpow * num) / tenpow;
}

@end
