//
//  IOSESMTableViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/07/30.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseESMView.h"

@interface IOSESMScrollViewController:UIViewController <UIImagePickerControllerDelegate, UIScrollViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;
@property(nonatomic, strong) UITapGestureRecognizer *singleTap;
@property NSMutableArray * esms;



@end
