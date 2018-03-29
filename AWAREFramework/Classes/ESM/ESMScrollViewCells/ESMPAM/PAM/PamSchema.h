//
//  PamSchema.h
//  PAMAlgorithm
//
//  Created by Yuuki Nishiyama on 3/16/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum: NSInteger {
    AFRAID      = 1,
    TENSE       = 2,
    EXCITED     = 3,
    DELIGHTED   = 4,
    FRUSTRATED  = 5,
    ANGRY       = 6,
    HAPPY       = 7,
    GLAD        = 8,
    MISERABLE   = 9,
    SAD         = 10,
    CALM        = 11,
    SATISFIED   = 12,
    GLOOMY      = 13,
    TIRED       = 14,
    SLEEPY      = 15,
    SERENE      = 16
} MoodEnum;

@interface PamSchema : NSObject

- (instancetype)initWithPosition:(int) position date:(NSDate*) date;

- (int) getPropertyAffectValence;
- (int) getPropertyAffectArousal;
- (int) getPropertyPositiveAffect;
- (int) getPropertyNegativeAffect;
- (MoodEnum)getPropertyMood;
+ (NSString *) getEmotionString:(MoodEnum) moodEnum;
- (NSDate *) getDate;

@end
