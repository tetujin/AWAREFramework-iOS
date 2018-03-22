//
//  ESMClockLineView.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/14.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ESMClockLineView : UIView

- (instancetype)initWithFrame:(CGRect)frame point1:(CGPoint)point1 point2:(CGPoint)point2;
- (void) setLineFrom:(CGPoint)point1 to:(CGPoint)point2;

@end
