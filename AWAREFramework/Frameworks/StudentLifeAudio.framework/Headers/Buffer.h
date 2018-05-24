//
//  Buffer.h
//  StudentlifeAudioPipelineDemo
//
//  Created by Rui Wang on 12/16/15.
//  Copyright © 2015 Rui Wang. All rights reserved.
//

#ifndef Buffer_h
#define Buffer_h


typedef struct FloatBuffer
{
    float *bufferPtr;
    long bufferLen;
    long bufferSize;
} FloatBuffer;

#endif /* Buffer_h */
