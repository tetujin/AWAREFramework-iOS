//
//  AWAREEsmViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/15/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
//  http://www.awareframework.com/esm/
//

#import "AWAREEsmViewController.h"
#import "ESM.h"
#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "SingleESMObject.h"
#import "ESMStorageHelper.h"
#import "AWAREDelegate.h"
// #import "IOSESM.h"

#import "PamSchema.h"
#import "QuartzCore/CALayer.h"

@interface AWAREEsmViewController ()

@end

@implementation AWAREEsmViewController {
    CGRect frameRect;
    int WIDTH_VIEW;
    int HIGHT_TITLE;
    int HIGHT_INSTRUCTION;
    int HIGHT_MAIN_CONTENT;
    int HIGHT_BUTTON;
    int HIGHT_SPACE;
    int HIGHT_LINE;
    int totalHight;
    
    AWAREStudy * study;
    
    CGRect titleRect;
    CGRect instructionRect;
    CGRect mainContentRect;
    CGRect buttonRect;
    CGRect spaceRect;
    CGRect lineRect;
    NSMutableArray* freeTextViews;
    NSMutableArray *uiElements;
    
    NSString * currentTextOfEsm;
    
    NSString* KEY_ELEMENT;
    NSString* KEY_TAG;
    NSString* KEY_TYPE;
    NSString* KEY_LABLES;
    NSString* KEY_OBJECT;
    
    int esmNumber;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    /// Init sensor manager for the list view
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    AWARECore * core = delegate.sharedAWARECore;
    study = core.sharedAwareStudy;
    
    currentTextOfEsm = @"";
    
    WIDTH_VIEW = self.view.frame.size.width;
    HIGHT_TITLE = 100;
    HIGHT_INSTRUCTION = 40;
    HIGHT_MAIN_CONTENT = 100;
    HIGHT_BUTTON = 60;
    HIGHT_SPACE = 20;
    HIGHT_LINE = 1;
    
    totalHight = 0;
    int buffer = 10;
    
    titleRect = CGRectMake(buffer, 0, WIDTH_VIEW - buffer*2, HIGHT_TITLE);
    instructionRect = CGRectMake(buffer, 0, WIDTH_VIEW - buffer*2, HIGHT_INSTRUCTION);
    mainContentRect = CGRectMake(buffer, 0, WIDTH_VIEW - buffer*2, HIGHT_MAIN_CONTENT);
    buttonRect = CGRectMake(buffer, 0, WIDTH_VIEW - buffer*2, HIGHT_BUTTON);
    spaceRect = CGRectMake(buffer, 0, WIDTH_VIEW - buffer*2, HIGHT_SPACE);
    lineRect = CGRectMake(buffer, 0, WIDTH_VIEW - buffer*2, HIGHT_LINE);
    
    [self addNullElement];
    
    self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap:)];
    self.singleTap.delegate = self;
    self.singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:self.singleTap];
    
    freeTextViews = [[NSMutableArray alloc] init];
    
    KEY_ELEMENT = @"KEY_ELEMENTS";
    KEY_TAG = @"KEY_TAG";
    KEY_TYPE = @"KEY_TYPE";
    KEY_LABLES = @"KEY_LABELS";
    KEY_OBJECT = @"KEY_OBJECT";
    
    esmNumber = 0;
    
    [_mainScrollView setBackgroundColor:[UIColor whiteColor]];
}



-(void)onSingleTap:(UITapGestureRecognizer *)recognizer {
    NSLog(@"Single Tap");
    for (UITextView *textView in freeTextViews) {
        [textView resignFirstResponder];
    }
}

-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == self.singleTap) {
        return YES;
    }
    return NO;
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    // Remove all UIView contents from super view (_mainScrollView).
    for (UIView * view in _mainScrollView.subviews) {
        [view removeFromSuperview];
    }
    totalHight = 0;
    [_mainScrollView setDelegate:self];
    [_mainScrollView setScrollEnabled:YES];
    [_mainScrollView setFrame:self.view.frame];
    
    uiElements = [[NSMutableArray alloc] init];
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    // Get ESM using an ESMStorageHelper
    ESMStorageHelper *helper = [[ESMStorageHelper alloc] init];
    currentTextOfEsm = [helper getEsmTextWithNumber:esmNumber];
    if (currentTextOfEsm != nil) {
        [self addEsm:currentTextOfEsm];
    }
//    NSArray* esms = [helper getEsmTexts];
//    for (NSString *esm in esms) {
//        // Set each ESM elemetns to the viewer
//        [self addEsm:esm];
//        currentTextOfEsm = esm;
//        break;
//    }
}

/**
 * Add ESM elements with a JSON text
 */
