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

- (id) init;
- (void) uninit;

- (void) startPipeline;
-( void) stopPipeline;

- (void) setTimeOfDutyCycleOffInConversationBySecond:(double)second;
- (void) setTimeOfDutyCycleOffBySecond:(double)second;

- (void) setAudioInterfaceEventHandler:(AudioInterfaceEventHandler) handler;
- (void) setAudioFeatureEventHandler:(AudioFeatureEventHandler) handler;
- (void) setConversationEventHandler:(ConversationEventHandler) handler;
- (void) setConversationEndEventHandler:(ConversationEndEventHandler) handler;
- (void) setConversationStartEventHandler:(ConversationStartEventHandler) handler;
    
@end
