//
//  ESMVideoView.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/17.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "BaseESMView.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface ESMVideoView : BaseESMView <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureMovieFileOutput * videoOutput;
@property (nonatomic, retain) AVPlayerViewController * playerViewController;

@end
