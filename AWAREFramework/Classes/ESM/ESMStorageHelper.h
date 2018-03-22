//
//  ESMStorageHelper.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/24/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MultiESMObject.h"

@interface ESMStorageHelper : NSObject
/**
 * ===========
 *  for ESMs
 * ===========
 */
//- (void) addEsmText:(NSString*) esmText;
- (void) addEsmText:(NSString *)esmText withId:(NSString *)scheduleId timeout:(NSNumber *)timeout;
- (void) addEsmText:(NSString *)esmText withId:(NSString *)scheduleId;
- (void) removeEsmTexts;
- (void) removeEsmWithText:(NSString*) esmText;
//- (void) removeEsmWithScheduleId:(NSString *)scheduleId;
- (NSArray *) getEsmTexts;
/** remove expired schedules */
// - (NSMutableArray *) removeExpiredEsms:(NSMutableArray*) esms;
- (NSString *) getEsmTextWithNumber:(int)esmNumber;
- (int) getNumberOfStoredESMs;
    
@end
