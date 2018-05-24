//
//  SLEZAudioPlayer.h
//  SLEZAudio
//
//  Created by Syed Haris Ali on 1/16/14.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
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
#import "TargetConditionals.h"
#import "SLEZAudioFile.h"
#import "SLEZOutput.h"

@class SLEZAudioPlayer;

//------------------------------------------------------------------------------
#pragma mark - Data Structures
//------------------------------------------------------------------------------

typedef NS_ENUM(NSUInteger, SLEZAudioPlayerState)
{
    SLEZAudioPlayerStateEndOfFile,
    SLEZAudioPlayerStatePaused,
    SLEZAudioPlayerStatePlaying,
    SLEZAudioPlayerStateReadyToPlay,
    SLEZAudioPlayerStateSeeking,
    SLEZAudioPlayerStateUnknown,
};

//------------------------------------------------------------------------------
#pragma mark - Notifications
//------------------------------------------------------------------------------

/**
 Notification that occurs whenever the SLEZAudioPlayer changes its `audioFile` property. Check the new value using the SLEZAudioPlayer's `audioFile` property.
 */
FOUNDATION_EXPORT NSString * const SLEZAudioPlayerDidChangeAudioFileNotification;

/**
 Notification that occurs whenever the SLEZAudioPlayer changes its `device` property. Check the new value using the SLEZAudioPlayer's `device` property.
 */
FOUNDATION_EXPORT NSString * const SLEZAudioPlayerDidChangeOutputDeviceNotification;

/**
 Notification that occurs whenever the SLEZAudioPlayer changes its `output` component's `pan` property. Check the new value using the SLEZAudioPlayer's `pan` property.
 */
FOUNDATION_EXPORT NSString * const SLEZAudioPlayerDidChangePanNotification;

/**
 Notification that occurs whenever the SLEZAudioPlayer changes its `output` component's play state. Check the new value using the SLEZAudioPlayer's `isPlaying` property.
 */
FOUNDATION_EXPORT NSString * const SLEZAudioPlayerDidChangePlayStateNotification;

/**
 Notification that occurs whenever the SLEZAudioPlayer changes its `output` component's `volume` property. Check the new value using the SLEZAudioPlayer's `volume` property.
 */
FOUNDATION_EXPORT NSString * const SLEZAudioPlayerDidChangeVolumeNotification;

/**
 Notification that occurs whenever the SLEZAudioPlayer has reached the end of a file and its `shouldLoop` property has been set to NO.
 */
FOUNDATION_EXPORT NSString * const SLEZAudioPlayerDidReachEndOfFileNotification;

/**
 Notification that occurs whenever the SLEZAudioPlayer performs a seek via the `seekToFrame` method or `setCurrentTime:` property setter. Check the new `currentTime` or `frameIndex` value using the SLEZAudioPlayer's `currentTime` or `frameIndex` property, respectively.
 */
FOUNDATION_EXPORT NSString * const SLEZAudioPlayerDidSeekNotification;

//------------------------------------------------------------------------------
#pragma mark - SLEZAudioPlayerDelegate
//------------------------------------------------------------------------------

/**
 The SLEZAudioPlayerDelegate provides event callbacks for the SLEZAudioPlayer. Since 0.5.0 the SLEZAudioPlayerDelegate provides a smaller set of delegate methods in favor of notifications to allow multiple receivers of the SLEZAudioPlayer event callbacks since only one player is typically used in an application. Specifically, these methods are provided for high frequency callbacks that wrap the SLEZAudioPlayer's internal SLEZAudioFile and SLEZOutput instances.
 @warning These callbacks don't necessarily occur on the main thread so make sure you wrap any UI code in a GCD block like: dispatch_async(dispatch_get_main_queue(), ^{ // Update UI });
 */
@protocol SLEZAudioPlayerDelegate <NSObject>

@optional

//------------------------------------------------------------------------------

/**
 Triggered by the SLEZAudioPlayer's internal SLEZAudioFile's SLEZAudioFileDelegate callback and notifies the delegate of the read audio data as a float array instead of a buffer list. Common use case of this would be to visualize the float data using an audio plot or audio data dependent OpenGL sketch.
 @param audioPlayer The instance of the SLEZAudioPlayer that triggered the event
 @param buffer           A float array of float arrays holding the audio data. buffer[0] would be the left channel's float array while buffer[1] would be the right channel's float array in a stereo file.
 @param bufferSize       The length of the buffers float arrays
 @param numberOfChannels The number of channels. 2 for stereo, 1 for mono.
 @param audioFile   The instance of the SLEZAudioFile that the event was triggered from
 */
- (void)  audioPlayer:(SLEZAudioPlayer *)audioPlayer
          playedAudio:(float **)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels
          inAudioFile:(SLEZAudioFile *)audioFile;;

