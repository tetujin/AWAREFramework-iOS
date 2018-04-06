//
//  ESMPAMView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/14.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMPAMView.h"
#import "PamSchema.h"

@implementation ESMPAMView{
    NSMutableArray * buttons;
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
    
    if(self != nil){
        [self addPAMElement:esm withFrame:frame];
    }
    return self;
}


- (void) addPAMElement:(EntityESM *)esm withFrame:(CGRect)frame{
    
    buttons = [[NSMutableArray alloc] init];
    
    int totalHeight = 0;
    int column = 4;
    int row = 4;
    
    NSInteger cellWidth = self.mainView.frame.size.width / column;
    NSInteger cellHeight = cellWidth;
    
    int pamNum = 1;
    
    for (int rowNum=0; rowNum<row; rowNum++ ) {
        for (int columnNum=0; columnNum<column; columnNum++) {
            // 1. Get random number between 1 and 3
            int randomNum = arc4random() % 3 + 1;
            NSString * imageName = [NSString stringWithFormat:@"%d_%d",pamNum, randomNum];
            UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(cellWidth * columnNum,
                                                                           cellHeight * rowNum,
                                                                           cellWidth,
                                                                           cellHeight)];
            UIImage *image = [self getImageFromLibBundleWithImageName:imageName type:@"jpg"];
            [button setImage:image forState:UIControlStateNormal];
            button.tag = pamNum;
            button.titleLabel.text = [NSString stringWithFormat:@"%d", pamNum];
            [button addTarget:self
                       action:@selector(pushedPamImage:)
             forControlEvents:UIControlEventTouchUpInside];
            [buttons addObject:button];
            [self.mainView addSubview:button];
            pamNum++;
        }
        totalHeight += cellHeight;
    }
    
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     totalHeight);
    [self refreshSizeOfRootView];
}



- (void) pushedPamImage:(UIButton *) sender {
    NSString *  selected = sender.titleLabel.text;
    AudioServicesPlaySystemSound(1105);
    for (UIButton * uiButton in buttons) {
        uiButton.layer.borderWidth = 0;
        uiButton.selected = NO;
        if ([uiButton.titleLabel.text isEqualToString:selected]) {
            uiButton.layer.borderColor = [UIColor redColor].CGColor;
            uiButton.layer.borderWidth = 5.0;
            uiButton.selected = YES;
        }
    }
}


- (NSString *)getUserAnswer{
    if ([self isNA]) return @"NA";
    int pamNumber = 0;
    for (UIButton * uiButton in buttons) {
        if (uiButton.selected) {
            pamNumber = [uiButton.titleLabel.text intValue];
            break;
        }
    }
    //////////////////////////
    if(pamNumber >= 1 && pamNumber <= 16){ // answered
        NSString * emotionStr = [PamSchema getEmotionString:pamNumber];
        return emotionStr;
    } else {// errored
        return @"";
    }
}

- (NSNumber  *)getESMState{
    if ([self isNA]) return @2;
    if (![[self getUserAnswer] isEqualToString:@""]) {
        return @2;
    }else{
        return @1;
    }
}


@end
