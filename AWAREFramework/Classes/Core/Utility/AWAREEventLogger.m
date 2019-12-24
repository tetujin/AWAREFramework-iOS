//
//  AWARELog.m
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/11/06.
//

#import "AWAREEventLogger.h"
#import "EntityEventLog+CoreDataClass.h"

@import CoreData;

static AWAREEventLogger * shared;

@implementation AWAREEventLogger{
    NSNotificationCenter * notificationCenter;
    NSString * KEY_APP_INSTALL;
    NSString * KEY_APP_VERSION;
    NSString * KEY_OS_VERSION;
}

+ (AWAREEventLogger * _Nonnull)shared{
    @synchronized(self){
        if (!shared){
            shared = [[AWAREEventLogger alloc] initWithAwareStudy:[AWAREStudy sharedStudy]];
            [shared checkOSVersion];
            [shared checkSoftwareVersion];
        }
    }
    return shared;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType
{
    KEY_APP_INSTALL = @"com.ios.awareframmework.eventlogger.key.install";
    KEY_APP_VERSION = @"com.ios.awareframmework.eventlogger.key.appv";
    KEY_OS_VERSION  = @"com.ios.awareframmework.eventlogger.key.osv";
    
    NSString * sensorName = @"ios_aware_log";
    AWAREStorage * storage = nil;
    
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:sensorName];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study
                                            sensorName:sensorName
                                            entityName:@"EntityEventLog"
                                        insertCallBack:^(NSDictionary *dataDict,
                                                         NSManagedObjectContext *childContext,
                                                         NSString *entity) {
            EntityEventLog* eventLog = (EntityEventLog *)[NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:childContext];
            [eventLog setValuesForKeysWithDictionary:dataDict];
        }];
    }
    
    notificationCenter = NSNotificationCenter.defaultCenter;
    [notificationCenter addObserver:self selector:@selector(notificationHandler:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(notificationHandler:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(notificationHandler:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(notificationHandler:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
    [notificationCenter addObserver:self selector:@selector(notificationHandler:) name:UIApplicationWillTerminateNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(notificationHandler:) name:UIApplicationWillResignActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(notificationHandler:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [notificationCenter addObserver:self selector:@selector(notificationHandler:) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(notificationHandler:) name:UIApplicationBackgroundRefreshStatusDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(notificationHandler:) name:UIApplicationSignificantTimeChangeNotification object:nil];
     
    [notificationCenter addObserver:self selector:@selector(notificationHandler:) name:NSProcessInfoPowerStateDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(notificationHandler:) name:UIApplicationBackgroundRefreshStatusDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(notificationHandler:) name:UIDeviceBatteryStateDidChangeNotification object:nil];

    UIDevice.currentDevice.batteryMonitoringEnabled = true;
    
    NSSetUncaughtExceptionHandler(&exceptionHandler);
    
    return [self initWithAwareStudy:study sensorName:sensorName storage:storage];
}

- (void) dealloc {
    [notificationCenter removeObserver:self name:UIApplicationDidFinishLaunchingNotification object:self];
    [notificationCenter removeObserver:self  name:UIApplicationDidBecomeActiveNotification object:self];
    [notificationCenter removeObserver:self  name:UIApplicationDidEnterBackgroundNotification object:self];
    
    [notificationCenter removeObserver:self  name:UIApplicationWillTerminateNotification object:self];
    [notificationCenter removeObserver:self  name:UIApplicationWillResignActiveNotification object:self];
    [notificationCenter removeObserver:self  name:UIApplicationWillEnterForegroundNotification object:self];
    
    [notificationCenter removeObserver:self  name:UIApplicationUserDidTakeScreenshotNotification object:self];
    [notificationCenter removeObserver:self  name:UIApplicationSignificantTimeChangeNotification object:self];
    [notificationCenter removeObserver:self  name:NSProcessInfoPowerStateDidChangeNotification object:self];
    [notificationCenter removeObserver:self  name:UIApplicationBackgroundRefreshStatusDidChangeNotification object:self];
    [notificationCenter removeObserver:self  name:UIDeviceBatteryStateDidChangeNotification object:self];
    [notificationCenter removeObserver:self  name:UIApplicationDidReceiveMemoryWarningNotification object:self];
}

- (void)createTable{
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:@"log_message" type:TCQTypeText default:@"''"];
    if (self.storage != nil ){
        [self.storage createDBTableOnServerWithTCQMaker:maker];
    }
}

- (void) notificationHandler:(NSNotification * )notification{
    if (notification.name != nil){
        NSMutableDictionary * event = [@{@"class":@"AWAREEventLogger",
                                         @"notification":notification.name } mutableCopy];
        if (notification.name == NSProcessInfoPowerStateDidChangeNotification) {
            [event setObject:@(NSProcessInfo.processInfo.lowPowerModeEnabled) forKey:@"state"];
        }else if (notification.name == UIDeviceBatteryStateDidChangeNotification){
            [event setObject:@(UIDevice.currentDevice.batteryState) forKey:@"state"];
            [event setObject:@(UIDevice.currentDevice.batteryLevel) forKey:@"level"];
        }else if (notification.name == UIApplicationDidReceiveMemoryWarningNotification){
            NSLog(@"AWAREEventLogger: UIApplicationDidReceiveMemoryWarningNotification");
//            if (AWAREStudy.sharedStudy.isDebug){
//                [AWAREUtils sendLocalPushNotificationWithTitle:@"Memory Warnings" body:nil timeInterval:0.1 repeats:NO];
//            }
        }else if(notification.name == UIApplicationDidFinishLaunchingNotification){
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            if ([userDefaults boolForKey:KEY_APP_TERMINATED]) {
                [AWAREEventLogger.shared logEvent:@{@"class":@"AWARECore",
                                                    @"event":@"auto-reboot by the location sensor"}];
                if (AWAREStudy.sharedStudy.isDebug){
                    [AWAREUtils sendLocalPushNotificationWithTitle:@"AWARE: Auto Reboot" body:nil timeInterval:0.1 repeats:NO];
                }
                [userDefaults setBool:NO forKey:KEY_APP_TERMINATED];
                [userDefaults synchronize];
            }else{
            }
        }else if(notification.name == UIApplicationWillTerminateNotification){
            [AWAREEventLogger.shared logEvent:@{@"class":@"AWAREEventLogger",
                                                @"event":@"terminate"}];
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setBool:YES forKey:KEY_APP_TERMINATED];
            [userDefaults synchronize];
        }
        [self logEvent:event];
    }else{
        [self logEvent:@{@"class":@"AWAREEventLogger",
                         @"event":notification.debugDescription}];
    }
    
}
     
- (BOOL) logEvent:(NSDictionary<NSString *,id> *)event{
    NSError * error = nil;
    NSData * eventData = [NSJSONSerialization dataWithJSONObject:event
                                                    options:NSJSONWritingFragmentsAllowed
                                                      error:&error];
    if (eventData != nil && self.storage != nil) {
        NSString * eventStr = [[NSString alloc] initWithData:eventData
                                                  encoding:NSUTF8StringEncoding];
        NSNumber * timestamp = [AWAREUtils getUnixTimestamp:[NSDate date]];
        [self.storage saveDataWithDictionary:@{@"timestamp":timestamp,
                                               @"device_id": AWAREStudy.sharedStudy.getDeviceId,
                                               @"log_message":eventStr}
                                      buffer:NO saveInMainThread:YES];
        return YES;
    }
    return NO;
}
     
void exceptionHandler(NSException *exception) {
    [AWAREEventLogger.shared logEvent:@{@"class":@"AWAREEventLogger",
                                        @"event":@"exception",
                                        @"reason":exception.description}];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:KEY_APP_TERMINATED];
    [userDefaults synchronize];
}

- (void)checkSoftwareVersion{
    NSString* currentVersion = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:KEY_APP_INSTALL]) {
        [self logEvent:@{@"class":@"AWAREEventLogger",
                         @"event":@"app install"}];
    }else{
        NSString* preVersion = @"";
        if ([defaults stringForKey:KEY_APP_VERSION]) {
            preVersion = [defaults stringForKey:KEY_APP_VERSION];
        }
    
        if (![currentVersion isEqualToString:preVersion]) {
            [self logEvent:@{@"class":@"AWAREEventLogger",
                             @"event":[NSString stringWithFormat:@"software update (%@ -> %@)",preVersion, currentVersion]}];
        }
        
        [defaults setObject:currentVersion forKey:KEY_APP_VERSION];
    }
    
    [defaults setBool:YES forKey:KEY_APP_INSTALL];
    [defaults setObject:currentVersion forKey:KEY_APP_VERSION];
}


- (void)checkOSVersion{
    NSString* currentOSVer = [[UIDevice currentDevice] systemVersion];
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    NSString* preOSVer = @"";
    if ([defaults stringForKey:KEY_OS_VERSION]) {
        preOSVer = [defaults stringForKey:KEY_OS_VERSION];
    }
    if (![currentOSVer isEqualToString:preOSVer]) {
        [self logEvent:@{@"class":@"AWAREEventLogger",
                         @"event":[NSString stringWithFormat:@"os update (%@ -> %@)",preOSVer, currentOSVer]}];
    }
    [defaults setObject:currentOSVer forKey:KEY_OS_VERSION];
}


@end
