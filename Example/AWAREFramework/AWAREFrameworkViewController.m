//
//  AWAREFrameworkViewController.m
//  AWAREFramework
//
//  Created by tetujin on 03/22/2018.
//  Copyright (c) 2018 tetujin. All rights reserved.
//

#import "AWAREFrameworkViewController.h"
#import "AWAREFrameworkAppDelegate.h"
#import <AWAREFramework/AWARESensors.h>
#import <AWAREFramework/ESMSchedule.h>
#import <AWAREFramework/ESMScheduleManager.h>
#import <AWAREFramework/ESMScrollViewController.h>
#import <AWAREFramework/SyncExecutor.h>
#import <AWAREFramework/CalendarESMScheduler.h>
#import <AWAREFramework/AWAREKeys.h>
#import <AWAREFramework/ExternalCoreDataHandler.h>
#import <AWAREFRamework/GoogleLogin.h>
#import <AWAREFramework/AWAREHealthKit.h>

#import "SampleSensor.h"
#import "SampleESMView.h"
#import <AWAREFramework/AWARESensorManager.h>

@interface AWAREFrameworkViewController ()

@end

@implementation AWAREFrameworkViewController{
    NSTimer * timer;
    // SampleSensor * sensor;
    AWAREHealthKit * healthKit;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [AWARECore.sharedCore requestPermissionForBackgroundSensingWithCompletion:^{
        [AWARECore.sharedCore activate];
        Screen * sensor = [[Screen alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeSQLite];
        Accelerometer * acc = [[Accelerometer alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeSQLite];
        Locations * location = [[Locations alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeSQLite];
        
        AWARESensorManager * manager = [AWARESensorManager sharedSensorManager];
        [manager addSensor:sensor];
        [manager addSensor:acc];
        [manager addSensor:location];
        [manager setDebugToAllSensors:YES];
        [manager startAllSensors];
    }];
//    ESMItem * originalESM = [[ESMItem alloc] init];
//    [originalESM setTrigger:@"a"];
//    [originalESM setTitle:@"This is a sample original ESM"];
//    [originalESM setType:99];
//
//    ESMItem * likertESM = [[ESMItem alloc] initAsLikertScaleESMWithTrigger:@"b"
//                                                                 likertMax:5
//                                                            likertMinLabel:@"bad"
//                                                            likertMaxLabel:@"good"
//                                                                likertStep:1];
//    [likertESM setTitle:@"hello world"];
//
//    ESMSchedule * schedule = [[ESMSchedule alloc] init];
//    schedule.startDate  = [NSDate new];
//    schedule.endDate    = [[NSDate new] dateByAddingTimeInterval:60*60*24];
//    schedule.scheduleId = @"sample_schedule";
//    [schedule addESM:originalESM];
//    [schedule addESM:likertESM];
//
//    [[ESMScheduleManager sharedESMScheduleManager] addSchedule:schedule];
    
//    Pedometer * pedometer = [[Pedometer alloc] init];
//    [pedometer startSensor];
//
//    healthKit = [[AWAREHealthKit alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeSQLite];
//    healthKit.fetchIntervalSecond = 60;
//    [healthKit startSensor];
//
//    [NSTimer scheduledTimerWithTimeInterval:5 repeats:NO block:^(NSTimer * _Nonnull timer) {
//        [self->healthKit.awareHKHeartRate.storage fetchTodaysDataWithHandler:^(NSString * name,
//                                                                              NSArray  * results,
//                                                                              NSDate   * start,
//                                                                              NSDate   * end,
//                                                                              NSError  * _Nullable error) {
//
//            for (NSDictionary * dict in results) {
//                if ([dict[@"type"] isEqualToString:@"HKQuantityTypeIdentifierHeartRate"]){
//                    NSDate * start = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)dict[@"timestamp"]).doubleValue/1000];
//                    NSDate * end   = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)dict[@"timestamp_end"]).doubleValue/1000];
//                    NSNumber * value = dict[@"value"];
//                    NSString * unit  = dict[@"unit"];
//                    NSLog(@"[%@][%@][%@][%@]", start, end, value, unit);
//                }
//            }
//        }];
//    }];
    
//    Processor * processor = [[Processor alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeSQLite];
//    [processor startSensor];
//    [processor setDebug:YES];
//    [processor setSensorEventHandler:^(AWARESensor *sensor, NSDictionary *data) {
//        NSLog(@"%@", data);
//    }];
        // [self testSensingWithStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeSQLite sensorManager:[AWARESensorManager sharedSensorManager]];

//    Accelerometer * acc = [[Accelerometer alloc] init];
//    // [acc setSavingIntervalWithSecond:1];
//    [acc setDebug:true];
//    [acc.storage setDebug:true];
//    [acc setSensorEventHandler:^(AWARESensor *sensor, NSDictionary *data) {
//        // NSLog(@"%@",data);
//    }];
//    if ([acc startSensor]) {
//        NSLog(@"start");
//    }else{
//
//    }
    
//    [acc performSelector:@selector(startSyncDB) withObject:nil afterDelay:3];
    
    // Do any additional setup after loading the view, typically from a nib.
//    AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
//    AWARECore * core = delegate.sharedAWARECore;
//    [core requestBackgroundSensing];
//    [core requestNotification:[UIApplication sharedApplication]];
//
//    [core.sharedAwareStudy setStudyURL:@"https://api.awareframework.com/index.php/webservice/index/1749/ITrUqPkbcSNM"];
//    [core.sharedAwareStudy setDebug:YES];
//    [core.sharedAwareStudy setMaximumByteSizeForDBSync:1000000];

//    IOSActivityRecognition * activity = [[IOSActivityRecognition alloc] initWithAwareStudy:core.sharedAwareStudy dbType:AwareDBTypeCSV];
//    [activity startSensorAsLiveModeWithFilterLevel:CMMotionActivityConfidenceLow];
//    [activity setDebug:YES];
    
//    Battery * battery = [[Battery alloc] initWithAwareStudy:core.sharedAwareStudy dbType:AwareDBTypeCSV];
//    [battery.storage setDebug:YES];
//    for (int i =0; i < 1000; i++) {
//        [battery.storage saveDataWithDictionary:@{@"battery_adaptor":@0,@"battery_health":@0,@"battery_level":@(-100),@"battery_scale":@(100),@"battery_status":@(0),@"battery_technology":@"",@"battery_temperature":@(0),@"battery_voltage":@(0),@"device_id":@"5fd18477-df66-4a8e-8fb1-010c03f75202",@"timestamp":@(i)} buffer:NO saveInMainThread:YES];
//    }
//
//    // [battery performSelector:@selector(startSyncDB) withObject:nil afterDelay:10];
//    [NSTimer scheduledTimerWithTimeInterval:5 repeats:NO block:^(NSTimer * _Nonnull timer) {
//        [activity.storage setDebug:YES];
//        [activity startSyncDB];
//        [battery.storage setDebug:YES];
//        [battery.storage startSyncStorage];
//    }];
    
//    [[AWAREStudy sharedStudy] setStudyURL:@"https://api.awareframework.com/index.php/webservice/index/1749/ITrUqPkbcSNM"];
//    [self testSensingWithStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeSQLite sensorManager:[AWARESensorManager sharedSensorManager]];
    
    
//    Accelerometer * accelerometer = [[Accelerometer alloc] initWithAwareStudy:core.sharedAwareStudy dbType:AwareDBTypeCSV];
//    [accelerometer startSensor];
//    [accelerometer startSyncDB];
    
//    ESMSchedule * schdule = [[ESMSchedule alloc] init];
//
//    ESMItem * item = [[ESMItem alloc] initAsTextESMWithTrigger:@"test"];
//    [item setTitle:@"hello"];
//    [schdule addESM:item];
//
//    [[ESMScheduleManager sharedESMScheduleManager] removeAllSchedulesFromDB];
//    [[ESMScheduleManager sharedESMScheduleManager] removeAllESMHitoryFromDB];
//
//    [[ESMScheduleManager sharedESMManager] addSchedule:schdule];
//
    
//    NSURL * dbURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"my.sqlite"];
//    [ExternalCoreDataHandler.sharedHandler overwriteDatabasePathWithFileURL:dbURL];
//
//    NSURL * modelURL = [[NSBundle mainBundle] URLForResource:@"MyCoreDataModel" withExtension:@"momd"];
//    [ExternalCoreDataHandler.sharedHandler overwriteManageObjectModelWithFileURL:modelURL];
//
//    sensor = [[SampleSensor alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeSQLite];
//    [sensor startSensor];
//    [sensor createTable];
//
//    [sensor.storage setSyncProcessCallBack:^(NSString *name, double progress, NSError * _Nullable error) {
//        NSLog(@"%f",progress);
//        NSLog(@"%@", error);
//    }];
//
//    [sensor.storage startSyncStorage];
    
    // [self testESMSchedule];
    
//    Bluetooth * bluetooth = [[Bluetooth alloc] init];
//    [bluetooth setSensorEventHandler:^(AWARESensor *sensor, NSDictionary *data) {
//        NSLog(@"%@",data);
//    }];
//    [bluetooth startSensor];

//    AWAREStudy * study = [AWAREStudy sharedStudy];
//    [study setStudyURL:@"https://api.awareframework.com/index.php/webservice/index/1838/0VeRlyz4Zw3b"];
//
//    Conversation * conv = [[Conversation alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
//    [conv startSensor];
//
//    [conv createTable];
//
//    [conv startSyncDB];
    
//    Battery * battery = [[Battery alloc] initWithAwareStudy:[AWAREStudy sharedStudy] dbType:AwareDBTypeSQLite];
//    [battery startSensor];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(esmEventHandler:) name:ACTION_AWARE_ESM_NEXT object:nil];

//    Fitbit * fitbit = [[Fitbit alloc] init];
//    [fitbit startSensor];

//    Calls * call = [[Calls alloc] initWithDBType:AwareDBTypeSQLite];
//    [call setDebug:YES];
//    [call startSensor];
//
//    AmbientNoise * noise = [[AmbientNoise alloc] initWithDBType:AwareDBTypeSQLite];
//    [noise setFrequencyMin:1];
//    [noise setSampleSize:30];
//    [noise setDebug:YES];
//    [noise startSensor];
//
//    Accelerometer * acc = [[Accelerometer alloc] initWithDBType:AwareDBTypeJSON];
//    [acc setDebug:YES];
//    [acc setSensingIntervalWithHz:1];
//    [acc startSensor];



//    Wifi * wifi = [[Wifi alloc] initWithDBType:AwareDBTypeSQLite];
//    [wifi setDebug:YES];
//    [wifi setSensingIntervalWithMinute:10];
//    [wifi startSensor];
    
//    Accelerometer * acc = [[Accelerometer alloc] initWithDBType:AwareDBTypeJSON];
//    [acc setDebug:YES];
//    [acc setSensingIntervalWithHz:5];
//    [acc startSensor];
    
//    FusedLocations * location = [[FusedLocations alloc] initWithDBType:AwareDBTypeSQLite];
//    [location setDebug:YES];
//    [location setIntervalSec:600];
//    [location startSensor];
    
//    _ble = [[Bluetooth alloc] initWithDBType:AwareDBTypeCSV];
//    [_ble setDebug:YES];
//    // [ble setCommonBLEServices];
//    //    [ble addBleUUID:[CBUUID UUIDWithString:@"884EDA57-8CDB-4845-B104-35742E6C47F9"]];
//    //    [ble setCommonBleUUIDs];
//    //    [ble addBLEService:[CBUUID UUIDWithString:@"7B5D063C-AB75-1C53-4EB3-6F28EBEC9C6E"]];
//    //    [ble addBLEService:[CBUUID UUIDWithString:@"55B2328E-BF11-7B76-408C-DA50DB978AF6"]];
//    [_ble setScanInterval:30];
//    [_ble setScanDuration:10];
//    [_ble startSensor];
    // [[AWARESensorManager sharedSensorManager] addSensor:_ble];
}

- (void) sendContextBasedESMNotification:(id)sender {
    NSLog(@"%@",sender);
}

- (void) setNotifWithHour:(int)hour min:(int)min sec:(int)sec title:(NSString *)title notifId:(NSString *)notifId {
    NSCalendar * cal = [NSCalendar currentCalendar];
    NSDateComponents * componetns = [cal components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:[NSDate new]];
    componetns.hour = hour;
    componetns.minute = min;
    componetns.second = sec;
    UNNotificationTrigger * notificationTrigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:componetns repeats:NO];
    
    NSLog(@"[CalendarESMScheduler] Set ESM Notification at %ld:%ld",(long)componetns.hour, (long)componetns.minute);
    
    UNMutableNotificationContent * notificationContent = [[UNMutableNotificationContent alloc] init];
    notificationContent.title = @"Hello 1";
    notificationContent.badge = @1;
    notificationContent.sound = [UNNotificationSound defaultSound];
    notificationContent.categoryIdentifier = PLUGIN_CALENDAR_ESM_SCHEDULER_NOTIFICATION_CATEGORY;
    
    // NOTE: Notification ID should use an unified ID
    UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:notifId content:notificationContent trigger:notificationTrigger];
    
    UNUserNotificationCenter * notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    [notificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error!=nil) {
            NSLog(@"%@",error.debugDescription);
        }
    }];
}