//------------------------------------------------------------------------------

/**
 Triggered by SLEZAudioPlayer's internal SLEZAudioFile's SLEZAudioFileDelegate callback and notifies the delegate of the current playback position. The framePosition provides the current frame position and can be calculated against the SLEZAudioPlayer's total frames using the `totalFrames` function from the SLEZAudioPlayer.
 @param audioPlayer The instance of the SLEZAudioPlayer that triggered the event
 @param framePosition The new frame index as a 64-bit signed integer
 @param audioFile   The instance of the SLEZAudioFile that the event was triggered from
 */
- (void)audioPlayer:(SLEZAudioPlayer *)audioPlayer
    updatedPosition:(SInt64)framePosition
        inAudioFile:(SLEZAudioFile *)audioFile;


/**
 Triggered by SLEZAudioPlayer's internal SLEZAudioFile's SLEZAudioFileDelegate callback and notifies the delegate that the end of the file has been reached. 
 @param audioPlayer The instance of the SLEZAudioPlayer that triggered the event
 @param audioFile   The instance of the SLEZAudioFile that the event was triggered from
 */
- (void)audioPlayer:(SLEZAudioPlayer *)audioPlayer
reachedEndOfAudioFile:(SLEZAudioFile *)audioFile;

@end

//------------------------------------------------------------------------------
#pragma mark - SLEZAudioPlayer
//------------------------------------------------------------------------------

/**
 The SLEZAudioPlayer provides an interface that combines the SLEZAudioFile and SLEZOutput to play local audio files. This class acts as the master delegate (the SLEZAudioFileDelegate) over whatever SLEZAudioFile instance, the `audioFile` property, it is using for playback as well as the SLEZOutputDelegate and SLEZOutputDataSource over whatever SLEZOutput instance is set as the `output`. Classes that want to get the SLEZAudioFileDelegate callbacks should implement the SLEZAudioPlayer's SLEZAudioPlayerDelegate on the SLEZAudioPlayer instance. Since 0.5.0 the SLEZAudioPlayer offers notifications over the usual delegate methods to allow multiple receivers to get the SLEZAudioPlayer's state changes since one player will typically be used in one application. The SLEZAudioPlayerDelegate, the `delegate`, provides callbacks for high frequency methods that simply wrap the SLEZAudioFileDelegate and SLEZOutputDelegate callbacks for providing the audio buffer played as well as the position updating (you will typically have one scrub bar in an application).
 */
@interface SLEZAudioPlayer : NSObject <SLEZAudioFileDelegate,
                                     SLEZOutputDataSource,
                                     SLEZOutputDelegate>

//------------------------------------------------------------------------------
#pragma mark - Properties
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Properties
///-----------------------------------------------------------

/**
 The SLEZAudioPlayerDelegate that will handle the audio player callbacks
 */
@property (nonatomic, weak) id<SLEZAudioPlayerDelegate> delegate;

//------------------------------------------------------------------------------

/**
 A BOOL indicating whether the player should loop the file
 */
@property (nonatomic, assign) BOOL shouldLoop;

//------------------------------------------------------------------------------

/**
 An SLEZAudioPlayerState value representing the current internal playback and file state of the SLEZAudioPlayer instance.
 */
@property (nonatomic, assign, readonly) SLEZAudioPlayerState state;

//------------------------------------------------------------------------------
#pragma mark - Initializers
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Initializers
///-----------------------------------------------------------

/**
 Initializes the SLEZAudioPlayer with an SLEZAudioFile instance. This does not use the SLEZAudioFile by reference, but instead creates a separate SLEZAudioFile instance with the same file at the given file path provided by the internal NSURL to use for internal seeking so it doesn't cause any locking between the caller's instance of the SLEZAudioFile.
 @param audioFile The instance of the SLEZAudioFile to use for initializing the SLEZAudioPlayer
 @return The newly created instance of the SLEZAudioPlayer
 */
- (instancetype)initWithAudioFile:(SLEZAudioFile *)audioFile;

//------------------------------------------------------------------------------

/**
 Initializes the SLEZAudioPlayer with an SLEZAudioFile instance and provides a way to assign the SLEZAudioPlayerDelegate on instantiation. This does not use the SLEZAudioFile by reference, but instead creates a separate SLEZAudioFile instance with the same file at the given file path provided by the internal NSURL to use for internal seeking so it doesn't cause any locking between the caller's instance of the SLEZAudioFile.
 @param audioFile The instance of the SLEZAudioFile to use for initializing the SLEZAudioPlayer
 @param delegate The receiver that will act as the SLEZAudioPlayerDelegate. Set to nil if it should have no delegate or use the initWithAudioFile: function instead.
 @return The newly created instance of the SLEZAudioPlayer
 */
