//
//  Calendar.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/04/03.
//

#import "AWARESensor.h"
#import <EventKitUI/EventKitUI.h>

@interface Calendar : AWARESensor

@property int offsetStartDay;
@property int offsetStartMonth;
@property int offsetStartYear;

@property int offsetEndDay;
@property int offsetEndMonth;
@property int offsetEndYear;

@end
