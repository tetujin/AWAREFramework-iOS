//
//  ESMScrollViewController.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/29.
//

#import "ESMScrollViewController.h"
#import "AWAREStudy.h"
#import "AWAREDelegate.h"
#import "ESMScheduleManager.h"

/////////
#import "EntityESMAnswer.h"
#import "EntityESMAnswerHistory+CoreDataClass.h"

///////// views ////////
#import "BaseESMView.h"
#import "ESMFreeTextView.h"
#import "ESMRadioView.h"
#import "ESMCheckBoxView.h"
#import "ESMLikertScaleView.h"
#import "ESMScaleView.h"
#import "ESMPAMView.h"
#import "ESMAudioView.h"
#import "ESMVideoView.h"
#import "ESMAudioView.h"
#import "ESMNumberView.h"
#import "ESMQuickAnswerView.h"
#import "ESMDateTimePickerView.h"
#import "ESMClockTimePickerView.h"
#import "ESMWebView.h"
#import "ESMPictureView.h"

//////// ESM sensor //////////
#import "ESM.h"

@interface ESMScrollViewController () {
    AWAREStudy * study;
    ESM * esmSensor;
    
    NSArray * esmSchedules;
    NSMutableArray * esmCells;
    int currentESMNumber;
    int currentESMScheduleNumber;
    int totalHight;
    int esmNumber;
     NSString * finalBtnLabel;
     NSString * cancelBtnLabel;
    
    // for touch events
    NSMutableArray* freeTextViews;
    NSMutableArray* sliderViews;
    NSMutableArray* numberViews;
    
    // for ESM flows
    bool flowsFlag;
    NSNumber * previousInterfaceType;
    
    // for observers
    NSString * appIntegration;
}
@end

