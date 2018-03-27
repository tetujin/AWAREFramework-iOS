//
//  ESMItem.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/27.
//

#import "ESMItem.h"

@implementation ESMItem

- (instancetype)init{
    self = [super init];
    if(self != nil){
        _double_esm_user_answer_timestamp = @0;
        _esm_checkboxes = @[];
        _esm_expiration_threshold = @0;
        _esm_flows = @[];
        _esm_instructions = @"";
        _esm_json = @{};
        _esm_likert_max = @7;
        _esm_likert_max_label = @"7";
        _esm_likert_min_label = @"1";
        _esm_likert_step = @1;
        _esm_minute_step = @1;
        _esm_na = false;
        _esm_number = @0;
        _esm_quick_answers = @[];
        _esm_radios = @[];
        _esm_scale_max = @10;
        _esm_scale_max_label = @"10";
        _esm_scale_min = @0;
        _esm_scale_min_label = @"0";
        _esm_scale_start = @5;
        _esm_scale_step = @1;
        _esm_start_date = @""; //yyyy-MM-dd
        _esm_start_time = @""; //"HH:mm:ss
        _esm_status = @0;
        _esm_submit = @"Submit";
        _esm_time_format = @"";
        _esm_title = @"";
        _esm_trigger = @"";
        _esm_type = AwareESMTypeNone;
        _esm_url = @"";
        _esm_user_answer = @"";
        _timestamp = @0;
        _esm_app_integration = @"";
    }
    return self;
}


- (instancetype) initWithConfiguration:(NSDictionary *) config{
    self = [self init];
    if (config != nil) {
        NSNumber * esmType = [config objectForKey:@"esm_type"];
        NSString * trigger = [config objectForKey:@"esm_trigger"];
        NSString * title = [config objectForKey:@"esm_title"];
        NSString * instructions = [config objectForKey:@"esm_instructions"];
        NSString * submit = [config objectForKey:@"esm_submit"];
        NSNumber * expiration = [config objectForKey:@"esm_expiration_threshold"];
        NSNumber * isNa = [config objectForKey:@"esm_na"];
        
        bool naState = NO;
        if (isNa != nil) naState = isNa.intValue;
        
        NSError * error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:config options:NSJSONWritingPrettyPrinted error:&error];
        if (error != nil) {
            NSLog(@"[EntityESM] Convert Error to JSON-String from Dictionary: %@", error.debugDescription);
            return self;
        }
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        if (esmType != nil) {
            if (esmType.intValue == AwareESMTypeText) { // text
                self = [self initAsTextESMWithTrigger:trigger
                                        title:title
                                 instructions:instructions
                                         isNa:naState
                                 submitButton:submit
                          expirationThreshold:expiration];
            }else if (esmType.intValue == AwareESMTypeRadio){ // radio
                self = [self initAsRadioESMWithTrigger:trigger
                                         title:title
                                  instructions:instructions
                                          isNa:naState
                                  submitButton:submit
                           expirationThreshold:expiration
                                    radioItems:@[]];
                self.esm_radios = [config objectForKey:@"esm_radios"];
            }else if (esmType.intValue == AwareESMTypeCheckbox){ // checkbox
                self = [self initAsCheckboxESMWithTrigger:trigger
                                            title:title
                                     instructions:instructions
                                             isNa:naState
                                     submitButton:submit
                              expirationThreshold:expiration
                                       checkboxes:@[]];
                self.esm_checkboxes = [config objectForKey:@"esm_checkboxes"];
            }else if (esmType.integerValue == AwareESMTypeLikertScale){ // likert scale
                NSNumber * max = [config objectForKey:@"esm_likert_max"];
                if (max == nil) max = @5;
                NSNumber * step = [config objectForKey:@"esm_likert_step"];
                if (step == nil) step = @1;
                self = [self initAsLikertScaleESMWithTrigger:trigger
                                               title:title
                                        instructions:instructions
                                                isNa:naState
                                        submitButton:submit
                                 expirationThreshold:expiration
                                           likertMax:max.intValue
                                      likertMinLabel:[config objectForKey:@"esm_likert_min_label"]
                                      likertMaxLabel:[config objectForKey:@"esm_likert_max_label"]
                                          likertStep:step.intValue];
            }else if (esmType.intValue == AwareESMTypeQuickAnswer){ // quick answer
                self = [self initAsQuickAnawerESMWithTrigger:trigger
                                               title:title
                                        instructions:instructions
                                                isNa:naState
                                        submitButton:submit
                                 expirationThreshold:expiration
                                        quickAnswers:@[]];
                self.esm_quick_answers = [config objectForKey:@"esm_quick_answers"];
            } else if (esmType.intValue == AwareESMTypeScale ){ // scale
                NSNumber * min = [config objectForKey:@"esm_scale_min"];
                if (min == nil) min = @0;
                NSNumber * max = [config objectForKey:@"esm_scale_max"];
                if (max == nil) max = @10;
                NSNumber * start = [config objectForKey:@"esm_scale_start"];
                if (start == nil) start = @5;
                NSNumber * step = [config objectForKey:@"esm_scale_step"];
                if (step == nil) step = @1;
                self = [self initAsScaleESMWithTrigger:trigger
                                         title:title
                                  instructions:instructions
                                          isNa:naState
                                  submitButton:submit
                           expirationThreshold:expiration
                                      scaleMin:min.intValue scaleMax:max.intValue
                                    scaleStart:start.intValue
                                 scaleMinLabel:[config objectForKey:@"esm_scale_min_label"]
                                 scaleMaxLabel:[config objectForKey:@"esm_scale_max_label"]
                                     scaleStep:step.intValue];
                
            } else if (esmType.intValue == AwareESMTypeDateTime ){ //datetime
                self = [self initAsDateTimeESMWithTrigger:title
                                            title:title
                                     instructions:instructions
                                             isNa:naState
                                     submitButton:submit
                              expirationThreshold:expiration];
            } else if (esmType.intValue == AwareESMTypePAM) { // PAM
                self = [self initAsPAMESMWithTrigger:trigger
                                       title:title
                                instructions:instructions
                                        isNa:naState
                                submitButton:submit
                         expirationThreshold:expiration];
            } else if (esmType.intValue == AwareESMTypeWeb ) {
                self = [self initAsWebESMWithTrigger:trigger
                                       title:title
                                instructions:instructions
                                        isNa:naState
                                submitButton:submit
                         expirationThreshold:expiration
                                         url:[config objectForKey:@"esm_url"]];
            }
        }
    }
    return self;
}


