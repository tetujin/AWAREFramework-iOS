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
    
    [study setWebserviceServer:@"Server URL"];
    
    Locations * location = [[Locations alloc] initWithAwareStudy:study dbType:AwareDBTypeCoreData];
    [location startSensor];
    
    Bluetooth * bluetooth = [[Bluetooth alloc] initWithAwareStudy:study dbType:AwareDBTypeCoreData];
    [bluetooth startSensor];
    
    Accelerometer * accelerometer = [[Accelerometer alloc] initWithAwareStudy:study dbType:(AwareDBType)AwareDBTypeCoreData];
    [accelerometer startSensorWithInterval:0.1 bufferSize:100];
    
    [manager addNewSensor:location];
    [manager addNewSensor:bluetooth];
    [manager addNewSensor:accelerometer];
    
    // [manager createAllTables];
    
    // [manager syncAllSensorsWithDBInForeground];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
