//
//  ESMClockLineView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/14.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMClockLineView.h"

@implementation ESMClockLineView{
    CGPoint firstPoint;
    CGPoint secondPoint;
}


- (instancetype)initWithFrame:(CGRect)frame point1:(CGPoint)point1 point2:(CGPoint)point2{
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor clearColor];
        firstPoint = point1;
        secondPoint = point2;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [self drawPoints];
}

- (void) drawPoints{
    [[UIColor colorWithRed:52.f/255.f green:181.f/255.f blue:230.f/255.f alpha:1.0] setStroke];
    // [[UIColor blueColor] setStroke];
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth     = 2.0f;
    [path moveToPoint:firstPoint];
    [path addLineToPoint:secondPoint];
    [path stroke];
}

- (void)setLineFrom:(CGPoint)point1 to:(CGPoint)point2{
    firstPoint = point1;
    secondPoint = point2;
    [self setNeedsDisplay];
}

@end
