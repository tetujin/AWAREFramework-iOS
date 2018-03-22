//
//  ESMAudioView.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/17.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "BaseESMView.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface ESMAudioView : BaseESMView <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer * player;

@end