- (void) setBasicInfoWithTrigger:(NSString *) trigger
                           title:(NSString *) title
                    instructions:(NSString *) instructions
                    submitButton:(NSString *) submitButton
             expirationThreshold:(NSNumber *) expirationThreshold
                            isNa:(BOOL) isNa {
    if (trigger != nil) {
        self.esm_trigger = trigger;
    }else{
        self.esm_trigger = [[NSUUID UUID] init].UUIDString;
    }

    if (expirationThreshold != nil) {
        self.esm_expiration_threshold = expirationThreshold;
    }else{
        self.esm_expiration_threshold = @0;
    }
    
    if (title != nil) {
        self.esm_title = title;
    }else{
        self.esm_title = @"";
    }
    
    if (instructions != nil) {
        self.esm_instructions = instructions;
    }else{
        self.esm_instructions = @"";
    }
    
    if (submitButton != nil) {
        self.esm_submit = submitButton;
    }else{
        self.esm_submit = @"Next";
    }
    self.esm_na = &(isNa);
}

//
//- (void) setJSON:(NSDictionary *)jsonDict{
//    if (jsonDict != nil) {
//        NSError * error = nil;
//        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&error];
//        if (error==nil) {
//            NSLog(@"[ESMItem] %@", error.debugDescription);
//            return;
//        }
//        NSString * jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//        self.esm_json = jsonStr;
//    }
//}

