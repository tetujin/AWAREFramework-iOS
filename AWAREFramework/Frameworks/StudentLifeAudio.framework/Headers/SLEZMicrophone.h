//
//  SLEZMicrophone.h
//  SLEZAudio
//
//  Created by Syed Haris Ali on 9/2/13.
//  Copyright (c) 2015 Syed Haris Ali. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TargetConditionals.h"
#import "SLEZAudioDevice.h"
#import "SLEZOutput.h"

@class SLEZMicrophone;

//------------------------------------------------------------------------------
#pragma mark - SLEZMicrophoneDelegate
//------------------------------------------------------------------------------

/**
 The SLEZMicrophoneDelegate for the SLEZMicrophone provides a receiver for the incoming audio data events. When the microphone has been successfully internally configured it will try to send its delegate an AudioStreamBasicDescription describing the format of the incoming audio data. 
 
 The audio data itself is sent back to the delegate in various forms:
 
   -`microphone:hasAudioReceived:withBufferSize:withNumberOfChannels:`
     Provides float arrays instead of the AudioBufferList structure to hold the audio data. There could be a number of float arrays depending on the number of channels (see the function description below). These are useful for doing any visualizations that would like to make use of the raw audio data.
 
   -`microphone:hasBufferList:withBufferSize:withNumberOfChannels:`
     Provides the AudioBufferList structures holding the audio data. These are the native structures Core Audio uses to hold the buffer information and useful for piping out directly to an output (see SLEZOutput).
 
 */
@protocol SLEZMicrophoneDelegate <NSObject>

@optional
///-----------------------------------------------------------
/// @name Audio Data Description
///-----------------------------------------------------------

/**
 Called anytime the SLEZMicrophone starts or stops.
 @param output The instance of the SLEZMicrophone that triggered the event.
 @param isPlaying A BOOL indicating whether the SLEZMicrophone instance is playing or not.
 */
- (void)microphone:(SLEZMicrophone *)microphone changedPlayingState:(BOOL)isPlaying;

//------------------------------------------------------------------------------

/**
 Called anytime the input device changes on an `SLEZMicrophone` instance.
 @param microphone The instance of the SLEZMicrophone that triggered the event.
 @param device The instance of the new SLEZAudioDevice the microphone is using to pull input.
 */
- (void)microphone:(SLEZMicrophone *)microphone changedDevice:(SLEZAudioDevice *)device;

//------------------------------------------------------------------------------

/**
 Returns back the audio stream basic description as soon as it has been initialized. This is guaranteed to occur before the stream callbacks, `microphone:hasBufferList:withBufferSize:withNumberOfChannels:` or `microphone:hasAudioReceived:withBufferSize:withNumberOfChannels:`
 @param microphone The instance of the SLEZMicrophone that triggered the event.
 @param audioStreamBasicDescription The AudioStreamBasicDescription that was created for the microphone instance.
 */
- (void)              microphone:(SLEZMicrophone *)microphone
  hasAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription;

///-----------------------------------------------------------
/// @name Audio Data Callbacks
///-----------------------------------------------------------

/**
 This method provides an array of float arrays of the audio received, each float array representing a channel of audio data This occurs on the background thread so any drawing code must explicity perform its functions on the main thread.
 @param microphone       The instance of the SLEZMicrophone that triggered the event.
 @param buffer           The audio data as an array of float arrays. In a stereo signal buffer[0] represents the left channel while buffer[1] would represent the right channel.
 @param bufferSize       The size of each of the buffers (the length of each float array).
 @param numberOfChannels The number of channels for the incoming audio.
 @warning This function executes on a background thread to avoid blocking any audio operations. If operations should be performed on any other thread (like the main thread) it should be performed within a dispatch block like so: dispatch_async(dispatch_get_main_queue(), ^{ ...Your Code... })
 */
- (void)    microphone:(SLEZMicrophone *)microphone
      hasAudioReceived:(float **)buffer
        withBufferSize:(UInt32)bufferSize
  withNumberOfChannels:(UInt32)numberOfChannels;

//------------------------------------------------------------------------------

