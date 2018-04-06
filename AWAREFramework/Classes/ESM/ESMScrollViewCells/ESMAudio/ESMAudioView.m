//
//  ESMAudioView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/17.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMAudioView.h"

@implementation ESMAudioView {
    UIButton * audioPlayBtn;
    UIButton *shutterBtn;
    UIView * audioLevelView;
    int * maxAudioLevelViewSize;
    NSString * audioFileName;
    NSTimer * baseTimer;
    UILabel * timerLabel;
    UIView * timerBGView;
    int totalTime;
    NSTimer * levelTimer;
    
}


- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm viewController:(UIViewController *)viewController{
    self = [super initWithFrame:frame esm:esm viewController:viewController];
    
    if(self != nil){
        [self addAudioElement:esm withFrame:frame];
        // [_imageView setBackgroundColor:[UIColor grayColor]];
    }
    return self;
}



- (void) addAudioElement:(EntityESM *)esm withFrame:(CGRect) frame {
    
    audioFileName = [NSString stringWithFormat:@"%@_audio",esm.esm_trigger];
    
    // int heightSpace = 10;
    // int widthSpace = 20;
    int previewHeight = 260;
    
//    UIView * audioBaseLevelView = [[UIView alloc] initWithFrame:CGRectMake(0,0,
//                                                              10,
//                                                              10)];
//    audioBaseLevelView.layer.cornerRadius = audioBaseLevelView.frame.size.width / 2.0;
//    audioBaseLevelView.center = CGPointMake(self.mainView.center.x, previewHeight/2);
//    audioBaseLevelView.clipsToBounds = YES;
//    audioBaseLevelView.backgroundColor = [UIColor whiteColor];
//    [self.mainView addSubview:audioBaseLevelView];
    

    
    /////////////////////////////////////////////////////////////////////////////
//    int previewHeight = (self.mainView.frame.size.width-(widthSpace*2))/3 * 4;
//    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
//    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    previewLayer.frame = CGRectMake(widthSpace,
//                                    0, //self.mainView.frame.origin.y,
//                                    self.mainView.frame.size.width-(widthSpace*2),
//                                    previewHeight);
//    [self.mainView.layer insertSublayer:previewLayer atIndex:0];
    
    ///////////////////////////////////////////////////////////////////////////////
//    _playerViewController = [[AVPlayerViewController alloc] init];
//    _playerViewController.view.frame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
//    _playerViewController.showsPlaybackControls = YES;
//    _playerViewController.view.hidden = YES;
//    _playerViewController.view.contentMode = UIViewContentModeScaleToFill;
//    [self.mainView addSubview:_playerViewController.view];
    
    /////////////////////////////////////////////////////////////////////////////
    timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    timerLabel.center = CGPointMake(self.mainView.center.x,
                                    20);
    timerLabel.text = @"00:00";
    timerLabel.textAlignment = NSTextAlignmentCenter;
    timerLabel.font = [UIFont fontWithName:timerLabel.font.fontName size:24];
    timerLabel.textColor = [UIColor whiteColor];;
    
    timerBGView =[[UIView alloc] initWithFrame:timerLabel.frame];
    [timerBGView setBackgroundColor:[UIColor grayColor]];
    timerBGView.alpha = 0.5;//
    timerBGView.layer.cornerRadius = 2.0f;
    [self.mainView addSubview:timerBGView];
    [self.mainView addSubview:timerLabel];
    
    ////////////////////////////
    audioLevelView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                              timerBGView.frame.origin.y + timerBGView.frame.size.height + 20,
                                                              100,
                                                              100)];
    audioLevelView.layer.cornerRadius = audioLevelView.frame.size.width / 2.0;
    audioLevelView.center = CGPointMake(self.mainView.center.x, audioLevelView.center.y);
    audioLevelView.clipsToBounds = YES;
    audioLevelView.backgroundColor = [UIColor darkGrayColor];
    [self.mainView addSubview:audioLevelView];
    
    
    /////////////////////////////////////////////////////////////////////////////////////
    shutterBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    shutterBtn.center = CGPointMake(self.mainView.center.x,
                                    previewHeight - 50 );
    [shutterBtn setImage:[self getImageFromLibAssetsWithImageName:@"camera_button_normal"] forState:UIControlStateNormal];
    [shutterBtn addTarget:self action:@selector(pressedShutterButton:) forControlEvents:UIControlEventTouchUpInside];
    shutterBtn.tag = 0;
    [self.mainView addSubview:shutterBtn];
    self.mainView.backgroundColor = [UIColor darkGrayColor];
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     previewHeight);
    
    ///////////////////////////////////////////////////////////////////////////////////
    audioPlayBtn = [[UIButton alloc] initWithFrame:CGRectMake(shutterBtn.frame.origin.x - 100,
                                                             0,
                                                             50, 50)];
    audioPlayBtn.center = CGPointMake(audioPlayBtn.center.x, shutterBtn.center.y);
    [audioPlayBtn setImage:[self getImageFromLibAssetsWithImageName:@"aware_audio_play"] forState:UIControlStateNormal];
    audioPlayBtn.tag = 0;
    [audioPlayBtn addTarget:self action:@selector(tappedAudioPlayButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.mainView addSubview:audioPlayBtn];

    /////////////////////////////////////////////////////////
    
    

    
    [self startAudioSession];
    
    [self refreshSizeOfRootView];
}


