//
//  ESM.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/22.
//

#import <UIKit/UIKit.h>
#import "AWARESensor.h"

@interface ESM:AWARESensor <AWARESensorDelegate>

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType;
@end
