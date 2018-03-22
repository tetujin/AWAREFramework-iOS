//
//  ESMObject.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/23/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const KEY_ESM_TYPE;
extern NSString* const KEY_ESM_STYLE;
extern NSString* const KEY_ESM_TITLE;
extern NSString* const KEY_ESM_SUBMIT;
extern NSString* const KEY_ESM_INSTRUCTIONS;
extern NSString* const KEY_ESM_RADIOS;
extern NSString* const KEY_ESM_CHECKBOXES;
extern NSString* const KEY_ESM_LIKERT_MAX;
extern NSString* const KEY_ESM_LIKERT_MAX_LABEL;
extern NSString* const KEY_ESM_LIKERT_MIN_LABEL;
extern NSString* const KEY_ESM_LIKERT_STEP;
extern NSString* const KEY_ESM_QUICK_ANSWERS;
extern NSString* const KEY_ESM_EXPIRATION_THRESHOLD;
extern NSString* const KEY_ESM_STATUS;
extern NSString* const KEY_ESM_USER_ANSWER_TIMESTAMP;
extern NSString* const KEY_ESM_USER_ANSWER;
extern NSString* const KEY_ESM_TRIGGER;
extern NSString* const KEY_ESM_SCALE_MIN;
extern NSString* const KEY_ESM_SCALE_MAX;
extern NSString* const KEY_ESM_SCALE_START;
extern NSString* const KEY_ESM_SCALE_MAX_LABEL;
extern NSString* const KEY_ESM_SCALE_MIN_LABEL;
extern NSString* const KEY_ESM_SCALE_STEP;
extern NSString* const KEY_ESM_IOS;

@interface SingleESMObject : NSObject
{
//    //extern NSString* const KEY_ESM_TYPE;
//    NSNumber* type;
//    //extern NSString* const KEY_ESM_TITLE;
//    NSString * title;
//    //extern NSString* const KEY_ESM_SUBMIT;
//    NSString * submit;
//    //extern NSString* const KEY_ESM_INSTRUCTIONS;
//    NSString * instructions;
//    //extern NSString* const KEY_ESM_RADIOS;
//    NSArray * radios;
//    //extern NSString* const KEY_ESM_CHECKBOXES;
//    NSArray * checkBoxes;
//    //extern NSString* const KEY_ESM_LIKERT_MAX;
//    NSNumber * likertMax;
//    //extern NSString* const KEY_ESM_LIKERT_MAX_LABEL;
//    NSNumber * likertMaxLabel;
//    //extern NSString* const KEY_ESM_LIKERT_MIN_LABEL;
//    NSString * likertMinLabel;
//    //extern NSString* const KEY_ESM_LIKERT_STEP;
//    NSNumber * likerStep;
//    //extern NSString* const KEY_ESM_QUICK_ANSWERS;
//    NSArray * quickAnswers;
//    //extern NSString* const KEY_ESM_EXPIRATION_THRESHOLD;
//    NSNumber * expirationThreshold;
//    //extern NSString* const KEY_ESM_STATUS;
//    NSNumber * status;
//    //extern NSString* const KEY_DOUBLE_ESM_USER_ANSWER_TIMESTAMP;
//    NSString * userAnswerTimestamp;
//    //extern NSString* const KEY_ESM_USER_ANSWER;
//    NSString * userAnswer;
//    //extern NSString* const KEY_ESM_TRIGGER;
//    NSString * esmTrigger;
//    //extern NSString* const KEY_ESM_SCALE_MIN;
//    NSNumber * scaleMin;
//    //extern NSString* const KEY_ESM_SCALE_MAX;
//    NSNumber * scaleMax;
//    //extern NSString* const KEY_ESM_SCALE_START;
//    NSNumber * scaleStart;
//    //extern NSString* const KEY_ESM_SCALE_MAX_LABEL;
//    NSString * scaleMaxLabel;
//    //extern NSString* const KEY_ESM_SCALE_MIN_LABEL;
//    NSString * scaleMinLabel;
//    //extern NSString* const KEY_ESM_SCALE_STEP;
//    NSNumber * scaleStep;
//    //@property (strong, nonatomic) IBOutlet NSNumber * esmiOS;
//    
//    NSMutableDictionary * esmObject;
//    NSMutableDictionary * esmObjectWithKey;
}

