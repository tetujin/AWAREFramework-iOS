//
//  AudioAnalysis.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/28/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AudioAnalysis.h"
#import "EZAudio.h"

// https://github.com/denzilferreira/com.aware.plugin.ambient_noise/blob/master/ambient_Noise/src/main/java/com/aware/plugin/ambient_noise/AudioAnalysis.java

@implementation AudioAnalysis{
    float* buffer;
    int bufferSize;
}


- (instancetype)initWithBuffer:(float *) audioBuffer bufferSize:(UInt32)audioBufferSize{
    self = [super init];
    if (self != nil) {
        buffer = audioBuffer;
        bufferSize = audioBufferSize;
    }
    return self;
}

/**
 * Get sample Root Mean Squares value. Used to detect silence.
 * @return RMS value
 */
- (double) getRMS{

//    double sum = 0d;
//    for( short data : audio_data ) {
//        sum += data;
//    }
//    double average = sum/audio_data.length;
//    double sumMeanSquare = 0d;
//    for( short data : audio_data ) {
//        sumMeanSquare += Math.pow(data-average, 2d);
//    }
//    double averageMeanSquare = sumMeanSquare/audio_data.length;
//    return Math.sqrt(averageMeanSquare);
 
    return [EZAudioUtilities RMS:buffer length:bufferSize];
}

/**
 * Get sound frequency in Hz
 * @return Frequency in Hz
 */
- (double) getFrequency {
//    if( audio_data.length == 0 ) return 0;
//    
//    //Create an FFT buffer
//    double[] fft_buffer = new double[ buffer_size * 2 ];
//    for( int i = 0; i< audio_data.length; i++ ) {
//        fft_buffer[2*i] = (double) audio_data[i];
//        fft_buffer[2*i+1] = 0;
//    }
//    
//    //apply FFT to fill imaginary buffers
//    DoubleFFT_1D fft = new DoubleFFT_1D(buffer_size);
//    fft.realForward(fft_buffer);
//    
//    //Fetch power spectrum (magnitudes) and normalize them
//    double[] magnitudes = new double[buffer_size/2];
//    for(int i = 1; i< buffer_size/2-1; i++ ) {
//        double real = fft_buffer[2*i];
//        double imaginary = fft_buffer[2*i+1];
//        magnitudes[i] = Math.sqrt((real*real)+(imaginary*imaginary));
//    }
//    
//    //find largest peak in power spectrum (magnitudes)
//    double max = -1;
//    int max_index = -1;
//    for( int i=0; i<buffer_size/2-1; i++ ) {
//        if( magnitudes[i] > max ) {
//            max = magnitudes[i];
//            max_index = i;
//        }
//    }
//    return 2*(max_index*8000/buffer_size);
    return 0;
}


/**
 * Relative ambient noise in dB
 * @return dB level
 */
- (double) getdB {
//    if( audio_data.length == 0 ) return 0;
//    double amplitude = -1;
//    for( short data : audio_data ) {
//        if( amplitude < data ) {
//            amplitude = data;
//        }
//    }
//    return Math.abs(20*Math.log10(amplitude/32768.0));
    
    if (bufferSize == 0) return 0;
    double amplitude = -1;
    for (int i=0; i<bufferSize; i++) {
        float data = buffer[i];
        if (amplitude < data) {
            amplitude = data;
        }
    }
    
    // double inf = INFINITY;
    return fabs(20*log10(amplitude/32768.0));
//    return
//    if (isinf(dB)){
//        NSLog(@"*** NOTE: The dB is infinity value!!! ***");
//        dB = 0;
//    }
//    return dB;

    
    
//    float sum = 0.0;
//    for(int i = 0; i < bufferSize; i++)
//        sum += buffer[i] * buffer[i];
//    return sqrtf( sum / bufferSize);
//    return 0;
}

//RMS to check if we are in silence
+ (BOOL) isSilent:(double)rms threshold:(int)threshold{
    if (rms > threshold) {
        return YES;
    }else{
        return NO;
    }
}

@end
