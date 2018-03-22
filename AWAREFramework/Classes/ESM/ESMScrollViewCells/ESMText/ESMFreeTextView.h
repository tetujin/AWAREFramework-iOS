//
//  ESMFreeTextView.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/11.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "BaseESMView.h"

@interface ESMFreeTextView : BaseESMView <UITextViewDelegate,UIGestureRecognizerDelegate>

//@property(nonatomic, strong) UITapGestureRecognizer *singleTap;

@property (nonatomic) IBOutlet UITextView * freeTextView;

@end