- (bool) addEsm:(NSString*) jsonStrOfAwareEsm {
    // Covert an ESM json string to ESM object
    NSData *data = [jsonStrOfAwareEsm dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id object = [NSJSONSerialization
                 JSONObjectWithData:data
                 options:0
                 error:&error];
    if(error) {
        /* JSON was malformed, act appropriately here */
        NSLog(@"JSON format error!");
        return NO;
    }
    NSMutableArray * results = [[NSMutableArray alloc] initWithArray:object];
    
    // Set ESM Elements
    int tag = 0;
    NSLog(@"====== Hello ESM !! =======");
    for (NSDictionary *oneEsmObject in results) {
        NSDictionary * dic = [oneEsmObject objectForKey:@"esm"];
        //The ESM type (1-free text, 2-radio, 3-checkbox, 4-likert, 5-quick, 6-scale)
        NSNumber* type = [dic objectForKey:KEY_ESM_TYPE];
        switch ([type intValue]) {
            case 1: // free text
                NSLog(@"Add free text");
                [self addFreeTextElement:dic withTag:tag];
                break;
            case 2: // radio
                NSLog(@"Add radio");
                [self addRadioElement:dic withTag:tag];
                break;
            case 3: // checkbox
                NSLog(@"Add check box");
                [self addCheckBoxElement:dic withTag:tag];
                break;
            case 4: // likert
                NSLog(@"Add likert");
                [self addLikertScaleElement:dic withTag:tag];
                break;
            case 5: // quick
                NSLog(@"Add quick");
//                quick = YES;
                [self addQuickAnswerElement:dic withTag:tag];
                break;
            case 6: // scale
                NSLog(@"Add scale");
                [self addScaleElement:dic withTag:tag];
                break;
            case 7: //timepicker
                NSLog(@"Timer Picker");
                [self addTimePickerElement:dic withTag:tag];
                break;
            case 8: //PAM
                NSLog(@"PAM");
                [self addPAMElement:dic withTag:tag];
                break;
            default:
            break;
        }
        [self addNullElement];
        [self addLineElement];
        tag++;
    }
    
//    if (results.count == 1 && quick){
    
//    } else {
        [self addNullElement];
        [self addSubmitButtonWithText:@"Submit"];
        [self addNullElement];
        [self addCancelButtonWithText:@"Cancel"];
        [self addNullElement];
//    }
    return YES;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * esm_type=1 : Add a Free Text element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addFreeTextElement:(NSDictionary *) dic withTag:(int) tag
{
    [self addCommonContents:dic];
    
    UITextView * textView = [[UITextView alloc] initWithFrame:CGRectMake(mainContentRect.origin.x, totalHight, mainContentRect.size.width, mainContentRect.size.height)];
    textView.layer.borderWidth = 1.0f;    // 枠線の幅
    textView.layer.cornerRadius = 5.0f;   // 角の丸み
//    [textView.layer setBorderColor:(__bridge CGColorRef _Nullable)([UIColor lightGrayColor])];
    [freeTextViews addObject:textView];
    [textView setDelegate:self];
    
    
    // @"esm_na"
    BOOL naState = [self getNaStateFromDict:dic];
    if (naState) {
        //for N/A option
        UIButton * naCheckBox = [[UIButton alloc] initWithFrame:CGRectMake(mainContentRect.origin.x,
                                                                           totalHight + textView.frame.size.height,
                                                                           30, 30)];
        [naCheckBox setImage:[UIImage imageNamed:@"unchecked_box"] forState:UIControlStateNormal];
        naCheckBox.selected = NO;
        naCheckBox.tag = tag;
        [naCheckBox addTarget:self
                       action:@selector(pushedNaBox:)
             forControlEvents:UIControlEventTouchUpInside];
        UILabel * nalabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+10+40,
                                                                      totalHight+ textView.frame.size.height,
                                                                      mainContentRect.size.width-90,
                                                                      30)];
        nalabel.text = @"NA";
        [self setContentSizeWithAdditionalHeight: mainContentRect.size.height + naCheckBox.frame.size.height ];
        
        [_mainScrollView addSubview:textView];
        [_mainScrollView addSubview:naCheckBox];
        [_mainScrollView addSubview:nalabel];
        
        //    [uiElements addObject:textView];
        NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
        [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
        [uiElement setObject:@1 forKey:KEY_TYPE];
        NSArray * contents = [[NSArray alloc] initWithObjects:textView, naCheckBox, nil];
        [uiElement setObject:contents forKey:KEY_ELEMENT];
        [uiElement setObject:[[NSArray alloc] init] forKey:KEY_LABLES];
        [uiElement setObject:dic forKey:KEY_OBJECT];
        
        [uiElements addObject:uiElement];
    }else{
        [self setContentSizeWithAdditionalHeight: mainContentRect.size.height];
        
        [_mainScrollView addSubview:textView];
        
        //    [uiElements addObject:textView];
        NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
        [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
        [uiElement setObject:@1 forKey:KEY_TYPE];
        NSArray * contents = [[NSArray alloc] initWithObjects:textView, nil];
        [uiElement setObject:contents forKey:KEY_ELEMENT];
        [uiElement setObject:[[NSArray alloc] init] forKey:KEY_LABLES];
        [uiElement setObject:dic forKey:KEY_OBJECT];
        
        [uiElements addObject:uiElement];
    }
    
    
    
}


/**
 * esm_type=2 : Add a Radio Element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_radios, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addRadioElement:(NSDictionary *) dic withTag:(int) tag {
    [self addCommonContents:dic];
    
    NSMutableArray *elements = [[NSMutableArray alloc] init];
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    
    NSArray * radios = [dic objectForKey:KEY_ESM_RADIOS];
    for (int i=0; i<radios.count ; i++) {
        NSString * labelText = @"";
        labelText = [radios objectAtIndex:i];
        UIButton *s = [[UIButton alloc] initWithFrame:CGRectMake(mainContentRect.origin.x + 10, totalHight, 30, 30)];
        [s setImage:[UIImage imageNamed:@"unselected_circle"] forState:UIControlStateNormal];
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x + 10 + 60,
                                                                    totalHight,
                                                                    mainContentRect.size.width - 90,
                                                                    30)];
        label.text = labelText;
        label.tag = totalHight;
        label.adjustsFontSizeToFitWidth = YES;
        s.tag = tag;
        
        [s addTarget:self action:@selector(btnSendCommentPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_mainScrollView addSubview:s];
        [_mainScrollView addSubview:label];
        [self setContentSizeWithAdditionalHeight:31+9]; // "9px" is buffer.
        
        [elements addObject:s];
        [labels addObject:label];
    }
    
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@2 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
}


- (void)btnSendCommentPressed:(UIButton *) sender {
    NSInteger tag = sender.tag;
    for (NSDictionary * dic in uiElements) {
        NSNumber * tagNumber = [dic objectForKey:KEY_TAG];
        if ([tagNumber integerValue] == tag) {
            NSArray* boxes = [dic objectForKey:KEY_ELEMENT];
            for (UIButton * button in boxes) {
                [button setSelected:NO];
            }
        }
    }
    
    NSLog(@"button pushed!");
    if ([sender isSelected]) {
        [sender setImage:[UIImage imageNamed:@"unselected_circle"] forState:UIControlStateNormal];
        [sender setSelected:NO];
    } else {
        [sender setImage:[UIImage imageNamed:@"selected_circle"] forState:UIControlStateSelected];
        [sender setSelected:YES];
    }

    
    for (NSDictionary * dic in uiElements) {
        NSNumber * tagNumber = [dic objectForKey:KEY_TAG];
        if ([tagNumber integerValue] == tag) {
            NSArray* labels = [dic objectForKey:KEY_LABLES];
            for (UILabel * label in labels) {
                NSLog(@"%@ %f", label.text, label.frame.origin.y);
                // selected button's y
                double selectedButtonY = sender.frame.origin.y;
                double labelY = label.frame.origin.y;
                NSError *error = nil;
                NSString *pattern = @"Other*";
                NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
                NSTextCheckingResult *match = [regexp firstMatchInString:label.text options:0 range:NSMakeRange(0, label.text.length)];
                NSString *matchedText = @"";
                if (match.numberOfRanges > 0) {
                    NSLog(@"matched text: %@", [label.text substringWithRange:[match rangeAtIndex:0]]);
                    matchedText = [label.text substringWithRange:[match rangeAtIndex:0]];
                }
                
                if (selectedButtonY == labelY && [matchedText isEqualToString:@"Other"]) {
                    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@""
                                                                message:@"Please write your original option."
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"OK", nil];
                    av.alertViewStyle = UIAlertViewStylePlainTextInput;
                    av.tag = tag;
                    [av textFieldAtIndex:0].delegate = self;
                    [av show];
                }
            }
        }
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"%@",[alertView textFieldAtIndex:0].text);
    NSInteger tag = alertView.tag;
    NSString * inputText = [alertView textFieldAtIndex:0].text;
    for (NSDictionary * dic in uiElements) {
        NSNumber * tagNumber = [dic objectForKey:KEY_TAG];
        if ([tagNumber integerValue] == tag) {
            NSArray* labels = [dic objectForKey:KEY_LABLES];
            for (UILabel * label in labels) {
//                NSLog(@"%@ %f", label.text, label.frame.origin.y);
                // selected button's y
                NSError *error = nil;
                NSString *pattern = @"Other*";
                NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
                NSTextCheckingResult *match = [regexp firstMatchInString:label.text options:0 range:NSMakeRange(0, label.text.length)];
                NSString *matchedText = @"";
                if (match.numberOfRanges > 0) {
                    NSLog(@"matched text: %@", [label.text substringWithRange:[match rangeAtIndex:0]]);
                    matchedText = [label.text substringWithRange:[match rangeAtIndex:0]];
                }
                if ([matchedText isEqualToString:@"Other"]) {
                    label.text = [NSString stringWithFormat:@"Other: %@", inputText];
                }
            }
        }
    }

}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////


/**
 * esm_type=3 : Add a Check Box Element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_checkboxes, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addCheckBoxElement:(NSDictionary *) dic withTag:(int) tag{
    [self addCommonContents:dic];
    NSMutableArray *elements = [[NSMutableArray alloc] init];
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    NSArray * checkBoxItems = [dic objectForKey:KEY_ESM_CHECKBOXES];
    for (int i=0; i<checkBoxItems.count; i++) {
        NSString* checkBoxItem  = @"";
//        if ( i == checkBoxItems.count ) {
//            checkBoxItem = @"N/A";
//        } else {
        checkBoxItem = [checkBoxItems objectAtIndex:i];
//        }
        UIButton *s = [[UIButton alloc] initWithFrame:CGRectMake(mainContentRect.origin.x + 10 , totalHight, 30, 30)];
        [s setImage:[UIImage imageNamed:@"unchecked_box"] forState:UIControlStateNormal];
        [s addTarget:self action:@selector(pushedCheckBox:) forControlEvents:UIControlEventTouchUpInside];
        s.tag = tag;
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x + 10 + 60, totalHight, mainContentRect.size.width - 90, 30)];
        label.adjustsFontSizeToFitWidth = YES;
        label.text = checkBoxItem;
        [labels addObject:label];
        
        [_mainScrollView addSubview:s];
        [_mainScrollView addSubview:label];
        [self setContentSizeWithAdditionalHeight:31+9]; // 9 is buffer.
        
        [elements addObject:s];
    }
    
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@3 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
}



- (void) pushedCheckBox:(UIButton *) sender {
    NSLog(@"button pushed!");
    if ([sender isSelected]) {
        [sender setImage:[UIImage imageNamed:@"unchecked_box"] forState:UIControlStateNormal];
        [sender setSelected:NO];
    } else {
        [sender setImage:[UIImage imageNamed:@"checked_box"] forState:UIControlStateSelected];
        [sender setSelected:YES];
    }
    
    if ([sender isSelected]) {
        NSInteger tag = sender.tag;
        for (NSDictionary * dic in uiElements) {
            NSNumber * tagNumber = [dic objectForKey:KEY_TAG];
            if ([tagNumber integerValue] == tag) {
                NSArray* labels = [dic objectForKey:KEY_LABLES];
                for (UILabel * label in labels) {
                    NSLog(@"%@ %f", label.text, label.frame.origin.y);
                    // selected button's y
                    double selectedButtonY = sender.frame.origin.y;
                    double labelY = label.frame.origin.y;
                    NSError *error = nil;
                    NSString *pattern = @"Other*";
                    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
                    NSTextCheckingResult *match = [regexp firstMatchInString:label.text options:0 range:NSMakeRange(0, label.text.length)];
                    NSString *matchedText = @"";
                    if (match.numberOfRanges > 0) {
                        NSLog(@"matched text: %@", [label.text substringWithRange:[match rangeAtIndex:0]]);
                        matchedText = [label.text substringWithRange:[match rangeAtIndex:0]];
                    }
                    
                    if (selectedButtonY == labelY && [matchedText isEqualToString:@"Other"]) {
                        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@""
                                                                    message:@"Please write your original option."
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                          otherButtonTitles:@"OK", nil];
                        av.alertViewStyle = UIAlertViewStylePlainTextInput;
                        av.tag = tag;
                        [av textFieldAtIndex:0].delegate = self;
                        [av show];
                    }
                }
            }
        }
    }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////


/**
 * esm_type=4 : Add a Likert Scale Element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_likert_max, esm_likert_max_label, esm_likert_min_label, esm_likert_step, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addLikertScaleElement:(NSDictionary *) dic withTag:(int) tag {
    [self addCommonContents:dic];
    
    NSMutableArray* elements = [[NSMutableArray alloc] init];
    NSMutableArray* labels = [[NSMutableArray alloc] init];

    NSNumber *max = [dic objectForKey:KEY_ESM_LIKERT_MAX];
    UIView* ratingView = [[UIView alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+60,
                                                                  totalHight,
                                                                  mainContentRect.size.width-120,
                                                                  60)];
    // Get "NA" state. The key for the NA state is "esm_na", also value is 0(FALSE) or 1(TURE).
    BOOL naState = [self getNaStateFromDict:dic];
    
    if(naState){ // NA is true
        // Add labels
        for (int i=0; i<[max intValue]+1; i++) {
            int anOptionWidth = ratingView.frame.size.width / ([max intValue] + 1); // "1" is a space for N/A label
            int addX = i * anOptionWidth;
            int x = ratingView.frame.origin.x + addX + (anOptionWidth/4);
            int y = totalHight;
            int w = ratingView.frame.size.height/2; //30
            int h = ratingView.frame.size.height/2; //30
            UILabel *numbers = [[UILabel alloc] initWithFrame:CGRectMake(x,y,w,h)];
            numbers.text = [NSString stringWithFormat:@"%d", i+1];
            //        [elements addObject:numbers];
            if ( i == ([max intValue]) ) { // last label
                numbers.text = @"NA";
                numbers.frame = CGRectMake(x-(anOptionWidth/4), y, w, h);
            }
            [_mainScrollView addSubview:numbers];
        }
        
        // Add options
        for (int i=0; i<([max intValue]+1) ; i++) {
            int anOptionWidth = ratingView.frame.size.width / ([max intValue]+1);
            int addX = i * anOptionWidth;
            int x = ratingView.frame.origin.x + addX;
            int y = totalHight + ratingView.frame.size.height/2;
            int w = ratingView.frame.size.height/2; //30
            int h = ratingView.frame.size.height/2; //30
            UIButton * option = [[UIButton alloc] initWithFrame:CGRectMake(x, y, w, h)];
            option.tag = tag;
            [option addTarget:self action:@selector(pushedLikertButton:) forControlEvents:UIControlEventTouchUpInside];
            [option setImage:[UIImage imageNamed:@"unselected_circle"] forState:UIControlStateNormal];
            option.selected = NO;
            [_mainScrollView addSubview:option];
            [elements addObject:option];
        }
        [self setContentSizeWithAdditionalHeight:ratingView.frame.size.height];
    }else{ // NA is false
        // Add labels
        for (int i=0; i<[max intValue]; i++) {
            int anOptionWidth = ratingView.frame.size.width / [max intValue]; // "1" is a space for N/A label
            int addX = i * anOptionWidth;
            int x = ratingView.frame.origin.x + addX + (anOptionWidth/4);
            int y = totalHight;
            int w = ratingView.frame.size.height/2; //30
            int h = ratingView.frame.size.height/2; //30
            UILabel *numbers = [[UILabel alloc] initWithFrame:CGRectMake(x,y,w,h)];
            numbers.text = [NSString stringWithFormat:@"%d", i+1];
            //        [elements addObject:numbers];
//            if ( i == ([max intValue]) ) { // last label
//                numbers.text = @"NA";
//                numbers.frame = CGRectMake(x-(anOptionWidth/4), y, w, h);
//            }
            [_mainScrollView addSubview:numbers];
        }
        
        // Add options
        for (int i=0; i<[max intValue] ; i++) {
            int anOptionWidth = ratingView.frame.size.width / [max intValue];
            int addX = i * anOptionWidth;
            int x = ratingView.frame.origin.x + addX;
            int y = totalHight + ratingView.frame.size.height/2;
            int w = ratingView.frame.size.height/2; //30
            int h = ratingView.frame.size.height/2; //30
            UIButton * option = [[UIButton alloc] initWithFrame:CGRectMake(x, y, w, h)];
            option.tag = tag;
            [option addTarget:self action:@selector(pushedLikertButton:) forControlEvents:UIControlEventTouchUpInside];
            [option setImage:[UIImage imageNamed:@"unselected_circle"] forState:UIControlStateNormal];
            option.selected = NO;
            [_mainScrollView addSubview:option];
            [elements addObject:option];
        }
        [self setContentSizeWithAdditionalHeight:ratingView.frame.size.height];
    }
    
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@4 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
}

- (void) pushedLikertButton:(UIButton *) sender {
    NSNumber * tag = [NSNumber numberWithInteger:sender.tag];
    int selectedX = sender.frame.origin.x;
    for (NSDictionary * dic in uiElements) {
        NSNumber *tagOfElement = [dic objectForKey:KEY_TAG];
        if ([tagOfElement isEqualToNumber:tag]) {
            NSArray * options = [dic objectForKey:KEY_ELEMENT];
            // init and set selected option
            for (UIButton * option in options) {
                int x = option.frame.origin.x;
                if (selectedX == x) {
                    [option setImage:[UIImage imageNamed:@"selected_circle"] forState:UIControlStateNormal];
                    option.selected = YES;
                }else{
                    [option setImage:[UIImage imageNamed:@"unselected_circle"] forState:UIControlStateNormal];
                    option.selected = NO;
                }
            }
        }
    }
}


- (IBAction)sliderValueChanged:(UISlider *)sender {
//    NSLog(@"slider value = %f", sender.value);
    int intValue = sender.value;
    [sender setValue:intValue];
    UILabel * label = [_mainScrollView viewWithTag:sender.frame.origin.y];
    [label setText:[NSString stringWithFormat:@"%d", intValue]];
}

- (void) pushedNaBox:(UIButton *) sender {
    NSLog(@"button pushed!");
    if ([sender isSelected]) {
        [sender setImage:[UIImage imageNamed:@"unchecked_box"] forState:UIControlStateNormal];
        [sender setSelected:NO];
    } else {
        [sender setImage:[UIImage imageNamed:@"checked_box"] forState:UIControlStateSelected];
        [sender setSelected:YES];
    }
}

- (void) setNaBoxFolse: (id) slider {
    NSInteger tag = [slider tag];
    NSLog(@"%ld",tag);
    NSDictionary * uiElement = [uiElements objectAtIndex:tag];
    NSArray *elements = [uiElement objectForKey:KEY_ELEMENT];
    if (elements.count > 1) {
        UIButton * button = [elements objectAtIndex:1];
        [button setImage:[UIImage imageNamed:@"unchecked_box"] forState:UIControlStateNormal];
        [button setSelected:NO];
    }
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////




/**
 * esm_type=5 : Add a Quick Answer Element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_quick_answers, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addQuickAnswerElement:(NSDictionary *) dic withTag:(int) tag{
    [self addCommonContents:dic];
    NSMutableArray *elements = [[NSMutableArray alloc] init];
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    
    for (NSString* answers in [dic objectForKey:KEY_ESM_QUICK_ANSWERS]) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(mainContentRect.origin.x, totalHight, buttonRect.size.width, buttonRect.size.height)];
        [button setTitle:answers forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor lightGrayColor]];
        [button addTarget:self action:@selector(pushedQuickAnswerButtons:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = tag;
        [_mainScrollView addSubview:button];
        [self setContentSizeWithAdditionalHeight:buttonRect.size.height + 5];
        [elements addObject:button];
        [labels addObject:answers];
    }
    
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@5 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
}


- (void) pushedQuickAnswerButtons:(UIButton *) button  {
    int tag = (int)button.tag;
    NSMutableDictionary * dic = [uiElements objectAtIndex:tag];
    NSMutableArray * buttons = [dic objectForKey:KEY_ELEMENT];
    for (UIButton * b in buttons) {
        b.selected = NO;
        b.layer.borderWidth = 0;
        if ([button.titleLabel isEqual:b.titleLabel]) {
            b.selected = YES;
            b.layer.borderColor = [UIColor redColor].CGColor;
            b.layer.borderWidth = 5.0;
        }
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////



/**
 * esm_type=6 : Add a Scale Element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_scale_min, esm_scale_max,
 esm_scale_start, esm_scale_max_label, esm_scale_min_label, esm_scale_step, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addScaleElement:(NSDictionary *) dic withTag:(int) tag{
    int valueLabelH = 30;
    int mainContentH = 30;
    int naH = 30;
    int spaceH = 10;
    [self addCommonContents:dic];
    // Add a value label
    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+60, totalHight, mainContentRect.size.width-120, valueLabelH)];
    // Add  min/max/slider value
    UILabel *minLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x,
                                                                  totalHight+valueLabelH,
                                                                  60, mainContentH)];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+60,
                                                                  totalHight+valueLabelH,
                                                                  mainContentRect.size.width-120, mainContentH)];
    UILabel *maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+mainContentRect.size.width -60,
                                                                  totalHight+valueLabelH,
                                                                  60, mainContentH)];
    
    minLabel.adjustsFontSizeToFitWidth = YES;
    maxLabel.adjustsFontSizeToFitWidth = YES;
    
    NSNumber *max = [dic objectForKey:KEY_ESM_SCALE_MAX];
    NSNumber *min = [dic objectForKey:KEY_ESM_SCALE_MIN];
    NSNumber *start = [dic objectForKey:KEY_ESM_SCALE_START];
    
    slider.maximumValue = [max floatValue];
    slider.minimumValue = [min floatValue];
    slider.value = [start floatValue];
    slider.tag = tag;
    [slider addTarget:self
               action:@selector(setNaBoxFolse:)
     forControlEvents:UIControlEventTouchUpInside];
    
    valueLabel.text = @"---";
    valueLabel.tag = totalHight;
    minLabel.text = [dic objectForKey:KEY_ESM_SCALE_MIN_LABEL];
    maxLabel.text = [dic objectForKey:KEY_ESM_SCALE_MAX_LABEL];
    
    valueLabel.textAlignment = NSTextAlignmentCenter;
    minLabel.textAlignment = NSTextAlignmentCenter;
    maxLabel.textAlignment = NSTextAlignmentCenter;
    
    
    
    // NA
    BOOL naState = [self getNaStateFromDict:dic];
    UIButton * naCheckBox = [[UIButton alloc] initWithFrame:CGRectMake(mainContentRect.origin.x,
                                                                       totalHight+valueLabelH+mainContentH+spaceH,
                                                                       30, naH)];
    [naCheckBox setImage:[UIImage imageNamed:@"unchecked_box"] forState:UIControlStateNormal];
    naCheckBox.tag = tag;
    naCheckBox.selected = NO;
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+10+40,
                                                                totalHight+valueLabelH+mainContentH+spaceH,
                                                                mainContentRect.size.width-90, naH)];
    label.adjustsFontSizeToFitWidth = YES;
    label.text = @"NA";
    [naCheckBox addTarget:self
                   action:@selector(pushedNaBox:)
         forControlEvents:UIControlEventTouchUpInside];

    
    
    [_mainScrollView addSubview:valueLabel];
    [_mainScrollView addSubview:slider];
    [_mainScrollView addSubview:maxLabel];
    [_mainScrollView addSubview:minLabel];
    if(naState){
        [_mainScrollView addSubview:naCheckBox];
        [_mainScrollView addSubview:label];
    }
    
    [self setContentSizeWithAdditionalHeight:valueLabelH + mainContentH + spaceH + naH];
    
    NSMutableArray * elements = [[NSMutableArray alloc] init];
    NSMutableArray * labels = [[NSMutableArray alloc] init];
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
//    [elements addObject:slider];
    [elements addObject:valueLabel]; // for detect
    if(naState)[elements addObject:naCheckBox];
    [labels addObject:maxLabel];
    if(naState)[labels addObject:label];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@6 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
    [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
}


- (IBAction)sliderChanged:(UISlider *)sender {
//    NSLog(@"slider value = %f", sender.value);
    int intValue = sender.value;
    [sender setValue:intValue];
    UILabel * label = [_mainScrollView viewWithTag:sender.frame.origin.y-30];
    [label setText:[NSString stringWithFormat:@"%d", intValue]];
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////


/**
 * esm_type=7 : Add a Time Picker (WIP)
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addTimePickerElement:(NSDictionary *)dic withTag:(int) tag{
    [self addCommonContents:dic];
    UIDatePicker * datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(mainContentRect.origin.x,
                                                                               totalHight,
                                                                               mainContentRect.size.width, 100)];
//    datePicker.date = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    datePicker.tag = tag;
    [datePicker addTarget:self
               action:@selector(setDateValue:)
     forControlEvents:UIControlEventValueChanged];
    
    int datePickerHight = datePicker.frame.size.height;
    
    
    // NA
    BOOL naState = [self getNaStateFromDict:dic];
    UIButton * naCheckBox = [[UIButton alloc] initWithFrame:CGRectMake(mainContentRect.origin.x,
                                                                       totalHight+datePickerHight+10,
                                                                       30, 30)];
    [naCheckBox setImage:[UIImage imageNamed:@"unchecked_box"] forState:UIControlStateNormal];
    naCheckBox.tag = tag;
    naCheckBox.selected = NO;
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+10+40,
                                                                totalHight+datePickerHight +10,
                                                                mainContentRect.size.width-90,
                                                                30)];
    label.adjustsFontSizeToFitWidth = YES;
    label.text = @"NA";
    [naCheckBox addTarget:self
                   action:@selector(pushedNaBox:)
         forControlEvents:UIControlEventTouchUpInside];
    
    
    [_mainScrollView addSubview:datePicker];
    if(naState)[_mainScrollView addSubview:naCheckBox];
    if(naState)[_mainScrollView addSubview:label];
    [self setContentSizeWithAdditionalHeight:datePickerHight + 10 + 30];
    
    
    NSMutableArray * elements = [[NSMutableArray alloc] init];
    NSMutableArray * labels = [[NSMutableArray alloc] init];
    NSNumber * datetime = [[NSNumber alloc] initWithInt:0];
    [elements addObject:datetime];
    if(naState)[elements addObject:naCheckBox];
    
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@7 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
}


- (void) setDateValue:(UIDatePicker * ) sender {
    
    NSInteger tag = sender.tag;
    NSMutableDictionary * uiElement = [uiElements objectAtIndex:tag];
    NSArray * elements = [uiElement objectForKey:KEY_ELEMENT];
    
    NSMutableArray * array = [[NSMutableArray alloc] initWithArray:elements];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:sender.date];
    [array setObject:unixtime atIndexedSubscript:0];
    
    [uiElement setObject:array forKey:KEY_ELEMENT];
    [uiElements replaceObjectAtIndex:tag withObject:uiElement];
    //    [uiElements insertObject:uiElement atIndex:tag];
}




/**
 * esm_type=8: Add a PAM (WIP)
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */

- (void) addPAMElement:(NSDictionary *)dic withTag:(int)tag{
    [self addCommonContents:dic];
    
    NSMutableArray * buttons = [[NSMutableArray alloc] init];
    
    int column = 4;
    int row = 4;
//    NSInteger cellWidth = mainContentRect.size.width/column;//self.view.frame.size.width
    NSInteger cellWidth = self.view.frame.size.width/column;//
    NSInteger cellHeight = cellWidth;
    
    int pamNum = 1;
    
    for (int rowNum=0; rowNum<row; rowNum++ ) {
        for (int columnNum=0; columnNum<column; columnNum++) {
            // 1. Get random number between 1 and 3
            int randomNum = arc4random() % 3 + 1;
//            NSString * emotion = [PamSchema getEmotionString:(NSInteger)pamNum];
//            NSString * imagePath = [NSString stringWithFormat:@"images/%d_%@/%d_%d.jpg",pamNum,emotion,pamNum, randomNum];
            NSString * imagePath = [NSString stringWithFormat:@"%d_%d.jpg",pamNum, randomNum];
            UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(cellWidth*columnNum, totalHight+cellHeight*rowNum, cellWidth, cellHeight)];
//            button.imageView.image = [UIImage imageNamed:@"ic_launcher-web"];
            [button setImage:[UIImage imageNamed:imagePath] forState:UIControlStateNormal];
            button.tag = tag;
            button.titleLabel.text = [NSString stringWithFormat:@"%d", pamNum];
            [button addTarget:self
                        action:@selector(pushedPamImage:)
                 forControlEvents:UIControlEventTouchUpInside];
            [buttons addObject:button];
            [_mainScrollView addSubview:button];
            pamNum++;
        }
    }
    
    [self setContentSizeWithAdditionalHeight:(int)cellHeight*(int)row];

    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@8 forKey:KEY_TYPE];
    [uiElement setObject:buttons forKey:KEY_ELEMENT];
//    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    [uiElements addObject:uiElement];
    
    
//    NSMutableArray *elements = [[NSMutableArray alloc] init];
//    NSMutableArray *labels = [[NSMutableArray alloc] init];
//    
//    NSArray * checkBoxItems = [dic objectForKey:KEY_ESM_CHECKBOXES];
//    for (int i=0; i<checkBoxItems.count; i++) {
//        NSString* checkBoxItem  = @"";
//        //        if ( i == checkBoxItems.count ) {
//        //            checkBoxItem = @"N/A";
//        //        } else {
//        checkBoxItem = [checkBoxItems objectAtIndex:i];
//        //        }
//        UIButton *s = [[UIButton alloc] initWithFrame:CGRectMake(mainContentRect.origin.x + 10 , totalHight, 30, 30)];
//        [s setImage:[UIImage imageNamed:@"unchecked_box"] forState:UIControlStateNormal];
//        [s addTarget:self action:@selector(pushedCheckBox:) forControlEvents:UIControlEventTouchUpInside];
//        s.tag = tag;
//        
//        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x + 10 + 60, totalHight, mainContentRect.size.width - 90, 30)];
//        label.adjustsFontSizeToFitWidth = YES;
//        label.text = checkBoxItem;
//        [labels addObject:label];
//        
//        [_mainScrollView addSubview:s];
//        [_mainScrollView addSubview:label];
//        [self setContentSizeWithAdditionalHeight:31+9]; // 9 is buffer.
//        
//        [elements addObject:s];
//    }
//    
//    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
//    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
//    [uiElement setObject:@3 forKey:KEY_TYPE];
//    [uiElement setObject:elements forKey:KEY_ELEMENT];
//    [uiElement setObject:labels forKey:KEY_LABLES];
//    [uiElement setObject:dic forKey:KEY_OBJECT];
//    
//    [uiElements addObject:uiElement];
}


