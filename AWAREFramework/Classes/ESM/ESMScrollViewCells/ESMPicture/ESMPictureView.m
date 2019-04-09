//
//  ESMPictureView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/17.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMPictureView.h"
#import <Photos/Photos.h>

@implementation ESMPictureView
{
    AVCaptureDevice * captureDevice;
    AVCaptureInput  * videoInput;
    UIButton        * shutterBtn;
    UIImageView     * imageView;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm viewController:(UIViewController *)viewController{
    self = [super initWithFrame:frame esm:esm viewController:viewController];
    
    if(self != nil){
        [self addPicturePageElement:esm withFrame:frame];
        // [_imageView setBackgroundColor:[UIColor grayColor]];
    }
    return self;
}



- (void) addPicturePageElement:(EntityESM *)esm withFrame:(CGRect) frame {
    
    // int heightSpace = 10;
    int widthSpace = 20;
    // int previewHeight = 400;
    
    captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

//    captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
//                                                       mediaType:AVMediaTypeVideo
//                                                        position:AVCaptureDevicePositionFront];

    NSError *error = nil;
    videoInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice
                                                             error:&error];
    
    if (videoInput) {
        AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
        [captureSession addInput:videoInput];
        [captureSession beginConfiguration];
        captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        [captureSession commitConfiguration];
        
        int previewHeight = (self.mainView.frame.size.width-(widthSpace*2))/3 * 4;
        
        AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        previewLayer.frame = CGRectMake(widthSpace,
                                          0, //self.mainView.frame.origin.y,
                                          self.mainView.frame.size.width-(widthSpace*2),
                                          previewHeight);
        [self.mainView.layer insertSublayer:previewLayer atIndex:0];
        
        //////////////////////////////////
        imageView = [[UIImageView alloc] initWithFrame:previewLayer.frame];
        [imageView setBackgroundColor:[UIColor grayColor]];
        UIImage * img = nil;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [imageView setImage:img];
        [imageView setHidden:YES];
        [imageView setNeedsDisplay];
        [self.mainView addSubview:imageView];
        
        //////////////////
        shutterBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        shutterBtn.center = CGPointMake(self.mainView.center.x,
                                        previewHeight - 50 );
        [shutterBtn setImage:[self getImageFromLibAssetsWithImageName:@"camera_button_normal"] forState:UIControlStateNormal];
        [shutterBtn addTarget:self action:@selector(pressedShutterButton:) forControlEvents:UIControlEventTouchUpInside];
        shutterBtn.tag = 0;
        [self.mainView addSubview:shutterBtn];
        
        self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                         self.mainView.frame.origin.y,
                                         self.mainView.frame.size.width,
                                         previewHeight);
        
        _photoOutput = [[AVCapturePhotoOutput alloc] init];
        [captureSession addOutput:_photoOutput];
        
        [captureSession startRunning];
    }else {
        NSLog(@"[ESMPicture] Error:%@", error);
    }

    
    [self refreshSizeOfRootView];
}


- (IBAction)pressedShutterButton:(UIButton *)sender {
    
    NSInteger tag = sender.tag;
    
    if(tag==0){
        AVCapturePhotoSettings * photoSettings = [AVCapturePhotoSettings photoSettings];
        [_photoOutput capturePhotoWithSettings:photoSettings delegate:self];
    }else{
        imageView.hidden = YES;
        [shutterBtn setImage:[self getImageFromLibAssetsWithImageName:@"camera_button_normal"] forState:UIControlStateNormal];
        shutterBtn.tag = 0;
    }
}


- (void)captureOutput:(AVCapturePhotoOutput *)output
didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer
previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer
     resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
      bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings
                error:(NSError *)error{
    if (error) {
        NSLog(@"error : %@", error.localizedDescription);
    }
    
    if (photoSampleBuffer) {
        
        NSData * data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
        UIImage * image = [UIImage imageWithData:data];

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->shutterBtn setImage:[self getImageFromLibAssetsWithImageName:@"camera_button_cancel"] forState:UIControlStateNormal];
            self->shutterBtn.tag = 1;
            self->imageView.image = image;
            self->imageView.hidden = NO;
        });

    }   
}

- (NSNumber *)getESMState{
    if(imageView.image == nil){
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
    if([self isNA]){
        return @"NA";
    }else{
        if(imageView.image != nil){
            NSString * base64Encoded = [UIImagePNGRepresentation(imageView.image) base64EncodedStringWithOptions:0];
            // SString *base64Encoded = [musicData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            return base64Encoded;
        }else{
            return @"";
        }
    }
}


@end
