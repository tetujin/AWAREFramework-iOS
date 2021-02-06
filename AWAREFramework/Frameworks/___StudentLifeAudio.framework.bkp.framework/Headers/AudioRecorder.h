//
//  AudioRecorder.h
//  StudentlifeAudioPipelineDemo
//
//  Created by Rui Wang on 12/2/15.
//  Copyright © 2015 Rui Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

// Import EZAudio header
#import "SLEZAudio.h"
#include "VAD.h"

@interface AudioRecorder : NSObject<SLEZMicrophoneDelegate, SLEZRecorderDelegate>

@property (atomic,assign) BOOL isRecording;

//------------------------------------------------------------------------------
#pragma mark - Actions


- (id)init : (VAD *)withClassifier;

//------------------------------------------------------------------------------

/**
 start the pipeline
 */
- (BOOL)startRecording;

//------------------------------------------------------------------------------

/**
  stop the pipeline
 */
- (void)stopRecording;


- (BOOL)isAvailable;

@end
