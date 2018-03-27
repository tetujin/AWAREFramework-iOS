//
//  TableViewCell.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/07/30.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//
// This source code is referred the following source code.
// http://qiita.com/kikuchy/items/f1d6731d804b63cf7a29
//

#import <UIKit/UIKit.h>
#import "EntityESM+CoreDataClass.h"
#import "AWAREKeys.h"
#import <AudioToolbox/AudioServices.h>

typedef enum: NSInteger {
    AwareESMCellStyleESM = 0,
    AwareESMCellStyleFooter = 1,
    AwareESMCellStyleNull = 2,
    AwareESMCellStyleLine = 3
} AwareESMCellStyle;


@interface BaseESMView : UIView{
    int esmType;
}

@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (nonatomic) IBOutlet EntityESM * esmEntity;

@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutlet UILabel *instructionLabel;
@property (nonatomic) IBOutlet UIView *mainView;
@property (nonatomic) IBOutlet UIView *naView;
@property (nonatomic) IBOutlet UIButton *naButton;
@property (nonatomic) IBOutlet UIView *splitLineView;
@property (nonatomic) IBOutlet UIView *spaceView;

- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm;

// - (void) setElements;
- (IBAction)pushedNAButton:(id)sender;
- (int) getESMType;
- (BOOL) isNA;
- (CGFloat) getViewHeight;
- (void) showNAView;
- (void) hideNAView;
// - (int) getHeight;
- (UIView *) generateESMView;
- (void) refreshSizeOfRootView;

- (NSNumber *) getESMState;
- (NSString *) getUserAnswer;
// - (NSString *) getUserAnswerWithJSONString;

//////////////////////////////
- (NSArray *) convertJsonStringToArray:(NSString *) jsonString;

@end