@implementation ESMScrollViewController


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    UIColor *customColor = [UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0];
    self.view.backgroundColor = customColor;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIScrollView * scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:scrollView];
    _mainScrollView = scrollView;
    
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    AWARECore * core = delegate.sharedAWARECore;
    study = core.sharedAwareStudy;
    
    flowsFlag = NO;
    finalBtnLabel = @"Submit";
    cancelBtnLabel = @"Cancel";
    freeTextViews = [[NSMutableArray alloc] init];
    sliderViews   = [[NSMutableArray alloc] init];
    numberViews   = [[NSMutableArray alloc] init];
    
    esmSensor = [[ESM alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
    [esmSensor createTable];
    
    _esms = [[NSMutableArray alloc] init];
    esmSchedules = [[NSArray alloc] init];
    esmCells = [[NSMutableArray alloc] init];
    
    self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap:)];
    self.singleTap.delegate = self;
    self.singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:self.singleTap];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    esmCells = [[NSMutableArray alloc] init];
    // Remove all UIView contents from super view (_mainScrollView).
    for (UIView * view in _mainScrollView.subviews) {
        [view removeFromSuperview];
    }
    totalHight = 0;
    
    bool isQuickAnswer = NO;
    
    ///////////////////////////////////////////////////////////////
    if(!flowsFlag){ /// normal case
        ESMScheduleManager *esmManager = [[ESMScheduleManager alloc] init];
        esmSchedules = [esmManager getValidSchedulesWithDatetime:[NSDate new]];
        
        if(esmSchedules != nil && esmSchedules.count > currentESMScheduleNumber){
            EntityESMSchedule * esmSchedule = esmSchedules[currentESMScheduleNumber];
            NSLog(@"[interface: %@]", esmSchedule.interface);
            NSSet * childEsms = esmSchedule.esms;
            // NSNumber * interface = schedule.interface;
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"esm_number" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObjects:sort,nil];
            NSArray *sortedEsms = [childEsms sortedArrayUsingDescriptors:sortDescriptors];
            
            if(sortedEsms.count == 0){
                NSLog(@"NO ESM Entity");
                return;
            }
            _esms = sortedEsms;
            //// interfacce 1 ////////
            if([esmSchedule.interface isEqualToNumber:@1]){
                previousInterfaceType = @1;
                // Submit button be shown if the element is the last one.
                // [self setSubmitButton];
                self.navigationItem.title = [NSString stringWithFormat:@"%@ - %d/%ld",
                                             esmSchedule.schedule_id,
                                             currentESMScheduleNumber+1,
                                             esmSchedules.count];
                
                
                for (EntityESM * esm in _esms) {
                    [self addAnESM:esm];
                    if([esm.esm_type isEqualToNumber:@5]){
                        isQuickAnswer = YES;
                    }
                }
                /////// interface 0 //////
            }else{
                previousInterfaceType = @0;
                // [self setEsm:sortedEsms[currentESMNumber] withTag:0 button:YES];
                EntityESM * esm = sortedEsms[currentESMNumber];
                [self addAnESM:esm];
                finalBtnLabel = esm.esm_submit;
                self.navigationItem.title = [NSString stringWithFormat:@"%@(%d/%ld) - %d/%ld",
                                             esmSchedule.schedule_id,
                                             currentESMNumber+1,
                                             sortedEsms.count,
                                             currentESMScheduleNumber+1,
                                             esmSchedules.count];
                if([esm.esm_type isEqualToNumber:@5]){
                    isQuickAnswer = YES;
                }
            }
            
        }else{
            NSLog(@"[ESMScrollViewController] NO ESM");
        }
        ///////////////////////////////////////////////////////////////
    }else{ /// ESMs by esm_flows exist
        
        @try {
            NSArray * nextESMs = [self getNextESMsFromDB];
            
            for (EntityESM * esm in nextESMs) {
                NSLog(@"%@",esm.esm_title);
                [self addAnESM:esm];
                finalBtnLabel = esm.esm_submit;
                if([esm.esm_type isEqualToNumber:@5]){
                    isQuickAnswer = YES;
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"%@", exception.debugDescription);
        } @finally {
        }
    }
    
    if(!isQuickAnswer){
        ////// add a submit (or next) and a cancel button /////////
        // add a cancel btn
        UIButton * cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(10,
                                                                          totalHight + 15,
                                                                          self.view.frame.size.width/5*2-15,
                                                                          60)];
        [cancelBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        cancelBtn.layer.borderColor = [UIColor grayColor].CGColor;
        cancelBtn.layer.borderWidth = 2;
        [cancelBtn setTitle:cancelBtnLabel forState:UIControlStateNormal];
        [cancelBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
        [cancelBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(pushedCancelButton:) forControlEvents:UIControlEventTouchUpInside];
        [_mainScrollView addSubview:cancelBtn];
        
        // add a submit btn
        UIButton * submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/5*2 + 5,
                                                                          totalHight + 15,
                                                                          self.view.frame.size.width/5*3-15,
                                                                          60)];
        [submitBtn setBackgroundColor:[UIColor darkGrayColor]];
        [submitBtn setTitle:finalBtnLabel forState:UIControlStateNormal];
        [submitBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
        [submitBtn addTarget:self action:@selector(pushedSubmitButton:) forControlEvents:UIControlEventTouchUpInside];
        [_mainScrollView addSubview:submitBtn];
        
        [self setContentSizeWithAdditionalHeight: 15 + 60 + 20];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

//////////////////////////////////////////////////////////////

- (void) addAnESM:(EntityESM *)esm {
    
    int esmType = [esm.esm_type intValue];
    BaseESMView * esmView = nil;
    
    if (esmType == 1) {
        esmView = [[ESMFreeTextView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
        [freeTextViews addObject:esmView];
    } else if(esmType == 2){
        esmView = [[ESMRadioView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 3){
        esmView = [[ESMCheckBoxView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 4){
        esmView = [[ESMLikertScaleView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 5){
        esmView = [[ESMQuickAnswerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 6){
        esmView = [[ESMScaleView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
        [sliderViews addObject:esmView];
    } else if(esmType == 7){
        esmView = [[ESMDateTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100)
                                                           esm:esm uiMode:UIDatePickerModeDateAndTime
                                                       version:1];
    } else if(esmType == 8){
        esmView = [[ESMPAMView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 9){
        esmView = [[ESMNumberView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
        [numberViews addObject:esmView];
    } else if(esmType == 10){
        esmView = [[ESMWebView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 11){
        esmView = [[ESMDateTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100)
                                                           esm:esm uiMode:UIDatePickerModeDate
                                                       version:1];
    } else if(esmType == 12){
        esmView = [[ESMDateTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100)
                                                           esm:esm
                                                        uiMode:UIDatePickerModeTime
                                                       version:1];
    } else if(esmType == 13){
        esmView = [[ESMClockTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 14){ // picture
        esmView = [[ESMPictureView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 15){ // voice
        esmView = [[ESMAudioView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 16){ // video
        esmView = [[ESMVideoView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    }
    
    
    ////////////////
    
    if(esmView != nil){
        [_mainScrollView addSubview:esmView];
        [self setContentSizeWithAdditionalHeight:esmView.frame.size.height];
        
        [esmCells addObject:esmView];
    }
}


-(void)onSingleTap:(UITapGestureRecognizer *)recognizer {
    @try {
        for (ESMFreeTextView *freeTextView in freeTextViews) {
            [freeTextView.freeTextView resignFirstResponder];
        }
        
        for (ESMScaleView * scaleView in sliderViews) {
            [scaleView.valueLabel resignFirstResponder];
        }
        
        for (ESMNumberView * numberView in numberViews) {
            [numberView.freeTextView resignFirstResponder];
        }
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    
}

-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == self.singleTap) {
        return YES;
    }
    return NO;
}


//////////////////////////////////////////

- (void) pushedCancelButton:(id) senser {
    AudioServicesPlaySystemSound(1104);
    
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
}


- (void) pushedSubmitButton:(id) senser {
    AudioServicesPlaySystemSound(1105);
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = delegate.persistentStoreCoordinator;
    
    NSMergePolicy *originalMergePolicy = context.mergePolicy;
    context.mergePolicy = NSOverwriteMergePolicy;
    
    ///////////////
    // nextESMs = [[NSMutableArray alloc] init];
    [self removeTempESMsFromDB];
    flowsFlag = NO;
    @try {
        EntityESMSchedule * entityESMSchedule = (EntityESMSchedule *) [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMSchedule class])
                                                                                                    inManagedObjectContext:context];
        entityESMSchedule.temporary = @(YES);
        
        for (BaseESMView *esmView in esmCells) {
            
            // A status of the ESM (0-new, 1-dismissed, 2-answered, 3-expired) -> Defualt is zero(0).
            NSNumber * esmState = [esmView getESMState];
            // A user ansert of the ESM
            NSString * esmUserAnswer = [esmView getUserAnswer];
            // Current time
            NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
            // Device ID
            NSString * deviceId = [study getDeviceId];
            // EntityESM obj
            EntityESM * esm = esmView.esmEntity;
            
            EntityESMAnswer * answer = (EntityESMAnswer *) [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMAnswer class])
                                                                                         inManagedObjectContext:context];
            answer.device_id = deviceId;
            answer.timestamp = esm.timestamp;
            answer.esm_json = esm.esm_json;
            answer.esm_trigger = esm.esm_trigger;
            answer.esm_expiration_threshold = esm.esm_expiration_threshold;
            answer.double_esm_user_answer_timestamp = unixtime;
            answer.esm_user_answer = esmUserAnswer;
            answer.esm_status = esmState;
            
            NSLog(@"--------[%@]---------", esm.esm_trigger);
            NSLog(@"device_id:        %@", answer.device_id);
            NSLog(@"timestamp:        %@", answer.timestamp);
            NSLog(@"esm_trigger:      %@", answer.esm_trigger);
            NSLog(@"esm_json:         %@", answer.esm_json);
            NSLog(@"threshold:        %@", answer.esm_expiration_threshold);
            NSLog(@"answer_timestamp: %@", answer.double_esm_user_answer_timestamp);
            NSLog(@"esm_status:       %@", answer.esm_status);
            NSLog(@"user_answer:      %@", answer.esm_user_answer);
            NSLog(@"---------------------");
            
            //////////////////////////////////////////////////
            entityESMSchedule.fire_hour = [esm.fire_hour copy];
            entityESMSchedule.expiration_threshold = [esm.expiration_threshold copy];
            entityESMSchedule.start_date = [esm.start_date copy];
            entityESMSchedule.end_date = [esm.end_date copy];
            entityESMSchedule.notification_title = [esm.notification_title copy];
            entityESMSchedule.noitification_body = [esm.noitification_body copy];
            entityESMSchedule.randomize_schedule = [esm.randomize_schedule copy];
            entityESMSchedule.schedule_id = [esm.schedule_id copy];
            entityESMSchedule.context = [esm.context copy];
            entityESMSchedule.interface = [esm.interface copy];
            
            // NSLog(@"[esm_app_integration] %@", [esmView.esmEntity.esm_app_integration copy]);
            appIntegration = esm.esm_app_integration;
            
            if (esm.esm_flows != nil) {
                bool isFlows = [self addNextESMs:esm withAnswer:answer context:context tempSchedule:entityESMSchedule];
                if (isFlows) {
                    flowsFlag = YES;
                }
            }
        }
        
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.debugDescription);
    } @finally {
        
    }
    
    // Save all data to SQLite
    NSError * error = nil;
    bool isSaved = [context save:&error];
    context.mergePolicy = originalMergePolicy;
    if(error != nil){
        NSLog(@"%@", error);
        
        [delegate.managedObjectContext reset];
        
        // esmSensor = [[IOSESM alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
        ESMScheduleManager * esmManager = [[ESMScheduleManager alloc] init];
        esmSchedules = [esmManager getValidSchedulesWithDatetime:[NSDate new]];
        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AWARE can not save your answer" message:@"Please push submit button again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [alert show];
    }
    
    ////////////////////////////////////////
    // Check an exist of next ESM
    if ( isSaved ) {
        
        /// for appearing esms by esm_flows ///
        if(flowsFlag){
            [self viewDidAppear:NO];
            return;
        }
        
        //////  interface = 1   ////////////
        EntityESMSchedule * schedule = esmSchedules[currentESMScheduleNumber];
        bool isDone = NO;
        if([schedule.interface isEqualToNumber:@1]){
            [self saveHistory:schedule context:context];
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
                [self saveHistory:schedule context:context];
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
            
            if([study getStudyURL] == nil || [[study getStudyURL] isEqualToString:@""]){
                esmNumber = 0;
                currentESMNumber = 0;
                currentESMScheduleNumber = 0;
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank you for your answer!"
                                                                message:nil delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
                [alert show];
                [self.navigationController popToRootViewControllerAnimated:YES];
                
            }else{
                [SVProgressHUD showWithStatus:@"uploading"];
                ESMScheduleManager * esmManager = [[ESMScheduleManager alloc] init];
                [esmManager refreshNotificationSchedules];
                
                [esmSensor.storage setSyncProcessCallBack:^(NSString *name, double progress, NSError * _Nullable error) {
                    NSLog(@"%@",name);
                    [SVProgressHUD dismiss];
                    [self.navigationController popViewControllerAnimated:YES];
                    self->esmNumber = 0;
                    self->currentESMNumber = 0;
                    self->currentESMScheduleNumber = 0;
                }];
                [esmSensor startSyncDB];
            }
        }
    } else {
        
    }
}

///////////////////////////////////////////
- (bool) addNextESMs:(EntityESM *)esm
          withAnswer:(EntityESMAnswer *) answer
             context:(NSManagedObjectContext *) context
        tempSchedule:(EntityESMSchedule *) entityESMSchedule {
    NSString * flowsStr = esm.esm_flows;
    
    if (flowsStr == nil || [flowsStr isEqualToString:@""]) {
        return NO;
    }
    
    NSError *e = nil;
    NSArray * flowsArray = [NSJSONSerialization JSONObjectWithData:[flowsStr dataUsingEncoding:NSUTF8StringEncoding]
                                                           options:NSJSONReadingAllowFragments
                                                             error:&e];
    if ( e != nil) {
        NSLog(@"[ESMScrollViewController -addNextESMs] Error: %@", e.debugDescription);
        return NO;
    }
    if(flowsArray == nil){
        NSLog(@"[ESMScrollViewController -addNextESMs] Error: web esm array is null.");
        return NO;
    }
    ////////////////////////////////////////
    bool flag = NO;
    int number = 0;
    // NSMutableArray * tempESMs = [[NSMutableArray alloc] init];
    for (NSDictionary * aFlow in flowsArray) {
        NSDictionary * nextESM   = [aFlow objectForKey:@"next_esm"];
        NSString * triggerAnswer = [aFlow objectForKey:@"user_answer"];
        if (triggerAnswer != nil && answer.esm_user_answer != nil) {
            ////////// if the user_answer and key is the same, an esm in the flows is stored ///////////
            if([triggerAnswer isEqualToString:answer.esm_user_answer] || [triggerAnswer isEqualToString:@"*"]){
                
                NSDictionary * esmDict = [nextESM objectForKey:@"esm"];
                if(esm != nil){
                    // EntityESM * entityEsm = [[EntityESM alloc] init];
                    number++;
                    EntityESM * entityEsm = (EntityESM *) [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESM class])
                                                                                        inManagedObjectContext:context];
                    entityEsm.timestamp = esm.timestamp;
                    entityEsm.esm_type   = [esmDict objectForKey:@"esm_type"];
                    
                    entityEsm.esm_title  = [esmDict objectForKey:@"esm_title"];
                    entityEsm.esm_submit = [esmDict objectForKey:@"esm_submit"];
                    entityEsm.esm_instructions = [esmDict objectForKey:@"esm_instructions"];
                    entityEsm.esm_radios     = [self convertNSArraytoJsonStr:[esmDict objectForKey:@"esm_radios"]];
                    entityEsm.esm_checkboxes = [self convertNSArraytoJsonStr:[esmDict objectForKey:@"esm_checkboxes"]];
                    entityEsm.esm_likert_max = [esmDict objectForKey:@"esm_likert_max"];
                    entityEsm.esm_likert_max_label = [esmDict objectForKey:@"esm_likert_max_label"];
                    entityEsm.esm_likert_min_label = [esmDict objectForKey:@"esm_likert_min_label"];
                    entityEsm.esm_likert_step = [esmDict objectForKey:@"esm_likert_step"];
                    entityEsm.esm_quick_answers = [self convertNSArraytoJsonStr:[esmDict objectForKey:@"esm_quick_answers"]];
                    entityEsm.esm_expiration_threshold = [esmDict objectForKey:@"esm_expiration_threshold"];
                    // entityEsm.esm_status    = [esm objectForKey:@"esm_status"];
                    entityEsm.esm_status = @0;
                    entityEsm.esm_trigger   = [[esmDict objectForKey:@"esm_trigger"] copy];
                    entityEsm.esm_scale_min = [esmDict objectForKey:@"esm_scale_min"];
                    entityEsm.esm_scale_max = [esmDict objectForKey:@"esm_scale_max"];
                    entityEsm.esm_scale_start = [esmDict objectForKey:@"esm_scale_start"];
                    entityEsm.esm_scale_max_label = [esmDict objectForKey:@"esm_scale_max_label"];
                    entityEsm.esm_scale_min_label = [esmDict objectForKey:@"esm_scale_min_label"];
                    entityEsm.esm_scale_step = [esmDict objectForKey:@"esm_scale_step"];
                    entityEsm.esm_json = [self convertNSArraytoJsonStr:@[esmDict]];
                    entityEsm.esm_number = @(number);
                    // for date&time picker
                    entityEsm.esm_start_time = [esmDict objectForKey:@"esm_start_time"];
                    entityEsm.esm_start_date = [esmDict objectForKey:@"esm_start_date"];
                    entityEsm.esm_time_format = [esmDict objectForKey:@"esm_time_format"];
                    entityEsm.esm_minute_step = [esmDict objectForKey:@"esm_minute_step"];
                    // for web ESM url
                    entityEsm.esm_url = [esmDict objectForKey:@"esm_url"];
                    // for na
                    entityEsm.esm_na = @([[esmDict objectForKey:@"esm_na"] boolValue]);
                    entityEsm.esm_flows = [self convertNSArraytoJsonStr:[esmDict objectForKey:@"esm_flows"]];
                    entityEsm.esm_app_integration = [esmDict objectForKey:@"esm_app_integration"];
                    
                    [entityESMSchedule addEsmsObject:entityEsm];
                    
                    flag = YES;
                }
            }
        }
    }
    return flag;
}

///////////////////////////////////////////

- (NSArray *) getNextESMsFromDB {
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    [req setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class])
                               inManagedObjectContext:delegate.managedObjectContext]];
    // [req setPredicate:[NSPredicate predicateWithFormat:@"(start_date <= %@) AND (end_date >= %@) OR (expiration_threshold=0)", datetime, datetime]];
    [req setPredicate:[NSPredicate predicateWithFormat:@"(temporary == 1)"]];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"start_date" ascending:NO];
    //    NSSortDescriptor *sortBySID = [[NSSortDescriptor alloc] initWithKey:@"schedule_id" ascending:NO];
    [req setSortDescriptors:@[sort]];
    
    NSFetchedResultsController *fetchedResultsController
    = [[NSFetchedResultsController alloc] initWithFetchRequest:req
                                          managedObjectContext:delegate.managedObjectContext
                                            sectionNameKeyPath:nil
                                                     cacheName:nil];
    
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    NSArray *results = [fetchedResultsController fetchedObjects];
    //    for (EntityESMSchedule * s in results) {
    //        NSLog(@"%@",s.notification_title);
    //    }
    
    if(results != nil){
        // NSLog(@"Stored ESM Schedules are %ld", results.count);
        NSMutableArray * esms = [[NSMutableArray alloc] init];
        for (EntityESMSchedule * schedule in results) {
            if (schedule != nil) {
                NSSet * childEsms = schedule.esms;
                NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"esm_number" ascending:YES];
                NSArray *sortDescriptors = [NSArray arrayWithObjects:sort,nil];
                NSArray *sortedEsms = [childEsms sortedArrayUsingDescriptors:sortDescriptors];
                [esms addObjectsFromArray:sortedEsms];
            }
        }
        return esms;
    }else{
        // NSLog(@"Stored ESM Schedule is Null.");
        return @[];
    }
}


- (bool) removeTempESMsFromDB{
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class]) inManagedObjectContext:delegate.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"temporary==1"];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *error;
    NSArray *items = [delegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *managedObject in items){
        [delegate.managedObjectContext deleteObject:managedObject];
    }
    
    if (error!= nil) {
        return YES;
    }else{
        NSLog(@"%@",error.debugDescription);
        return NO;
    }
}

///////////////////////////////////////////

/**
 * This method is managing a total height of the ESM elemetns and a size of the base scroll view. You should call this method if you add a new element to the _mainScrollView.
 */
- (void) setContentSizeWithAdditionalHeight:(int) additionalHeight {
    totalHight += additionalHeight;
    [_mainScrollView setContentSize:CGSizeMake(self.view.frame.size.width, totalHight)];
}


- (NSString *) convertNSArraytoJsonStr:(NSArray *)array{
    if(array != nil){
        NSError * error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];
        if(error == nil){
            return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }
    return @"[]";
}


//////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////

- (void) saveHistory:(EntityESMSchedule *)esmSchedule context:(NSManagedObjectContext *)context {
    EntityESMAnswerHistory * entityESMHistory = (EntityESMAnswerHistory *) [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMAnswerHistory class])
                                                                            
                                                                                                         inManagedObjectContext:context];
    entityESMHistory.timestamp = @([NSDate new].timeIntervalSince1970);
    entityESMHistory.fire_hour = esmSchedule.fire_hour;
    entityESMHistory.schedule_id = esmSchedule.schedule_id;
    NSError * error = nil;
    bool result = [context save:&error];
    if(!result && error != nil){
        NSLog(@"%@", error.debugDescription);
    }else{
        NSLog(@"Success to save data");
    }
}

@end
