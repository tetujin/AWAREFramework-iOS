//
//  Steps.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/31/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <CoreMotion/CoreMotion.h>

@interface Pedometer : AWARESensor <AWARESensorDelegate>

@property (strong, nonatomic) CMPedometer* pedometer;

@end