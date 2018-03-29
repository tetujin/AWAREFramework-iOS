//
//  ESMItem.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/27.
//

#import "ESMItem.h"

@implementation ESMItem{
    NSMutableDictionary * esmDict;
}

- (instancetype)init{
    self = [super init];
    esmDict = [[NSMutableDictionary alloc] init];
    if(self != nil){
        _double_esm_user_answer_timestamp = @0;
        _esm_checkboxes = @"";
        _esm_expiration_threshold = @0;
        _esm_flows = @"";
        _esm_instructions = @"";
        _esm_json = @"";
        _esm_likert_max = @7;
        _esm_likert_max_label = @"7";
        _esm_likert_min_label = @"1";
        _esm_likert_step = @1;
        _esm_minute_step = @1;
        _esm_na = @(NO);
        _esm_number = @0;
        _esm_quick_answers = @"";
        _esm_radios = @"";
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
        _esm_type = @0;
        _esm_url = @"";
        _esm_user_answer = @"";
        _timestamp = @0;
        _esm_app_integration = @"";
    }
    return self;
}


- (instancetype) initWithConfiguration:(NSDictionary *) config {
    self = [self init];
    if (config != nil) {
        NSNumber * esmType = [config objectForKey:@"esm_type"];
        NSString * trigger = [config objectForKey:@"esm_trigger"];
        
         NSError * error = nil;
         NSData *jsonData = [NSJSONSerialization dataWithJSONObject:config options:NSJSONWritingPrettyPrinted error:&error];
         if (error != nil) {
            NSLog(@"[EntityESM] Convert Error to JSON-String from Dictionary: %@", error.debugDescription);
            return self;
         }
         NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (jsonString != nil) {
            self.esm_json = jsonString;
        }
        
        if (esmType != nil) {
            if (esmType.intValue == AwareESMTypeText) { // text
                self = [self initAsTextESMWithTrigger:trigger];
            }else if (esmType.intValue == AwareESMTypeRadio){ // radio
                self = [self initAsRadioESMWithTrigger:trigger
                                    radioItems:@[]];
                self.esm_radios = [config objectForKey:@"esm_radios"];
            }else if (esmType.intValue == AwareESMTypeCheckbox){ // checkbox
                self = [self initAsCheckboxESMWithTrigger:trigger
                                       checkboxes:@[]];
                self.esm_checkboxes = [config objectForKey:@"esm_checkboxes"];
            }else if (esmType.integerValue == AwareESMTypeLikertScale){ // likert scale
                NSNumber * max = [config objectForKey:@"esm_likert_max"];
                if (max == nil) max = @5;
                NSNumber * step = [config objectForKey:@"esm_likert_step"];
                if (step == nil) step = @1;
                self = [self initAsLikertScaleESMWithTrigger:trigger
                                           likertMax:max.intValue
                                      likertMinLabel:[config objectForKey:@"esm_likert_min_label"]
                                      likertMaxLabel:[config objectForKey:@"esm_likert_max_label"]
                                          likertStep:step.intValue];
            }else if (esmType.intValue == AwareESMTypeQuickAnswer){ // quick answer
                self = [self initAsQuickAnawerESMWithTrigger:trigger
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
                                      scaleMin:min.intValue scaleMax:max.intValue
                                    scaleStart:start.intValue
                                 scaleMinLabel:[config objectForKey:@"esm_scale_min_label"]
                                 scaleMaxLabel:[config objectForKey:@"esm_scale_max_label"]
                                     scaleStep:step.intValue];
                
            } else if (esmType.intValue == AwareESMTypeDateTime ){ //datetime
                self = [self initAsDateTimeESMWithTrigger:trigger];
            } else if (esmType.intValue == AwareESMTypePAM) { // PAM
                self = [self initAsPAMESMWithTrigger:trigger];
            } else if (esmType.intValue == AwareESMTypeWeb ) {
                self = [self initAsWebESMWithTrigger:trigger
                                         url:[config objectForKey:@"esm_url"]];
            }
        }
        
        NSString * title = [config objectForKey:@"esm_title"];
        NSString * instructions = [config objectForKey:@"esm_instructions"];
        NSString * submit = [config objectForKey:@"esm_submit"];
        NSNumber * expiration = [config objectForKey:@"esm_expiration_threshold"];
        NSNumber * isNa = [config objectForKey:@"esm_na"];
        
        bool naState = NO;
        if (isNa != nil) naState = isNa.intValue;
        
        self.esm_title = title;
        self.esm_instructions = instructions;
        self.esm_submit = submit;
        self.esm_expiration_threshold = expiration;
        self.esm_na = @(naState);
    }
    return self;
}