- (BOOL) startAudioSession {
    // Prepare the audio session
    NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error]) {
        NSLog(@"Error setting session category: %@", error.localizedFailureReason);
        return NO;
    }
    
    if (![session setActive:YES error:&error]) {
        NSLog(@"Error activating audio session: %@", error.localizedFailureReason);
        return NO;
    }
    return session.isInputAvailable;
}


- (IBAction)pressedShutterButton:(UIButton *)sender {
    
    NSInteger tag = sender.tag;
    
    if(tag==0){ // normal -> stop
        AudioServicesPlaySystemSound(1117);
        [shutterBtn setImage:[self getImageFromLibAssetsWithImageName:@"camera_button_stop"] forState:UIControlStateNormal];
        shutterBtn.tag = 1;
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:audioFileName];
        NSFileManager *manager = [[NSFileManager alloc] init];
        if ([manager fileExistsAtPath:outputPath]) {
            [manager removeItemAtPath:outputPath error:nil];
        }
        [self performSelector:@selector(record) withObject:nil afterDelay:0.5f];
        totalTime = 0;
        audioPlayBtn.hidden = YES;
        audioLevelView.backgroundColor = [UIColor whiteColor];

    }else if(tag==1){ // stop -> cancel
        // change button image and tag for next action
        [shutterBtn setImage:[self getImageFromLibAssetsWithImageName:@"camera_button_cancel"] forState:UIControlStateNormal];
        shutterBtn.tag = 2;
        // _playerViewController.view.hidden = NO;
        timerLabel.text = @"00:00";
        if(baseTimer != nil)[baseTimer invalidate];
        if(levelTimer != nil)[levelTimer invalidate];
        timerLabel.hidden = YES;
        timerBGView.hidden = YES;
        audioPlayBtn.hidden = NO;
        [self stopRecording];
        [self performSelector:@selector(playStopSound) withObject:nil afterDelay:0.5f];
        audioLevelView.backgroundColor = [UIColor darkGrayColor];
    
    }else if(tag==2){ // cancel -> normal
        // _playerViewController.view.hidden = YES;
        [shutterBtn setImage:[self getImageFromLibAssetsWithImageName:@"camera_button_normal"] forState:UIControlStateNormal];
        shutterBtn.tag = 0;
        // remove video
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:audioFileName];
        NSFileManager *manager = [[NSFileManager alloc] init];
        if ([manager fileExistsAtPath:outputPath]) {
            [manager removeItemAtPath:outputPath error:nil];
        }
        timerLabel.hidden = NO;
        timerBGView.hidden = NO;
        AudioServicesPlaySystemSound(1105);
    }
}

- (void) playStopSound {
    AudioServicesPlaySystemSound(1118);
}


- (NSNumber *)getESMState{
    NSData *musicData = [self getAudioData];
    if(musicData == nil){
        if ([self isNA]) {
            return @2;
        }else{
            return @1;
        }
    }else{
        return @2;
    }
}

- (NSString *)getUserAnswer{
    NSData *musicData = [self getAudioData];
    if (musicData != nil) {
        NSString *base64Encoded = [musicData base64EncodedStringWithOptions:0];
        return base64Encoded;
    }else{
        return @"";
    }
}


- (NSData *) getAudioData{
    NSArray *searchPaths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath_ = [searchPaths objectAtIndex: 0];
    NSString *pathToSave = [documentPath_ stringByAppendingPathComponent:audioFileName];
    NSURL *url = [NSURL fileURLWithPath:pathToSave];//FILEPATH];
    NSData *musicData = [NSData dataWithContentsOfURL:url];
    return musicData;
}


- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    // [self play];
}

////////////////////////////////////////////////////////

- (void) tappedAudioPlayButton:(UIButton *)sender{
    NSInteger tag = sender.tag;
    if(tag == 0){
        [audioPlayBtn setImage:[self getImageFromLibAssetsWithImageName:@"aware_audio_pause"] forState:UIControlStateNormal];
        audioPlayBtn.tag = 1;
        [self play];
    }else{
        [audioPlayBtn setImage:[self getImageFromLibAssetsWithImageName:@"aware_audio_play"] forState:UIControlStateNormal];
        audioPlayBtn.tag = 0;
        [self stopPlaying];
    }

}

