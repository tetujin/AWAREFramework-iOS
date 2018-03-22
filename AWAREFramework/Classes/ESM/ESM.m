//
//  ESM.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/16/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

/** ESM and WebESM plugin are replaced to iOS ESM ( = IOSESM class) plugin */

#import "ESM.h"
#import "AWAREEsmUtils.h"
#import "AWARESchedule.h"
#import "ESMStorageHelper.h"
#import "Debug.h"
#import "ESMSchedule.h"
#import "ESMManager.h"
#import "AWAREUtils.h"
#import "WebESM.h"

@implementation ESM {
    WebESM * webESM;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:@"esms"
                        dbEntityName:nil
                              dbType:AwareDBTypeTextFile];
    if (self) {
        webESM = [[WebESM alloc] initWithAwareStudy:study dbType:AwareDBTypeCoreData];
    }
    return self;
}

- (void) createTable {
//    NSLog(@"[%@] Create Table", [self getSensorName]);
//    
//    TCQMaker *tcqMaker = [[TCQMaker alloc] init];
//    [tcqMaker addColumn:@"esm_json"                         type:TCQTypeText    default:@"''"];
//    [tcqMaker addColumn:@"esm_status"                       type:TCQTypeInteger default:@"0"];
//    [tcqMaker addColumn:@"esm_expiration_threshold"         type:TCQTypeInteger default:@"0"];
//    [tcqMaker addColumn:@"double_esm_user_answer_timestamp" type:TCQTypeReal    default:@"0"];
//    [tcqMaker addColumn:@"esm_user_answer"                  type:TCQTypeText    default:@"''"];
//    [tcqMaker addColumn:@"esm_trigger"                      type:TCQTypeText    default:@"''"];
//    NSString * query = [tcqMaker getTableCreateQueryWithUniques:nil];
//    
//    [super createTable:query];
}

/**
 * DEFAULT:
 *
 */
-(BOOL)startSensorWithSettings:(NSArray *)settings{

    //    // Make ESM configurations
//    NSString * esmId = @"test_esm"; //Identifer of a notification
//    NSString * notificationTitle = @"ESM from AWARE iOS client"; // Notification title (iOS9 or later are support this function)
//    NSString * notificationBody = @"Tap to answer!"; // Notification Body
//    NSMutableArray * esms = [self getESMDictionaries]; // Generate ESM objects. Please refer to the -getESMDictionaries.
//    // NSDate * now = [NSDate new];
//    NSArray * hours = [NSArray arrayWithObjects:@(-1), @1,@2,@3,@4,@5,@6,@7,@8,@9,@10,@11,@12,@13,@14,@15,@16,@17,@18,@19,@20,@21,@22,@23,nil];
//    NSInteger timeout = 60*10; // Timeout
//
//    // Set the information to ESMSchedule
//    ESMSchedule * schedule = [[ESMSchedule alloc] initWithIdentifier:esmId
//                                                       scheduledESMs:esms
//                                                           fireHours:hours
//                                                               title:notificationTitle
//                                                                body:notificationBody
//                                                            interval:NSCalendarUnitDay
//                                                            category:[self getSensorName]
//                                                                icon:1
//                                                             timeout:timeout
//                                                   randomizeSchedule:@0
//                                                             context:@[]
//                                                           startDate:nil
//                                                             endDate:nil];
//    //    // Add the schedule to ESMManager
//    
//    [webESM removeNotificationSchedules];
//    
//    [webESM setWebESMsWithSchedule:schedule];
    
    return YES;
}

- (BOOL)stopSensor{

    return YES;
}


- (NSMutableArray *) getSampleFireHours{
    NSDate * now = [NSDate new];
    NSArray * hours = [NSArray arrayWithObjects:@1,@2,@3,@4,@5,@6,@7,@8,@9,@10,@11,@12,@13,@14,@15,@16,@17,@18,@19,@20,@21,@22,@23,nil];
    NSMutableArray * fireHours = [[NSMutableArray alloc] init]; // Generate fire NSDates
    for (NSNumber * hour in hours) {
        [fireHours addObject:[AWAREUtils getTargetNSDate:now hour:[hour intValue] nextDay:YES]];
    }
    return fireHours;
}


