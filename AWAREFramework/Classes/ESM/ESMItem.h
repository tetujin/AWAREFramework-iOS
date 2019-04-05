//
//  ESMItem.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/27.
//

#import <Foundation/Foundation.h>
#import "EntityESM+CoreDataClass.h"

@interface ESMItem : NSObject

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, readonly) NSString *device_id;
@property (nonatomic, readonly) NSNumber *double_esm_user_answer_timestamp;
@property (nonatomic, readonly) NSString *esm_checkboxes;
@property (nonatomic, readonly) NSNumber *esm_expiration_threshold;
@property (nonatomic, readonly) NSString *esm_flows;
@property (nonatomic, readonly) NSString *esm_instructions;
@property (nonatomic, readonly) NSString *esm_json;
@property (nonatomic, readonly) NSNumber *esm_likert_max;
@property (nonatomic, readonly) NSString *esm_likert_max_label;
@property (nonatomic, readonly) NSString *esm_likert_min_label;
@property (nonatomic, readonly) NSNumber *esm_likert_step;
@property (nonatomic, readonly) NSNumber *esm_minute_step;
@property (nonatomic, readonly) NSNumber *esm_na;
@property (nonatomic, readonly) NSNumber *esm_number;
@property (nonatomic, readonly) NSString *esm_quick_answers;
@property (nonatomic, readonly) NSString *esm_radios;
@property (nonatomic, readonly) NSNumber *esm_scale_max;
@property (nonatomic, readonly) NSString *esm_scale_max_label;
@property (nonatomic, readonly) NSNumber *esm_scale_min;
@property (nonatomic, readonly) NSString *esm_scale_min_label;
@property (nonatomic, readonly) NSNumber *esm_scale_start;
@property (nonatomic, readonly) NSNumber *esm_scale_step;
@property (nonatomic, readonly, nullable) NSString *esm_start_date;
@property (nonatomic, readonly, nullable) NSString *esm_start_time;
@property (nonatomic, readonly) NSNumber *esm_status;
@property (nonatomic, readonly) NSString *esm_submit;
@property (nonatomic, readonly) NSString *esm_time_format;
@property (nonatomic, readonly) NSString *esm_title;
@property (nonatomic, readonly) NSString *esm_trigger;
@property (nonatomic, readonly) NSNumber *esm_type;
@property (nonatomic, readonly) NSString *esm_url;
@property (nonatomic, readonly) NSString *esm_user_answer;
@property (nonatomic, readonly) NSNumber *timestamp;
@property (nonatomic, readonly) NSString *esm_app_integration;

- (instancetype) initWithConfiguration:(NSDictionary *) config;

- (instancetype) initAsTextESMWithTrigger:(NSString *) trigger;

- (instancetype) initAsRadioESMWithTrigger:(NSString *) trigger
                              radioItems:(NSArray *) radioItems;

- (instancetype) initAsCheckboxESMWithTrigger:(NSString *) trigger
                                 checkboxes:(NSArray *) checkboxes;

- (instancetype) initAsLikertScaleESMWithTrigger:(NSString *) trigger
                                     likertMax:(int) likertMax
                                likertMinLabel:(NSString *) minLabel
                                likertMaxLabel:(NSString *) maxLabel
                                    likertStep:(int) likertStep;

- (instancetype) initAsQuickAnawerESMWithTrigger:(NSString *) trigger
                                  quickAnswers:(NSArray *) quickAnswers;

- (instancetype) initAsScaleESMWithTrigger:(NSString *) trigger
                                scaleMin:(int)scaleMin
                                scaleMax:(int)scaleMax
                              scaleStart:(int)scaleStart
                           scaleMinLabel:(NSString *)minLabel
                           scaleMaxLabel:(NSString *)maxLabel
                               scaleStep:(int)step;

- (instancetype) initAsDateTimeESMWithTrigger:(NSString *) trigger;
- (instancetype) initAsDateTimeESMWithTrigger:(NSString *) trigger minutesGranularity:(NSNumber * _Nullable) granularity;

- (instancetype) initAsPAMESMWithTrigger:(NSString *) trigger;

- (instancetype) initAsNumericESMWithTrigger:(NSString *) trigger;

- (instancetype) initAsWebESMWithTrigger:(NSString *) trigger
                                   url:(NSString *) url;

- (instancetype) initAsTimePickerESMWithTrigger:(NSString *)trigger;
- (instancetype) initAsTimePickerESMWithTrigger:(NSString *)trigger minutesGranularity:(NSNumber * _Nullable) granularity;
- (instancetype) initAsDatePickerESMWithTrigger:(NSString *)trigger;
- (instancetype) initAsClockDatePickerESMWithTrigger:(NSString *)trigger;
- (instancetype) initAsPictureESMWithTrigger:(NSString *)trigger;
- (instancetype) initAsAudioESMWithTrigger:(NSString *)trigger;
- (instancetype) initAsVideoESMWithTrigger:(NSString *)trigger;

- (void) setTitle:(NSString *) title;
- (void) setInstructions:(NSString *) instructions;
- (void) setSubmitButtonName:(NSString *) submit;
- (void) setExpirationWithMinute:(int)expiration;
- (void) setNARequirement:(BOOL)na;
- (void) setNumber:(int)number;
- (BOOL) setFlowWithItems:(NSArray<ESMItem *>*)items answerKey:(NSArray <NSString *>*)keys;
- (void) setType:(int)type;
- (void) setTrigger:(NSString *)trigger;

NS_ASSUME_NONNULL_END

@end

