//
//  WebESMViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/17/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "IOSESMViewController.h"
#import "ESM.h"
#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "SingleESMObject.h"
#import "ESMStorageHelper.h"
#import "AWAREDelegate.h"
#import "IOSESM.h"
#import "EntityESMHistory.h"
#import "EntityESM+CoreDataClass.h"

#import "PamSchema.h"
#import "QuartzCore/CALayer.h"
#import "EntityESMAnswer.h"
#import "AWARESensorManager.h"

#import "SVProgressHUD.h"
#import "BalacnedCampusESMScheduler.h"
#import "EntityESMAnswerBC+CoreDataClass.h"

@implementation IOSESMViewController
{
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
    
    // WebESM * webESM;
    IOSESM * iOSESM;
    BalacnedCampusESMScheduler * bcESM;
    NSArray * esmSchedules;
    int currentESMNumber;
    int currentESMScheduleNumber;
    
    NSObject * observer;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
    
//    webESM = [[WebESM alloc] initWithAwareStudy:study dbType:AwareDBTypeCoreData];
//    [webESM allowsCellularAccess];
//    [webESM allowsDateUploadWithoutBatteryCharging];

    iOSESM = [[IOSESM alloc] initWithAwareStudy:study dbType:AwareDBTypeCoreData];
    [iOSESM allowsCellularAccess];
    [iOSESM allowsDateUploadWithoutBatteryCharging];
    
    // WIP
    bcESM = [[BalacnedCampusESMScheduler alloc] initWithAwareStudy:study dbType:AwareDBTypeCoreData];
    [bcESM allowsCellularAccess];
    [bcESM allowsDateUploadWithoutBatteryCharging];
    
    currentESMNumber = 0;
    currentESMScheduleNumber = 0;
    
    [_mainScrollView setBackgroundColor:[UIColor whiteColor]];
    
    observer = [[NSNotificationCenter defaultCenter]
                addObserverForName:ACTION_AWARE_DATA_UPLOAD_PROGRESS
                object:nil
                queue:nil
                usingBlock:^(NSNotification *notif) {
                    if ([[notif.userInfo objectForKey:@"KEY_UPLOAD_SENSOR_NAME"] isEqualToString:SENSOR_PLUGIN_WEB_ESM] ||
                        [[notif.userInfo objectForKey:@"KEY_UPLOAD_SENSOR_NAME"] isEqualToString:@"esms"] ||
                        [[notif.userInfo objectForKey:@"KEY_UPLOAD_SENSOR_NAME"] isEqualToString:SENSOR_PLUGIN_IOS_ESM] ||
                        [[notif.userInfo objectForKey:@"KEY_UPLOAD_SENSOR_NAME"] isEqualToString:SENSOR_PLUGIN_CAMPUS]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"%@", notif.debugDescription);
                            
                            BOOL uploadSuccess = [[notif.userInfo objectForKey:@"KEY_UPLOAD_SUCCESS"] boolValue];
                            BOOL uploadFin = [[notif.userInfo objectForKey:@"KEY_UPLOAD_FIN"] boolValue];
                            
                            // uploadSuccess = NO; // ** Just for TEST **
                            
                            if( uploadFin == YES && uploadSuccess == YES ){
                                [SVProgressHUD dismiss];
                                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Submission is succeeded!" message:@"Thank you for your submission." preferredStyle:UIAlertControllerStyleAlert];
                                
                                [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                    esmNumber = 0;
                                    currentESMNumber = 0;
                                    currentESMScheduleNumber = 0;
                                    [self.navigationController popToRootViewControllerAnimated:YES];
                                }]];
                                [self presentViewController:alertController animated:YES completion:nil];
                                
                            //}else if(uploadFin == YES &&  uploadSuccess == NO){
                            }else if(uploadSuccess == NO){
                                [SVProgressHUD dismiss];
                                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"** Submission is failed! **" message:@"Please submit your answer again." preferredStyle:UIAlertControllerStyleAlert];
                                alertController.view.subviews.firstObject.backgroundColor = [UIColor redColor];
                                alertController.view.subviews.firstObject.layer.cornerRadius = 15;
                                alertController.view.subviews.firstObject.tintColor = [UIColor whiteColor];
                                
                                [alertController addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                                    // [self.navigationController popToRootViewControllerAnimated:YES];
                                }]];
                                [self presentViewController:alertController animated:YES completion:nil];
                            }else{
                                
                            }
                        });
                    }
                }];
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
    // esms = [webESM getValidESMsWithDatetime:[NSDate new]];
    esmSchedules = [iOSESM getValidESMSchedulesWithDatetime:[NSDate new]];
    if(esmSchedules != nil && esmSchedules.count > currentESMScheduleNumber){
        
        EntityESMSchedule * esmSchedule = esmSchedules[currentESMScheduleNumber];
        NSLog(@"[interface: %@]", esmSchedule.interface);
        NSSet * childEsms = esmSchedule.esms;
        // NSNumber * interface = schedule.interface;
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"esm_number" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sort,nil];
        NSArray *sortedEsms = [childEsms sortedArrayUsingDescriptors:sortDescriptors];
        
        if([esmSchedule.interface isEqualToNumber:@1]){
            // self.navigationItem.title = esmSchedule.schedule_id;
            int tag = 0;
            for (EntityESM * esm in sortedEsms) {
                // "interface is 1 (multiple esm)"
                EntityESM * loopESM = esm;
                // The loop is broken if this element 's interface is 0.
                [self setEsm:loopESM withTag:tag button:NO];
                tag++;
            }
            // Submit button be shown if the element is the last one.
            [self setSubmitButton];
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %d/%ld",
                                         esmSchedule.schedule_id,
                                         currentESMScheduleNumber+1,
                                         esmSchedules.count];
        }else{
            [self setEsm:sortedEsms[currentESMNumber] withTag:0 button:YES];
            self.navigationItem.title = [NSString stringWithFormat:@"%@(%d/%ld) - %d/%ld",
                                         esmSchedule.schedule_id,
                                         currentESMNumber+1,
                                         sortedEsms.count,
                                         currentESMScheduleNumber+1,
                                         esmSchedules.count];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    if (observer != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
}

- (void) setEsm:(EntityESM *)esm withTag:(int)tag button:(bool)buttonState{
    // Set ESM Elements
    NSLog(@"====== Hello ESM !! =======");
    NSLog(@"Interface Type: %@",esm.interface);
    
    //NSDictionary * dic = [oneEsmObject objectForKey:@"esm"];
    //The ESM type (1-free text, 2-radio, 3-checkbox, 4-likert, 5-quick, 6-scale)
    NSNumber* type = esm.esm_type; //[dic objectForKey:KEY_ESM_TYPE];
    switch ([type intValue]) {
        case 1: // free text
            NSLog(@"Add free text");
            [self addFreeTextElement:esm withTag:tag];
            break;
        case 2: // radio
            NSLog(@"Add radio");
            [self addRadioElement:esm withTag:tag];
            break;
        case 3: // checkbox
            NSLog(@"Add check box");
            [self addCheckBoxElement:esm withTag:tag];
            break;
        case 4: // likert
            NSLog(@"Add likert");
            [self addLikertScaleElement:esm withTag:tag];
            break;
        case 5: // quick
            NSLog(@"Add quick");
            //                quick = YES;
            [self addQuickAnswerElement:esm withTag:tag];
            break;
        case 6: // scale
            NSLog(@"Add scale");
            [self addScaleElement:esm withTag:tag];
            break;
        case 7: //timepicker
            NSLog(@"Timer Picker");
            [self addTimePickerElement:esm withTag:tag];
            break;
        case 8: //PAM
            NSLog(@"PAM");
            [self addPAMElement:esm withTag:tag];
            break;
        case 9: // Web Page
            NSLog(@"Web Page");
            [self addWebPageElement:esm withTag:tag];
            break;
        default:
            break;
    }
    [self addNullElement];
    [self addLineElement];

    
    if (buttonState) {
        [self addNullElement];
        [self addSubmitButtonWithText:esm.esm_submit];
        [self addNullElement];
        [self addCancelButtonWithText:@"Cancel"];
        [self addNullElement];
    }
}

- (void) setSubmitButton {
    [self addNullElement];
    [self addSubmitButtonWithText:@"Submit"];
    [self addNullElement];
    [self addCancelButtonWithText:@"Cancel"];
    [self addNullElement];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * esm_type=1 : Add a Free Text element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addFreeTextElement:(EntityESM *)esm withTag:(int) tag
{
    [self addCommonContents:esm];
    
    UITextView * textView = [[UITextView alloc] initWithFrame:CGRectMake(mainContentRect.origin.x, totalHight, mainContentRect.size.width, mainContentRect.size.height)];
    textView.layer.borderWidth = 1.0f;
    textView.layer.cornerRadius = 5.0f;
    //    [textView.layer setBorderColor:(__bridge CGColorRef _Nullable)([UIColor lightGrayColor])];
    [freeTextViews addObject:textView];
    [textView setDelegate:self];
    
    // @"esm_na"
    if (esm.esm_na.boolValue) {
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
        [uiElement setObject:esm forKey:KEY_OBJECT];
        
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
        [uiElement setObject:esm forKey:KEY_OBJECT];
        
        [uiElements addObject:uiElement];
    }
}


/**
 * esm_type=2 : Add a Radio Element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_radios, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addRadioElement:(EntityESM *) esm withTag:(int) tag {
    [self addCommonContents:esm];
    
    NSMutableArray *elements = [[NSMutableArray alloc] init];
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    
    NSArray * radios = [self convertJsonStringToArray:esm.esm_radios]; //[dic objectForKey:KEY_ESM_RADIOS];
    
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
    [uiElement setObject:esm forKey:KEY_OBJECT];
    
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
- (void) addCheckBoxElement:(EntityESM *) esm withTag:(int) tag{
    [self addCommonContents:esm];
    NSMutableArray *elements = [[NSMutableArray alloc] init];
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    
    NSArray * checkBoxItems = [self convertJsonStringToArray:esm.esm_checkboxes]; // [dic objectForKey:KEY_ESM_CHECKBOXES];
    
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
    [uiElement setObject:esm forKey:KEY_OBJECT];
    
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
- (void) addLikertScaleElement:(EntityESM *) esm withTag:(int) tag {
    [self addCommonContents:esm];
    
    NSMutableArray* elements = [[NSMutableArray alloc] init];
    NSMutableArray* labels = [[NSMutableArray alloc] init];
    
    NSNumber *max = esm.esm_likert_max; //[dic objectForKey:KEY_ESM_LIKERT_MAX];
    UIView* ratingView = [[UIView alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+60,
                                                                  totalHight,
                                                                  mainContentRect.size.width-120,
                                                                  60)];

    
    // Add  min/max/slider value
    UILabel *minLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x,
                                                                  totalHight + ratingView.frame.size.height/2,
                                                                  60, ratingView.frame.size.height/2)];
    UILabel *maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+mainContentRect.size.width -60,
                                                                  totalHight + ratingView.frame.size.height/2,
                                                                  60, ratingView.frame.size.height/2)];
    
    minLabel.adjustsFontSizeToFitWidth = YES;
    maxLabel.adjustsFontSizeToFitWidth = YES;
    
    minLabel.text = esm.esm_likert_min_label; // [dic objectForKey:KEY_ESM_SCALE_MIN_LABEL];
    maxLabel.text = esm.esm_likert_max_label; // [dic objectForKey:KEY_ESM_SCALE_MAX_LABEL];
    
    minLabel.textAlignment = NSTextAlignmentCenter;
    maxLabel.textAlignment = NSTextAlignmentCenter;
    
    [_mainScrollView addSubview:minLabel];
    [_mainScrollView addSubview:maxLabel];

    // Check "NA" state.
    if(esm.esm_na.boolValue){ // NA is true
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
    [uiElement setObject:esm forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
}

- (void) pushedLikertButton:(UIButton *) sender {
    NSNumber * tag = [NSNumber numberWithInteger:sender.tag];
    // NSLog(@"selected item: %@",tag);
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
- (void) addQuickAnswerElement:(EntityESM *) esm withTag:(int) tag{
    [self addCommonContents:esm];
    NSMutableArray *elements = [[NSMutableArray alloc] init];
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    
    NSArray * options = [self convertJsonStringToArray:esm.esm_quick_answers];
    
    for (NSString* answer in options) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(mainContentRect.origin.x, totalHight, buttonRect.size.width, buttonRect.size.height)];
        [button setTitle:answer forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor lightGrayColor]];
        [button addTarget:self action:@selector(pushedQuickAnswerButtons:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = tag;
        [_mainScrollView addSubview:button];
        [self setContentSizeWithAdditionalHeight:buttonRect.size.height + 5];
        [elements addObject:button];
        [labels addObject:answer];
    }
    
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@5 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:esm forKey:KEY_OBJECT];
    
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
- (void) addScaleElement:(EntityESM *) esm withTag:(int) tag{
    int valueLabelH = 30;
    int mainContentH = 30;
    int naH = 30;
    int spaceH = 10;
    [self addCommonContents:esm];
    // Add a value label
    // UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+60, totalHight, mainContentRect.size.width-120, valueLabelH)];
    UITextField *valueLabel = [[UITextField alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+60,
                                                                            totalHight,
                                                                            mainContentRect.size.width-120,
                                                                            valueLabelH)];
    [valueLabel setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
    [valueLabel addTarget:self action:@selector(changeTextFieldValue:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [valueLabel addTarget:self action:@selector(touchDownTextFiledValue:) forControlEvents:UIControlEventEditingDidBegin];
    // valueLabel.tag = tag;
    
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
    
    // NSNumber *max = [dic objectForKey:KEY_ESM_SCALE_MAX];
    // NSNumber *min = [dic objectForKey:KEY_ESM_SCALE_MIN];
    // NSNumber *start = [dic objectForKey:KEY_ESM_SCALE_START];
    
    slider.maximumValue = esm.esm_scale_max.floatValue; // [max floatValue];
    slider.minimumValue = esm.esm_scale_min.floatValue; //[min floatValue];
    float value = esm.esm_scale_start.floatValue;
    slider.value = value; // [start floatValue];
    slider.tag = tag;
    [slider addTarget:self action:@selector(setNaBoxFolse:) forControlEvents:UIControlEventTouchUpInside];
    
    
    valueLabel.text = @"---";
    valueLabel.tag = totalHight;
    minLabel.text = esm.esm_scale_min_label; // [dic objectForKey:KEY_ESM_SCALE_MIN_LABEL];
    maxLabel.text = esm.esm_scale_max_label; // [dic objectForKey:KEY_ESM_SCALE_MAX_LABEL];
    
    valueLabel.textAlignment = NSTextAlignmentCenter;
    minLabel.textAlignment = NSTextAlignmentCenter;
    maxLabel.textAlignment = NSTextAlignmentCenter;
    
    
    
    // NA
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
    [naCheckBox addTarget:self action:@selector(pushedNaBox:) forControlEvents:UIControlEventTouchUpInside];

    
    [_mainScrollView addSubview:valueLabel];
    [_mainScrollView addSubview:slider];
    [_mainScrollView addSubview:maxLabel];
    [_mainScrollView addSubview:minLabel];
    if(esm.esm_na.boolValue){
        [_mainScrollView addSubview:naCheckBox];
        [_mainScrollView addSubview:label];
    }
    
    [self setContentSizeWithAdditionalHeight:valueLabelH + mainContentH + spaceH + naH];
    
    NSMutableArray * elements = [[NSMutableArray alloc] init];
    NSMutableArray * labels = [[NSMutableArray alloc] init];
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    //    [elements addObject:slider];
    [elements addObject:valueLabel]; // for detect
    if(esm.esm_na.boolValue)[elements addObject:naCheckBox];
    [labels addObject:maxLabel];
    if(esm.esm_na.boolValue)[labels addObject:label];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@6 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:esm forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
    [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
}


- (IBAction)sliderChanged:(UISlider *)sender {
    // NSLog(@"slider value = %f", sender.value);
    double value = sender.value;
    NSInteger tag = sender.tag;
    if(uiElements.count >= tag ){
        EntityESM *esm = [[uiElements objectAtIndex:tag] objectForKey:KEY_OBJECT];
        NSNumber * step = esm.esm_scale_step;
        
        if([step isEqual:@0.1]){
            double tempValue = value*10;
            int intValue = tempValue/10;
            [sender setValue:intValue];
            UITextField * textField = [_mainScrollView viewWithTag:sender.frame.origin.y-30];
            [textField setText:[NSString stringWithFormat:@"%0.1f", value]];
        }else{
            [sender setValue:(int)value];
            UITextField * textField = [_mainScrollView viewWithTag:sender.frame.origin.y-30];
            [textField setText:[NSString stringWithFormat:@"%d", (int)value]];
        }
    }
    // NSArray * contents = [[uiElements objectAtIndex:tag] objectForKey:KEY_ELEMENT];
    // NSArray * labels = [[uiElements objectAtIndex:tag] objectForKey:KEY_LABLES];
}


- (IBAction) changeTextFieldValue:(UITextField *) textField {
//    // Get value from text field and convert the text format value to float format
//    NSString * text = textField.text;
//    float floatValue = text.floatValue;
//    if( floatValue == 0 ||  ){
//        textField.text = [NSString stringWithFormat:@"0"];
//    }
    
//    if(uiElements.count >= tag ){
//        EntityESM *esm = [[uiElements objectAtIndex:tag] objectForKey:KEY_OBJECT];
//        NSNumber * step = esm.esm_scale_step;
//        if([step isEqual:@0.1]){
//            textField.text = [NSString stringWithFormat:@"%0.1f", floatValue];
//        }else{
//            textField.text = [NSString stringWithFormat:@"%d", (int)floatValue];
//        }
//    }
}


- (IBAction) touchDownTextFiledValue:(UITextField *) textField{
    NSString * text = textField.text;
    if([text isEqualToString:@"---"] ||
       [text isEqualToString:@"--"] ||
       [text isEqualToString:@"-"]){
        textField.text = @"";
    }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////


/**
 * esm_type=7 : Add a Time Picker (WIP)
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addTimePickerElement:(EntityESM *)esm withTag:(int) tag{
    [self addCommonContents:esm];
    UIDatePicker * datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(mainContentRect.origin.x,
                                                                               totalHight,
                                                                               mainContentRect.size.width, 100)];
    //    datePicker.date = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    datePicker.tag = tag;
    // datePicker.minuteInterval = 30; //TODO
    [datePicker addTarget:self
                   action:@selector(setDateValue:)
         forControlEvents:UIControlEventValueChanged];
    
    int datePickerHight = datePicker.frame.size.height;
    
    
    // NA
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
    if(esm.esm_na.boolValue)[_mainScrollView addSubview:naCheckBox];
    if(esm.esm_na.boolValue)[_mainScrollView addSubview:label];
    [self setContentSizeWithAdditionalHeight:datePickerHight + 10 + 30];
    
    
    NSMutableArray * elements = [[NSMutableArray alloc] init];
    NSMutableArray * labels = [[NSMutableArray alloc] init];
    NSNumber * datetime = [[NSNumber alloc] initWithInt:0];
    [elements addObject:datetime];
    if(esm.esm_na.boolValue)[elements addObject:naCheckBox];
    
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@7 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:esm forKey:KEY_OBJECT];
    
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

- (void) addPAMElement:(EntityESM *)esm withTag:(int)tag{
    [self addCommonContents:esm];
    
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
    [uiElement setObject:esm forKey:KEY_OBJECT];
    [uiElements addObject:uiElement];
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



/**
 *
 *
 *
 */

- (void) addWebPageElement:(EntityESM *)esm withTag:(int) tag {
    
    [self addCommonContents:esm];
    
    UIWebView * webView =  [[UIWebView alloc] initWithFrame:CGRectMake(mainContentRect.origin.x, totalHight, mainContentRect.size.width, mainContentRect.size.height*3)];
    NSString *path = esm.esm_url;
    NSURL *url = [NSURL URLWithString:path];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [webView loadRequest:req];
    
    [_mainScrollView addSubview:webView];
    [self setContentSizeWithAdditionalHeight:webView.frame.size.height + 10 + 30];
    
    NSMutableArray * elements = [[NSMutableArray alloc] init];
    NSMutableArray * labels = [[NSMutableArray alloc] init];
    // NSNumber * datetime = [[NSNumber alloc] initWithInt:0];
    // [elements addObject:datetime];
    // if(naState)[elements addObject:naCheckBox];
    
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@9 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:esm forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
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
- (void) addCommonContents:(EntityESM *) esm {
    //  make each content
    [self addTitleWithText: esm.esm_title ];//[dic objectForKey:KEY_ESM_TITLE]];
    [self addInstructionsWithText: esm.esm_instructions ];//[dic objectForKey:KEY_ESM_INSTRUCTIONS]];
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
    
    // NSNumber *NEW = @0;
    NSNumber *DISMISSED = @1;
    NSNumber *ANSWERED = @2;
    NSString * NA = @"NA";
    // NSNumber *EXPIRED = @3;
    
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    // the status of the ESM (0-new, 1-dismissed, 2-answered, 3-expired) -> Defualt is zero(0).
    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = delegate.persistentStoreCoordinator;
    
    NSMergePolicy *originalMergePolicy = context.mergePolicy;
    context.mergePolicy = NSOverwriteMergePolicy;

    
    for (int i=0; i<uiElements.count; i++) {
        
        NSLog(@"Number of UI Elements: %ld", uiElements.count);
        
        EntityESM *esm = [[uiElements objectAtIndex:i] objectForKey:KEY_OBJECT];
        NSArray * contents = [[uiElements objectAtIndex:i] objectForKey:KEY_ELEMENT];
        NSArray * labels = [[uiElements objectAtIndex:i] objectForKey:KEY_LABLES];

        NSNumber* type = esm.esm_type; // [esmDic objectForKey:KEY_ESM_TYPE];
        NSString * esmUserAnswer = @"";
        NSNumber * esmState = DISMISSED;
        
        // save each data to the dictionary
        ///////////// Free Test //////////////////
        if ([type isEqualToNumber:@1]) {
            NSLog(@"Get free text data.");
            if (contents != nil) {
                UITextView * textView = [contents objectAtIndex:0];
                // answer.esm_user_answer = textView.text;
                esmUserAnswer = textView.text;
                esmState = ANSWERED;
                NSLog(@"Value is = %@", textView.text);
                if ([textView.text isEqualToString:@""]) {
                    //answer.esm_status = DISMISSED;
                    esmState = DISMISSED;
                }
                if (contents.count > 1) {
                    UIButton * naButton = [contents objectAtIndex:1];
                    if (naButton.selected) {
                        //answer.esm_user_answer = @"NA";
                        // answer.esm_status = ANSWERED;
                        esmUserAnswer = NA;
                        esmState = ANSWERED;
                    }
                }
            }
        //////////////// Radio Button ////////////////
        } else if ([type isEqualToNumber:@2]) {
            NSLog(@"Get radio data.");
            bool skip = true;
            NSString * selectedItem = @"";
            if (contents != nil) {
                for (int i=0; i<contents.count; i++) {
                    UIButton * button = [contents objectAtIndex:i];
                    UILabel * label = [labels objectAtIndex:i];
                    if(button.selected) {
                        selectedItem = label.text;
                        skip = false;
                    }
                }
            }
            if(skip){
                //answer.esm_user_answer = @"";
                //answer.esm_status = DISMISSED;
                esmUserAnswer = @"";
                esmState = DISMISSED;
            }else{
                //answer.esm_user_answer = selectedItem;
                //answer.esm_status = ANSWERED;
                esmUserAnswer = selectedItem;
                esmState = ANSWERED;
            }
        /////////////// Check Box //////////////////
        } else if ([type isEqualToNumber:@3]) {
            NSLog(@"Get check box data.");
            NSString * selectedItemsStr = @"";
            bool skip = true;
            if (contents != nil) {
                //                NSString *result = @"";
                NSMutableArray * results = [[NSMutableArray alloc] init];
                for (int i=0; i<contents.count; i++) {
                    UIButton * button = [contents objectAtIndex:i];
                    UILabel * label = [labels objectAtIndex:i];
                    if (button.selected) {
                        if (label.text != nil) {
                            [results addObject:label.text];
                            skip = false;
                        }
                    }
                }
                selectedItemsStr = [self convertArrayToCSVFormat:results];
            }
            if(skip){
                esmUserAnswer = @"";
                esmState = DISMISSED;
            }else{
                esmUserAnswer = selectedItemsStr;
                esmState = ANSWERED;
            }
        ////////////////// Likert Scale ////////////////////
        } else if ([type isEqualToNumber:@4]) {
            NSLog(@"Get likert data");
            if (contents != nil) {
                if ( contents.count > 1) {
                    // Get seleted option
                    int selectedOption = -1;
                    for (int i = 0; i<contents.count; i++) {
                        UIButton * option = [contents objectAtIndex:i];
                        if (option.selected) {
                            selectedOption = i;
                        }
                    }
                    
                    if (selectedOption == -1) {
                        esmUserAnswer = @"";
                        esmState = DISMISSED;
                    }else{
                        /**
                         * ========================================================================================
                         * [NOTE]: If the dic include "esm_radios", we have to change the value to the label's text
                         * ========================================================================================
                         */
                        esmUserAnswer = @(selectedOption).stringValue;
                        esmState = ANSWERED;
                        NSLog(@"%d", selectedOption);
                        
                        NSArray * radios = [self convertJsonStringToArray:esm.esm_radios]; //(NSArray *)[esmDic objectForKey:@"esm_radios"];
                        if (radios != nil) {
                            for (int i=0; i<radios.count; i++) {
                                if (i == selectedOption) {
                                    NSString* selectedLabel = [radios objectAtIndex:i];
                                    // Set user answer
                                    // [dic setObject:selectedLabel forKey:KEY_ESM_USER_ANSWER];
                                    // Change ESM type to radio button
                                    // answer.esm_user_answer = selectedLabel;
                                    esmUserAnswer = selectedLabel;
                                    NSLog(@"selected label: %@", selectedLabel);
                                }
                            }
                        }
                    }
                }
            }
        /////////////// Quick Button ///////////////////
        } else if ([type isEqualToNumber:@5]) {
            NSLog(@"Get Quick button data");
            if (contents != nil) {
                if ( contents.count > 1) {
                    // Quick Answer Button
                    NSString * selectedItem = nil;
                    for (UIButton * uiButton in contents) {
                        if (uiButton.selected) {
                            selectedItem = uiButton.titleLabel.text;
                            break;
                        }
                    }
                    
                    if (selectedItem == nil) { // dismissed
//                        answer.esm_user_answer = @"";
//                        answer.esm_status = DISMISSED;
                        esmUserAnswer = @"";
                        esmState = DISMISSED;
                    } else if (selectedItem != nil){ // answered
//                        answer.esm_user_answer = selectedItem;
//                        answer.esm_status = ANSWERED;
                        esmUserAnswer = selectedItem;
                        esmState = ANSWERED;
                    }
                }
            }
        /////////////// Scale ////////////////////////
        } else if ([type isEqualToNumber:@6]) {
            NSLog(@"Get Scale data");
            if (contents != nil) {
                UILabel * label = [contents objectAtIndex:0];
                if ([label.text isEqualToString:@"---"]) {
                    esmUserAnswer = @"";
                    esmState = DISMISSED;
                }else{
                    esmUserAnswer = label.text;
                    esmState = ANSWERED;
                }
                
                if ( contents.count > 1) {
                    UIButton * naButton = [contents objectAtIndex:1];
                    if(naButton.selected){
                        esmUserAnswer = NA;
                        esmState = ANSWERED;
                    }
                }
            }
        ///////////// Date Picker ///////////////////
        } else if ([type isEqual:@7]){
            NSLog(@"Get Date Picker");
            if (contents != nil) {
                // DatePicker Value
                NSNumber *zero = @0;
                if ( [contents objectAtIndex:0] != zero ){
                    NSString * strTimestamp = [[contents objectAtIndex:0] stringValue];
                    esmUserAnswer = strTimestamp;
                    esmState = ANSWERED;
                    NSLog(@"selecte date => %@", [contents objectAtIndex:0]);
                }else{
                    esmUserAnswer = @"";
                    esmState = DISMISSED;
                }
                if ( contents.count > 1) {
                    // Get N/A button value and set N/A condition
                    UIButton* naButton = [contents objectAtIndex:1];
                    if(naButton.selected){
                        esmUserAnswer = NA;
                        esmState = ANSWERED;
                    }
                }
            }
        ///////////////// PAM /////////////////////////
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
                    
                    if(pamNumber >= 1 && pamNumber <= 16){ // answered
                        NSString * emotionStr = [PamSchema getEmotionString:pamNumber];
                        esmUserAnswer = emotionStr;
                        esmState = ANSWERED;
                    } else {// errored
                        NSLog(@"dissmiss");
                        esmUserAnswer = @"";
                        esmState = DISMISSED;
                    }
                }
            }
        /////////////////// web page //////////////////
        } else if ( [type isEqual:@9]){
            esmUserAnswer = @"";
            esmState = ANSWERED;
        } else {
            
        }
        
        ///////////////////////////////////////////////////
        
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSString * deviceId = [study getDeviceId];
        
        if([IOSESM getTableVersion] == 1){
            EntityESMAnswerBC * answer = (EntityESMAnswerBC *)
            [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMAnswerBC class])
                                          inManagedObjectContext:context];
            // add special data to dic from each uielements
            // 24 items
            NSLog(@"--> %@", esm.debugDescription);
            
            answer.timestamp = esm.timestamp;
            
            answer.double_esm_user_answer_timestamp = unixtime;
            answer.device_id = deviceId;
            answer.esm_user_answer = esmUserAnswer;
            if(answer.esm_user_answer == nil) answer.esm_user_answer = @"";
            answer.esm_type = type;
            if(answer.esm_type == nil) answer.esm_type = @0;
            answer.esm_trigger = esm.esm_trigger;
            if(answer.esm_trigger == nil) answer.esm_trigger = @"";
            ////////////////////////////////////////////
            answer.esm_title = esm.esm_title;
            if(answer.esm_title == nil) answer.esm_title = @"";
            answer.esm_status  = esmState;
            if(answer.esm_status == nil) answer.esm_status = DISMISSED;
            answer.esm_instructions = esm.esm_instructions;
            if(answer.esm_instructions == nil) answer.esm_instructions = @"";
            answer.esm_expiration_threshold = esm.esm_expiration_threshold;
            if(answer.esm_expiration_threshold == nil) answer.esm_expiration_threshold = @0;
            answer.esm_submit = esm.esm_submit;
            if(answer.esm_submit == nil) answer.esm_submit = @"";
            //////////////////////
            answer.esm_scale_step = esm.esm_scale_step;
            if(answer.esm_scale_step == nil) answer.esm_scale_step = @0;
            answer.esm_scale_start = esm.esm_scale_start;
            if(answer.esm_scale_start == nil) answer.esm_scale_start = @0;
            answer.esm_scale_min = esm.esm_scale_min;
            if(answer.esm_scale_min == nil) answer.esm_scale_min = @0;
            answer.esm_scale_max = esm.esm_scale_max;
            if(answer.esm_scale_max == nil) answer.esm_scale_max = @0;
            answer.esm_scale_min_label = esm.esm_scale_min_label;
            if(answer.esm_scale_min_label == nil) answer.esm_scale_min_label = @"";
            answer.esm_scale_max_label = esm.esm_scale_max_label;
            if(answer.esm_scale_max_label == nil)answer.esm_scale_max_label = @"";
            //////////////////////
            answer.esm_radios = esm.esm_radios;
            if(answer.esm_radios == nil) answer.esm_radios = @"";
            ////////////////////////
            answer.esm_quick_answers = esm.esm_quick_answers;
            if(answer.esm_quick_answers == nil) answer.esm_quick_answers = @"";
            ////////////////////////
            answer.esm_likert_step = esm.esm_likert_step;
            if(answer.esm_likert_step == nil) answer.esm_likert_step = @0;
            answer.esm_likert_max = esm.esm_likert_max;
            if(answer.esm_likert_max == nil) answer.esm_likert_max = @0;
            answer.esm_likert_max_label = esm.esm_likert_max_label;
            if(answer.esm_likert_max_label == nil) answer.esm_likert_max_label = @"";
            answer.esm_likert_min_label = esm.esm_likert_min_label;
            if(answer.esm_likert_min_label == nil) answer.esm_likert_min_label = @"";

            ////////////////////////
            answer.esm_checkboxes = esm.esm_checkboxes;
            if(answer.esm_checkboxes == nil) answer.esm_checkboxes = @"";
        }else if([IOSESM getTableVersion] == 2){
            EntityESMAnswer * answer = (EntityESMAnswer *)
            [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMAnswer class])
                                          inManagedObjectContext:context];
            // add special data to dic from each uielements
            
            answer.device_id = deviceId;
            answer.timestamp = esm.timestamp;
            answer.esm_json = esm.esm_json;
            answer.esm_trigger = esm.esm_trigger;
            answer.esm_expiration_threshold = esm.esm_expiration_threshold;
            answer.double_esm_user_answer_timestamp = unixtime;
            answer.esm_user_answer = esmUserAnswer;
            answer.esm_status = esmState;
            
            NSLog(@"-----------------");
            NSLog(@"%@", answer.esm_user_answer);
            NSLog(@"%@", answer.device_id);
            NSLog(@"%@", answer.timestamp);
            NSLog(@"%@", answer.esm_trigger);
            NSLog(@"%@", answer.esm_json);
            NSLog(@"%@", answer.esm_expiration_threshold);
            NSLog(@"%@", answer.double_esm_user_answer_timestamp);
            NSLog(@"%@", answer.esm_status);
            NSLog(@"%@", answer.esm_user_answer);
            NSLog(@"-----------------");
        }else{
            NSLog(@"Error at IOSESMViewController.m");
        }
    }
    
    NSError * error = nil;
    bool result = [context save:&error];
    // NSMergePolicy *originalMergePolicy = context.mergePolicy;
    context.mergePolicy = originalMergePolicy;
    if(error != nil){
        NSLog(@"%@", error);
        
        [delegate.managedObjectContext reset];
        
        iOSESM = [[IOSESM alloc] initWithAwareStudy:study dbType:AwareDBTypeCoreData];
        esmSchedules = [iOSESM getValidESMSchedulesWithDatetime:[NSDate new]];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AWARE can not save your answer" message:@"Please push submit button again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    if ( result ) {
        //////  interface = 1   ////////////
        EntityESMSchedule * schedule = esmSchedules[currentESMScheduleNumber];
        bool isDone = NO;
        if([schedule.interface isEqualToNumber:@1]){
            currentESMScheduleNumber++;
            if (currentESMScheduleNumber < esmSchedules.count){
                [self viewDidAppear:NO];
                return;
            }else{
                isDone = YES;
            }
        /////  interface = 0 //////////
        }else{
            currentESMNumber++;
            if (currentESMNumber < schedule.esms.count){
                [self viewDidAppear:NO];
                return;
            }else{
                currentESMScheduleNumber++;
                if (currentESMScheduleNumber < esmSchedules.count){
                    currentESMNumber = 0;
                    [self viewDidAppear:NO];
                    return;
                }else{
                    isDone = YES;
                }
            }
        }
        
        ///////////////////////
        
        if(isDone){
            if([study getStudyId] == nil){
                esmNumber = 0;
                currentESMNumber = 0;
                currentESMScheduleNumber = 0;
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank you for your answer!"
                                                                message:nil delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
                [alert show];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }else{
                
                if([delegate.sharedAWARECore.sharedSensorManager isExist:SENSOR_PLUGIN_CAMPUS]){
                    [SVProgressHUD showWithStatus:@"uploading"];
                    [bcESM setUploadingState:NO];
                    [bcESM syncAwareDB];
                    
                    // [iOSESM setUploadingState:NO];
                    // [iOSESM syncAwareDB];
                    [iOSESM refreshNotifications];
                }
                
                if([delegate.sharedAWARECore.sharedSensorManager isExist:SENSOR_PLUGIN_IOS_ESM]){
                    [SVProgressHUD showWithStatus:@"uploading"];
                    [iOSESM setUploadingState:NO];
                    [iOSESM syncAwareDB];
                    [iOSESM refreshNotifications];
                }
            }
        }
    } else {
        
    }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method stores the esm answerds to local database with esm_status=2(dissmissed).
 * And also, this method calls when a user push "cancel" button.
 */
- (void) pushedCancelButton:(id) senser {
    NSLog(@"Cancel button was pushed!");
    
    // If the local esm storage stored some esms,
    // (1)AWARE iOS save the answer as cancel(dismiss).
    // In addition, (2)UI view moves to a next stored esm.
    // Answers object
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = delegate.persistentStoreCoordinator;
    
    NSMergePolicy *originalMergePolicy = context.mergePolicy;
    context.mergePolicy = NSOverwriteMergePolicy;
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    for (int i=0; i<uiElements.count; i++) {
        
        EntityESM *esm = [[uiElements objectAtIndex:i] objectForKey:KEY_OBJECT];
        
        if([IOSESM getTableVersion] == 1){ //TODO
            EntityESMAnswerBC * answer = (EntityESMAnswerBC *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMAnswerBC class])
                                                                                        inManagedObjectContext:context];
            
            answer.timestamp = esm.timestamp;
            answer.double_esm_user_answer_timestamp = unixtime;
            answer.device_id = [delegate.sharedAWARECore.sharedAwareStudy getDeviceId];
            answer.esm_user_answer = @"";
            answer.esm_type = esm.esm_type;
            if(answer.esm_type == nil) answer.esm_type = @1;
            answer.esm_trigger = esm.esm_trigger;
            if(answer.esm_trigger ==
               nil) answer.esm_trigger = @"";
            ////////////////////////////////////////////
            answer.esm_title = esm.esm_title;
            if(answer.esm_title == nil) answer.esm_title = @"";
            answer.esm_status  = @1;
            answer.esm_instructions = esm.esm_instructions;
            if(answer.esm_instructions == nil) answer.esm_instructions = @"";
            answer.esm_submit = esm.esm_submit;
            if(answer.esm_submit == nil) answer.esm_submit = @"";
            answer.esm_expiration_threshold = esm.esm_expiration_threshold;
            if(answer.esm_expiration_threshold == nil) answer.esm_expiration_threshold = @0;
            ////////////////////////
            answer.esm_scale_step = esm.esm_scale_step;
            if(answer.esm_scale_step == nil) answer.esm_scale_step = @0;
            answer.esm_scale_start = esm.esm_scale_start;
            if(answer.esm_scale_start == nil) answer.esm_scale_start = @0;
            answer.esm_scale_min = esm.esm_scale_min;
            if(answer.esm_scale_min == nil) answer.esm_scale_min = @0;
            answer.esm_scale_max = esm.esm_scale_max;
            if(answer.esm_scale_max == nil) answer.esm_scale_max = @0;
            answer.esm_scale_min_label = esm.esm_scale_min_label;
            if(answer.esm_scale_min_label == nil) answer.esm_scale_min_label = @"";
            answer.esm_scale_max_label = esm.esm_scale_max_label;
            if(answer.esm_scale_max_label == nil)answer.esm_scale_max_label = @"";
            ////////////////////////
            answer.esm_radios = esm.esm_radios;
            if(answer.esm_radios == nil) answer.esm_radios = @"";
            ////////////////////////
            answer.esm_quick_answers = esm.esm_quick_answers;
            if(answer.esm_quick_answers == nil) answer.esm_quick_answers = @"";
            ////////////////////////
            answer.esm_likert_step = esm.esm_likert_step;
            if(answer.esm_likert_step == nil) answer.esm_likert_step = @0;
            answer.esm_likert_max = esm.esm_likert_max;
            if(answer.esm_likert_max == nil) answer.esm_likert_max = @0;
            answer.esm_likert_max_label = esm.esm_likert_max_label;
            if(answer.esm_likert_max_label == nil) answer.esm_likert_max_label = @"";
            answer.esm_likert_min_label = esm.esm_likert_min_label;
            if(answer.esm_likert_min_label == nil) answer.esm_likert_min_label = @"";
            
            ////////////////////////
            answer.esm_checkboxes = esm.esm_checkboxes;
            if(answer.esm_checkboxes == nil) answer.esm_checkboxes = @"";
            
        }else if([IOSESM getTableVersion] == 2){
            EntityESMAnswer * answer = (EntityESMAnswer *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMAnswer class])
                                                                                        inManagedObjectContext:context];
            answer.timestamp = esm.timestamp;
            answer.device_id = [study getDeviceId];
            answer.double_esm_user_answer_timestamp = unixtime;
            answer.esm_user_answer = @"";
            answer.esm_status = @1; //dissmiss
            answer.esm_json = esm.esm_json;
            answer.esm_trigger = esm.esm_trigger;
            answer.esm_expiration_threshold = esm.expiration_threshold;
            NSLog(@"%@", answer);
        }else{
            NSLog(@"Table version is not set");
        }
        
    }
    
    NSError * error = nil;
    [context save:&error];
    if(error != nil){
        NSLog(@"%@", error.debugDescription);
    }
    context.mergePolicy = originalMergePolicy;
    
    if(!error){
        
        //////  interface = 1   ////////////
        EntityESMSchedule * schedule = esmSchedules[currentESMScheduleNumber];
        if([schedule.interface isEqualToNumber:@1]){
            if(currentESMScheduleNumber > 0){
                currentESMScheduleNumber--;
            }else{
                currentESMScheduleNumber = 0;
            }
            if (currentESMScheduleNumber < esmSchedules.count){
                [self viewDidAppear:NO];
                return;
            }else{
                EntityESMSchedule * previousESMSchedule = esmSchedules[currentESMScheduleNumber];
                if( [previousESMSchedule.interface isEqualToNumber:@0] ){
                    if(previousESMSchedule.esms.count > 0){
                        currentESMNumber = (int)previousESMSchedule.esms.count - 1;
                    }else{
                        currentESMNumber = 0;
                    }
                }else{
                    currentESMNumber = 0;
                }
                // isDone = YES;
            }
        /////  interface = 0 //////////
        }else{
            currentESMNumber--;
            if (currentESMNumber >= 0 ){
                [self viewDidAppear:NO];
                return;
            }else{
                // currentESMNumber = 0;
                if (currentESMScheduleNumber > 0){
                    currentESMScheduleNumber--;
                    EntityESMSchedule * previousESMSchedule = esmSchedules[currentESMScheduleNumber];
                    if( [previousESMSchedule.interface isEqualToNumber:@0] ){
                        if(previousESMSchedule.esms.count > 0){
                            currentESMNumber = (int)previousESMSchedule.esms.count - 1;
                        }else{
                            currentESMNumber = 0;
                        }
                    }else{
                        currentESMNumber = 0;
                    }
                    [self viewDidAppear:NO];
                    return;
                }else{
                    NSLog(@"This ESM is the first ESM.");
                }
            }
        }
///////////////////// backup ///////////////////
//        currentESMNumber--;
//        if(currentESMNumber < 0)currentESMNumber = 0;
//        if ( currentESMNumber < esmSchedules.count ) {
//            [self viewDidAppear:NO];
//            return ;
//        } else {
//            [self.navigationController popToRootViewControllerAnimated:YES];
//            currentESMNumber = 0;
//        }
        
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AWARE could not save your answer"
                                                        message:@"Please push submit button again."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [delegate.managedObjectContext reset];
        esmSchedules = [iOSESM getValidESMSchedulesWithDatetime:[NSDate new]];
    }
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void) saveESMHistoryWithScheduleId:(NSString *)scheduleId
                     originalFireDate:(NSNumber *)originalFireDate
                            randomize:(NSNumber *)randomize
                             fireDate:(NSNumber *)fireDate
                  expirationThreshold:(NSNumber *)expirationThreshold