- (NSMutableArray *) getESMDictionaries {
    NSString * deviceId = @"";
    NSString * submit = @"Next";
    double timestamp = 0;
    NSNumber * exprationThreshold = [NSNumber numberWithInt:60];
    NSString * trigger = @"trigger";
    
    NSMutableDictionary *dicFreeText = [SingleESMObject getEsmDictionaryAsFreeTextWithDeviceId:deviceId
                                                                               timestamp:timestamp
                                                                                   title:@"ESM Freetext"
                                                                            instructions:@"The user can answer an open ended question." submit:submit
                                                                     expirationThreshold:exprationThreshold
                                                                                 trigger:trigger];
    
    NSMutableDictionary *dicRadio = [SingleESMObject getEsmDictionaryAsRadioWithDeviceId:deviceId
                                                                         timestamp:timestamp
                                                                             title:@"ESM Radio"
                                                                      instructions:@"The user can only choose one option."
                                                                            submit:submit
                                                               expirationThreshold:exprationThreshold
                                                                           trigger:trigger
                                                                            radios:[NSArray arrayWithObjects:@"Aston Martin", @"Lotus", @"Jaguar", nil]];
    
    NSMutableDictionary *dicCheckBox = [SingleESMObject getEsmDictionaryAsCheckBoxWithDeviceId:deviceId
                                                                               timestamp:timestamp
                                                                                   title:@"ESM Checkbox"
                                                                            instructions:@"The user can choose multiple options."
                                                                                  submit:submit
                                                                     expirationThreshold:exprationThreshold
                                                                                 trigger:trigger
                                                                              checkBoxes:[NSArray arrayWithObjects:@"One", @"Two", @"Three", nil]];
    
    NSMutableDictionary *dicLikert = [SingleESMObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                                timestamp:timestamp
                                                                                    title:@"ESM Likert"
                                                                             instructions:@"User rating 1 to 5 or 7 at 1 step increments."
                                                                                   submit:submit
                                                                      expirationThreshold:exprationThreshold
                                                                                  trigger:trigger
                                                                                likertMax:@7
                                                                           likertMaxLabel:@"7"
                                                                           likertMinLabel:@"1"
                                                                               likertStep:@1];
    
    NSMutableDictionary *dicQuick = [SingleESMObject getEsmDictionaryAsQuickAnswerWithDeviceId:deviceId
                                                                               timestamp:timestamp
                                                                                   title:@"ESM Quick Answer"
                                                                            instructions:@"One touch answer."
                                                                                  submit:submit
                                                                     expirationThreshold:exprationThreshold
                                                                                 trigger:trigger
                                                                            quickAnswers:[NSArray arrayWithObjects:@"Yes", @"No", @"Maybe", nil]];
    
    NSMutableDictionary *dicScale = [SingleESMObject getEsmDictionaryAsScaleWithDeviceId:deviceId
                                                                         timestamp:timestamp
                                                                             title:@"ESM Scale"
                                                                      instructions:@"Between 0 and 10 with 2 increments."
                                                                            submit:submit
                                                               expirationThreshold:exprationThreshold
                                                                           trigger:trigger
                                                                               min:@0
                                                                               max:@10
                                                                        scaleStart:@5
                                                                          minLabel:@"0"
                                                                          maxLabel:@"10"
                                                                         scaleStep:@1];
    
    NSMutableDictionary *dicDatePicker = [SingleESMObject getEsmDictionaryAsDatePickerWithDeviceId:deviceId
                                                                                   timestamp:timestamp
                                                                                       title:@"ESM Date Picker"
                                                                                instructions:@"The user selects date and time."
                                                                                      submit:submit
                                                                         expirationThreshold:exprationThreshold
                                                                                     trigger:trigger];
    
    NSMutableDictionary *dicPAM = [SingleESMObject getEsmDictionaryAsPAMWithDeviceId:deviceId
                                                                                         timestamp:timestamp
                                                                                             title:@"ESM Date Picker"
                                                                                      instructions:@"The user selects date and time."
                                                                                            submit:submit
                                                                               expirationThreshold:exprationThreshold
                                                                                           trigger:trigger];
    
    NSMutableArray* esms = [[NSMutableArray alloc] initWithObjects:dicFreeText, dicRadio, dicCheckBox,dicLikert, dicQuick, dicScale, dicDatePicker, dicPAM, nil];
    
    return esms;
}

///////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////



- (BOOL) syncAwareDBWithData:(NSDictionary *)dictionary {
    return [super syncAwareDBWithData:dictionary];
}

//////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

+ (BOOL)isAppearedThisSection{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:@"key_esm_appeared_section"];
}

+ (void)setAppearedState:(BOOL)state{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:state forKey:@"key_esm_appeared_section"];
}


@end
