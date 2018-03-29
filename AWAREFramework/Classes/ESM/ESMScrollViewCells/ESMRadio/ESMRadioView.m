//
//  ESMRadioView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/04.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMRadioView.h"

@implementation ESMRadioView{
    NSMutableArray *options;
    NSMutableArray *labels;
    NSString * selectedLabelName;
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
    selectedLabelName = @"";
    if(self != nil){
        [self addRadioElement:esm withFrame:frame];
    }
    return self;
}


/**
 * esm_type=2 : Add a Radio Element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_radios, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addRadioElement:(EntityESM *) esm withFrame:(CGRect)frame {
    
    options = [[NSMutableArray alloc] init];
    labels = [[NSMutableArray alloc] init];
    NSArray * radios = [self convertJsonStringToArray:esm.esm_radios];
    
    int margin = 10;
    int totalHeight = 0;
    int objHeight = 30;
    int verticalMargin = 10;
    
    for (int i=0; i<radios.count ; i++) {
        //////////////////////////////////////
        
        UIButton *s = [[UIButton alloc] initWithFrame:CGRectMake(  margin, totalHeight, objHeight, objHeight)];
        [s setImage:[self getImageFromLibAssetsWithImageName:@"unselected_circle"] forState:UIControlStateNormal];
        s.tag = i;
        [s addTarget:self action:@selector(selectedRadioButton:) forControlEvents:UIControlEventTouchUpInside];
        
        
        NSString * labelText = @"";
        labelText = [radios objectAtIndex:i];
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(margin + s.frame.size.width + margin,
                                                                    totalHeight,
                                                                    self.mainView.frame.size.width - (margin + s.frame.size.width + margin),
                                                                    objHeight)];
        label.text = labelText;
        label.tag  = i;
        label.adjustsFontSizeToFitWidth = YES;
        
        [self.mainView addSubview:s];
        [self.mainView addSubview:label];
        totalHeight += objHeight + verticalMargin; // "10px" is buffer.
        
        [options addObject:s];
        [labels addObject:labelText];
    }
    
//    totalHeight
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     totalHeight);
    
    [self refreshSizeOfRootView];
}


-(void)selectedRadioButton:(UIButton *)sender{
    NSLog(@"sender:%ld",sender.tag);
    for (UIButton * button in options) {
        [button setImage:[self getImageFromLibAssetsWithImageName:@"unselected_circle"] forState:UIControlStateNormal];
    }
    [[options objectAtIndex:sender.tag] setImage:[self getImageFromLibAssetsWithImageName:@"selected_circle"] forState:UIControlStateNormal];
    AudioServicesPlaySystemSound(1105);
    selectedLabelName = [labels objectAtIndex:sender.tag];
}

//////////////////////////////////
- (NSNumber  *)getESMState{
    if ([self isNA]) return @2;
    if(![[self getUserAnswer] isEqualToString:@""]){
        return @2;
    }else{
        return @1;
    }
}

- (NSString *)getUserAnswer{
    if([self isNA]) return @"NA";
    /////////////////////////////////
    return selectedLabelName;
}

@end