- (void) pushedPamImage:(UIButton *) sender {
//    NSLog(@"%ld %@", sender.tag, sender.titleLabel.text);
    NSMutableDictionary * elements = [uiElements objectAtIndex:sender.tag];
    NSMutableArray * buttons = [elements objectForKey:KEY_ELEMENT];
    NSString *  selected = sender.titleLabel.text;
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

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Add a null element to the UI view.
 */
- (void) addNullElement {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, totalHight, WIDTH_VIEW, HIGHT_SPACE)];
//    [view setBackgroundColor:[UIColor grayColor]];
    [_mainScrollView addSubview:view];
    [self setContentSizeWithAdditionalHeight:HIGHT_SPACE];
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Add a line element to the UI view.
 */
- (void) addLineElement {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(lineRect.origin.x, totalHight, lineRect.size.width, lineRect.size.height)];
//    [view setBackgroundColor:[UIColor lightTextColor]];
    [view setBackgroundColor:[UIColor lightGrayColor]];
    [_mainScrollView addSubview:view];
    [self setContentSizeWithAdditionalHeight:lineRect.size.height];
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Add common contents in the ESM view
 */
- (void) addCommonContents:(NSDictionary *) dic {
    //  make each content
    [self addTitleWithText:[dic objectForKey:KEY_ESM_TITLE]];
    [self addInstructionsWithText:[dic objectForKey:KEY_ESM_INSTRUCTIONS]];
}


