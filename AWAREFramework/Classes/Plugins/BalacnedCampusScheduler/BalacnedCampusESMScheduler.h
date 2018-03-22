//
//  Scheduler.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/17/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface BalacnedCampusESMScheduler : AWARESensor <AWARESensorDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSString * getConfigFileIdentifier;

- (void) setESMWithUserInfo:(NSDictionary*) userInfo;

@end