- (instancetype) initAsTextESMWithTrigger:(NSString *) trigger{
    self = [self init];
    
    esmDict = [self setBasicElementsWithESMType:AwareESMTypeText
                                        trigger:trigger];

    if (esmDict != nil) {
        self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
    }
    
    return self;
}

- (instancetype) initAsRadioESMWithTrigger:(NSString *) trigger
                                radioItems:(NSArray *) radioItems{
    self = [self init];
    if (radioItems != nil) {
        esmDict = [self setBasicElementsWithESMType:AwareESMTypeRadio
                                            trigger:trigger];
        self.esm_radios = [self convertToJSONStringWithArray:radioItems];
        if (esmDict != nil) {
            [esmDict setObject:radioItems forKey:@"esm_radios"];
            self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
        }
    }
    
    return self;
}

- (instancetype) initAsCheckboxESMWithTrigger:(NSString *) trigger
                                   checkboxes:(NSArray *) checkboxes{
    self = [self init];
    if(checkboxes != nil){
        esmDict = [self setBasicElementsWithESMType:AwareESMTypeCheckbox
                                                                  trigger:trigger];
        self.esm_checkboxes = [self convertToJSONStringWithArray:checkboxes];
        if (esmDict != nil) {
            [esmDict setObject:checkboxes forKey:@"esm_checkboxes"];
            self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
        }
    }
    return self;
}


- (instancetype) initAsLikertScaleESMWithTrigger:(NSString *) trigger
                                       likertMax:(int) likertMax
                                  likertMinLabel:(NSString *) minLabel
                                  likertMaxLabel:(NSString *) maxLabel
                                      likertStep:(int) likertStep{
    self = [self init];
    if ( minLabel != nil && maxLabel != nil ) {
        esmDict = [self setBasicElementsWithESMType:AwareESMTypeLikertScale
                                                                  trigger:trigger];
        self.esm_likert_max = @(likertMax);
        self.esm_likert_min_label = minLabel;
        self.esm_likert_max_label = maxLabel;
        self.esm_likert_step = @(likertStep);
        if (esmDict != nil) {
            [esmDict setObject:@(likertMax) forKey:@"esm_likert_max"];
            [esmDict setObject:@(likertStep) forKey:@"esm_likert_step"];
            [esmDict setObject:minLabel forKey:@"esm_likert_min_label"];
            [esmDict setObject:maxLabel forKey:@"esm_likert_max_label"];
            self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
        }
    }
    return self;
}

- (instancetype) initAsQuickAnawerESMWithTrigger:(NSString *) trigger
                                    quickAnswers:(NSArray *) quickAnswers{
    self = [self init];
    if(quickAnswers != nil){
        esmDict = [self setBasicElementsWithESMType:AwareESMTypeQuickAnswer
                                                                  trigger:trigger];
        self.esm_quick_answers = [self convertToJSONStringWithArray:quickAnswers];
        if (esmDict!=nil) {
            [esmDict setObject:quickAnswers forKey:@"esm_quick_answers"];
            self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
        }
    }
    
    
    return self;
}

- (instancetype) initAsScaleESMWithTrigger:(NSString *) trigger
                                  scaleMin:(int)scaleMin
                                  scaleMax:(int)scaleMax
                                scaleStart:(int)scaleStart
                             scaleMinLabel:(NSString *)minLabel
                             scaleMaxLabel:(NSString *)maxLabel
                                 scaleStep:(int)step{
    self = [self init];
    if (minLabel != nil && maxLabel != nil) {
        esmDict = [self setBasicElementsWithESMType:AwareESMTypeScale
                                                                  trigger:trigger];
        [esmDict setObject:@(scaleMin) forKey:@"esm_scale_min"];
        [esmDict setObject:@(scaleMax) forKey:@"esm_scale_max"];
        [esmDict setObject:@(scaleStart) forKey:@"esm_scale_start"];
        [esmDict setObject:minLabel forKey:@"esm_scale_min_label"];
        [esmDict setObject:maxLabel forKey:@"esm_scale_max_label"];
        
        self.esm_scale_min = @(scaleMin);
        self.esm_scale_max = @(scaleMax);
        self.esm_scale_start = @(scaleStart);
        self.esm_scale_min_label = minLabel;
        self.esm_scale_max_label = maxLabel;
        self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
    }
    return self;
}

