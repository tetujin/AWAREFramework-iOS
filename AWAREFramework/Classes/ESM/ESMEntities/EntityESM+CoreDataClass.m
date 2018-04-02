//
//  EntityESM+CoreDataClass.m
//  
//
//  Created by Yuuki Nishiyama on 2017/09/23.
//
//

#import "EntityESM+CoreDataClass.h"
#import "ESM.h"

@implementation EntityESM


- (void) setESMWithESMItem:(ESMItem *) esmItem{
    self.device_id = esmItem.device_id;
    self.double_esm_user_answer_timestamp = esmItem.double_esm_user_answer_timestamp;
    self.esm_checkboxes = esmItem.esm_checkboxes;
    self.esm_expiration_threshold = esmItem.esm_expiration_threshold;
    self.esm_flows = esmItem.esm_flows;
    self.esm_instructions = esmItem.esm_instructions;
    self.esm_json = esmItem.esm_json;
    self.esm_likert_max = esmItem.esm_likert_max;
    self.esm_likert_max_label = esmItem.esm_likert_max_label;
    self.esm_likert_min_label = esmItem.esm_likert_min_label;
    self.esm_likert_step = esmItem.esm_likert_step;
    self.esm_minute_step = esmItem.esm_minute_step;
    self.esm_na = esmItem.esm_na;
    self.esm_number = esmItem.esm_number;
    self.esm_quick_answers = esmItem.esm_quick_answers;
    self.esm_radios = esmItem.esm_radios;
    self.esm_scale_max = esmItem.esm_scale_max;
    self.esm_scale_max_label = esmItem.esm_scale_max_label;
    self.esm_scale_min = esmItem.esm_scale_min;
    self.esm_scale_min_label = esmItem.esm_scale_min_label;
    self.esm_scale_start = esmItem.esm_scale_start;
    self.esm_scale_step = esmItem.esm_scale_step;
    self.esm_start_date= esmItem.esm_start_date;
    self.esm_start_time = esmItem.esm_start_time;
    self.esm_status = esmItem.esm_status;
    self.esm_submit = esmItem.esm_submit;
    self.esm_time_format = esmItem.esm_time_format;
    self.esm_title = esmItem.esm_title;
    self.esm_trigger = esmItem.esm_trigger;
    self.esm_type = esmItem.esm_type;
    self.esm_url = esmItem.esm_url;
    self.esm_user_answer = esmItem.esm_user_answer;
    self.esm_app_integration = esmItem.esm_app_integration;
    
//    self.timestamp = @0;
//    self.esm_schedule
}

