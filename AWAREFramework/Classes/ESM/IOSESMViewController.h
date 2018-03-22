//
//  WebESMViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/17/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface IOSESMViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;
@property(nonatomic, strong) UITapGestureRecognizer *singleTap;


@end
