//
//  PamSchema.m
//  PAMAlgorithm
//
//  Created by Yuuki Nishiyama on 3/16/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//
// http://resources.cornellhci.org/pam/README.txt
// http://resources.cornellhci.org/pam/
//
//

#import "PamSchema.h"

@implementation PamSchema{
    int propertyAffectValence;
    int propertyAffectArousal;
    int propertyPositiveAffect;
    int propertyNegativeAffect;
    MoodEnum propertyMood;
    NSDate* propertyDate;
}


- (instancetype)initWithPosition:(int) position date:(NSDate*) date{
    self = [super init];
    if(self){
        int valence = [self valence:position];
        int arousal = [self arousal:position];
        int positiveAffect = [self positiveAffectWithValence:valence arousal:arousal];
        int negativeAffect = [self negativeAffectWithValence:valence arousal:arousal];
        MoodEnum moodEnue = [self determineMoodWithValence:valence arousal:arousal];
        
        propertyAffectValence = valence;
        propertyAffectArousal = arousal;
        propertyPositiveAffect = positiveAffect;
        propertyNegativeAffect = negativeAffect;
        propertyMood = moodEnue;
        propertyDate = date;
    }
    return self;
}


- (int) getPropertyAffectValence{
    return propertyAffectValence;
}

- (int) getPropertyAffectArousal{
    return propertyAffectArousal;
}

- (int) getPropertyPositiveAffect{
    return propertyPositiveAffect;
}

- (int) getPropertyNegativeAffect{
    return propertyNegativeAffect;
}

- (MoodEnum)getPropertyMood{
    return propertyMood;
}

- (NSDate *) getDate{
    return propertyDate;
}


- (int) arousal:(int)position {
    switch (position) {
        case 1:
        case 2:
        case 3:
        case 4:
            return 4;
        case 5:
        case 6:
        case 7:
        case 8:
            return 3;
        case 9:
        case 10:
        case 11:
        case 12:
            return 2;
        case 13:
        case 14:
        case 15:
        case 16:
            return 1;
        default:
            return 0;
    }
    return 0;
}

- (int) valence:(int)position{
    switch (position) {
        case 1:
        case 5:
        case 9:
        case 13:
            return 1;
        case 2:
        case 6:
        case 10:
        case 14:
            return 2;
        case 3:
        case 7:
        case 11:
        case 15:
            return 3;
        case 4:
        case 8:
        case 12:
        case 16:
            return 4;
        default:
            return 0;
    }
    return 0;
}


- (int)positiveAffectWithValence:(int)valence arousal:(int)arousal {
    if (valence > 0 && valence < 5 && arousal > 0 && arousal < 5) {
        return (4 * valence) + arousal - 4;
    } else {
        return 0;
    }
}


- (int)negativeAffectWithValence:(int) valence arousal:(int)arousal {
    if (valence > 0 && valence < 5 && arousal > 0 && arousal < 5) {
        return 4 * (5 - valence) + arousal - 4;
    } else {
        return 0;
    }
}

- (MoodEnum) determineMoodWithValence:(int) valence arousal:(int)arousal {
    
    switch (arousal) {
        case 4:
            switch (valence) {
                case 1:
                    return AFRAID;
                case 2:
                    return TENSE;
                case 3:
                    return EXCITED;
                case 4:
                    return DELIGHTED;
                default:
                    return 0;
            }
        case 3:
            switch (valence) {
                case 1:
                    return FRUSTRATED;
                case 2:
                    return ANGRY;
                case 3:
                    return HAPPY;
                case 4:
                    return GLAD;
                default:
                    return 0;
            }
        case 2:
            switch (valence) {
                case 1:
                    return MISERABLE;
                case 2:
                    return SAD;
                case 3:
                    return CALM;
                case 4:
                    return SATISFIED;
                default:
                    return 0;
            }
        case 1:
            switch (valence) {
                case 1:
                    return GLOOMY;
                case 2:
                    return TIRED;
                case 3:
                    return SLEEPY;
                case 4:
                    return SERENE;
                default:
                    return 0;
            }
        default:
            return 0;
    }
    
}



+ (NSString *) getEmotionString:(MoodEnum) moodEnum {
    switch (moodEnum) {
        case AFRAID:
            return @"afraid";
        case TENSE:
            return @"tense";
        case EXCITED:
            return @"excited";
        case DELIGHTED:
            return @"delighted";
        case FRUSTRATED:
            return @"frustrated";
        case ANGRY:
            return @"angry";
        case HAPPY:
            return @"happy";
        case GLAD:
            return @"glad";
        case MISERABLE:
            return @"miserable";
        case SAD:
            return @"sad";
        case CALM:
            return @"calm";
        case SATISFIED:
            return @"satisfied";
        case GLOOMY:
            return @"gloomy";
        case TIRED:
            return @"tired";
        case SLEEPY:
            return @"sleepy";
        case SERENE:
            return @"serene";
        default:
            return @"";
    }
}

- (NSString *)debugDescription{
    return [NSString stringWithFormat:@"%d\t%d\t%@",
            propertyAffectValence,
            propertyAffectArousal,
            [PamSchema getEmotionString:propertyMood]];
}

@end