- (EntityESM *)setESMWithConfiguration:(NSDictionary *)config{
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
                [self setAsTextESMWithTrigger:trigger
                                         json:jsonString
                                        title:title
                                 instructions:instructions
                                         isNa:naState
                                 submitButton:submit
                          expirationThreshold:expiration];
            }else if (esmType.intValue == AwareESMTypeRadio){ // radio
                    [self setAsRadioESMWithTrigger:trigger
                                              json:jsonString
                                             title:title
                                      instructions:instructions
                                              isNa:naState
                                      submitButton:submit
                               expirationThreshold:expiration
                                        radioItems:@[]];
                    self.esm_radios = [config objectForKey:@"esm_radios"];
            }else if (esmType.intValue == AwareESMTypeCheckbox){ // checkbox
                    [self setAsCheckboxESMWithTrigger:trigger
                                                 json:jsonString
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
                [self setAsLikertScaleESMWithTrigger:trigger
                                                json:jsonString
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
                [self setAsQuickAnawerESMWithTrigger:trigger
                                                json:jsonString
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
                [self setAsScaleESMWithTrigger:trigger
                                          json:jsonString
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
                [self setAsDateTimeESMWithTrigger:title
                                             json:jsonString
                                            title:title
                                     instructions:instructions
                                             isNa:naState
                                     submitButton:submit
                              expirationThreshold:expiration];
            } else if (esmType.intValue == AwareESMTypePAM) { // PAM
                [self setAsPAMESMWithTrigger:trigger
                                        json:jsonString
                                       title:title
                                instructions:instructions
                                        isNa:naState
                                submitButton:submit
                         expirationThreshold:expiration];
            } else if (esmType.intValue == AwareESMTypeWeb ) {
                [self setAsWebESMWithTrigger:trigger
                                        json:jsonString
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
                            json:(NSString *) jsonString
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
    
    if (jsonString != nil) {
        self.esm_json = jsonString;
    }else{
        self.esm_json = @"";
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
    
    self.esm_na = @(isNa);
}

- (EntityESM *)setAsTextESMWithTrigger:(NSString *)trigger json:(NSString *)jsonString title:(NSString *)title instructions:(NSString *)instructions isNa:(BOOL)isNa submitButton:(NSString *)submitButton expirationThreshold:(NSNumber *)expirationThreshold{
    [self setBasicInfoWithTrigger:trigger
                             json:jsonString
                            title:title
                     instructions:instructions
                     submitButton:submitButton
              expirationThreshold:expirationThreshold isNa:isNa];
    self.esm_type = @1;
    return self;
}


- (EntityESM *)setAsRadioESMWithTrigger:(NSString *)trigger json:(NSString *)jsonString title:(NSString *)title instructions:(NSString *)instructions isNa:(BOOL)isNa submitButton:(NSString *)submitButton expirationThreshold:(NSNumber *)expirationThreshold radioItems:(NSArray *)radioItems{
    [self setBasicInfoWithTrigger:trigger
                             json:jsonString
                            title:title
                     instructions:instructions
                     submitButton:submitButton
              expirationThreshold:expirationThreshold isNa:isNa];
    self.esm_type = @2;
    if (radioItems != nil) {
        NSError *e = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:radioItems options:NSJSONWritingPrettyPrinted error:&e];
        if(e!=nil){
            NSLog(@"%@", [e localizedDescription]);
        }else{
            self.esm_radios = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    return self;
}

- (EntityESM *)setAsCheckboxESMWithTrigger:(NSString *)trigger json:(NSString *)jsonString title:(NSString *)title instructions:(NSString *)instructions isNa:(BOOL)isNa submitButton:(NSString *)submitButton expirationThreshold:(NSNumber *)expirationThreshold checkboxes:(NSArray *)checkboxes{
    [self setBasicInfoWithTrigger:trigger
                             json:jsonString
                            title:title
                     instructions:instructions
                     submitButton:submitButton
              expirationThreshold:expirationThreshold isNa:isNa];
    self.esm_type = @3;
    if (checkboxes != nil) {
        NSError *e = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:checkboxes options:NSJSONWritingPrettyPrinted error:&e];
        if(e!=nil){
            NSLog(@"%@", [e localizedDescription]);
        }else{
            self.esm_checkboxes = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    return self;
}

- (EntityESM *)setAsLikertScaleESMWithTrigger:(NSString *)trigger json:(NSString *)jsonString title:(NSString *)title instructions:(NSString *)instructions isNa:(BOOL)isNa submitButton:(NSString *)submitButton expirationThreshold:(NSNumber *)expirationThreshold likertMax:(int)likertMax likertMinLabel:(NSString *)minLabel likertMaxLabel:(NSString *)maxLabel likertStep:(int)likertStep{
    [self setBasicInfoWithTrigger:trigger
                             json:jsonString
                            title:title
                     instructions:instructions
                     submitButton:submitButton
              expirationThreshold:expirationThreshold isNa:isNa];
    self.esm_type = @4;
    self.esm_likert_max = @(likertMax);
    self.esm_likert_max_label = maxLabel;
    self.esm_likert_min_label = minLabel;
    self.esm_likert_step = @(likertStep);
    return self;
}


- (EntityESM *)setAsQuickAnawerESMWithTrigger:(NSString *)trigger json:(NSString *)jsonString title:(NSString *)title instructions:(NSString *)instructions isNa:(BOOL)isNa submitButton:(NSString *)submitButton expirationThreshold:(NSNumber *)expirationThreshold quickAnswers:(NSArray *)quickAnswers{
    [self setBasicInfoWithTrigger:trigger
                             json:jsonString
                            title:title
                     instructions:instructions
                     submitButton:submitButton
              expirationThreshold:expirationThreshold isNa:isNa];
    self.esm_type = @5;
    if (quickAnswers != nil) {
        NSError *e = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:quickAnswers options:NSJSONWritingPrettyPrinted error:&e];
        if(e!=nil){
            NSLog(@"%@", [e localizedDescription]);
        }else{
            self.esm_quick_answers = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    return self;
}

- (EntityESM *)setAsScaleESMWithTrigger:(NSString *)trigger json:(NSString *)jsonString title:(NSString *)title instructions:(NSString *)instructions isNa:(BOOL)isNa submitButton:(NSString *)submitButton expirationThreshold:(NSNumber *)expirationThreshold scaleMin:(int)scaleMin scaleMax:(int)scaleMax scaleStart:(int)scaleStart scaleMinLabel:(NSString *)minLabel scaleMaxLabel:(NSString *)maxLabel scaleStep:(int)step{
    [self setBasicInfoWithTrigger:trigger
                             json:jsonString
                            title:title
                     instructions:instructions
                     submitButton:submitButton
              expirationThreshold:expirationThreshold isNa:isNa];
    self.esm_type = @6;
    self.esm_scale_min = @(scaleMin);
    self.esm_scale_max = @(scaleMax);
    self.esm_scale_start = @(scaleStart);
    self.esm_scale_min_label = minLabel;
    self.esm_scale_max_label = maxLabel;
    self.esm_scale_step = @(step);
    return self;
}

- (EntityESM *)setAsDateTimeESMWithTrigger:(NSString *)trigger json:(NSString *)jsonString title:(NSString *)title instructions:(NSString *)instructions isNa:(BOOL)isNa submitButton:(NSString *)submitButton expirationThreshold:(NSNumber *)expirationThreshold{
    [self setBasicInfoWithTrigger:trigger
                             json:jsonString
                            title:title
                     instructions:instructions
                     submitButton:submitButton
              expirationThreshold:expirationThreshold isNa:isNa];
    self.esm_type = @7;
    return self;
}

- (EntityESM *)setAsPAMESMWithTrigger:(NSString *)trigger json:(NSString *)jsonString title:(NSString *)title instructions:(NSString *)instructions isNa:(BOOL)isNa submitButton:(NSString *)submitButton expirationThreshold:(NSNumber *)expirationThreshold{
    [self setBasicInfoWithTrigger:trigger
                             json:jsonString
                            title:title
                     instructions:instructions
                     submitButton:submitButton
              expirationThreshold:expirationThreshold isNa:isNa];
    self.esm_type = @8;
    return self;
}

- (EntityESM *)setAsNumericESMWithTrigger:(NSString *)trigger json:(NSString *)jsonString title:(NSString *)title instructions:(NSString *)instructions isNa:(BOOL)isNa submitButton:(NSString *)submitButton expirationThreshold:(NSNumber *)expirationThreshold{
    [self setBasicInfoWithTrigger:trigger
                             json:jsonString
                            title:title
                     instructions:instructions
                     submitButton:submitButton
              expirationThreshold:expirationThreshold isNa:isNa];
    self.esm_type = @9;
    return self;
}


- (EntityESM *)setAsWebESMWithTrigger:(NSString *)trigger json:(NSString *)jsonString title:(NSString *)title instructions:(NSString *)instructions isNa:(BOOL)isNa submitButton:(NSString *)submitButton expirationThreshold:(NSNumber *)expirationThreshold url:(NSString *)url{
    [self setBasicInfoWithTrigger:trigger
                             json:jsonString
                            title:title
                     instructions:instructions
                     submitButton:submitButton
              expirationThreshold:expirationThreshold isNa:isNa];
    self.esm_type = @10;
    self.esm_url = url;
    return self;
}

@end