- (instancetype)initWithEsm:(NSDictionary* )esmObj;

//extern NSString* const KEY_ESM_TYPE;
@property (strong, nonatomic) IBOutlet NSNumber* type;
// extern NSString* const KEY_ESM_STYLE;
@property (strong, nonatomic) IBOutlet NSNumber* style;
//extern NSString* const KEY_ESM_TITLE;
@property (strong, nonatomic) IBOutlet NSString * title;
//extern NSString* const KEY_ESM_SUBMIT;
@property (strong, nonatomic) IBOutlet NSString * submit;
//extern NSString* const KEY_ESM_INSTRUCTIONS;
@property (strong, nonatomic) IBOutlet NSString * instructions;
//extern NSString* const KEY_ESM_RADIOS;
@property (strong, nonatomic) IBOutlet NSArray * radios;
//extern NSString* const KEY_ESM_CHECKBOXES;
@property (strong, nonatomic) IBOutlet NSArray * checkBoxes;
//extern NSString* const KEY_ESM_LIKERT_MAX;
@property (strong, nonatomic) IBOutlet NSNumber * likertMax;
//extern NSString* const KEY_ESM_LIKERT_MAX_LABEL;
@property (strong, nonatomic) IBOutlet NSNumber * likertMaxLabel;
//extern NSString* const KEY_ESM_LIKERT_MIN_LABEL;
@property (strong, nonatomic) IBOutlet NSString * likertMinLabel;
//extern NSString* const KEY_ESM_LIKERT_STEP;
@property (strong, nonatomic) IBOutlet NSNumber * likerStep;
//extern NSString* const KEY_ESM_QUICK_ANSWERS;
@property (strong, nonatomic) IBOutlet NSArray * quickAnswers;
//extern NSString* const KEY_ESM_EXPIRATION_THRESHOLD;
@property (strong, nonatomic) IBOutlet NSNumber * expirationThreshold;
//extern NSString* const KEY_ESM_STATUS;
@property (strong, nonatomic) IBOutlet NSNumber * status;
//extern NSString* const KEY_DOUBLE_ESM_USER_ANSWER_TIMESTAMP;
@property (strong, nonatomic) IBOutlet NSString * userAnswerTimestamp;
//extern NSString* const KEY_ESM_USER_ANSWER;
@property (strong, nonatomic) IBOutlet NSString * userAnswer;
//extern NSString* const KEY_ESM_TRIGGER;
@property (strong, nonatomic) IBOutlet NSString * esmTrigger;
//extern NSString* const KEY_ESM_SCALE_MIN;
@property (strong, nonatomic) IBOutlet NSNumber * scaleMin;
//extern NSString* const KEY_ESM_SCALE_MAX;
@property (strong, nonatomic) IBOutlet NSNumber * scaleMax;
//extern NSString* const KEY_ESM_SCALE_START;
@property (strong, nonatomic) IBOutlet NSNumber * scaleStart;
//extern NSString* const KEY_ESM_SCALE_MAX_LABEL;
@property (strong, nonatomic) IBOutlet NSString * scaleMaxLabel;
//extern NSString* const KEY_ESM_SCALE_MIN_LABEL;
@property (strong, nonatomic) IBOutlet NSString * scaleMinLabel;
//extern NSString* const KEY_ESM_SCALE_STEP;
@property (strong, nonatomic) IBOutlet NSNumber * scaleStep;
//@property (strong, nonatomic) IBOutlet NSNumber * esmiOS;

@property (strong, nonatomic) IBOutlet NSMutableDictionary * esmObject;
@property (strong, nonatomic) IBOutlet NSMutableDictionary * esmObjectWithKey;


- (bool) isSingleEsm;
//- (NSMutableDictionary*) getEsmDictionaryWithDeviceId:(NSString*)deviceId timestamp:(double) timestamp;


