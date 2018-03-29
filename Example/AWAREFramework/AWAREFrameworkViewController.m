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
    
    ESM * esm = [[ESM alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
    
    [manager addSensors:@[accelerometer,esm]];
    [manager createAllTables];
    [manager startAllSensors];
    
    [self setESMSchedule];
    
    ESMScheduleManager * esmManager = [[ESMScheduleManager alloc] init];
    [esmManager setNotificationSchedules];
}


- (void)viewDidAppear:(BOOL)animated{
    
    //    ESMScheduleManager * esmManager = [[ESMScheduleManager alloc] init];
    //    if ([esmManager getValidSchedules].count > 0) {
    //        ESMScrollViewController * esmView  = [[ESMScrollViewController alloc] init];
    //        [self.navigationController pushViewController:esmView animated:YES];
    //    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pushedESMCheckButton:(id)sender {
    ESMScheduleManager * esmManager = [[ESMScheduleManager alloc] init];
    if ([esmManager getValidSchedules].count > 0) {
        ESMScrollViewController * esmView  = [[ESMScrollViewController alloc] init];
        [self.navigationController pushViewController:esmView animated:YES];
    }
}



- (void) setESMSchedule{
    
    ESMSchedule * schedule = [[ESMSchedule alloc] init];
    schedule.notificationTitle = @"hello";
    schedule.noitificationBody = @"This is a test notification";
    schedule.fireHours = @[@8,@9,@10,@11,@16,@17,@18,@19,@20,@21,@22,@23,@24,@1];
    schedule.scheduleId = @"id_1";
    schedule.expirationThreshold = @60;
    schedule.startDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-60*60*24];
    schedule.endDate = [[NSDate alloc] initWithTimeIntervalSinceNow:60*60*24];
    schedule.interface = @0;
    
    /////////////////////////
    ESMItem * text = [[ESMItem alloc] initAsTextESMWithTrigger:@"text"];
     [text setTitle:@"hello world!"];
    
    ///////////////////////
    ESMItem * radio = [[ESMItem alloc] initAsRadioESMWithTrigger:@"radio"
                                                      radioItems:@[@"A",@"B",@"C",@"D",@"E"]];
    [schedule.esms addObject:radio];
    
    
    ///////////////////////
    ESMItem * checkbox = [[ESMItem alloc] initAsCheckboxESMWithTrigger:@"checkbox"
                                                            checkboxes:@[@"A",@"B",@"C",@"E",@"F"]];
    [schedule.esms addObject:checkbox];
    
    /////////////////////
    ESMItem * likertScale = [[ESMItem alloc] initAsLikertScaleESMWithTrigger:@"likert"
                                                                  likertMax:10
                                                             likertMinLabel:@"min"
                                                             likertMaxLabel:@"max"
                                                                 likertStep:1];
    [schedule.esms addObject:likertScale];
    
    
    ////////////////////////
    ESMItem * pam = [[ESMItem alloc] initAsPAMESMWithTrigger:@"pam"];
    [schedule.esms addObject:pam];
    
    
    ESMScheduleManager * esmManager = [[ESMScheduleManager alloc] init];
    [esmManager deleteAllSchedules];
    
    [esmManager addSchedule:schedule];
    
    // [esmManager setNotificationSchedules];
}



@end
