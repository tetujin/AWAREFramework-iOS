//
//  ESMFreeTextView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/11.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMFreeTextView.h"

@implementation ESMFreeTextView {
    
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
        [self addFreeTextElement:esm withFrame:frame];
    }
    return self;
}



- (void) addFreeTextElement:(EntityESM *)esm withFrame:(CGRect)frame {
    
    _freeTextView = [[UITextView alloc] initWithFrame:CGRectMake(10,
                                                                         10,
                                                                         self.mainView.frame.size.width - 20,
                                                                         self.mainView.frame.size.height )];
    _freeTextView.layer.borderWidth = 2.0f;
    _freeTextView.layer.cornerRadius = 3.0f;
    _freeTextView.layer.borderColor = [UIColor grayColor].CGColor;
    _freeTextView.selectable = YES;
    _freeTextView.textAlignment = NSTextAlignmentCenter;
    _freeTextView.delegate = self;
    [_freeTextView setFont:[UIFont systemFontOfSize:18]];
    [self.mainView addSubview:_freeTextView];
    
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     _freeTextView.frame.size.height + 10);
    [self refreshSizeOfRootView];
}

- (void)textViewDidChange:(UITextView *)textView{
    // AWARE_ESM_SELECTION_CHANGE_EVENT
    if(textView.text!=nil){
        [NSNotificationCenter.defaultCenter postNotificationName:AWARE_ESM_SELECTION_UPDATE_EVENT
                                                          object:self
                                                        userInfo:@{AWARE_ESM_SELECTION_UPDATE_EVENT_DATA:textView.text}];
    }
}


//////////////////////////

- (NSNumber *)getESMState{
    if([_freeTextView.text isEqualToString:@""]){
        if ([self isNA]) {
            return @2;
        }else{
            return @1;
        }
    }else{
        return @2;
    }
}

- (NSString *)getUserAnswer{
    if([self isNA]){
        return @"NA";
    }else{
        return _freeTextView.text;
    }
}


@end
