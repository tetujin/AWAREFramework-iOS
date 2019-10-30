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

extern NSString * const AWARE_PREFERENCES_STATUS_CONVERSATION;

@interface Conversation : AWARESensor <AWARESensorDelegate>

@property (nonatomic, strong) AudioPipeline *pipeline;

/**
Plugin conversations delay: How long we wait until we start classification (in minutes)
 */
@property int conversationsDelay;

/**
Plugin conversations off duty: How long we wait until we sample again (in minutes)
*/
@property int conversationsOffDudy;

/**
Plugin conversations length: For how long we collect data for (in minutes, >= delay period)
*/
@property int conversationsLength;

@end
