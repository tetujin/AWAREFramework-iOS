//
//  EntityESM+CoreDataClass.h
//  
//
//  Created by Yuuki Nishiyama on 2017/09/23.
//
//

#import <Foundation/Foundation.h>
#import "EntityESMSchedule.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityESM : EntityESMSchedule

- (EntityESM *) setAsTextESMWithTitle:(NSString *) title
                         instructions:(NSString *) instructions
                                 isNa:(BOOL) isNa
                         submitButton:(NSString *) submitButton;

- (EntityESM *) setAsRadioESMWithTitle:(NSString *) title
                          instructions:(NSString *) instructions
                                  isNa:(BOOL) isNa
                          submitButton:(NSString *) submitButton
                             radioItems:(NSArray *) radioItems;

- (EntityESM *) setAsCheckboxESMWithTitle:(NSString *) title
                             instructions:(NSString *) instructions
                                     isNa:(BOOL) isNa
                             submitButton:(NSString *) submitButton
                            checkboxes:(NSArray *) checkboxes;

- (EntityESM *) setAsLikertScaleESMWithTitle:(NSString *) title
                                instructions:(NSString *) instructions
                                        isNa:(BOOL) isNa
                                submitButton:(NSString *) submitButton
                                   likertMax:(int) likertMax
                                likertMinLabel:(NSString *) minLabel
                                likertMaxLabel:(NSString *) maxLabel
                                    likertStep:(int) likertStep;

- (EntityESM *) setAsQuickAnawerESMWithTitle:(NSString *) title
                                instructions:(NSString *) instructions
                                        isNa:(BOOL) isNa
                                submitButton:(NSString *) submitButton
                                quickAnswers:(NSArray *) quickAnswers;

- (EntityESM *) setAsScaleESMWithTitle:(NSString *) title
                          instructions:(NSString *) instructions
                                  isNa:(BOOL) isNa
                          submitButton:(NSString *) submitButton
                              scaleMin:(int)scaleMin
                               scaleMax:(int)scaleMax
                             scaleStart:(int)scaleStart
                          scaleMinLabel:(NSString *)minLabel
                          scaleMaxLabel:(NSString *)maxLabel
                              scaleStep:(int)step;

- (EntityESM *) setAsDateTimeESMWithTitle:(NSString *) title
                        instructions:(NSString *) instructions
                                isNa:(BOOL) isNa
                        submitButton:(NSString *) submitButton;

- (EntityESM *) setAsPAMESMWithTitle:(NSString *) title
                        instructions:(NSString *) instructions
                                isNa:(BOOL) isNa
                      submitButton:(NSString *) submitButton;

- (EntityESM *) setAsNumericESMWithTitle:(NSString *) title
                            instructions:(NSString *) instructions
                                    isNa:(BOOL) isNa
                            submitButton:(NSString *) submitButton;

- (EntityESM *) setAsWebESMWithTitle:(NSString *) title
                      instructions:(NSString *) instructions
                              isNa:(BOOL) isNa
                      submitButton:(NSString *) submitButton
                               url:(NSString *) url;

@end

NS_ASSUME_NONNULL_END

#import "EntityESM+CoreDataProperties.h"