- (void) calendarESMTest {
    // AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
    AWARECore * core = [AWARECore sharedCore];
    [core requestPermissionForBackgroundSensing];
    [core requestPermissionForPushNotification];
}

- (void) testCSVStorageWithStudy:(AWAREStudy * )study{
    Battery * battery = [[Battery alloc] initWithAwareStudy:study dbType:AwareDBTypeCSV];
    [battery setIntervalSecond:1];
    [battery startSensor];
//    [battery setSensorEventCallBack:^(NSDictionary *data) {
//        NSLog(@"%@",data.debugDescription);
//    }];
}

- (void) testAccelerometerSync{
    
    AWAREStudy * study = [AWAREStudy sharedStudy];
    [study setMaximumNumberOfRecordsForDBSync:100];
    [study setMaximumByteSizeForDBSync:1000];
    [study setCleanOldDataType:cleanOldDataTypeAlways];
    
    Accelerometer * accelerometer = [[Accelerometer alloc] initWithAwareStudy:study dbType:AwareDBTypeJSON];
    [accelerometer.storage removeLocalStorageWithName:@"accelerometer" type:@"json"];
    
    [accelerometer.storage setBufferSize:10];
    for (int i =0; i<100; i++) {
//        NSNumber * timestamp = @([NSDate new].timeIntervalSince1970);
        [accelerometer.storage saveDataWithDictionary:@{@"timestamp":@(i),@"device_id":study.getDeviceId} buffer:YES saveInMainThread:YES];
    }
    // [accelerometer.storage resetMark];

    // [accelerometer setDebug:YES];
    [accelerometer.storage setSyncTaskIntervalSecond:1];
    [accelerometer performSelector:@selector(startSyncDB) withObject:nil afterDelay:10];
    
}