- (instancetype) initAsDateTimeESMWithTrigger:(NSString *) trigger{
    self = [self init];
    esmDict = [self setBasicElementsWithESMType:AwareESMTypeDateTime
                                                              trigger:trigger];
    if (esmDict != nil) {
        self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
    }
    return self;
}

- (instancetype) initAsPAMESMWithTrigger:(NSString *) trigger{
    self = [self init];
    esmDict = [self setBasicElementsWithESMType:AwareESMTypePAM
                                                              trigger:trigger];
    if (esmDict!=nil) {
        self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
    }
    return self;
}

- (instancetype) initAsNumericESMWithTrigger:(NSString *) trigger{
    self = [self init];
    esmDict = [self setBasicElementsWithESMType:AwareESMTypeNumeric
                                                              trigger:trigger];
    if (esmDict != nil) {
        self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
    }
    return self;
}

- (instancetype) initAsWebESMWithTrigger:(NSString *) trigger
                                     url:(NSString *) url{
    self = [self init];
    if (url!=nil) {
        esmDict = [self setBasicElementsWithESMType:AwareESMTypeWeb
                                                                  trigger:trigger];
        self.esm_url = url;
        if (esmDict != nil) {
            [esmDict setObject:url forKey:@"esm_url"];
            self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
        }
    }
    return self;
}

//////////////////////////////////////

- (NSMutableDictionary * ) setBasicElementsWithESMType:(AwareESMType)type
                                               trigger:(NSString *) trigger{
    self.esm_type = @(type);
    
    if (trigger != nil) {
        self.esm_trigger = trigger;
    }else{
        self.esm_trigger = [[NSUUID UUID] init].UUIDString;
    }
    
    NSMutableDictionary * esmDict = [[NSMutableDictionary alloc] initWithObjects:@[@(type), self.esm_trigger,self.esm_expiration_threshold,self.esm_title, self.esm_instructions, self.esm_submit, self.esm_na] forKeys:@[@"esm_type",@"esm_trigger", @"esm_expiration_threshold", @"esm_title", @"esm_instructions", @"esm_submit", @"esm_na"]];
    return esmDict;
}

- (void) setTitle:(NSString *) title{
    self.esm_title = title;
    if (esmDict!=nil) {
        [esmDict setObject:title forKey:@"esm_title"];
        self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
    }
}

- (void) setInstructions:(NSString *) instructions{
    self.esm_instructions = instructions;
    if (esmDict!=nil) {
        [esmDict setObject:instructions forKey:@"esm_instructions"];
        self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
    }
}

- (void) setSubmitButtonName:(NSString *) submit{
    self.esm_submit = submit;
    if (esmDict!=nil) {
        [esmDict setObject:submit forKey:@"esm_submit"];
        self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
    }
}

- (void) setESMExpirationMin:(int)expiration{
    self.esm_expiration_threshold = @(expiration);
    if (esmDict!=nil) {
        [esmDict setObject:@(expiration) forKey:@"esm_expiration_threshold"];
        self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
    }
}

- (void) setNARequirement:(BOOL)na{
    self.esm_na = @(na);
    if (esmDict!=nil) {
        [esmDict setObject:@(na) forKey:@"esm_na"];
        self.esm_json = [self convertToJSONStringWithDictionary:esmDict];
    }
}

////////////////////////////////

- (NSString *) convertToJSONStringWithArray:(NSArray *) array{
    NSError * error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        NSLog(@"[EntityESM] Convert Error to JSON-String from NSArray: %@", error.debugDescription);
        return @"";
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (jsonString != nil) {
        return jsonString;
    }else{
        return @"";
    }
}

- (NSString *) convertToJSONStringWithDictionary:(NSDictionary *) dictionary{
    NSError * error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        NSLog(@"[EntityESM] Convert Error to JSON-String from NSDictionary: %@", error.debugDescription);
        return @"";
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (jsonString != nil) {
        return jsonString;
    }else{
        return @"";
    }
}


@end
