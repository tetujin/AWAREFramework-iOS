//
//  ESMManager.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESMSchedule.h"

@interface ESMManager : NSObject

- (void) addESMSchedules:(ESMSchedule *) schdule;
- (void) startAllESMSchedules;
- (void) stopAllESMSchedules;

@end