- (void)audioSensorWith:(AWAREStudy *)study{
    AmbientNoise * noise = [[AmbientNoise alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
    [noise createTable];
    [noise startSensor];
    [noise setDebug:YES];

    [noise.storage setDebug:YES];
    [noise performSelector:@selector(startSyncDB) withObject:nil afterDelay:10];
//    id callback = ^(NSString *name, double progress, NSError * _Nullable error) {
//        NSLog(@"[%@] %3.2f %%", name, progress*100.0f);
//    };
//    [noise performSelector:@selector(startSyncDB) withObject:callback afterDelay:5];
//    //[noise.storage resetMark];
//    // [noise startSyncDB];
//
//    [noise performSelector:@selector(startSyncDB) withObject:callback afterDelay:10];
}


- (void)viewDidAppear:(BOOL)animated{

//    GoogleLogin * login = [[GoogleLogin alloc] initWithAwareStudy:[AWAREStudy sharedStudy]
//                                                           dbType:AwareDBTypeJSON
//                                                         clientId:@"513561083200-em3srmsc40a2q6cuh8o2hguvhd1umfll.apps.googleusercontent.com"];
//
//    [login startSensor];
//
//    if([login isNeedLogin]){
//        AWAREGoogleLoginViewController * loginViewController = [[AWAREGoogleLoginViewController alloc] init];
//        loginViewController.googleLogin = login;
//        [self presentViewController:loginViewController animated:YES completion:^{
//            NSLog(@"done");
//        }];
//    }
//
//    NSLog(@"%@", [GoogleLogin getUserName]);
//    NSLog(@"%@", [GoogleLogin getEmail]);
//    NSLog(@"%@", [GoogleLogin getPhonenumber]);
    
    [super viewDidAppear:animated];
    
    // get valid ESMs
    NSArray * schdules = [[ESMScheduleManager sharedESMScheduleManager] getValidSchedules];
    // check number of the valid ESMs
    if (schdules.count > 0) {
        ESMScrollViewController * esmScrollViewController  = [[ESMScrollViewController alloc] init];
        // set a handler for generating the original ESM generation
        [esmScrollViewController setOriginalESMViewGenerationHandler:^BaseESMView * _Nullable (EntityESM * _Nonnull esm,
                                                                                               double bottomESMViewPositionY,
                                                                                               UIViewController * viewController) {
            if (esm.esm_type != nil && esm.esm_type.intValue == 99){
                double height = 100;
                double width  = viewController.view.frame.size.width;
                return [[SampleESMView alloc] initWithFrame:CGRectMake(0, bottomESMViewPositionY, width, height)
                                                        esm:esm
                                             viewController:viewController];
            }
            return nil;
        }];
        // remove an ESM Schedule
        [esmScrollViewController setAnswerCompletionHandler:^{
            [[ESMScheduleManager sharedESMScheduleManager] deleteScheduleWithId:@"sample_schedule"];
        }];
        // show ESM scroll view
        [self presentViewController:esmScrollViewController animated:YES completion:^{
            
        }];
        /** or, following code if your project using Navigation Controller */
        // [self.navigationController pushViewController:esmView animated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) testSensingWithStudy:(AWAREStudy *) study dbType:(AwareDBType)dbType sensorManager:(AWARESensorManager *)manager{
    
    Accelerometer * accelerometer = [[Accelerometer alloc] initWithAwareStudy:study dbType:dbType];
    
    Barometer * barometer = [[Barometer alloc] initWithAwareStudy:study dbType:dbType];
    
    Bluetooth * bluetooth = [[Bluetooth alloc] initWithAwareStudy:study dbType:dbType];

    Battery * battery = [[Battery alloc] initWithAwareStudy:study dbType:dbType];

    Calls * call = [[Calls alloc] initWithAwareStudy:study dbType:dbType];

    Gravity * gravity = [[Gravity alloc] initWithAwareStudy:study dbType:dbType];

    Gyroscope * gyroscope = [[Gyroscope alloc] initWithAwareStudy:study dbType:dbType];

    LinearAccelerometer * linearAccelerometer = [[LinearAccelerometer alloc] initWithAwareStudy:study dbType:dbType];

    Locations * location = [[Locations alloc] initWithAwareStudy:study dbType:dbType];

    Magnetometer * magnetometer = [[Magnetometer alloc] initWithAwareStudy:study dbType:dbType];

    Network * network = [[Network alloc] initWithAwareStudy:study dbType:dbType];

    Orientation * orientation = [[Orientation alloc] initWithAwareStudy:study dbType:dbType];

    Pedometer * pedometer = [[Pedometer alloc] initWithAwareStudy:study dbType:dbType];

    Processor * processor = [[Processor alloc] initWithAwareStudy:study dbType:dbType];

    Proximity * proximity = [[Proximity alloc] initWithAwareStudy:study dbType:dbType];

    Rotation * rotation = [[Rotation alloc] initWithAwareStudy:study dbType:dbType];

    Screen * screen = [[Screen alloc] initWithAwareStudy:study dbType:dbType];

    Timezone * timezone = [[Timezone alloc] initWithAwareStudy:study dbType:dbType];

    Wifi * wifi = [[Wifi alloc] initWithAwareStudy:study dbType:dbType];
    
    //////////////////
    
    AmbientNoise * noise = [[AmbientNoise alloc] initWithAwareStudy:study dbType:dbType];
    
    Calendar * cal = [[Calendar alloc] initWithAwareStudy:study dbType:dbType];
    
    Contacts * contacts = [[Contacts alloc] initWithAwareStudy:study dbType:dbType];
    
    DeviceUsage * usage = [[DeviceUsage alloc] initWithAwareStudy:study dbType:dbType];
    
    FusedLocations * flocation = [[FusedLocations alloc] initWithAwareStudy:study dbType:dbType];
    
    GoogleLogin * login = [[GoogleLogin alloc] initWithAwareStudy:study dbType:dbType];
    
    IOSActivityRecognition * activity = [[IOSActivityRecognition alloc] initWithAwareStudy:study dbType:dbType];
    
    Memory * memory = [[Memory alloc] initWithAwareStudy:study dbType:dbType];
    
    NTPTime * ntp = [[NTPTime alloc] initWithAwareStudy:study dbType:dbType];
    
    OpenWeather * weather = [[OpenWeather alloc] initWithAwareStudy:study dbType:dbType];
    
    [manager addSensors:@[accelerometer,barometer,bluetooth,battery,call,gravity,gyroscope,linearAccelerometer,location,magnetometer,network,orientation,pedometer,processor,proximity,rotation,screen,timezone,wifi,
                          noise, cal, contacts, usage, flocation, login, activity, memory, ntp, weather]];
    
    // bluetooth,
    
//    [manager setSensorEventCallbackToAllSensors:^(NSDictionary *data) {
//        NSLog(@"%@",data);
//    }];
    // [manager addSensor:accelerometer];
    // [manager performSelector:@selector(syncAllSensorsForcefully) withObject:nil afterDelay:10];
    
    SyncProcessCallBack callback = ^(NSString *name, double progress, NSError * _Nullable error) {
        NSLog(@"%@ %3.2f",name, progress);
    };

    [manager setDebugToAllStorage:YES];
    [manager setDebugToAllSensors:YES];
    [manager setSyncProcessCallbackToAllSensorStorages:callback];
    [NSTimer scheduledTimerWithTimeInterval:10 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [manager syncAllSensorsForcefully];
    }];
    
    for (AWARESensor * sensor in [manager getAllSensors] ) {
        NSLog(@"[%@] %d", [sensor getSensorName], [sensor isSensing]);
    }
    
    [manager startAllSensors];
    
    NSLog(@"=====");
    
    for (AWARESensor * sensor in [manager getAllSensors] ) {
        NSLog(@"[%@] %d", [sensor getSensorName], [sensor isSensing]);
    }
    
//    NSArray * data = [accelerometer.storage fetchTodaysData];
//    for (EntityAccelerometer * acc in data) {
//        NSLog(@"%@",acc.double_values_0);
//    }
//
//    [accelerometer.storage fetchTodaysDataWithHandler:^(NSString *name, NSArray *results, NSDate * start, NSDate * end, NSError * error) {
//        NSLog(@"thread : %d", [NSThread isMainThread]);
////        for (EntityAccelerometer * acc in results) {
////            NSLog(@"%@",acc);
////        }
//    }];
    
}

- (void) testSQLite{
    
    AWAREStudy * study = [AWAREStudy sharedStudy];
    Accelerometer * accelerometer = [[Accelerometer alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
    [accelerometer.storage setBufferSize:500];
    for (int i =0; i<1000; i++) {
        NSNumber * timestamp = @([NSDate new].timeIntervalSince1970);
        [accelerometer.storage saveDataWithDictionary:@{@"timestamp":timestamp,@"device_id":study.getDeviceId} buffer:YES saveInMainThread:YES];
    }
}


- (void) testESMSchedule{
    
    ESMSchedule * schedule = [[ESMSchedule alloc] init];
    schedule.notificationTitle = @"title";
    schedule.notificationBody = @"body";
    schedule.scheduleId = @"id";
    schedule.expirationThreshold = @60;
    schedule.startDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-60*60*24*10];
    schedule.endDate = [[NSDate alloc] initWithTimeIntervalSinceNow:60*60*24*10];
    // schedule.interface = @1;
    for (int i=8; i<24; i++){
        [schedule addHour:@(i)];
    }
    
    /////////////////////////
    ESMItem * text = [[ESMItem alloc] initAsTextESMWithTrigger:@"text"];
    [text setTitle:@"Freetext"];
    [text setInstructions:@"Open-ended text input"];
    
    ESMItem * radio = [[ESMItem alloc] initAsRadioESMWithTrigger:@"radio"
                                                      radioItems:@[@"A",@"B",@"C",@"D",@"E"]];
    [radio setTitle:@"Radio"];
    [radio setInstructions:@"Single choice is allowed"];
    
    ESMItem * checkbox = [[ESMItem alloc] initAsCheckboxESMWithTrigger:@"checkbox"
                                                            checkboxes:@[@"A",@"B",@"C",@"E",@"Other"]];
    [checkbox setTitle:@"Checkbox"];
    [checkbox setInstructions:@"Multiple choice is allowed"];
    
    ESMItem * likertScale = [[ESMItem alloc] initAsLikertScaleESMWithTrigger:@"4_likert"
                                                                  likertMax:10
                                                             likertMinLabel:@"min"
                                                             likertMaxLabel:@"max"
                                                                 likertStep:1];
    [likertScale setTitle:@"Likert"];
    [likertScale setInstructions:@"Likert ESM"];
    
    
    ESMItem * quickAnswer = [[ESMItem alloc] initAsQuickAnawerESMWithTrigger:@"quick" quickAnswers:@[@"A",@"B",@"C"]];
    [quickAnswer setTitle:@"Quick Answers ESM"];
    
    
    ESMItem * scale = [[ESMItem alloc] initAsScaleESMWithTrigger:@"scalse"
                                                        scaleMin:0
                                                        scaleMax:100
                                                      scaleStart:50
                                                   scaleMinLabel:@"Poor"
                                                   scaleMaxLabel:@"Perfect"
                                                       scaleStep:10];
    [scale setTitle:@"Scale"];
    [scale setInstructions:@"Scale ESM"];
    
    ESMItem * datetime = [[ESMItem alloc] initAsDateTimeESMWithTrigger:@"datetime"];
    [datetime setTitle:@"Date Time"];
    [datetime setInstructions:@"Date and Time ESM"];

    ESMItem * pam = [[ESMItem alloc] initAsPAMESMWithTrigger:@"pam"];
    
    ESMItem * numeric = [[ESMItem alloc] initAsNumericESMWithTrigger:@"number"];
    [numeric setTitle:@"Numeric"];
    [numeric setInstructions:@"The user can enter a number"];

    ESMItem * web = [[ESMItem alloc] initAsWebESMWithTrigger:@"web" url:@"https://google.com"];
    [web setTitle:@"Web"];
    [web setInstructions:@"Web ESM"];
    
    ESMItem * date = [[ESMItem alloc] initAsDatePickerESMWithTrigger:@"date"];
    [date setTitle:@"Date"];
    [date setInstructions:@"Date ESM"];
    
    ESMItem * time = [[ESMItem alloc] initAsTimePickerESMWithTrigger:@"time"];
    [time setTitle:@"Time"];
    [time setInstructions:@"Time ESM"];

    ESMItem * clock = [[ESMItem alloc] initAsClockDatePickerESMWithTrigger:@"clock"];
    [clock setTitle:@"Clock"];
    [clock setInstructions:@"Clock ESM"];
    
    ESMItem * picture = [[ESMItem alloc] initAsPictureESMWithTrigger:@"picture"];
    [picture setTitle:@"Picture"];
    [picture setInstructions:@"Picture ESM"];
    
    ESMItem * audio = [[ESMItem alloc] initAsAudioESMWithTrigger:@"audio"];
    [audio setTitle:@"Audio"];
    [audio setInstructions:@"Audio ESM"];
    
    ESMItem * video = [[ESMItem alloc] initAsVideoESMWithTrigger:@"5_video"];
    
    [schedule addESMs:@[text,radio,checkbox,likertScale,quickAnswer, scale, datetime, pam, numeric, web, date, time, clock, picture, audio, video]];
    
    
    ESMScheduleManager * esmManager = [ESMScheduleManager sharedESMScheduleManager];
    esmManager.debug = YES;
    [esmManager addSchedule:schedule];
    
    if ([esmManager getValidSchedules].count > 0) {
        ESMScrollViewController * esmView  = [[ESMScrollViewController alloc] init];
        [self.navigationController pushViewController:esmView animated:YES];
    }
    
}



- (IBAction)pushedSyncButton:(id)sender {
//    [sensor.storage setDebug:YES];
//    [sensor.storage startSyncStorage];
}

@end