/**
 Returns back the buffer list containing the audio received. This occurs on the background thread so any drawing code must explicity perform its functions on the main thread.
 @param microphone       The instance of the SLEZMicrophone that triggered the event.
 @param bufferList       The AudioBufferList holding the audio data.
 @param bufferSize       The size of each of the buffers of the AudioBufferList.
 @param numberOfChannels The number of channels for the incoming audio.
 @warning This function executes on a background thread to avoid blocking any audio operations. If operations should be performed on any other thread (like the main thread) it should be performed within a dispatch block like so: dispatch_async(dispatch_get_main_queue(), ^{ ...Your Code... })
 */
- (void)    microphone:(SLEZMicrophone *)microphone
         hasBufferList:(AudioBufferList *)bufferList
        withBufferSize:(UInt32)bufferSize
  withNumberOfChannels:(UInt32)numberOfChannels;

@end

//------------------------------------------------------------------------------
#pragma mark - SLEZMicrophone
//------------------------------------------------------------------------------

/**
 The SLEZMicrophone provides a component to get audio data from the default device microphone. On OSX this is the default selected input device in the system preferences while on iOS this defaults to use the default RemoteIO audio unit. The microphone data is converted to a float buffer array and returned back to the caller via the SLEZMicrophoneDelegate protocol.
 */
@interface SLEZMicrophone : NSObject <SLEZOutputDataSource>

//------------------------------------------------------------------------------

/**
 The SLEZMicrophoneDelegate for which to handle the microphone callbacks
 */
@property (nonatomic, weak) id<SLEZMicrophoneDelegate> delegate;

//------------------------------------------------------------------------------

/**
 The SLEZAudioDevice being used to pull the microphone data.
 - On iOS this can be any of the available microphones on the iPhone/iPad devices (usually there are 3). Defaults to the first microphone found (bottom mic)
 - On OSX this can be any of the plugged in devices that Core Audio can detect (see kAudioUnitSubType_HALOutput for more information)
 System Preferences -> Sound for the available inputs)
 */
@property (nonatomic, strong) SLEZAudioDevice *device;

//------------------------------------------------------------------------------

/**
 A BOOL describing whether the microphone is on and passing back audio data to its delegate.
 */
@property (nonatomic, assign) BOOL microphoneOn;

//------------------------------------------------------------------------------

/**
 An SLEZOutput to use for porting the microphone input out (passthrough).
 */
@property (nonatomic, strong) SLEZOutput *output;

//------------------------------------------------------------------------------
#pragma mark - Initializers
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Initializers
///-----------------------------------------------------------

/**
 Creates an instance of the SLEZMicrophone with a delegate to respond to the audioReceived callback. This will not start fetching the audio until startFetchingAudio has been called. Use initWithMicrophoneDelegate:startsImmediately: to instantiate this class and immediately start fetching audio data.
 @param 	delegate 	A SLEZMicrophoneDelegate delegate that will receive the audioReceived callback.
 @return	An instance of the SLEZMicrophone class. This should be strongly retained.
 */
- (SLEZMicrophone *)initWithMicrophoneDelegate:(id<SLEZMicrophoneDelegate>)delegate;

//------------------------------------------------------------------------------

/**
 Creates an instance of the SLEZMicrophone with a custom AudioStreamBasicDescription and provides the caller to specify a delegate to respond to the audioReceived callback. This will not start fetching the audio until startFetchingAudio has been called. Use initWithMicrophoneDelegate:startsImmediately: to instantiate this class and immediately start fetching audio data.
 @param 	microphoneDelegate 	        A SLEZMicrophoneDelegate delegate that will receive the audioReceived callback.
 @param 	audioStreamBasicDescription A custom AudioStreamBasicFormat for the microphone input.
 @return	An instance of the SLEZMicrophone class. This should be strongly retained.
 */
-(SLEZMicrophone *)initWithMicrophoneDelegate:(id<SLEZMicrophoneDelegate>)delegate
            withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription;

//------------------------------------------------------------------------------

