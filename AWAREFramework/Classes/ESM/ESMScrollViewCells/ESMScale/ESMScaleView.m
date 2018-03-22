//
//  ESMScaleView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/12.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMScaleView.h"
#import <math.h>

@implementation ESMScaleView {
    UISlider *slider;
    UILabel *minLabel;
    UILabel *maxLabel;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm{
    self = [super initWithFrame:frame esm:esm];
    
    if(self != nil){
        [self addScaleElement:esm withFrame:frame];
    }
    
    return self;
}



/**
 * esm_type=6 : Add a Scale Element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_scale_min, esm_scale_max,
 esm_scale_start, esm_scale_max_label, esm_scale_min_label, esm_scale_step, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addScaleElement:(EntityESM *) esm withFrame:(CGRect) frame{
    int valueLabelH = 30;
    int mainContentH = 60;
    int spaceH = 10;

    // Add a value label
    // UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+60, totalHight, mainContentRect.size.width-120, valueLabelH)];
    _valueLabel = [[UITextField alloc] initWithFrame:CGRectMake(60,
                                                                0,
                                                                self.mainView.frame.size.width-120,
                                                               valueLabelH)];
    [_valueLabel setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
    [_valueLabel addTarget:self action:@selector(changeTextFieldValue:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [_valueLabel addTarget:self action:@selector(touchDownTextFiledValue:) forControlEvents:UIControlEventEditingDidBegin];
    // valueLabel.tag = tag;
    
    // Add  min/max/slider value
    minLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                         valueLabelH,
                                                         60,
                                                         mainContentH )];
    slider   = [[UISlider alloc] initWithFrame:CGRectMake(60,
                                                          valueLabelH,
                                                          self.mainView.frame.size.width - 120,
                                                          mainContentH)];
    maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.mainView.frame.size.width -60,
                                                         valueLabelH,
                                                         60,
                                                         mainContentH)];
    
    minLabel.adjustsFontSizeToFitWidth = YES;
    maxLabel.adjustsFontSizeToFitWidth = YES;
    
    minLabel.numberOfLines = 3;
    maxLabel.numberOfLines = 3;
    
    // [minLabel setBackgroundColor:[UIColor blueColor]];
    
    slider.maximumValue = esm.esm_scale_max.floatValue; // [max floatValue];
    slider.minimumValue = esm.esm_scale_min.floatValue; //[min floatValue];
    float value = esm.esm_scale_start.floatValue;
    slider.value = value;
    
    _valueLabel.text = @"---";
    minLabel.text = esm.esm_scale_min_label; // [dic objectForKey:KEY_ESM_SCALE_MIN_LABEL];
    maxLabel.text = esm.esm_scale_max_label; // [dic objectForKey:KEY_ESM_SCALE_MAX_LABEL];
    
    _valueLabel.textAlignment = NSTextAlignmentCenter;
    minLabel.textAlignment = NSTextAlignmentCenter;
    maxLabel.textAlignment = NSTextAlignmentCenter;
    
    [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];

    [self.mainView addSubview:_valueLabel];
    [self.mainView addSubview:maxLabel];
    [self.mainView addSubview:minLabel];
    [self.mainView addSubview:slider];
    
    int h = valueLabelH + mainContentH;
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     h);
    
    [self refreshSizeOfRootView];
}


- (IBAction)sliderChanged:(UISlider *)sender {
    // NSLog(@"slider value = %f", sender.value);
    double value = sender.value;
    // NSInteger tag = sender.tag;

    NSNumber * step = self.esmEntity.esm_scale_step;
    
    if([step isEqual:@0.1]){
        double tempValue = value*10;
        int intValue = tempValue/10;
        [sender setValue:intValue];
        [_valueLabel setText:[NSString stringWithFormat:@"%0.1f", value]];
    }else{
        if(![_valueLabel.text isEqualToString:[NSString stringWithFormat:@"%d",(int)value]]){
            AudioServicesPlaySystemSound(1105);
        }
        [sender setValue:(int)value];
        [_valueLabel setText:[NSString stringWithFormat:@"%d", (int)value]];
    }
    
}


- (IBAction) changeTextFieldValue:(UITextField *) textField {

}


- (IBAction) touchDownTextFiledValue:(UITextField *) textField{
    NSString * text = textField.text;
    if([text isEqualToString:@"---"] ||
       [text isEqualToString:@"--"] ||
       [text isEqualToString:@"-"]){
        textField.text = @"";
    }
}

- (NSDecimalNumber *)getScaleWithDecimalNumber:(NSDecimalNumber *)aNumber scale:(NSInteger)aScale {
    NSDecimalNumberHandler *roundingStyle = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                                   scale:aScale
                                                                                        raiseOnExactness:NO
                                                                                         raiseOnOverflow:NO
                                                                                        raiseOnUnderflow:NO
                                                                                     raiseOnDivideByZero:NO];
    return [aNumber decimalNumberByRoundingAccordingToBehavior:roundingStyle];
}


- (NSString *)getUserAnswer{
    if ([self isNA]) return @"NA";
    if ([_valueLabel.text isEqualToString:@"---"] ||
        [_valueLabel.text isEqualToString:@"--"]  ||
        [_valueLabel.text isEqualToString:@"-"] ) {
        return @"";
    }else{
        return _valueLabel.text;
    }
}

- (NSNumber *)getESMState{
    if ([self isNA]) return @2;
    
    if (![[self getUserAnswer] isEqualToString:@""]) {
        return @2;
    }else{
        return @1;
    }
}

@end