- (instancetype) initAsTextESMWithTrigger:(NSString *) trigger
                                    title:(NSString *) title
                             instructions:(NSString *) instructions
                                     isNa:(BOOL) isNa
                             submitButton:(NSString *) submitButton
                      expirationThreshold:(NSNumber *) expirationThreshold{
    self = [self init];
    return self;
}

- (instancetype) initAsRadioESMWithTrigger:(NSString *) trigger
                                     title:(NSString *) title
                              instructions:(NSString *) instructions
                                      isNa:(BOOL) isNa
                              submitButton:(NSString *) submitButton
                       expirationThreshold:(NSNumber *) expirationThreshold
                                radioItems:(NSArray *) radioItems{
    self = [self init];
    return self;
}

- (instancetype) initAsCheckboxESMWithTrigger:(NSString *) trigger
                                        title:(NSString *) title
                                 instructions:(NSString *) instructions
                                         isNa:(BOOL) isNa
                                 submitButton:(NSString *) submitButton
                          expirationThreshold:(NSNumber *) expirationThreshold
                                   checkboxes:(NSArray *) checkboxes{
    self = [self init];
    return self;
}

- (instancetype) initAsLikertScaleESMWithTrigger:(NSString *) trigger
                                           title:(NSString *) title
                                    instructions:(NSString *) instructions
                                            isNa:(BOOL) isNa
                                    submitButton:(NSString *) submitButton
                             expirationThreshold:(NSNumber *) expirationThreshold
                                       likertMax:(int) likertMax
                                  likertMinLabel:(NSString *) minLabel
                                  likertMaxLabel:(NSString *) maxLabel
                                      likertStep:(int) likertStep{
    self = [self init];
    return self;
}

- (instancetype) initAsQuickAnawerESMWithTrigger:(NSString *) trigger
                                           title:(NSString *) title
                                    instructions:(NSString *) instructions
                                            isNa:(BOOL) isNa
                                    submitButton:(NSString *) submitButton
                             expirationThreshold:(NSNumber *) expirationThreshold
                                    quickAnswers:(NSArray *) quickAnswers{
    self = [self init];
    return self;
}

- (instancetype) initAsScaleESMWithTrigger:(NSString *) trigger
                                     title:(NSString *) title
                              instructions:(NSString *) instructions
                                      isNa:(BOOL) isNa
                              submitButton:(NSString *) submitButton
                       expirationThreshold:(NSNumber *) expirationThreshold
                                  scaleMin:(int)scaleMin
                                  scaleMax:(int)scaleMax
                                scaleStart:(int)scaleStart
                             scaleMinLabel:(NSString *)minLabel
                             scaleMaxLabel:(NSString *)maxLabel
                                 scaleStep:(int)step{
    self = [self init];
    return self;
}

- (instancetype) initAsDateTimeESMWithTrigger:(NSString *) trigger
                                        title:(NSString *) title
                                 instructions:(NSString *) instructions
                                         isNa:(BOOL) isNa
                                 submitButton:(NSString *) submitButton
                          expirationThreshold:(NSNumber *) expirationThreshold{
    self = [self init];
    return self;
}

- (instancetype) initAsPAMESMWithTrigger:(NSString *) trigger
                                   title:(NSString *) title
                            instructions:(NSString *) instructions
                                    isNa:(BOOL) isNa
                            submitButton:(NSString *) submitButton
                     expirationThreshold:(NSNumber *) expirationThreshold{
    self = [self init];
    return self;
}

- (instancetype) initAsNumericESMWithTrigger:(NSString *) trigger
                                       title:(NSString *) title
                                instructions:(NSString *) instructions
                                        isNa:(BOOL) isNa
                                submitButton:(NSString *) submitButton
                         expirationThreshold:(NSNumber *) expirationThreshold{
    self = [self init];
    return self;
}

- (instancetype) initAsWebESMWithTrigger:(NSString *) trigger
                                   title:(NSString *) title
                            instructions:(NSString *) instructions
                                    isNa:(BOOL) isNa
                            submitButton:(NSString *) submitButton
                     expirationThreshold:(NSNumber *) expirationThreshold
                                     url:(NSString *) url{
    self = [self init];
    return self;
}


@end