///////////////////////////////////////////////////////////////

- (BOOL) record
{
    NSError *error;
    
    // Recording settings
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    
    [settings setValue: [NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [settings setValue: [NSNumber numberWithFloat:8000.0] forKey:AVSampleRateKey];
    [settings setValue: [NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    [settings setValue: [NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [settings setValue: [NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [settings setValue: [NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    [settings setValue:  [NSNumber numberWithInt: AVAudioQualityMax] forKey:AVEncoderAudioQualityKey];
    
    NSArray *searchPaths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath_ = [searchPaths objectAtIndex: 0];
    NSString *pathToSave = [documentPath_ stringByAppendingPathComponent:audioFileName];
    // File URL
    NSURL *url = [NSURL fileURLWithPath:pathToSave];//FILEPATH];
    
    NSFileManager *manager = [[NSFileManager alloc] init];
    if ([manager fileExistsAtPath:pathToSave]) {
        [manager removeItemAtPath:pathToSave error:nil];
    }
    
    [self startAudioSession];
    
    // Create recorder
    _recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    if (!_recorder)
    {
        NSLog(@"Error establishing recorder: %@", error.localizedFailureReason);
        return NO;
    }
    
    // Initialize degate, metering, etc.
    _recorder.delegate = self;
    _recorder.meteringEnabled = YES;

    if (![_recorder prepareToRecord])
    {
        NSLog(@"Error: Prepare to record failed");
        //[self say:@"Error while preparing recording"];
        return NO;
    }
    
    if (![_recorder record])
    {
        NSLog(@"Error: Record failed");
        //  [self say:@"Error while attempting to record audio"];
        return NO;
    }
    
    
    levelTimer = [NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector: @selector(levelTimerCallback:) userInfo: nil repeats: YES];

    
    // Set a timer to monitor levels, current time
    baseTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                repeats:YES block:^(NSTimer * _Nonnull timer) {
                                                    self->totalTime++;
                                                    int mm = self->totalTime/60;
                                                    int ss = self->totalTime%60;
                                                    NSString * ssstr;
                                                    NSString * mmstr;
                                                    if(ss<10){
                                                        ssstr = [NSString stringWithFormat:@"0%d",ss];
                                                    }else{
                                                        ssstr = [NSString stringWithFormat:@"%d", ss];
                                                    }
                                                    if(mm<10){
                                                        mmstr = [NSString stringWithFormat:@"0%d",mm];
                                                    }else{
                                                        mmstr = [NSString stringWithFormat:@"%d",mm];
                                                    }
                                                    self->timerLabel.text = [NSString stringWithFormat:@"%@:%@",mmstr,ssstr];
                                                    
                                                    [self->_recorder updateMeters];
                                                }];
    return YES;
}

- (void)levelTimerCallback:(NSTimer *)timer {
    [_recorder updateMeters];
    // here is the DB!
    // the value is -160 - 0
    // https://developer.apple.com/documentation/avfoundation/avaudioplayer/1388509-peakpowerforchannel?changes=latest_minor&language=objc
    // float peakDecebels =  [_recorder peakPowerForChannel:0];
    float averagePower = ([_recorder averagePowerForChannel:0] * -1 );
    // NSLog(@"%f",averagePower);
    // audioLevelView.alpha = averagePower;
    audioLevelView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    audioLevelView.layer.borderWidth = averagePower;
    audioLevelView.layer.backgroundColor = [UIColor whiteColor].CGColor;
}


- (void) stopRecording{
    // This causes the didFinishRecording delegate method to fire
    [_recorder stop];
}

-(void)play {
    NSArray *searchPaths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath_ = [searchPaths objectAtIndex: 0];
    NSString *pathToSave = [documentPath_ stringByAppendingPathComponent:audioFileName];
    // File URL
    NSURL *url = [NSURL fileURLWithPath:pathToSave];//FILEPATH];
    
    NSError * error = nil;
    //Start playback
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    
    if (!_player) {
        NSLog(@"Error establishing player for %@: %@", _recorder.url, error.localizedFailureReason);
        return;
    }
    
    _player.delegate = self;
    
    // Change audio session for playback
    if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error]) {
        NSLog(@"Error updating audio session: %@", error.localizedFailureReason);
        return;
    }

    [_player prepareToPlay];
    [_player play];
}


- (void) stopPlaying {
    [_player stop];
}

- (void) continueRecording {
    // resume from a paused recording
    [_recorder record];
}

- (void) pauseRecording {
    // pause an ongoing recording
    [_recorder pause];
}


///////////////////////////////////////////////



@end