/**
 Creates an instance of the SLEZMicrophone with a delegate to respond to the audioReceived callback and allows the caller to specify whether they'd immediately like to start fetching the audio data.
 @param 	delegate 	A SLEZMicrophoneDelegate delegate that will receive the audioReceived callback.
 @param 	startsImmediately 	A boolean indicating whether to start fetching the data immediately. IF YES, the delegate's audioReceived callback will immediately start getting called.
 @return	An instance of the SLEZMicrophone class. This should be strongly retained.
 */
- (SLEZMicrophone *)initWithMicrophoneDelegate:(id<SLEZMicrophoneDelegate>)delegate
                           startsImmediately:(BOOL)startsImmediately;

//------------------------------------------------------------------------------

/**
 Creates an instance of the SLEZMicrophone with a custom AudioStreamBasicDescription and provides the caller with a delegate to respond to the audioReceived callback and allows the caller to specify whether they'd immediately like to start fetching the audio data.
 @param 	delegate 	A SLEZMicrophoneDelegate delegate that will receive the audioReceived callback.
 @param 	audioStreamBasicDescription A custom AudioStreamBasicFormat for the microphone input.
 @param 	startsImmediately 	A boolean indicating whether to start fetching the data immediately. IF YES, the delegate's audioReceived callback will immediately start getting called.
 @return	An instance of the SLEZMicrophone class. This should be strongly retained.
 */
- (SLEZMicrophone *)initWithMicrophoneDelegate:(id<SLEZMicrophoneDelegate>)delegate
             withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription
                           startsImmediately:(BOOL)startsImmediately;

//------------------------------------------------------------------------------
#pragma mark - Class Initializers
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Class Initializers
///-----------------------------------------------------------

/**
 Creates an instance of the SLEZMicrophone with a delegate to respond to the audioReceived callback. This will not start fetching the audio until startFetchingAudio has been called. Use microphoneWithDelegate:startsImmediately: to instantiate this class and immediately start fetching audio data.
 @param 	delegate 	A SLEZMicrophoneDelegate delegate that will receive the audioReceived callback.
 @return	An instance of the SLEZMicrophone class. This should be declared as a strong property!
 */
+ (SLEZMicrophone *)microphoneWithDelegate:(id<SLEZMicrophoneDelegate>)delegate;

//------------------------------------------------------------------------------

/**
 Creates an instance of the SLEZMicrophone with a delegate to respond to the audioReceived callback. This will not start fetching the audio until startFetchingAudio has been called. Use microphoneWithDelegate:startsImmediately: to instantiate this class and immediately start fetching audio data.
 @param 	delegate 	A SLEZMicrophoneDelegate delegate that will receive the audioReceived callback.
 @param 	audioStreamBasicDescription A custom AudioStreamBasicFormat for the microphone input.
 @return	An instance of the SLEZMicrophone class. This should be declared as a strong property!
 */
+ (SLEZMicrophone *)microphoneWithDelegate:(id<SLEZMicrophoneDelegate>)delegate
         withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription;

//------------------------------------------------------------------------------

/**
 Creates an instance of the SLEZMicrophone with a delegate to respond to the audioReceived callback and allows the caller to specify whether they'd immediately like to start fetching the audio data.
 
 @param microphoneDelegate A SLEZMicrophoneDelegate delegate that will receive the audioReceived callback.
 @param startsImmediately  A boolean indicating whether to start fetching the data immediately. IF YES, the delegate's audioReceived callback will immediately start getting called.
 @return An instance of the SLEZMicrophone class. This should be strongly retained.
 */
+ (SLEZMicrophone *)microphoneWithDelegate:(id<SLEZMicrophoneDelegate>)delegate
                        startsImmediately:(BOOL)startsImmediately;

//------------------------------------------------------------------------------

/**
 Creates an instance of the SLEZMicrophone with a delegate to respond to the audioReceived callback and allows the caller to specify whether they'd immediately like to start fetching the audio data.
 
 @param microphoneDelegate A SLEZMicrophoneDelegate delegate that will receive the audioReceived callback.
 @param audioStreamBasicDescription A custom AudioStreamBasicFormat for the microphone input.
 @param startsImmediately  A boolean indicating whether to start fetching the data immediately. IF YES, the delegate's audioReceived callback will immediately start getting called.
 @return An instance of the SLEZMicrophone class. This should be strongly retained.
 */
