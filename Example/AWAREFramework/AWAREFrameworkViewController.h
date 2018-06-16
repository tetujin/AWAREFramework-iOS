//
//  AWAREFrameworkViewController.h
//  AWAREFramework
//
//  Created by tetujin on 03/22/2018.
//  Copyright (c) 2018 tetujin. All rights reserved.
//

@import UIKit;
@import AWAREFramework;

@interface AWAREFrameworkViewController : UIViewController

- (IBAction)pushedSyncButton:(id)sender;

@property (strong, nonatomic) Bluetooth * ble;

@end