- (void) addTitleWithText:(NSString *) title {
    if (![title isEqualToString:@""]) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleRect.origin.x, totalHight, titleRect.size.width, titleRect.size.height)];
        [titleLabel setText:title];
        titleLabel.font = [titleLabel.font fontWithSize:25];
        titleLabel.numberOfLines = 5;
        titleLabel.adjustsFontSizeToFitWidth = YES;
        [_mainScrollView addSubview:titleLabel];
        [self setContentSizeWithAdditionalHeight:HIGHT_TITLE];
    }
}

- (void) addInstructionsWithText:(NSString*) text {
    if (![text isEqualToString:@""]) {
        UILabel *instructionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(instructionRect.origin.x, totalHight, instructionRect.size.width, instructionRect.size.height)];
        [instructionsLabel setText:text];
        //    [instructionsLabel setBackgroundColor:[UIColor redColor]];
        instructionsLabel.numberOfLines = 5;
        instructionsLabel.adjustsFontSizeToFitWidth = YES;
        [_mainScrollView addSubview:instructionsLabel];
        [self setContentSizeWithAdditionalHeight:HIGHT_INSTRUCTION];
    }
}

- (void) addSubmitButtonWithText:(NSString*) text {
    UIButton *submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(buttonRect.origin.x, totalHight, buttonRect.size.width, buttonRect.size.height)];
    [submitBtn setTitle:text forState:UIControlStateNormal];
    [submitBtn setBackgroundColor:[UIColor grayColor]];
    [_mainScrollView addSubview:submitBtn];
    [self setContentSizeWithAdditionalHeight:HIGHT_BUTTON];
    [submitBtn setTag:0];
    [submitBtn addTarget:self action:@selector(pushedSubmitButton:) forControlEvents:UIControlEventTouchUpInside];
}


