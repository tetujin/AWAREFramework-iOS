//
//  AudioPipeline.h
//  StudentlifeAudioPipelineDemo
//
//  Created by Rui Wang on 12/2/15.
//  Copyright © 2015 Rui Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VAD.h"

@interface AudioPipeline : NSObject

- (id _Nullable ) init;
- (void) uninit;

- (void) startPipeline;
-( void) stopPipeline;

- (void) setTimeOfDutyCycleOffInConversationBySecond:(double)second;
- (void) setTimeOfDutyCycleOffBySecond:(double)second;

- (void) setAudioInterfaceEventHandler:(AudioInterfaceEventHandler _Nonnull) handler;
- (void) setAudioFeatureEventHandler:(AudioFeatureEventHandler _Nonnull)     handler;
- (void) setConversationEventHandler:(ConversationEventHandler _Nonnull)     handler;
- (void) setConversationEndEventHandler:(ConversationEndEventHandler _Nonnull) handler;
- (void) setConversationStartEventHandler:(ConversationStartEventHandler _Nonnull) handler;
    
@end