+ (SLEZMicrophone *)microphoneWithDelegate:(id<SLEZMicrophoneDelegate>)delegate
         withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription
                       startsImmediately:(BOOL)startsImmediately;

//------------------------------------------------------------------------------
#pragma mark - Shared Instance
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Shared Instance
///-----------------------------------------------------------

/**
 A shared instance of the microphone component. Most applications will only need to use one instance of the microphone component across multiple views. Make sure to call the `startFetchingAudio` method to receive the audio data in the microphone delegate.
 @return A shared instance of the `SLEZAudioMicrophone` component.
 */
+ (SLEZMicrophone *)sharedMicrophone;

//------------------------------------------------------------------------------
#pragma mark - Events
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Starting/Stopping The Microphone
///-----------------------------------------------------------

/**
 Starts fetching audio from the default microphone. Will notify delegate with audioReceived callback.
 */
- (void)startFetchingAudio;

//------------------------------------------------------------------------------

/**
 Stops fetching audio. Will stop notifying the delegate's audioReceived callback.
 */
- (void)stopFetchingAudio;

//------------------------------------------------------------------------------
#pragma mark - Getters
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Getting The Microphone's Audio Format
///-----------------------------------------------------------

/**
 Provides the AudioStreamBasicDescription structure containing the format of the microphone's audio.
 @return An AudioStreamBasicDescription structure describing the format of the microphone's audio.
 */
- (AudioStreamBasicDescription)audioStreamBasicDescription;

//------------------------------------------------------------------------------

/**
 Provides the underlying Audio Unit that is being used to fetch the audio.
 @return The AudioUnit used for the microphone
 */
- (AudioUnit *)audioUnit;

//------------------------------------------------------------------------------
#pragma mark - Setters
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Customizing The Microphone Stream Format
///-----------------------------------------------------------

/**
 Sets the AudioStreamBasicDescription on the microphone input. Must be linear PCM and must be the same sample rate as the stream format coming in (check the current `audioStreamBasicDescription` before setting).
 @warning Do not set this while fetching audio (startFetchingAudio)
 @param asbd The new AudioStreamBasicDescription to use in place of the current audio format description.
 */
- (void)setAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd;

///-----------------------------------------------------------
/// @name Setting The Microphone's Hardware Device
///-----------------------------------------------------------

/**
 Sets the SLEZAudioDevice being used to pull the microphone data.
 - On iOS this can be any of the available microphones on the iPhone/iPad devices (usually there are 3). Defaults to the first microphone found (bottom mic)
 - On OSX this can be any of the plugged in devices that Core Audio can detect (see kAudioUnitSubType_HALOutput for more information)
 System Preferences -> Sound for the available inputs)
 @param device An SLEZAudioDevice instance that should be used to fetch the microphone data.
 */
- (void)setDevice:(SLEZAudioDevice *)device;

//------------------------------------------------------------------------------
#pragma mark - Direct Output
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Setting The Microphone's Output (Direct Out)
///-----------------------------------------------------------

/**
 When set this will pipe out the contents of the microphone into an SLEZOutput. This is known as a passthrough or direct out that will simply pipe the microphone input to an output.
 @param output An SLEZOutput instance that the microphone will use to output its audio data to the speaker.
 */
- (void)setOutput:(SLEZOutput *)output;

//------------------------------------------------------------------------------
#pragma mark - Subclass Methods
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Subclass
///-----------------------------------------------------------

/**
 The default AudioStreamBasicDescription set as the stream format of the microphone if no custom description is set. Defaults to a non-interleaved float format with the number of channels specified by the `numberOfChannels` method.
 @return An AudioStreamBasicDescription that will be used as the default stream format.
 */
- (AudioStreamBasicDescription)defaultStreamFormat;

//------------------------------------------------------------------------------

/**
 The number of channels the input microphone is expected to have. Defaults to 1 (assumes microphone is mono).
 @return A UInt32 representing the number of channels expected for the microphone.
 */
- (UInt32)numberOfChannels;

//------------------------------------------------------------------------------

@end
