//
//  ESMNumberView.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/15.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "BaseESMView.h"

@interface ESMNumberView : BaseESMView <UITextInputDelegate,UITextViewDelegate>

@property (nonatomic) IBOutlet UITextView * freeTextView;
@property (nonatomic) IBOutlet UIPickerView * pickerView;

@end