- (void) addCancelButtonWithText:(NSString*) text {
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(buttonRect.origin.x, totalHight, buttonRect.size.width, buttonRect.size.height)];
    [cancelBtn setTitle:text forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    cancelBtn.layer.borderColor = [UIColor lightGrayColor].CGColor;
    cancelBtn.layer.borderWidth = 2;
    [_mainScrollView addSubview:cancelBtn];
    [self setContentSizeWithAdditionalHeight:HIGHT_BUTTON];
    [cancelBtn addTarget:self action:@selector(pushedCancelButton:) forControlEvents:UIControlEventTouchUpInside];
}





//////////////////////////////////////////////////////////////////////////////////////////////////////////////


/**
 * This method stores the esm answerds to local database with esm_status=2(answered). If the answers include dissmiss, this method save the answer as esm_status=1(dissmissed).
 * And also, this method calls when a user push "submit" button.
 */
- (void) pushedSubmitButton:(id) senser {
    NSLog(@"Submit button was pushed!");
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    ESM *esm = [[ESM alloc] initWithAwareStudy:study
                                        dbType:AwareDBTypeTextFile];
    
    // NSNumber *NEW = @0;
    NSNumber *DISMISSED = @1;
    NSNumber *ANSWERED = @2;
    // NSNumber *EXPIRED = @3;
    
//    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
//    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSString * deviceId = [esm getDeviceId];
    
    for (int i=0; i<uiElements.count; i++) {
        NSDictionary *esmDic = [[uiElements objectAtIndex:i] objectForKey:KEY_OBJECT];
        NSArray * contents = [[uiElements objectAtIndex:i] objectForKey:KEY_ELEMENT];
        NSArray * labels = [[uiElements objectAtIndex:i] objectForKey:KEY_LABLES];
        NSMutableDictionary *dic =  [self getEsmFormatDictionary:(NSMutableDictionary *)esmDic
                                                   withTimesmap:unixtime
                                                        devieId:deviceId];
//        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:unixtime forKey:KEY_ESM_USER_ANSWER_TIMESTAMP];
        [dic setObject:deviceId forKey:@"device_id"];
        [dic setObject:ANSWERED forKey:KEY_ESM_STATUS]; // the status of the ESM (0-new, 1-dismissed, 2-answered, 3-expired) -> Defualt is zero(0).
        // add special data to dic from each uielements
        NSNumber* type = [esmDic objectForKey:KEY_ESM_TYPE];
        // save each data to the dictionary
        if ([type isEqualToNumber:@1]) {
            NSLog(@"Get free text data.");
            if (contents != nil) {
                UITextView * textView = [contents objectAtIndex:0];
                [dic setObject:textView.text forKey:KEY_ESM_USER_ANSWER];
                NSLog(@"Value is = %@", textView.text);
                if ([textView.text isEqualToString:@""]) {
                    [dic setObject:DISMISSED forKey:KEY_ESM_STATUS];
                }
                if (contents.count > 1) {
                    UIButton * naButton = [contents objectAtIndex:1];
                    if (naButton.selected) {
                        [dic setObject:@"NA" forKey:KEY_ESM_USER_ANSWER];
                        [dic setObject:ANSWERED forKey:KEY_ESM_STATUS];
                    }
                }

//                if (contents.count > 1) {
//                    UITextView * textView = [contents objectAtIndex:0];
//                    [dic setObject:textView.text forKey:KEY_ESM_USER_ANSWER];
//                    NSLog(@"Value is = %@", textView.text);
//                    UIButton * naButton = [contents objectAtIndex:1];
//                    if ([textView.text isEqualToString:@""] && !naButton.selected) {
//                        [dic setObject:DISMISSED forKey:KEY_ESM_STATUS];
//                    }
//                    if (naButton.selected) {
//                        [dic setObject:@"NA" forKey:KEY_ESM_USER_ANSWER];
//                        [dic setObject:ANSWERED forKey:KEY_ESM_STATUS];
//                    }
//                }
            }
        } else if ([type isEqualToNumber:@2]) {
            NSLog(@"Get radio data.");
            bool skip = true;
            if (contents != nil) {
                for (int i=0; i<contents.count; i++) {
                    UIButton * button = [contents objectAtIndex:i];
                    UILabel * label = [labels objectAtIndex:i];
                    if(button.selected) {
                        [dic setObject:label.text forKey:KEY_ESM_USER_ANSWER];
                        skip = false;
                    }
                }
            }
            if(skip){
                [dic setObject:DISMISSED forKey:KEY_ESM_STATUS];
            }else{
                [dic setObject:ANSWERED forKey:KEY_ESM_STATUS];
            }
        } else if ([type isEqualToNumber:@3]) {
            NSLog(@"Get check box data.");
            bool skip = true;
            if (contents != nil) {
//                NSString *result = @"";
                NSMutableArray * results = [[NSMutableArray alloc] init];
                for (int i=0; i<contents.count; i++) {
                    UIButton * button = [contents objectAtIndex:i];
                    UILabel * label = [labels objectAtIndex:i];
                    if (button.selected) {
//                        result = [NSString stringWithFormat:@"%@,%@", result , label.text];
                        if (label.text != nil) {
                            [results addObject:label.text];
                            skip = false;
                        }
                    }
                }
                [dic setObject:[self convertArrayToCSVFormat:results] forKey:KEY_ESM_USER_ANSWER];
            }
            if(skip){
                [dic setObject:DISMISSED forKey:KEY_ESM_STATUS];
            }else{
                [dic setObject:ANSWERED forKey:KEY_ESM_STATUS];
            }
        } else if ([type isEqualToNumber:@4]) {
            NSLog(@"Get likert data");
            [dic setObject:ANSWERED forKey:KEY_ESM_STATUS];
            
            NSArray * radios = (NSArray *)[esmDic objectForKey:@"esm_radios"];
            if (radios != nil) {
                if (radios.count > 0) {
                    // update esm type
                    [dic setObject:@2 forKey:KEY_ESM_TYPE];
                }
            }
            if (contents != nil) {
                if ( contents.count > 1) {
                    int selectedOption = -1;
                    for (int i = 0; i<contents.count; i++) {
                        UIButton * option = [contents objectAtIndex:i];
                        if (option.selected) {
                            selectedOption = i;
                        }
                    }
                    
                    if (selectedOption == -1) {
                        [dic setObject:DISMISSED forKey:KEY_ESM_STATUS];
                    }else{
                        [dic setObject:[NSNumber numberWithInt:selectedOption] forKey:KEY_ESM_USER_ANSWER];
                        /**
                         * =====================================================================
                         * [NOTE]: If the dic include "esm_radios". we change the value as label
                         * =====================================================================
                         */
                        NSArray * radios = (NSArray *)[esmDic objectForKey:@"esm_radios"];
                        if (radios != nil) {
                            for (int i=0; i<radios.count; i++) {
                                if (i == selectedOption) {
                                    NSString* selectedLabel = [radios objectAtIndex:i];
                                    // Set user answer
                                    [dic setObject:selectedLabel forKey:KEY_ESM_USER_ANSWER];
                                    // Change ESM type to radio button
                                    NSLog(@"selected label: %@", selectedLabel);
                                }
                                [dic setObject:@2 forKey:KEY_ESM_TYPE];
                            }
                            
                        }
                        [dic setObject:ANSWERED forKey:KEY_ESM_STATUS];
                    }
                    NSLog(@"%d", selectedOption);
                }
            }
        } else if ([type isEqualToNumber:@5]) {
            NSLog(@"Get Quick button data");
            if (contents != nil) {
                if ( contents.count > 1) {
                    // DatePicker Value
                    NSString * title = nil;
                    for (UIButton * uiButton in contents) {
                        if (uiButton.selected) {
                            title = uiButton.titleLabel.text;
                            break;
                        }
                    }
                    
                    if (title == nil) { // dismissed
                        [dic setObject:@1 forKey:KEY_ESM_STATUS];
                        [dic setObject:@"" forKey:KEY_ESM_USER_ANSWER];
                    } else if (title != nil){ // answered
                        [dic setObject:title forKey:KEY_ESM_USER_ANSWER];
                        [dic setObject:@2 forKey:KEY_ESM_STATUS];
                    }
                }
            }
        } else if ([type isEqualToNumber:@6]) {
            NSLog(@"Get Scale data");
            if (contents != nil) {
                UILabel * label = [contents objectAtIndex:0];
                if ([label.text isEqualToString:@"---"]) {
                    [dic setObject:@"" forKey:KEY_ESM_USER_ANSWER];
                    [dic setObject:@1 forKey:KEY_ESM_STATUS];
                }else{
                    [dic setObject:label.text forKey:KEY_ESM_USER_ANSWER];
                    [dic setObject:@2 forKey:KEY_ESM_STATUS];
                }
                if ( contents.count > 1) {
                    UIButton * naButton = [contents objectAtIndex:1];
                    if(naButton.selected){
                        [dic setObject:@"NA" forKey:KEY_ESM_USER_ANSWER];
                        [dic setObject:@2 forKey:KEY_ESM_STATUS];
                    }
                }
//                if ( contents.count > 1) {
//                    UILabel * label = [contents objectAtIndex:0];
//                    if ([label.text isEqualToString:@"---"]) {
//                        [dic setObject:@"" forKey:KEY_ESM_USER_ANSWER];
//                        [dic setObject:@1 forKey:KEY_ESM_STATUS];
//                    }else{
//                        [dic setObject:label.text forKey:KEY_ESM_USER_ANSWER];
//                        [dic setObject:@2 forKey:KEY_ESM_STATUS];
//                    }
//                    
//                    UIButton * naButton = [contents objectAtIndex:1];
//                    if(naButton.selected){
//                        [dic setObject:@"NA" forKey:KEY_ESM_USER_ANSWER];
//                        [dic setObject:@2 forKey:KEY_ESM_STATUS];
//                    }
//                }
            }
        } else if ([type isEqual:@7]){
            NSLog(@"Get Date Picker");
            if (contents != nil) {
                // DatePicker Value
                NSNumber *zero = @0;
                if ( [contents objectAtIndex:0] != zero ){
//                        UIDatePicker * datePicker = [contents objectAtIndex:0];
//                        double selectedDate = [datePicker.date timeIntervalSince1970];
                    [dic setObject:[[contents objectAtIndex:0] stringValue] forKey:KEY_ESM_USER_ANSWER];
                    [dic setObject:@2 forKey:KEY_ESM_STATUS];
                    NSLog(@"selecte date => %@", [contents objectAtIndex:0]);
                }else{
                    [dic setObject:@"0" forKey:KEY_ESM_USER_ANSWER];
                    [dic setObject:@1 forKey:KEY_ESM_STATUS];
                }
                if ( contents.count > 1) {
                    // Get N/A button value and set N/A condition
                    UIButton* naButton = [contents objectAtIndex:1];
                    if(naButton.selected){
                        [dic setObject:@"NA" forKey:KEY_ESM_USER_ANSWER];
                        [dic setObject:@2 forKey:KEY_ESM_STATUS];
                    }
                }
            }
        } else if ([type isEqual:@8]){ // PAM
            NSLog(@"Get PAM data");
            if (contents != nil) {
                if ( contents.count > 1) {
                    // DatePicker Value
                    int pamNumber = 0;
                    for (UIButton * uiButton in contents) {
                        if (uiButton.selected) {
                            pamNumber = [uiButton.titleLabel.text intValue];
                            break;
                        }
                    }
                    
                    if (pamNumber == 0) { // dismissed
                        [dic setObject:@1 forKey:KEY_ESM_STATUS];
                        [dic setObject:@"" forKey:KEY_ESM_USER_ANSWER];
                    } else if (pamNumber >= 1 && pamNumber <= 16){ // answered
                        NSString * emotionStr = [PamSchema getEmotionString:pamNumber];
                        [dic setObject:emotionStr forKey:KEY_ESM_USER_ANSWER];
                        [dic setObject:@2 forKey:KEY_ESM_STATUS];
                    } else {// errored
                        NSLog(@"error");
                        [dic setObject:@"" forKey:KEY_ESM_USER_ANSWER];
                        [dic setObject:@1 forKey:KEY_ESM_STATUS];
                    }
                    
                    // Get N/A button value and set N/A condition
//                    UIButton* naButton = [contents objectAtIndex:1];
//                    if(naButton.selected){
//                        [dic setObject:@"NA" forKey:KEY_ESM_USER_ANSWER];
//                        [dic setObject:@2 forKey:KEY_ESM_STATUS];
//                    }
                    
//                    NSNumber *zero = @0;
//                    if ( [contents objectAtIndex:0] != zero ){
//                        //                        UIDatePicker * datePicker = [contents objectAtIndex:0];
//                        //                        double selectedDate = [datePicker.date timeIntervalSince1970];
//                        [dic setObject:[[contents objectAtIndex:0] stringValue] forKey:KEY_ESM_USER_ANSWER];
//                        [dic setObject:@2 forKey:KEY_ESM_STATUS];
//                        NSLog(@"selecte date => %@", [contents objectAtIndex:0]);
//                    }else{
//                        [dic setObject:@"0" forKey:KEY_ESM_USER_ANSWER];
//                        [dic setObject:@1 forKey:KEY_ESM_STATUS];
//                    }
//
                }
            }
        } else {

        }
        
        // Remove "esm_na" from the dictionary
        [dic removeObjectForKey:@"esm_na"];
        [dic removeObjectForKey:@"esm_reload"];
        [dic removeObjectForKey:@"esm_style"];
        
        [array addObject:dic];
        
    }

    // Check stored ESM data
    NSLog(@"%@", array.debugDescription );
    
    bool result = [esm saveDataWithArray:array];
    
    if ( result ) {

        ESMStorageHelper * helper = [[ESMStorageHelper alloc] init];
//        [helper removeEsmWithText:currentTextOfEsm];
        
        /**
         * If the device has other ESM.
         */
//        if([helper getEsmTexts].count > 0){
//            [self viewDidAppear:NO];
//            return ;
//        }else{
//            [esm performSelector:@selector(syncAwareDB) withObject:0 afterDelay:5];
//        }
        esmNumber++;
        if([helper getNumberOfStoredESMs] > esmNumber){
            [self viewDidAppear:NO];
            return ;
        }else{
            // Thank You!!
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank for submitting your answer!"
                                                            message:@""
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
            esmNumber = 0;
            [esm setUploadingState:NO]; //TEST
            [esm performSelector:@selector(syncAwareDB) withObject:0 afterDelay:5];
        }

        [self.navigationController popToRootViewControllerAnimated:YES];
        
//        CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
//        if (currentVersion >= 9.0) {
////            [self.navigationController.navigationBar setDelegate:self];
//            [self.navigationController popToRootViewControllerAnimated:YES];
//        } else{
//            [self dismissViewControllerAnimated:YES completion:nil];
//            [self viewDidAppear:NO];
//        }
       
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AWARE can not save your answer" message:@"Please push submit button again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method stores the esm answerds to local database with esm_status=2(dissmissed).
 * And also, this method calls when a user push "cancel" button.
 */
- (void) pushedCancelButton:(id) senser {
    NSLog(@"Cancel button was pushed!");
    
    // If the local esm storage stored some esms,(1)AWARE iOS save the answer as cancel(dismiss). In addition, (2)UI view moves to a next stored esm.
    // Answers object
    NSMutableArray *answers = [[NSMutableArray alloc] init];
    
    // Create
    ESM *esm = [[ESM alloc] initWithAwareStudy:study dbType:AwareDBTypeTextFile];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSString *deviceId = [esm getDeviceId];
    for (int i=0; i<uiElements.count; i++) {
        NSDictionary *esmDic = [[uiElements objectAtIndex:i] objectForKey:KEY_OBJECT];
        NSMutableDictionary *dic = [self getEsmFormatDictionary:(NSMutableDictionary *)esmDic
                                                   withTimesmap:unixtime
                                                        devieId:deviceId];
//        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:deviceId forKey:@"device_id"];
        // set answerd timestamp with KEY_ESM_USER_ANSWER_TIMESTAMP
        [dic setObject:unixtime forKey:KEY_ESM_USER_ANSWER_TIMESTAMP];
        // Set "dismiss" status to KEY_ESM_STATUS. //TODO: Check!
        [dic setObject:@1 forKey:KEY_ESM_STATUS];
        // Add the esm to answer object.
        [answers addObject:dic];
    }
    // Save the answers to the local storage.
    [esm saveDataWithArray:answers];
    // Sync with AWARE database immediately
    [esm performSelector:@selector(syncAwareDB) withObject:0 afterDelay:5];
    
    // Remove the answerd ESM from local storage.
     ESMStorageHelper * helper = [[ESMStorageHelper alloc] init];
//     [helper removeEsmWithText:currentTextOfEsm];
    
    // If the local esm storage is empty, the UIView move to the top-page.
//    if([helper getEsmTexts].count > 0){
//        [self viewDidAppear:NO];
//        return ;
//    }
    esmNumber++;
    if([helper getNumberOfStoredESMs] > esmNumber){
        [self viewDidAppear:NO];
        return;
    }else{
        esmNumber = 0;
    }
    
    [self.navigationController popToRootViewControllerAnimated:YES];

//    CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
//    if (currentVersion >= 9.0) {
//                    [self.navigationController.navigationBar setDelegate:self];
//        [self.navigationController popToRootViewControllerAnimated:YES];
//    } else{
//        [self dismissViewControllerAnimated:YES completion:nil];
//        [self viewDidAppear:NO];
//    }
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method creates a complemented ESM safely for storing the ESM Object to the localstorage.
 *
 * @param originalDic A NSNutableDictionary with insufficie elements
 * @param unixtime A current timestamp
 * @param deviceId A evice_id for an aware study
 * @return A complemented ESM NSMutableDictionary
 */
- (NSMutableDictionary *) getEsmFormatDictionary:(NSMutableDictionary *)originalDic
                                    withTimesmap:(NSNumber *)unixtime
                                         devieId:(NSString*) deviceId{
    // make base dictionary from SingleEsmObject with device ID and timestamp
//    SingleESMObject *singleObject = [[SingleESMObject alloc] init];
    NSMutableDictionary * dic = [SingleESMObject getEsmDictionaryWithDeviceId:deviceId
                                                                 timestamp:[unixtime doubleValue]
                                                                      type:@0
                                                                     title:@""
                                                              instructions:@""
                                                                    submit:@""
                                                       expirationThreshold:@0
                                                                   trigger:@""];
    
    [dic setObject:@"" forKey:KEY_ESM_RADIOS];
    [dic setObject:@"" forKey:KEY_ESM_CHECKBOXES];
    [dic setObject:@"" forKey:KEY_ESM_QUICK_ANSWERS];
    for (id key in [originalDic keyEnumerator]) {
        //        NSLog(@"Key: %@ => Value:%@" , key, [originalDic objectForKey:key]);
        if([key isEqualToString:KEY_ESM_RADIOS]){
            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_RADIOS];
        }else if([key isEqualToString:KEY_ESM_CHECKBOXES]){
            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_CHECKBOXES];
        }else if([key isEqualToString:KEY_ESM_QUICK_ANSWERS]){
            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_QUICK_ANSWERS];
        }else{
            NSObject *object = [originalDic objectForKey:key];
            if (object == nil) {
                object = @"";
            }
            [dic setObject:object forKey:key];
        }
    }
    return dic;
}


/**
 * This method converts NSArray object to JSON array string.
 * @param array NSArray Object (e.g., the value of esm_radios, esm_checkboxes, and esm_quick_answers.)
 * @return A JSON format string (["a","b", "c"])
 */
- (NSString* ) convertArrayToCSVFormat:(NSArray *) array {
    if (array == nil || array.count == 0){
        return @"";
    }
    NSError * error;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    NSString* jsonString = [[NSString alloc] initWithData:jsondata encoding:NSUTF8StringEncoding];
    if ([jsonString isEqualToString:@""] || jsonString == nil) {
        return @"[]";
    }
    
    return jsonString;
}


/**
 * This method is managing a total height of the ESM elemetns and a size of the base scroll view. You should call this method if you add a new element to the _mainScrollView.
 */
- (void) setContentSizeWithAdditionalHeight:(int) additionalHeight {
    totalHight += additionalHeight;
    [_mainScrollView setContentSize:CGSizeMake(WIDTH_VIEW, totalHight)];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL) getNaStateFromDict:(NSDictionary *)dict{
    bool isExist = [dict.allKeys containsObject:@"esm_na"];
    if (isExist) {
        return [[dict objectForKey:@"esm_na"] boolValue];
    }else{
        return YES;
    }
}


@end
