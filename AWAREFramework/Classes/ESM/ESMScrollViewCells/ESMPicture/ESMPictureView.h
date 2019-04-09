//
//  ESMPictureView.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/17.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//
// [sample] http://akira.watson.jp/iphone/objective-c/camera.html

#import "BaseESMView.h"
#import <AVFoundation/AVFoundation.h>

@interface ESMPictureView : BaseESMView<AVCapturePhotoCaptureDelegate>

// @property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;
@property (nonatomic, strong) AVCapturePhotoOutput * photoOutput;

@end
