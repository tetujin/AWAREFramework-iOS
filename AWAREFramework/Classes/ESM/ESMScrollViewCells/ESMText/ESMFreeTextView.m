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


- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm{
    self = [super initWithFrame:frame esm:esm];
    
    if(self != nil){
        [self addFreeTextElement:esm withFrame:frame];
    }
    return self;
}



/**
 * esm_type=1 : Add a Free Text element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
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
