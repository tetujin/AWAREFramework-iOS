//
//  StudentLife.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/21/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <UIKit/UIKit.h>
#import <StudentLifeAudio/StudentLifeAudio.h>

@interface Conversation : AWARESensor <AWARESensorDelegate>

@property (nonatomic, strong) AudioPipeline *pipeline;

@end
