//
//  ESMNumberView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/15.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMNumberView.h"

@implementation ESMNumberView

- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm viewController:(UIViewController *)viewController{
    self = [super initWithFrame:frame esm:esm viewController:viewController];

    if(self != nil){
        [self addFreeTextElement:esm withFrame:frame];
    }
    return self;
}



/**
 Add Free Text Element to an ESM Number View

 @param esm An EntityESM
 @param frame A location of this view
 */
- (void) addFreeTextElement:(EntityESM *)esm withFrame:(CGRect)frame {
    
    _freeTextView = [[UITextView alloc] initWithFrame:CGRectMake(10,
                                                                 10,
                                                                 self.mainView.frame.size.width - 20,
                                                                 43 )];
    _freeTextView.layer.borderWidth = 2.0f;
    _freeTextView.layer.cornerRadius = 3.0f;
    _freeTextView.layer.borderColor = [UIColor grayColor].CGColor;
    _freeTextView.selectable = YES;
    _freeTextView.keyboardType = UIKeyboardTypeDecimalPad; //UIKeyboardTypeNumberPad;
    _freeTextView.textAlignment = NSTextAlignmentCenter;
     _freeTextView.delegate = self;
    [_freeTextView setFont:[UIFont systemFontOfSize:23]];
    [self.mainView addSubview:_freeTextView];
    
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     _freeTextView.frame.size.height + 10 + 30);
    [self refreshSizeOfRootView];
}


////////////////
- (void)textViewDidChange:(UITextView *)textView{
    [_freeTextView.font fontWithSize:25];
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
