//
//  ESMItem.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/27.
//

#import <Foundation/Foundation.h>
#import "EntityESM+CoreDataClass.h"

@interface ESMItem : NSObject

@property (nonatomic) NSString *device_id;
@property (nonatomic) NSNumber *double_esm_user_answer_timestamp;
@property (nonatomic) NSArray *esm_checkboxes;
@property (nonatomic) NSNumber *esm_expiration_threshold;
@property (nonatomic) NSArray *esm_flows;
@property (nonatomic) NSString *esm_instructions;
@property (nonatomic) NSDictionary *esm_json;
@property (nonatomic) NSNumber *esm_likert_max;
@property (nonatomic) NSString *esm_likert_max_label;
@property (nonatomic) NSString *esm_likert_min_label;
@property (nonatomic) NSNumber *esm_likert_step;
@property (nonatomic) NSNumber *esm_minute_step;
@property (nonatomic) BOOL *esm_na;
@property (nonatomic) NSNumber *esm_number;
@property (nonatomic) NSArray *esm_quick_answers;
@property (nonatomic) NSArray *esm_radios;
@property (nonatomic) NSNumber *esm_scale_max;
@property (nonatomic) NSString *esm_scale_max_label;
@property (nonatomic) NSNumber *esm_scale_min;
@property (nonatomic) NSString *esm_scale_min_label;
@property (nonatomic) NSNumber *esm_scale_start;
@property (nonatomic) NSNumber *esm_scale_step;
@property (nonatomic) NSString *esm_start_date;
@property (nonatomic) NSString *esm_start_time;
@property (nonatomic) NSNumber *esm_status;
@property (nonatomic) NSString *esm_submit;
@property (nonatomic) NSString *esm_time_format;
@property (nonatomic) NSString *esm_title;
@property (nonatomic) NSString *esm_trigger;
@property (nonatomic) AwareESMType esm_type;
@property (nonatomic) NSString *esm_url;
@property (nonatomic) NSString *esm_user_answer;
@property (nonatomic) NSNumber *timestamp;
@property (nonatomic) NSString *esm_app_integration;

- (instancetype) initWithConfiguration:(NSDictionary *) config;

- (instancetype) initAsTextESMWithTrigger:(NSString *) trigger
                                  title:(NSString *) title
                           instructions:(NSString *) instructions
                                   isNa:(BOOL) isNa
                           submitButton:(NSString *) submitButton
                    expirationThreshold:(NSNumber *) expirationThreshold;

- (instancetype) initAsRadioESMWithTrigger:(NSString *) trigger
                                   title:(NSString *) title
                            instructions:(NSString *) instructions
                                    isNa:(BOOL) isNa
                            submitButton:(NSString *) submitButton
                     expirationThreshold:(NSNumber *) expirationThreshold
                              radioItems:(NSArray *) radioItems;

- (instancetype) initAsCheckboxESMWithTrigger:(NSString *) trigger
                                      title:(NSString *) title
                               instructions:(NSString *) instructions
                                       isNa:(BOOL) isNa
                               submitButton:(NSString *) submitButton
                        expirationThreshold:(NSNumber *) expirationThreshold
                                 checkboxes:(NSArray *) checkboxes;

- (instancetype) initAsLikertScaleESMWithTrigger:(NSString *) trigger
                                         title:(NSString *) title
                                  instructions:(NSString *) instructions
                                          isNa:(BOOL) isNa
                                  submitButton:(NSString *) submitButton
                           expirationThreshold:(NSNumber *) expirationThreshold
                                     likertMax:(int) likertMax
                                likertMinLabel:(NSString *) minLabel
                                likertMaxLabel:(NSString *) maxLabel
                                    likertStep:(int) likertStep;

- (instancetype) initAsQuickAnawerESMWithTrigger:(NSString *) trigger
                                         title:(NSString *) title
                                  instructions:(NSString *) instructions
                                          isNa:(BOOL) isNa
                                  submitButton:(NSString *) submitButton
                           expirationThreshold:(NSNumber *) expirationThreshold
                                  quickAnswers:(NSArray *) quickAnswers;

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
                               scaleStep:(int)step;

- (instancetype) initAsDateTimeESMWithTrigger:(NSString *) trigger
                                      title:(NSString *) title
                               instructions:(NSString *) instructions
                                       isNa:(BOOL) isNa
                               submitButton:(NSString *) submitButton
                        expirationThreshold:(NSNumber *) expirationThreshold;

- (instancetype) initAsPAMESMWithTrigger:(NSString *) trigger
                                 title:(NSString *) title
                          instructions:(NSString *) instructions
                                  isNa:(BOOL) isNa
                          submitButton:(NSString *) submitButton
                   expirationThreshold:(NSNumber *) expirationThreshold;

- (instancetype) initAsNumericESMWithTrigger:(NSString *) trigger
                                     title:(NSString *) title
                              instructions:(NSString *) instructions
                                      isNa:(BOOL) isNa
                              submitButton:(NSString *) submitButton
                       expirationThreshold:(NSNumber *) expirationThreshold;

- (instancetype) initAsWebESMWithTrigger:(NSString *) trigger
                                 title:(NSString *) title
                          instructions:(NSString *) instructions
                                  isNa:(BOOL) isNa
                          submitButton:(NSString *) submitButton
                   expirationThreshold:(NSNumber *) expirationThreshold
                                   url:(NSString *) url;

@end

