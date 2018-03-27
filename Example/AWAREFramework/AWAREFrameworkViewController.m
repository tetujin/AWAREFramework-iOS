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
#import <AWaREFramework/ESMSchedule.h>

@interface AWAREFrameworkViewController ()

@end

@implementation AWAREFrameworkViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
    AWAREStudy * study = delegate.sharedAWARECore.sharedAwareStudy;
    AWARESensorManager * manager = delegate.sharedAWARECore.sharedSensorManager;
    
    Accelerometer * accelerometer = [[Accelerometer alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
    [accelerometer setDebugState:YES];
    [accelerometer setSensingIntervalWithHz:10];
    [accelerometer setSavingInterval:30];
    
    IOSESM * esm = [[IOSESM alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
    
    [manager addSensors:@[esm,accelerometer]];
    
    [manager createAllTables];
    
    [manager startAllSensors];
    
//    Battery * battery = [[Battery alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
//    [battery setIntervalSecond:1];
//    [battery startSensor];
    
//    Locations * location = [[Locations alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
//    [location startSensor];
//    [location setDebugState:true];
    
//    Bluetooth * bluetooth = [[Bluetooth alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
//    [bluetooth startSensor];
//    [bluetooth setDebugState:true];
    
//    Accelerometer * accelerometer = [[Accelerometer alloc] initWithAwareStudy:study dbType:(AwareDBType)AwareDBTypeJSON];
//    [accelerometer startSensorWithInterval:0.1 bufferSize:100];
//    [accelerometer setDebugState:true];
    
//    [manager addSensors:@[accelerometer,location,bluetooth]];
//    [manager startAllSensors];
    
    //////////////////////////////////
    
//     AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
//    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
//    context.persistentStoreCoordinator =  delegate.persistentStoreCoordinator;
//
//    EntityESMSchedule * schedule = [[EntityESMSchedule alloc] initWithContext:context];
//    schedule.start_date = [NSDate new];
//    schedule.end_date = [[NSDate alloc] initWithTimeIntervalSinceNow:60*60*24];
//    schedule.fire_hour = @13;
//    schedule.notification_title = @"Hello";
//    schedule.noitification_body = @"this is a test noftification from AWARE iOS";
//    schedule.schedule_id = @"test_id";
//
//    EntityESM * textESM = [[EntityESM alloc] initWithContext:context];
//    [textESM setAsTextESMWithTrigger:@"OK"
//                                json:@""
//                               title:@""
//                        instructions:@""
//                                isNa:@YES
//                        submitButton:@""
//                 expirationThreshold:@5];
//    [schedule addEsmsObject:textESM];
//
//    NSError * error = nil;
//    bool success = [context save:&error];
//    if (success){
//        NSLog(@"==== success! ====");
//    }

}

- (void)viewDidAppear:(BOOL)animated{
    
//    IOSESMScrollViewController * esmView  = [[IOSESMScrollViewController alloc] init];
////    [self presentViewController:esmView animated:YES completion:^{
////
////    }];
//    [self.navigationController pushViewController:esmView animated:YES];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