{
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    // the status of the ESM (0-new, 1-dismissed, 2-answered, 3-expired) -> Defualt is zero(0).
    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = delegate.persistentStoreCoordinator;
    
    EntityESMHistory * history = (EntityESMHistory *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMHistory class])
                                                                                inManagedObjectContext:context];
    history.schedule_id = scheduleId;//x
    history.original_fire_date = originalFireDate;//x
    history.randomize = randomize; //x
    history.fire_date = fireDate;
    history.expiration_threshold = expirationThreshold;
    
    NSError * error = nil;
    if(![context save:&error]){
        NSLog(@"%@", error.debugDescription);
    }
}

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
    
//    for (id key in [originalDic keyEnumerator]) {
//        //        NSLog(@"Key: %@ => Value:%@" , key, [originalDic objectForKey:key]);
//        if([key isEqualToString:KEY_ESM_RADIOS]){
//            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_RADIOS];
//        }else if([key isEqualToString:KEY_ESM_CHECKBOXES]){
//            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_CHECKBOXES];
//        }else if([key isEqualToString:KEY_ESM_QUICK_ANSWERS]){
//            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_QUICK_ANSWERS];
//        }else{
//            NSObject *object = [originalDic objectForKey:key];
//            if (object == nil) {
//                object = @"";
//            }
//            [dic setObject:object forKey:key];
//        }
//    }
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
//- (BOOL) state:(EntityESM *)esm{
//    BOOL isExist = esm.esm_na;
//    if (isExist) {
//        return YES;
//    }else{
//        return NO;
//    }
//}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSArray *) convertJsonStringToArray:(NSString *) jsonString {
    if(jsonString != nil){
        NSData *jsonData = [jsonString dataUsingEncoding:NSUnicodeStringEncoding];
        NSError *error;
        
        NSArray *array = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:NSJSONReadingAllowFragments
                                                           error:&error];
        if(error == nil){
            return array;
        }
    }
    return @[];
}

@end