- (instancetype)initWithAudioFile:(SLEZAudioFile *)audioFile
                         delegate:(id<SLEZAudioPlayerDelegate>)delegate;

//------------------------------------------------------------------------------

/**
 Initializes the SLEZAudioPlayer with an SLEZAudioPlayerDelegate.
 @param delegate The receiver that will act as the SLEZAudioPlayerDelegate. Set to nil if it should have no delegate or use the initWithAudioFile: function instead.
 @return The newly created instance of the SLEZAudioPlayer
 */
- (instancetype)initWithDelegate:(id<SLEZAudioPlayerDelegate>)delegate;

//------------------------------------------------------------------------------

/**
 Initializes the SLEZAudioPlayer with an NSURL instance representing the file path of the audio file.
 @param url The NSURL instance representing the file path of the audio file.
 @return The newly created instance of the SLEZAudioPlayer
 */
- (instancetype)initWithURL:(NSURL*)url;

//------------------------------------------------------------------------------

/**
 Initializes the SLEZAudioPlayer with an NSURL instance representing the file path of the audio file and a caller to assign as the SLEZAudioPlayerDelegate on instantiation.
 @param url The NSURL instance representing the file path of the audio file.
 @param delegate The receiver that will act as the SLEZAudioPlayerDelegate. Set to nil if it should have no delegate or use the initWithAudioFile: function instead.
 @return The newly created instance of the SLEZAudioPlayer
 */
- (instancetype)initWithURL:(NSURL*)url
                   delegate:(id<SLEZAudioPlayerDelegate>)delegate;

//------------------------------------------------------------------------------
#pragma mark - Class Initializers
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Class Initializers
///-----------------------------------------------------------

/**
 Class initializer that creates a default SLEZAudioPlayer.
 @return The newly created instance of the SLEZAudioPlayer
 */
+ (instancetype)audioPlayer;

//------------------------------------------------------------------------------

/**
 Class initializer that creates the SLEZAudioPlayer with an SLEZAudioFile instance. This does not use the SLEZAudioFile by reference, but instead creates a separate SLEZAudioFile instance with the same file at the given file path provided by the internal NSURL to use for internal seeking so it doesn't cause any locking between the caller's instance of the SLEZAudioFile.
 @param audioFile The instance of the SLEZAudioFile to use for initializing the SLEZAudioPlayer
 @return The newly created instance of the SLEZAudioPlayer
 */
+ (instancetype)audioPlayerWithAudioFile:(SLEZAudioFile *)audioFile;

//------------------------------------------------------------------------------

/**
 Class initializer that creates the SLEZAudioPlayer with an SLEZAudioFile instance and provides a way to assign the SLEZAudioPlayerDelegate on instantiation. This does not use the SLEZAudioFile by reference, but instead creates a separate SLEZAudioFile instance with the same file at the given file path provided by the internal NSURL to use for internal seeking so it doesn't cause any locking between the caller's instance of the SLEZAudioFile.
 @param audioFile The instance of the SLEZAudioFile to use for initializing the SLEZAudioPlayer
 @param delegate The receiver that will act as the SLEZAudioPlayerDelegate. Set to nil if it should have no delegate or use the audioPlayerWithAudioFile: function instead.
 @return The newly created instance of the SLEZAudioPlayer
 */
+ (instancetype)audioPlayerWithAudioFile:(SLEZAudioFile *)audioFile
                                delegate:(id<SLEZAudioPlayerDelegate>)delegate;

//------------------------------------------------------------------------------

/**
 Class initializer that creates a default SLEZAudioPlayer with an SLEZAudioPlayerDelegate..
 @return The newly created instance of the SLEZAudioPlayer
 */
+ (instancetype)audioPlayerWithDelegate:(id<SLEZAudioPlayerDelegate>)delegate;

//------------------------------------------------------------------------------

/**
 Class initializer that creates the SLEZAudioPlayer with an NSURL instance representing the file path of the audio file.
 @param url The NSURL instance representing the file path of the audio file.
 @return The newly created instance of the SLEZAudioPlayer
 */
+ (instancetype)audioPlayerWithURL:(NSURL*)url;

//------------------------------------------------------------------------------

/**
 Class initializer that creates the SLEZAudioPlayer with an NSURL instance representing the file path of the audio file and a caller to assign as the SLEZAudioPlayerDelegate on instantiation.
 @param url The NSURL instance representing the file path of the audio file.
 @param delegate The receiver that will act as the SLEZAudioPlayerDelegate. Set to nil if it should have no delegate or use the audioPlayerWithURL: function instead.
 @return The newly created instance of the SLEZAudioPlayer
 */
+ (instancetype)audioPlayerWithURL:(NSURL*)url
                          delegate:(id<SLEZAudioPlayerDelegate>)delegate;

//------------------------------------------------------------------------------
#pragma mark - Singleton
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Shared Instance
///-----------------------------------------------------------

