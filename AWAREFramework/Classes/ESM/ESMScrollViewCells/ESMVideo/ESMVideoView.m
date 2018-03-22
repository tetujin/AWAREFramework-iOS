//
//  ESMVideoView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/17.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMVideoView.h"

@implementation ESMVideoView
{
    AVCaptureDevice *captureDevice;
    AVCaptureDevice *audioDevice;
    AVCaptureInput *videoInput;
    AVCaptureInput *audioInput;
    UIButton *shutterBtn;
    UIImageView * imageView;
    NSString * videoFileName;
    NSTimer * baseTimer;
    UILabel * timerLabel;
    UIView * timerBGView;
    int totalTime;
}


- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm{
    self = [super initWithFrame:frame esm:esm];
    
    if(self != nil){
        [self addVideoElement:esm withFrame:frame];
        // [_imageView setBackgroundColor:[UIColor grayColor]];
    }
    return self;
}



- (void) addVideoElement:(EntityESM *)esm withFrame:(CGRect) frame {
    
    videoFileName = [NSString stringWithFormat:@"%@_output.mp4",esm.esm_trigger];
    
    // int heightSpace = 10;
    int widthSpace = 20;
    // int previewHeight = 400;
    
    //////////////////////////// Audio //////////////////////////////
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord
                                           error:&error];
    
    if(!error){
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if(error) NSLog(@"Error while activating AudioSession : %@", error);
    }else{
        NSLog(@"Error while setting category of AudioSession : %@", error);
    }
    
    
    //////////////////////////// Video Camera ////////////////////////
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    
    
    captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    audioDevice   = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];

    //    captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
    //                                                       mediaType:AVMediaTypeVideo
    //                                                        position:AVCaptureDevicePositionFront];
    
    videoInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice
                                                       error:nil];
    audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice
                                                       error:nil];
    _videoOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    if (videoInput && audioInput) {
        
        [captureSession beginConfiguration];
        [captureSession addInput:videoInput];
        [captureSession addInput:audioInput];
        captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        [captureSession addOutput:_videoOutput];
        AVCaptureConnection *c = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
        if (c.active) {
            NSLog(@"[AWARE] connection for video output is active");
        } else {
            NSLog(@"[AWARE] connection for video output is not active");
        }
        [captureSession commitConfiguration];

        
        
        /////////////////////////////////////////////////////////////////////////////
        int previewHeight = (self.mainView.frame.size.width-(widthSpace*2))/3 * 4;
        
        AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        previewLayer.frame = CGRectMake(widthSpace,
                                        0, //self.mainView.frame.origin.y,
                                        self.mainView.frame.size.width-(widthSpace*2),
                                        previewHeight);
        [self.mainView.layer insertSublayer:previewLayer atIndex:0];
        
        ///////////////////////////////////////////////////////////////////////////////
        _playerViewController = [[AVPlayerViewController alloc] init];
        _playerViewController.view.frame = CGRectMake(0, 0, self.mainView.frame.size.width, 100);
        _playerViewController.showsPlaybackControls = YES;
        _playerViewController.view.hidden = YES;
        _playerViewController.view.contentMode = UIViewContentModeScaleToFill;
        
        [self.mainView addSubview:_playerViewController.view];
        
        
        /////////////////////////////////////////////////////////////////////////////////////
        shutterBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        shutterBtn.center = CGPointMake(self.mainView.center.x,
                                        previewHeight - 50 );
        [shutterBtn setImage:[UIImage imageNamed:@"camera_button_normal"] forState:UIControlStateNormal];
        [shutterBtn addTarget:self action:@selector(pressedShutterButton:) forControlEvents:UIControlEventTouchUpInside];
        shutterBtn.tag = 0;
        [self.mainView addSubview:shutterBtn];
        self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                         self.mainView.frame.origin.y,
                                         self.mainView.frame.size.width,
                                         previewHeight);
        
        
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
        
        /////////////////////////////////////////////////////////
        
        [captureSession startRunning];
    }else {
        NSLog(@"ERROR:%@", error);
    }
    
    [self refreshSizeOfRootView];
}


- (IBAction)pressedShutterButton:(UIButton *)sender {
    
    NSInteger tag = sender.tag;
    
    if(tag==0){ // normal -> stop
        AudioServicesPlaySystemSound(1117);
        [shutterBtn setImage:[UIImage imageNamed:@"camera_button_stop"] forState:UIControlStateNormal];
        shutterBtn.tag = 1;
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoFileName];
        NSFileManager *manager = [[NSFileManager alloc] init];
        if ([manager fileExistsAtPath:outputPath]) {
            [manager removeItemAtPath:outputPath error:nil];
        }
        [_videoOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputPath] recordingDelegate:self];
        totalTime = 0;
        baseTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                repeats:YES block:^(NSTimer * _Nonnull timer) {
                                                    totalTime++;
                                                    int mm = totalTime/60;
                                                    int ss = totalTime%60;
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
                                                    timerLabel.text = [NSString stringWithFormat:@"%@:%@",mmstr,ssstr];
                                                }];
    }else if(tag==1){ // stop -> cancel
        [shutterBtn setImage:[UIImage imageNamed:@"camera_button_cancel"] forState:UIControlStateNormal];
        shutterBtn.tag = 2;
        _playerViewController.view.hidden = NO;
        [_videoOutput stopRecording];
        timerLabel.text = @"00:00";
        if(baseTimer != nil)[baseTimer invalidate];
        timerLabel.hidden = YES;
        timerBGView.hidden = YES;
        AudioServicesPlaySystemSound(1118);
    }else if(tag==2){ // cancel -> normal
        _playerViewController.view.hidden = YES;
        [shutterBtn setImage:[UIImage imageNamed:@"camera_button_normal"] forState:UIControlStateNormal];
        shutterBtn.tag = 0;
        // remove video
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoFileName];
        NSFileManager *manager = [[NSFileManager alloc] init];
        if ([manager fileExistsAtPath:outputPath]) {
            [manager removeItemAtPath:outputPath error:nil];
        }
        timerLabel.hidden = NO;
        timerBGView.hidden = NO;
        AudioServicesPlaySystemSound(1105);
    }
}


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error{
    NSLog(@"%@",outputFileURL);
    _playerViewController.player = [AVPlayer playerWithURL:outputFileURL];
    // [_playerViewController.player play];
}



- (NSString *)getUserAnswer{
    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoFileName];
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(outputPath)){
        UISaveVideoAtPathToSavedPhotosAlbum (outputPath,self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
    
    return @"answered";
}

    
- (NSNumber *)getESMState{
    if(shutterBtn.tag == 2){
        return @2;
    }else{
        return @1;
    }
}

    
- (void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if (error){
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Photo/Video Saving Failed"  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil, nil];
//        [alert show];
    } else {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Photo/Video Saved" message:@"Saved To Photo Album"  delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
//        [alert show];
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoFileName];
        NSFileManager *manager = [[NSFileManager alloc] init];
        if ([manager fileExistsAtPath:outputPath]) {
            [manager removeItemAtPath:outputPath error:nil];
        }
    }
}


@end