+ (NSMutableDictionary*) getEsmDictionaryWithDeviceId:(NSString*)deviceId
                                            timestamp:(double) timestamp
                                                 type:(NSNumber *) type
                                                title:(NSString *) title
                                         instructions:(NSString *) instructions
                                               submit:(NSString *) submit
                                  expirationThreshold:(NSNumber *) expirationThreshold
                                              trigger:(NSString*) trigger;


+ (NSMutableDictionary*) getEsmDictionaryAsFreeTextWithDeviceId:(NSString*)deviceId
                                                      timestamp:(double) timestamp
                                                          title:(NSString *) title
                                                   instructions:(NSString *) instructions
                                                         submit:(NSString *) submit
                                            expirationThreshold:(NSNumber *) expirationThreshold
                                                        trigger:(NSString*) trigger;

+ (NSMutableDictionary*) getEsmDictionaryAsRadioWithDeviceId:(NSString*)deviceId
                                                   timestamp:(double) timestamp
                                                       title:(NSString *) title
                                                instructions:(NSString *) instructions
                                                      submit:(NSString *) submit
                                         expirationThreshold:(NSNumber *) expirationThreshold
                                                     trigger:(NSString*) trigger
                                                      radios:(NSArray *) radios;


+ (NSMutableDictionary *) getEsmDictionaryAsCheckBoxWithDeviceId:(NSString*)deviceId
                                                       timestamp:(double) timestamp
                                                           title:(NSString *) title
                                                    instructions:(NSString *) instructions
                                                          submit:(NSString *) submit
                                             expirationThreshold:(NSNumber *) expirationThreshold
                                                         trigger:(NSString*) trigger
                                                      checkBoxes:(NSArray *) checkBoxes;



+ (NSMutableDictionary *) getEsmDictionaryAsLikertScaleWithDeviceId:(NSString*)deviceId
                                                          timestamp:(double) timestamp
                                                              title:(NSString *) title
                                                       instructions:(NSString *) instructions
                                                             submit:(NSString *) submit
                                                expirationThreshold:(NSNumber *) expirationThreshold
                                                            trigger:(NSString*) trigger
                                                          likertMax:(NSNumber *) likertMax
                                                     likertMaxLabel:(NSString *) likertMaxLabel
                                                     likertMinLabel:(NSString *) likertMinLabel
                                                         likertStep:(NSNumber *) likertStep;


+ (NSMutableDictionary *) getEsmDictionaryAsQuickAnswerWithDeviceId:(NSString*)deviceId
                                                          timestamp:(double) timestamp
                                                              title:(NSString *) title
                                                       instructions:(NSString *) instructions
                                                             submit:(NSString *) submit
                                                expirationThreshold:(NSNumber *) expirationThreshold
                                                            trigger:(NSString*) trigger
                                                       quickAnswers:(NSArray *) quickAnswers;


+ (NSMutableDictionary *) getEsmDictionaryAsScaleWithDeviceId:(NSString*)deviceId
                                                    timestamp:(double) timestamp
                                                        title:(NSString *) title
                                                 instructions:(NSString *) instructions
                                                       submit:(NSString *) submit
                                          expirationThreshold:(NSNumber *) expirationThreshold
                                                      trigger:(NSString*) trigger
                                                          min:(NSNumber *) min
                                                          max:(NSNumber *) max
                                                   scaleStart:(NSNumber *) start
                                                     minLabel:(NSString *) minLabel
                                                     maxLabel:(NSString *) maxLabel
                                                    scaleStep:(NSNumber *) scaleStep;


+ (NSMutableDictionary *) getEsmDictionaryAsDatePickerWithDeviceId:(NSString*)deviceId
                                                         timestamp:(double) timestamp
                                                             title:(NSString *) title
                                                      instructions:(NSString *) instructions
                                                            submit:(NSString *) submit
                                               expirationThreshold:(NSNumber *) expirationThreshold
                                                           trigger:(NSString*) trigger;

+ (NSMutableDictionary *) getEsmDictionaryAsPAMWithDeviceId:(NSString*)deviceId
                                                         timestamp:(double) timestamp
                                                             title:(NSString *) title
                                                      instructions:(NSString *) instructions
                                                            submit:(NSString *) submit
                                               expirationThreshold:(NSNumber *) expirationThreshold
                                                           trigger:(NSString*) trigger;
@end
