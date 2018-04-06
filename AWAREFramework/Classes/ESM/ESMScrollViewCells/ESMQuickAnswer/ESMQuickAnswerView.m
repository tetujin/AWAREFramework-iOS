//
//  ESMQuickAnswer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/12.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMQuickAnswerView.h"

@implementation ESMQuickAnswerView{
    NSMutableArray * buttons;
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
        [self addQuickAnswerElement:esm withFrame:frame];
    }
    
    return self;
}


- (void) addQuickAnswerElement:(EntityESM *) esm withFrame:(CGRect) frame {
    buttons = [[NSMutableArray alloc] init];
    
    NSArray * options = [self convertJsonStringToArray:esm.esm_quick_answers];
    int totalHeigth = 0;
    int buttonHeight = 60;
    int verticalSpace = 5;
    
    if(options.count == 2){
        /////// button 1
        NSString * answer1 = [options objectAtIndex:0];
        UIButton *button1 = [[UIButton alloc] initWithFrame:CGRectMake(10, totalHeigth, frame.size.width/2 - 15, buttonHeight)];
        [button1 setTitle:answer1 forState:UIControlStateNormal];
        [button1 setBackgroundColor:[UIColor darkGrayColor]];
        [button1.titleLabel setFont:[UIFont systemFontOfSize:20]];
        [button1 addTarget:self action:@selector(pushedQuickAnswerButtons:) forControlEvents:UIControlEventTouchUpInside];
        button1.tag = 0;
        [buttons addObject:button1];
        [self.mainView addSubview:button1];
        
        ///// button 2
        NSString * answer2 = [options objectAtIndex:1];
        UIButton *button2 = [[UIButton alloc] initWithFrame:CGRectMake(5 + frame.size.width/2, totalHeigth, frame.size.width/2 - 15, buttonHeight)];
        [button2 setTitle:answer2 forState:UIControlStateNormal];
        [button2 setBackgroundColor:[UIColor darkGrayColor]];
        [button2.titleLabel setFont:[UIFont systemFontOfSize:20]];
        [button2 addTarget:self action:@selector(pushedQuickAnswerButtons:) forControlEvents:UIControlEventTouchUpInside];
        button2.tag = 1;
        [buttons addObject:button2];
        [self.mainView addSubview:button2];
        
        totalHeigth += buttonHeight + verticalSpace;
        
    }else{
        for (int i=0; i<options.count; i++) {
            NSString * answer = [options objectAtIndex:i];
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(10, totalHeigth, frame.size.width-20, buttonHeight)];
            [button setTitle:answer forState:UIControlStateNormal];
            [button setBackgroundColor:[UIColor darkGrayColor]];
            [button addTarget:self action:@selector(pushedQuickAnswerButtons:) forControlEvents:UIControlEventTouchUpInside];
            button.tag = i;
            [self.mainView addSubview:button];
            totalHeigth += buttonHeight + verticalSpace;
            [buttons addObject:button];
        }
    }
    
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     totalHeigth);
    
    [self refreshSizeOfRootView];
    
}


- (void) pushedQuickAnswerButtons:(UIButton *) button  {
    // int tag = (int)button.tag;
    AudioServicesPlaySystemSound(1105);
    for (UIButton * b in buttons) {
        b.selected = NO;
        b.layer.borderWidth = 0;
        if ([button.titleLabel isEqual:b.titleLabel]) {
            b.selected = YES;
            b.layer.borderColor = [UIColor redColor].CGColor;
            b.layer.borderWidth = 5.0;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_PUSHED_QUICK_ANSWER_BUTTON object:button];
    });
}

- (NSString *)getUserAnswer{
    if([self isNA]) return @"NA";
    NSString * seletedLabel = @"";
    for (UIButton * b in buttons) {
        if(b.selected){
            seletedLabel = b.titleLabel.text;
        }
    }
    return seletedLabel;
}

- (NSNumber  *)getESMState{
    if([self isNA]) return @2;
    if (![[self getUserAnswer] isEqualToString:@""]) {
        return @2;
    }else{
        return @1;
    }
}

@end
