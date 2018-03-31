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

@interface AWAREFrameworkViewController ()

@end

@implementation AWAREFrameworkViewController{
    SQLiteStorage * storage;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
    AWAREStudy * study = delegate.sharedAWARECore.sharedAwareStudy;
    // AWARESensorManager * manager = delegate.sharedAWARECore.sharedSensorManager;
    [study setMaximumNumberOfRecordsForDBSync:100];
    
    [study setWebserviceServer:@"https://api.awareframework.com/index.php/webservice/index/1550/idXL2PZTlDNN"];
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


- (void) testSQLite{
    
    AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
    AWAREStudy * study = delegate.sharedAWARECore.sharedAwareStudy;
    [storage setBufferSize:500];
    for (int i =0; i<1000; i++) {
        NSNumber * timestamp = @([NSDate new].timeIntervalSince1970);
        [storage saveDataWithDictionary:@{@"timestamp":timestamp,@"device_id":study.getDeviceId} buffer:YES saveInMainThread:YES];
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
    
    [esmManager setNotificationSchedules];
}



@end
