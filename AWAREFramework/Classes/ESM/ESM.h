//
//  ESM.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/22.
//

#import <UIKit/UIKit.h>
#import "AWARESensor.h"
#import "EntityESMSchedule.h"

@interface ESM : AWARESensor

- (BOOL) setESMSchedule:(EntityESMSchedule* )esmSchedule;

@end
