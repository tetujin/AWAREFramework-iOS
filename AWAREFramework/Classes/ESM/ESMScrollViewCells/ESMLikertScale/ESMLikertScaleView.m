//
//  LikertScaleESMView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/03.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMLikertScaleView.h"

@implementation ESMLikertScaleView{
    NSMutableArray * options;
    int selectedOption;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm{
    self = [super initWithFrame:frame esm:esm];
    
    if(self != nil){
        [self addLikertScaleElement:esm withFrame:frame];
    }
    
    return self;
}


/**
 * esm_type=4 : Add a Likert Scale Element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_likert_max, esm_likert_max_label, esm_likert_min_label, esm_likert_step, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addLikertScaleElement:(EntityESM *)esm withFrame:(CGRect)frame{
    
    selectedOption = 0; // defualt value is 0
    options = [[NSMutableArray alloc] init];
    
    NSNumber *max = esm.esm_likert_max;
    
    int mainW = self.mainView.frame.size.width;
    UIView* ratingView = [[UIView alloc] initWithFrame:CGRectMake(60,
                                                                  0,
                                                                  mainW-120,
                                                                  60)];
    
    // Add  min/max/slider value
    UILabel *minLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,
                                                                  ratingView.frame.size.height/2,
                                                                  60,
                                                                  ratingView.frame.size.height/2)];
    UILabel *maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(minLabel.frame.size.width + ratingView.frame.size.width-10,
                                                                  ratingView.frame.size.height/2,
                                                                  60,
                                                                  ratingView.frame.size.height/2)];
    
    minLabel.numberOfLines = 3;
    maxLabel.numberOfLines = 3;
    
    minLabel.adjustsFontSizeToFitWidth = YES;
    maxLabel.adjustsFontSizeToFitWidth = YES;
    
    minLabel.text = esm.esm_likert_min_label;
    maxLabel.text = esm.esm_likert_max_label;
    
    minLabel.textAlignment = NSTextAlignmentCenter;
    maxLabel.textAlignment = NSTextAlignmentCenter;
    
//    minLabel.textAlignment = NSTextAlignmentLeft;
//    maxLabel.textAlignment = NSTextAlignmentRight;
    
//    [minLabel setBackgroundColor:[UIColor blueColor]];
//    [maxLabel setBackgroundColor:[UIColor blueColor]];
    
    [self.mainView addSubview:minLabel];
    [self.mainView addSubview:maxLabel];
    [self.mainView addSubview:ratingView];

    // Add labels
    for (int i=0; i<[max intValue]; i++) {
        int anOptionWidth = ratingView.frame.size.width / [max intValue]; // "1" is a space for N/A label
        int addX = i * anOptionWidth;
        int x = addX + (anOptionWidth/4);
        int y = 0;//mainY;
        int w = ratingView.frame.size.height/2; //30
        int h = ratingView.frame.size.height/2; //30
        UILabel *number = [[UILabel alloc] initWithFrame:CGRectMake(x,y,w,h)];
        number.text = [NSString stringWithFormat:@"%d", i+1];
        number.textAlignment = NSTextAlignmentCenter;
        [ratingView addSubview:number];
        // [number setBackgroundColor:[UIColor redColor]];
    }
    
    // Add options
    for (int i=0; i<[max intValue] ; i++) {
        int anOptionWidth = ratingView.frame.size.width / [max intValue];
        int addX = i * anOptionWidth;
        // int x = addX;
        int x = addX + (anOptionWidth/4);
        int y = 0 + ratingView.frame.size.height/2;
        int w = ratingView.frame.size.height/2; //30
        int h = ratingView.frame.size.height/2; //30
        UIButton * option = [[UIButton alloc] initWithFrame:CGRectMake(x, y, w, h)];
        // [option setCenter:CGPointMake(x, y)];
        option.tag = i;
        [option addTarget:self action:@selector(pushedLikertButton:) forControlEvents:UIControlEventTouchUpInside];
        [option setImage:[self getImageFromLibAssetsWithImageName:@"unselected_circle"] forState:UIControlStateNormal];
        option.selected = NO;
        // [option setBackgroundColor:[UIColor redColor]];
        [ratingView addSubview:option];
        [options addObject:option];
    }
    // [self.mainView sizeToFit];
    
    // Fit the size of base-view with content view (modified x,y position)
    // CGRect rect = CGRectMake(0, frame.origin.y, self.contentView.frame.size.width, self.contentView.frame.size.height);
    // [self setFrame:rect];
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     ratingView.frame.size.height);
    
    [self refreshSizeOfRootView];
    
}


- (void) pushedLikertButton:(UIButton *) sender {
    
    for (int i=0; i<options.count; i++) {
        UIButton * option = (UIButton *)[options objectAtIndex:i];
        if (i==sender.tag) {
            [option setImage:[self getImageFromLibAssetsWithImageName:@"selected_circle"] forState:UIControlStateNormal];
            option.selected = YES;
            selectedOption = i+1;
            AudioServicesPlaySystemSound(1104);
        }else{
            [option setImage:[self getImageFromLibAssetsWithImageName:@"unselected_circle"] forState:UIControlStateNormal];
            option.selected = NO;
            AudioServicesPlaySystemSound(1105);
        }
    }
}


- (NSString *)getUserAnswer{
    if (self.isNA) {
        return @"NA";
    }else{
        if(selectedOption == 0){
            return @"";
        }else{
            return [NSString stringWithFormat:@"%d",selectedOption];
        }
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
