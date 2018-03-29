//
//  AudioAnalysis.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/28/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioAnalysis : NSObject

- (instancetype) initWithBuffer:(float *)buffer bufferSize:(UInt32)bufferSize;

- (double) getRMS;
- (double) getFrequency;
- (double) getdB;
+ (BOOL) isSilent:(double)rms threshold:(int)threshold;

@end
