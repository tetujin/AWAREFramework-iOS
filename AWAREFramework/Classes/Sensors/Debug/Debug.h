//
//  Debug.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWARESensor.h"
#import "AWAREKeys.h"


@interface Debug : AWARESensor <AWARESensorDelegate>

// - (instancetype) initWithAwareStudy:(AWAREStudy *) study;

- (void) saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *) label;

@end
