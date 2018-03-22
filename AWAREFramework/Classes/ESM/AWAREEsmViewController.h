//
//  AWAREEsmViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/15/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AWAREEsmViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UIAlertViewDelegate>


@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;
@property(nonatomic, strong) UITapGestureRecognizer *singleTap;

@end
