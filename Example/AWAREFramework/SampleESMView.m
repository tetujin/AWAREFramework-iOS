//
//  SampleESMView.m
//  
//
//  Created by Yuuki Nishiyama on 2019/03/27.
//

#import "SampleESMView.h"

@implementation SampleESMView

- (instancetype)initWithFrame:(CGRect)frame
                          esm:(EntityESM *)esm
               viewController:(UIViewController *)viewController{
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
    _freeTextView.layer.borderWidth  = 1.0f;
    _freeTextView.layer.cornerRadius = 1.0f;
    _freeTextView.layer.borderColor  = [UIColor grayColor].CGColor;
    _freeTextView.delegate           = self;
    [_freeTextView setFont:[UIFont systemFontOfSize:16]];
    [self.mainView addSubview:_freeTextView];
    
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     _freeTextView.frame.size.height + 10);
    [self refreshSizeOfRootView];
}

//////////////////////////

- (NSNumber *) getESMState {
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

- (NSString *) getUserAnswer {
    if([self isNA]){
        return @"NA";
    }else{
        return _freeTextView.text;
    }
}


@end
