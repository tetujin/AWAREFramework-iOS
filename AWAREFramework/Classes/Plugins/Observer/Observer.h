//
//  Observer.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/6/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface Observer : AWARESensor <AWARESensorDelegate>

- (bool) sendSurvivalSignal;
- (bool) sendSurvivalSignalWithLabel:(NSString *)label;
- (bool) sendSurvivalSignalWithCategory:(NSString *)category message:(NSString *)message;

- (bool) sendComplianceState;

@end