/**
 The shared instance (singleton) of the audio player. Most applications will only have one instance of the SLEZAudioPlayer that can be reused with multiple different audio files.
 *  @return The shared instance of the SLEZAudioPlayer.
 */
+ (instancetype)sharedAudioPlayer;

//------------------------------------------------------------------------------
#pragma mark - Properties
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Properties
///-----------------------------------------------------------

/**
 Provides the SLEZAudioFile instance that is being used as the datasource for playback. When set it creates a copy of the SLEZAudioFile provided for internal use. This does not use the SLEZAudioFile by reference, but instead creates a copy of the SLEZAudioFile instance provided.
 */
@property (nonatomic, readwrite, copy) SLEZAudioFile *audioFile;

//------------------------------------------------------------------------------

/**
 Provides the current offset in the audio file as an NSTimeInterval (i.e. in seconds).  When setting this it will determine the correct frame offset and perform a `seekToFrame` to the new time offset.
 @warning Make sure the new current time offset is less than the `duration` or you will receive an invalid seek assertion.
 */
@property (nonatomic, readwrite) NSTimeInterval currentTime;

//------------------------------------------------------------------------------

/**
 The SLEZAudioDevice instance that is being used by the `output`. Similarly, setting this just sets the `device` property of the `output`.
 */
@property (readwrite) SLEZAudioDevice *device;

//------------------------------------------------------------------------------

/**
 Provides the duration of the audio file in seconds.
 */
@property (readonly) NSTimeInterval duration;

//------------------------------------------------------------------------------

/**
 Provides the current time as an NSString with the time format MM:SS.
 */
@property (readonly) NSString *formattedCurrentTime;

//------------------------------------------------------------------------------

/**
 Provides the duration as an NSString with the time format MM:SS.
 */
@property (readonly) NSString *formattedDuration;

//------------------------------------------------------------------------------

/**
 Provides the SLEZOutput that is being used to handle the actual playback of the audio data. This property is also settable, but note that the SLEZAudioPlayer will become the output's SLEZOutputDataSource and SLEZOutputDelegate. To listen for the SLEZOutput's delegate methods your view should implement the SLEZAudioPlayerDelegate and set itself as the SLEZAudioPlayer's `delegate`.
 */
@property (nonatomic, strong, readwrite) SLEZOutput *output;

//------------------------------------------------------------------------------

/**
 Provides the frame index (a.k.a the seek positon) within the audio file being used for playback. This can be helpful when seeking through the audio file.
 @return An SInt64 representing the current frame index within the audio file used for playback.
 */
@property (readonly) SInt64 frameIndex;

//------------------------------------------------------------------------------

/**
 Provides a flag indicating whether the SLEZAudioPlayer is currently playing back any audio.
 @return A BOOL indicating whether or not the SLEZAudioPlayer is performing playback,
 */
@property (readonly) BOOL isPlaying;

//------------------------------------------------------------------------------

/**
 Provides the current pan from the audio player's internal `output` component. Setting the pan adjusts the direction of the audio signal from left (0) to right (1). Default is 0.5 (middle).
 */
@property (nonatomic, assign) float pan;

//------------------------------------------------------------------------------

/**
 Provides the total amount of frames in the current audio file being used for playback.
 @return A SInt64 representing the total amount of frames in the current audio file being used for playback.
 */
@property (readonly) SInt64 totalFrames;

//------------------------------------------------------------------------------

/**
 Provides the file path that's currently being used by the player for playback.
 @return  The NSURL representing the file path of the audio file being used for playback.
 */
@property (nonatomic, copy, readonly) NSURL *url;

//------------------------------------------------------------------------------

/**
  Provides the current volume from the audio player's internal `output` component. Setting the volume adjusts the gain of the output between 0 and 1. Default is 1.
 */
@property (nonatomic, assign) float volume;

//------------------------------------------------------------------------------
#pragma mark - Actions
//------------------------------------------------------------------------------

///-----------------------------------------------------------
/// @name Controlling Playback
///-----------------------------------------------------------

/**
 Starts playback.
 */
- (void)play;

//------------------------------------------------------------------------------

/**
 Loads an SLEZAudioFile and immediately starts playing it.
 @param audioFile An SLEZAudioFile to use for immediate playback.
 */
- (void)playAudioFile:(SLEZAudioFile *)audioFile;

//------------------------------------------------------------------------------

/**
 Pauses playback.
 */
- (void)pause;

//------------------------------------------------------------------------------

/**
 Seeks playback to a specified frame within the internal SLEZAudioFile. This will notify the SLEZAudioFileDelegate (if specified) with the audioPlayer:updatedPosition:inAudioFile: function.
 @param frame The new frame position to seek to as a SInt64.
 */
- (void)seekToFrame:(SInt64)frame;

@end
