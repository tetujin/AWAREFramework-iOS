//
//  VAD.h
//  StudentlifeAudioPipelineDemo
//
//  Created by Rui Wang on 12/2/15.
//  Copyright © 2015 Rui Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "jni_types.h"

@interface VAD : NSObject

@property Boolean inCoversation;

typedef void (^AudioInterfaceEventHandler)( int inference, double energy, long timestamp, long sync_id );
typedef void (^ConversationEventHandler)( long startTime, long endTime);
typedef void (^AudioFeatureEventHandler) ( jfloat* fVector,
                                           jfloat* obsProbVector,
                                           jbyte* inferRes,
                                           jint* numOfPeaks,
                                           jfloat* autoCorPeakVal,
                                           jshort* autoCorPeakLg,
                                           long timestamp );
typedef void (^ConversationStartEventHandler) (long startTime);
typedef void (^ConversationEndEventHandler) (long endTime);


@property AudioInterfaceEventHandler audioInterfaceEventHandler;
@property ConversationEventHandler conversationEventHandler;
@property AudioFeatureEventHandler audioFeatureEventHandler;
@property ConversationStartEventHandler conversationStartEventHandler;
@property ConversationEndEventHandler conversationEndEventHandler;

-(id)init;
-(void)uninit;

-(void)resetClassifier;

// the assumption is that bufferSize <= FRAME_SHIFT
-(void)classify: (float *)buffer withBufferSize:(UInt32)bufferSize  timestamp: (long)timestamp;

@end
