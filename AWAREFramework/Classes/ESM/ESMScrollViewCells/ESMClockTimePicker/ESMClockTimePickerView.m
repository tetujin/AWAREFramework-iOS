//
//  ESMClockTimePickerView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/14.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMClockTimePickerView.h"
#import "ESMClockLineView.h"

@implementation ESMClockTimePickerView{
    UIView * headerView;
    // UIView * timeView;
    UIButton * hourBtn;
    UIButton * minBtn;
    UIView *baseClockView;
    NSMutableArray * buttons;
    UIButton * amBtn;
    UIButton * pmBtn;
    bool amState;
    ESMClockLineView * lineView;
    
    UIColor * clockBackgroundColor;
    UIColor * clockCyanColor;
    UIColor * clockUnselectedObjColor;
    
    NSArray * amHours;
    NSArray * pmHours;
    NSArray * mins;
    
    int tx;
    int ty;

    int mode;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm viewController:(UIViewController *)viewController{
    self = [super initWithFrame:frame esm:esm viewController:viewController];
    
    amHours = @[@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"11",@"12",@"1",@"2",@"3"];
    pmHours = @[@"15",@"16",@"17",@"18",@"19",@"20",@"21",@"22",@"23",@"0",@"13",@"14",@"15"];
    mins = @[@"15",@"20",@"25",@"30",@"35",@"40",@"45",@"50",@"55",@"0",@"5",@"10",@"15"];
    self.userInteractionEnabled = true;
    
    [self isAM];
    if(self != nil){
        tx = 0;
        ty = 0;
        [self addClockTimePickerElement:esm withFrame:frame];
    }
    return self;
}

- (void) addClockTimePickerElement:(EntityESM *)esm withFrame:(CGRect) frame {
    int clockWidth = self.mainView.frame.size.width - 100; // 40 is a buffer (right:20 + left:20)
    int blankSpace = 10;
    
    clockBackgroundColor = [UIColor colorWithRed:238.f/255.f green:238.f/255.f blue:238.f/255.f alpha:1.0];
    clockCyanColor = [UIColor colorWithRed:52.f/255.f green:181.f/255.f blue:230.f/255.f alpha:1.0];
    clockUnselectedObjColor = [UIColor colorWithRed:190.f/255.f green:232.f/255.f blue:246.f/255.f alpha:1.0];
    
    //////// header view ///////////
    headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 80)];
    headerView.backgroundColor = clockCyanColor;
    [self.mainView addSubview:headerView];

    ////////////////////
    UIButton * colonLabel = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 15, headerView.frame.size.height/4 * 3)];
    colonLabel.center = CGPointMake(headerView.frame.size.width/2, headerView.frame.size.height/2-5);
    [colonLabel setTitle:@":" forState:UIControlStateNormal];
    [colonLabel setTitleColor:clockUnselectedObjColor forState:UIControlStateNormal];
    colonLabel.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:50];
    [headerView addSubview:colonLabel];
    
    //////////////////
    mode = 0;
    hourBtn = [[UIButton alloc] initWithFrame:CGRectMake(colonLabel.frame.origin.x - headerView.frame.size.width/2/2,
                                                         colonLabel.frame.origin.y + 5,
                                                         headerView.frame.size.width/2/2,
                                                         headerView.frame.size.height/4 * 3)];
    [hourBtn setTitle:@"12" forState:UIControlStateNormal];
    hourBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:50];
    hourBtn.titleLabel.textAlignment = NSTextAlignmentRight;
    hourBtn.tag = 0;
    [hourBtn addTarget:self action:@selector(pushedHourMinButton:) forControlEvents:UIControlEventTouchDown];
    [headerView addSubview:hourBtn];
    
    //////////////////
    minBtn  = [[UIButton alloc] initWithFrame:CGRectMake(colonLabel.frame.origin.x+colonLabel.frame.size.width,
                                                         colonLabel.frame.origin.y + 5,
                                                         headerView.frame.size.width/2/2,
                                                         headerView.frame.size.height/4 * 3)];
    [minBtn setTitle:@"00" forState:UIControlStateNormal];
    [minBtn setTitleColor:clockUnselectedObjColor forState:UIControlStateNormal];
    minBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:50];
    minBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
    minBtn.tag = 1;
    [minBtn addTarget:self action:@selector(pushedHourMinButton:) forControlEvents:UIControlEventTouchDown];
    [headerView addSubview:minBtn];
    
    ///////////////////////////////////
    // [headerView addSubview:timeView];
    
    ///// AM button
    amBtn = [[UIButton alloc] initWithFrame:CGRectMake(minBtn.frame.origin.x + minBtn.frame.size.width,
                                                      minBtn.frame.origin.y,
                                                      40,
                                                      minBtn.frame.size.height/2)];
    [amBtn setTitle:@"AM" forState:UIControlStateNormal];
    amBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
    [amBtn addTarget:self action:@selector(selectedAMPMbutton:) forControlEvents:UIControlEventTouchDown];
    [headerView addSubview:amBtn];
    
    ///// PM button
    pmBtn = [[UIButton alloc] initWithFrame:CGRectMake(minBtn.frame.origin.x + minBtn.frame.size.width,
                                                      minBtn.frame.origin.y + minBtn.frame.size.height - minBtn.frame.size.height/2,
                                                      40,
                                                      minBtn.frame.size.height/2)];
    [pmBtn setTitle:@"PM" forState:UIControlStateNormal];
    pmBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
    [pmBtn addTarget:self action:@selector(selectedAMPMbutton:) forControlEvents:UIControlEventTouchDown];
    [headerView addSubview:pmBtn];
    
    if([self isAM]){
        [amBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [pmBtn setTitleColor:clockUnselectedObjColor forState:UIControlStateNormal];
        amState = YES;
    }else{
        [amBtn setTitleColor:clockUnselectedObjColor forState:UIControlStateNormal];
        [pmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        amState = NO;
    }
    
    //////// clock view ///////////
    baseClockView = [[UIView alloc] initWithFrame:CGRectMake(50,
                                                             headerView.frame.size.height + blankSpace,
                                                             clockWidth,
                                                             clockWidth)];
    baseClockView.layer.cornerRadius = clockWidth / 2.0;
    baseClockView.clipsToBounds = YES;
    baseClockView.backgroundColor = clockBackgroundColor;
    
    lineView = [[ESMClockLineView alloc] initWithFrame:CGRectMake(0, 0,
                                                                 clockWidth,
                                                                 clockWidth)
                                                point1:CGPointMake(clockWidth/2, clockWidth/2)
                                                point2:CGPointMake(clockWidth/2, 10)];
    [baseClockView addSubview:lineView];
    //The setup code (in viewDidLoad in your view controller)
    UIPanGestureRecognizer *singleFingerTap =
    [[UIPanGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(dragging:)];
    [lineView addGestureRecognizer:singleFingerTap];
    
    ////////// adding a small center circle
    UIView * centerCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    centerCircle.backgroundColor = clockCyanColor;
    centerCircle.layer.cornerRadius = 10 / 2.0;
    centerCircle.center = CGPointMake(baseClockView.frame.size.width/2,
                                      baseClockView.frame.size.height/2);
    [baseClockView addSubview:centerCircle];
    
    //////// 12 angles ///////////
    int n;
    float x,y,k;
    float radius;
    n=12;
    radius = baseClockView.frame.size.width/2 - 30;
    int pointNumber = 3;
    buttons = [[NSMutableArray alloc] init];
    for(k=0;k<2*M_PI;k+=2*M_PI/n){
        x = radius * cos(k) + (baseClockView.frame.size.width/2);
        y = radius * sin(k) + (baseClockView.frame.size.width/2);
        // NSLog(@"[%d] k=%6.2f, x=%4.2f, y=%4.2f\n", pointNumber,k/M_PI*180,x,y);
        UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(x, y, 40, 40)];
        button.center = CGPointMake(x, y);
        [button setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
        [button setTitle:[[NSString alloc] initWithFormat:@"%d",pointNumber]  forState:UIControlStateNormal];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
        [baseClockView addSubview:button];
        ////////// set an event to each button
        // [button addTarget:self action:@selector(selectedNumber:) forControlEvents:UIControlEventTouchDown];
        UIPanGestureRecognizer *panGestureTap =
        [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(numDragging:)];
        [button addGestureRecognizer:panGestureTap];
        ////////// set a tag to each button
        button.tag = pointNumber;
        //////////
        button.layer.cornerRadius = button.frame.size.width / 2.0;
        button.clipsToBounds = YES;
        /////////
        pointNumber++;
        if(n<pointNumber){
            pointNumber = 1;
            button.backgroundColor = clockCyanColor;
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        [buttons addObject:button];
    }
    
    [self.mainView addSubview:baseClockView];
    
    ///////////////
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     headerView.frame.size.height + blankSpace + baseClockView.frame.size.height);
    [self refreshSizeOfRootView];
}

- (void) numDragging:(UIPanGestureRecognizer *)gesture {
    CGPoint newCoord = [gesture locationInView:gesture.view.superview];
    [self draggingLineTo:newCoord gesture:gesture];
}

- (void) dragging:(UIPanGestureRecognizer *)gesture {
    CGPoint newCoord = [gesture locationInView:gesture.view];
    [self draggingLineTo:newCoord gesture:gesture];
}

- (void) draggingLineTo:(CGPoint)point gesture:(UIPanGestureRecognizer *)gesture{
    bool isNoSelectedBtn = YES;
    NSInteger previousSelectedBtn = 0;
    for (UIButton * button in buttons) {
        if ([button.backgroundColor isEqual:clockCyanColor]) {
            previousSelectedBtn = button.tag;
        }
    }
    
    for (UIButton * button in buttons) {
        if(CGRectContainsPoint(button.frame, point)){
            [lineView setLineFrom:CGPointMake(lineView.frame.size.width/2,lineView.frame.size.height/2)
                               to:button.center];
            if (![button.backgroundColor isEqual:clockCyanColor]) {
                AudioServicesPlaySystemSound(1104);
            }
            button.backgroundColor = clockCyanColor;
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            
            
            if (mode == 0) {
                if (button.tag < 10) {
                    [hourBtn setTitle:[NSString stringWithFormat:@"0%ld",button.tag] forState:UIControlStateNormal];
                }else{
                    [hourBtn setTitle:[NSString stringWithFormat:@"%ld",button.tag] forState:UIControlStateNormal];
                }
            } else if ( mode == 1){
                if (button.tag < 10){
                    [minBtn  setTitle:[NSString stringWithFormat:@"0%ld",button.tag] forState:UIControlStateNormal];
                }else{
                    [minBtn  setTitle:[NSString stringWithFormat:@"%ld",button.tag] forState:UIControlStateNormal];
                }
            }
            isNoSelectedBtn = NO;
        }else{
            button.backgroundColor = [UIColor clearColor];
            [button setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
        }
    }
    
    ///////////////////////////
    if(isNoSelectedBtn){
        for (UIButton *button in buttons) {
            if (button.tag == previousSelectedBtn) {
                button.backgroundColor = clockCyanColor;
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            }
        }
    }
    
    ///////////////////////////
    //check its state
    if(gesture.state==UIGestureRecognizerStateBegan){
    }else if(gesture.state==UIGestureRecognizerStateEnded){
        if(mode == 0){
            [self pushedHourMinButton:minBtn];
            [self moveSelectorToOriginalPosition];
        }
    }
}


- (void) selectedAMPMbutton:(UIButton *)button{
    AudioServicesPlaySystemSound(1104);
    if([button.titleLabel.text isEqualToString:@"AM"]){
        [amBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [pmBtn setTitleColor:clockUnselectedObjColor forState:UIControlStateNormal];
        amState = YES;
    }else{
        [amBtn setTitleColor:clockUnselectedObjColor forState:UIControlStateNormal];
        [pmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        amState = NO;
    }
}


- (void) pushedHourMinButton:(UIButton *) button {
    AudioServicesPlaySystemSound(1104);
    mode = (int)button.tag; // 0=hour, 1=min
    
    if(button.tag == 0){
        [hourBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [minBtn  setTitleColor:clockUnselectedObjColor forState:UIControlStateNormal];
        for (int i=0; i<amHours.count; i++) {
            NSString * label = [amHours objectAtIndex:i];
            UIButton * btn = [buttons objectAtIndex:i];
            [btn setTitle:label forState:UIControlStateNormal];
            btn.tag = label.intValue;
        }
        [self moveSelectorToOriginalPosition];
    }else if(button.tag == 1){
        [hourBtn setTitleColor:clockUnselectedObjColor forState:UIControlStateNormal];
        [minBtn  setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        for (int i=0; i<mins.count; i++) {
            NSString * label = [mins objectAtIndex:i];
            UIButton * btn = [buttons objectAtIndex:i];
            [btn setTitle:label forState:UIControlStateNormal];
            btn.tag = label.intValue;
        }
    }else{
        
    }

}


- (void) moveSelectorToOriginalPosition {
    /////////// move the selector to 12 or 00 number //////////////////
    UIButton * topBtn = [buttons objectAtIndex:9];
    for (UIButton * btn in buttons) {
        if(btn.tag != topBtn.tag){
            btn.backgroundColor = [UIColor clearColor];
            [btn setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
        }
    }
    [lineView setLineFrom:CGPointMake(lineView.frame.size.width/2,lineView.frame.size.height/2)
                       to:topBtn.center];
    topBtn.backgroundColor = clockCyanColor;
    [topBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    /////////////////////////////
}

- (bool) is24h {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSRange amRange = [dateString rangeOfString:[formatter AMSymbol]];
    NSRange pmRange = [dateString rangeOfString:[formatter PMSymbol]];
    BOOL is24h = (amRange.location == NSNotFound && pmRange.location == NSNotFound);
    //NSLog(@"%@\n",(is24h ? @"YES" : @"NO"));
    return is24h;
}


- (BOOL) isAM {
    NSDate *nowdate = [NSDate new]; //[[NSDate alloc] initWithTimeIntervalSinceNow:60*60*4];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH"];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"US"]];
    NSString *dateString = [formatter stringFromDate:nowdate];
    if (self.isDebug) {
        NSLog(@"%@",dateString);
    }
    if( dateString.intValue >= 12 ){ // pm
        return NO;
    }else{
        return YES;
    }
}

- (BOOL) isPM {
    return ![self isAM];
}

- (NSNumber *)getESMState{
    return @2;
}

- (NSString *)getUserAnswer{
    NSString * hour = hourBtn.titleLabel.text;
    NSString * min  = minBtn.titleLabel.text;
    if (amState) {
        return [NSString stringWithFormat:@"%@:%@(%@)",hour,min,@"AM"];
    }else{
        return [NSString stringWithFormat:@"%@:%@(%@)",hour,min,@"PM"];
    }
}

@end
