//
//  Screen.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

extern NSString * const AWARE_PREFERENCES_STATUS_SCREEN;

@interface Screen : AWARESensor <AWARESensorDelegate>

- (BOOL) startSensor;

@end
