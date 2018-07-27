//
//  ESMDateTimePickerView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/13.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMDateTimePickerView.h"
#import "AWAREUtils.h"

@implementation ESMDateTimePickerView{
    UIDatePicker * dateTimePicker;
    NSString * userAnswer;
    int version;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm viewController:(UIViewController *)viewController{
    self = [super initWithFrame:frame esm:esm viewController:viewController];
    
    if(self != nil){
        [self addTimePickerElement:esm withFrame:frame uiMode:UIDatePickerModeDateAndTime version:1];
        [self changedDatePickerValue:dateTimePicker];
    }
    return self;
}

//    dateTimePicker.datePickerMode = UIDatePickerModeDateAndTime;
//    dateTimePicker.datePickerMode = UIDatePickerModeDate;
//    dateTimePicker.datePickerMode = UIDatePickerModeTime;
- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm uiMode:(UIDatePickerMode)mode version:(int)version viewController:(UIViewController *)viewController{
    self = [super initWithFrame:frame esm:esm viewController:viewController];
    userAnswer = @"";
    if(self != nil){
        // version = v;
        [self addTimePickerElement:esm withFrame:frame uiMode:mode version:version];
    }
    return self;
}


/**
esm_type=7 : Add a Date and Time Picker

 */
- (void) addTimePickerElement:(EntityESM *)esm withFrame:(CGRect) frame uiMode:(UIDatePickerMode) mode version:(int)ver{
    version = ver;
    dateTimePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(40,
                                                                    0,
                                                                    self.mainView.frame.size.width-80,
                                                                    150)];
    dateTimePicker.datePickerMode = mode;
    [dateTimePicker addTarget:self action:@selector(changedDatePickerValue:) forControlEvents:UIControlEventValueChanged];

    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    // [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSString * startDateStr = esm.esm_start_date;
    if(startDateStr != nil){
        NSDate *date = [formatter dateFromString:startDateStr];
        // NSLog(@"date: %@",date);
        dateTimePicker.date = date;
    }

    [formatter setDateFormat:@"HH:mm:ss"];
    NSString * startTimeStr = esm.esm_start_time;
    if (startTimeStr != nil) {
        NSDate *time = [formatter dateFromString:startTimeStr];
        if(startDateStr != nil){
            // incule start date
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
            NSDate *datetime = [formatter dateFromString:[NSString stringWithFormat:@"%@ %@",startDateStr,startTimeStr]];
            dateTimePicker.date = datetime;
        }else{
            dateTimePicker.date = time;
        }
    }
    
    // NSString * timeFormat = esm.esm_time_format;
    
    // Set a step of minute
    NSNumber * minStep = esm.esm_minute_step;
    if (minStep !=nil && minStep > 0) {
        dateTimePicker.minuteInterval = minStep.intValue;
    }
    
    int datePickerHeight = dateTimePicker.frame.size.height;
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     datePickerHeight);
    [self.mainView addSubview:dateTimePicker];
    [self refreshSizeOfRootView];
}


- (void) changedDatePickerValue:(UIDatePicker * ) sender {
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    NSDate * date = dateTimePicker.date;
    
    if(version == 0){
        userAnswer = [AWAREUtils getUnixTimestamp:sender.date].stringValue;
    }else if(version == 1){
        if (dateTimePicker.datePickerMode == UIDatePickerModeDateAndTime) {
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
            userAnswer = [formatter stringFromDate:date];
            //userAnswer = [dateTimePicker date].debugDescription;
        } else if (dateTimePicker.datePickerMode == UIDatePickerModeDate){
            [formatter setDateFormat:@"yyyy-MM-dd Z"];
            userAnswer = [formatter stringFromDate:date];
            //userAnswer = [dateTimePicker date].debugDescription;
        } else if (dateTimePicker.datePickerMode == UIDatePickerModeTime){
            [formatter setDateFormat:@"HH:mm:ss Z"];
            userAnswer = [formatter stringFromDate:date];
            //userAnswer = [dateTimePicker date].debugDescription;
        } else{
            // [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
            userAnswer = [AWAREUtils getUnixTimestamp:sender.date].stringValue;
        }
    }else{
        userAnswer = [AWAREUtils getUnixTimestamp:sender.date].stringValue;
    }
     // NSLog(@"%@",userAnswer);
}


- (NSString *) getUserAnswer {
    if ([self isNA]) return @"NA";
    return userAnswer;
}

- (NSNumber  *)getESMState{
    if ([userAnswer isEqualToString:@""]) return @1;
    return @2;
}

@end
