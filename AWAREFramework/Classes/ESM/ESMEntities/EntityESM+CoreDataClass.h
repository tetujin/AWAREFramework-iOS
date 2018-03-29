//
//  EntityESM+CoreDataClass.h
//  
//
//  Created by Yuuki Nishiyama on 2017/09/23.
//
//

#import <Foundation/Foundation.h>
#import "EntityESMSchedule+CoreDataClass.h"
#import "ESMItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum: NSInteger {
    AwareESMTypeNone        = 0,
    AwareESMTypeText        = 1,
    AwareESMTypeRadio       = 2,
    AwareESMTypeCheckbox    = 3,
    AwareESMTypeLikertScale = 4,
    AwareESMTypeQuickAnswer = 5,
    AwareESMTypeScale       = 6,
    AwareESMTypeDateTime    = 7,
    AwareESMTypePAM         = 8,
    AwareESMTypeNumeric     = 9,
    AwareESMTypeWeb         = 10
} AwareESMType;

@interface EntityESM : EntityESMSchedule

- (EntityESM *) setESMWithConfiguration:(NSDictionary *) config;

- (EntityESM *) setAsTextESMWithTrigger:(NSString *) trigger
                                   json:(NSString *) jsonString
                                  title:(NSString *) title
                           instructions:(NSString *) instructions
                                   isNa:(BOOL) isNa
                           submitButton:(NSString *) submitButton
                    expirationThreshold:(NSNumber *) expirationThreshold;

- (EntityESM *) setAsRadioESMWithTrigger:(NSString *) trigger
                                    json:(NSString *) jsonString
                                   title:(NSString *) title
                            instructions:(NSString *) instructions
                                    isNa:(BOOL) isNa
                            submitButton:(NSString *) submitButton
                      expirationThreshold:(NSNumber *) expirationThreshold
                              radioItems:(NSArray *) radioItems;

- (EntityESM *) setAsCheckboxESMWithTrigger:(NSString *) trigger
                                       json:(NSString *) jsonString
                                      title:(NSString *) title
                               instructions:(NSString *) instructions
                                       isNa:(BOOL) isNa
                               submitButton:(NSString *) submitButton
                         expirationThreshold:(NSNumber *) expirationThreshold
                                 checkboxes:(NSArray *) checkboxes;

- (EntityESM *) setAsLikertScaleESMWithTrigger:(NSString *) trigger
                                          json:(NSString *) jsonString
                                         title:(NSString *) title
                                  instructions:(NSString *) instructions
                                          isNa:(BOOL) isNa
                                  submitButton:(NSString *) submitButton
                            expirationThreshold:(NSNumber *) expirationThreshold
                                     likertMax:(int) likertMax
                                likertMinLabel:(NSString *) minLabel
                                likertMaxLabel:(NSString *) maxLabel
                                    likertStep:(int) likertStep;

- (EntityESM *) setAsQuickAnawerESMWithTrigger:(NSString *) trigger
                                          json:(NSString *) jsonString
                                         title:(NSString *) title
                                  instructions:(NSString *) instructions
                                          isNa:(BOOL) isNa
                                  submitButton:(NSString *) submitButton
                            expirationThreshold:(NSNumber *) expirationThreshold
                                  quickAnswers:(NSArray *) quickAnswers;

- (EntityESM *) setAsScaleESMWithTrigger:(NSString *) trigger
                                    json:(NSString *) jsonString
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

- (EntityESM *) setAsDateTimeESMWithTrigger:(NSString *) trigger
                                       json:(NSString *) jsonString
                                      title:(NSString *) title
                               instructions:(NSString *) instructions
                                       isNa:(BOOL) isNa
                               submitButton:(NSString *) submitButton
                         expirationThreshold:(NSNumber *) expirationThreshold;

- (EntityESM *) setAsPAMESMWithTrigger:(NSString *) trigger
                                  json:(NSString *) jsonString
                                 title:(NSString *) title
                          instructions:(NSString *) instructions
                                  isNa:(BOOL) isNa
                          submitButton:(NSString *) submitButton
                    expirationThreshold:(NSNumber *) expirationThreshold;

- (EntityESM *) setAsNumericESMWithTrigger:(NSString *) trigger
                                      json:(NSString *) jsonString
                                     title:(NSString *) title
                              instructions:(NSString *) instructions
                                      isNa:(BOOL) isNa
                              submitButton:(NSString *) submitButton
                        expirationThreshold:(NSNumber *) expirationThreshold;

- (EntityESM *) setAsWebESMWithTrigger:(NSString *) trigger
                                  json:(NSString *) jsonString
                                 title:(NSString *) title
                          instructions:(NSString *) instructions
                                  isNa:(BOOL) isNa
                          submitButton:(NSString *) submitButton
                    expirationThreshold:(NSNumber *) expirationThreshold
                                   url:(NSString *) url;

@end

NS_ASSUME_NONNULL_END

#import "EntityESM+CoreDataProperties.h"
