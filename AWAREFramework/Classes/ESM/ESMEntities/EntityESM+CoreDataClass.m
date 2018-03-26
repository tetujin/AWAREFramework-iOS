//
//  EntityESM+CoreDataClass.m
//  
//
//  Created by Yuuki Nishiyama on 2017/09/23.
//
//

#import "EntityESM+CoreDataClass.h"

@implementation EntityESM

- (void) setBasicInfoWithTitle:(NSString *) title
                  instructions:(NSString *) instructions
                  submitButton:(NSString *) submitButton
                          isNa:(BOOL) isNa {
    self.esm_title = title;
    self.esm_instructions = instructions;
    self.esm_submit = submitButton;
    self.esm_na = @(isNa);
}

- (EntityESM *) setAsTextESMWithTitle:(NSString *) title
                         instructions:(NSString *) instructions
                                 isNa:(BOOL) isNa
                         submitButton:(NSString *) submitButton{
    [self setBasicInfoWithTitle:title instructions:instructions submitButton:submitButton isNa:isNa];
    self.esm_type = @1;
    return self;
}

- (EntityESM *) setAsRadioESMWithTitle:(NSString *) title
                          instructions:(NSString *) instructions
                                  isNa:(BOOL) isNa
                          submitButton:(NSString *) submitButton
                            radioItems:(NSArray *) radioItems{
    [self setBasicInfoWithTitle:title instructions:instructions submitButton:submitButton isNa:isNa];
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

- (EntityESM *) setAsCheckboxESMWithTitle:(NSString *) title
                             instructions:(NSString *) instructions
                                     isNa:(BOOL) isNa
                             submitButton:(NSString *) submitButton
                               checkboxes:(NSArray *) checkboxes{
    [self setBasicInfoWithTitle:title instructions:instructions submitButton:submitButton isNa:isNa];
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

- (EntityESM *) setAsLikertScaleESMWithTitle:(NSString *) title
                                instructions:(NSString *) instructions
                                        isNa:(BOOL) isNa
                                submitButton:(NSString *) submitButton
                                   likertMax:(int) likertMax
                              likertMinLabel:(NSString *) minLabel
                              likertMaxLabel:(NSString *) maxLabel
                                  likertStep:(int) likertStep{
    [self setBasicInfoWithTitle:title instructions:instructions submitButton:submitButton isNa:isNa];
    self.esm_type = @4;
    self.esm_likert_max = @(likertMax);
    self.esm_likert_max_label = maxLabel;
    self.esm_likert_min_label = minLabel;
    self.esm_likert_step = @(likertStep);
    return self;
}

- (EntityESM *) setAsQuickAnawerESMWithTitle:(NSString *) title
                                instructions:(NSString *) instructions
                                        isNa:(BOOL) isNa
                                submitButton:(NSString *) submitButton
                                quickAnswers:(NSArray *) quickAnswers{
    [self setBasicInfoWithTitle:title instructions:instructions submitButton:submitButton isNa:isNa];
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

- (EntityESM *) setAsScaleESMWithTitle:(NSString *) title
                          instructions:(NSString *) instructions
                                  isNa:(BOOL) isNa
                          submitButton:(NSString *) submitButton
                              scaleMin:(int)scaleMin
                              scaleMax:(int)scaleMax
                            scaleStart:(int)scaleStart
                         scaleMinLabel:(NSString *)minLabel
                         scaleMaxLabel:(NSString *)maxLabel
                             scaleStep:(int)step{
    [self setBasicInfoWithTitle:title instructions:instructions submitButton:submitButton isNa:isNa];
    self.esm_type = @6;
    self.esm_scale_min = @(scaleMin);
    self.esm_scale_max = @(scaleMax);
    self.esm_scale_start = @(scaleStart);
    self.esm_scale_min_label = minLabel;
    self.esm_scale_max_label = maxLabel;
    self.esm_scale_step = @(step);
    return self;
}

- (EntityESM *)setAsDateTimeESMWithTitle:(NSString *)title instructions:(NSString *)instructions isNa:(BOOL)isNa submitButton:(NSString *)submitButton{
    self.esm_type = @7;
    return self;
}

- (EntityESM *)setAsPAMESMWithTitle:(NSString *)title instructions:(NSString *)instructions isNa:(BOOL)isNa submitButton:(NSString *)submitButton{
    self.esm_type = @8;
    return self;
}

- (EntityESM *) setAsNumericESMWithTitle:(NSString *) title
                            instructions:(NSString *) instructions
                                    isNa:(BOOL) isNa
                            submitButton:(NSString *) submitButton{
    [self setBasicInfoWithTitle:title instructions:instructions submitButton:submitButton isNa:isNa];
    self.esm_type = @9;
    return self;
}


- (EntityESM *)setAsWebESMWithTitle:(NSString *)title instructions:(NSString *)instructions isNa:(BOOL)isNa submitButton:(NSString *)submitButton url:(NSString *)url{
    self.esm_type = @10;
    self.esm_url = url;
    return self;
}


@end
