//
//  DataTypeConverter.h
//  StudentLife
//
//  Created by Rui Wang on 12/18/15.
//  Copyright © 2015 Rui Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "stdint.h"

@interface DataTypeConverter : NSObject

/* ========================= */
+(void)toByta: (Byte)data outPtr:(Byte*)outPtr;
+(void)toByta: (Byte*) data withLen:(int)srcLen  dest:(Byte*)dest destLen:(int)destLen;

/* ========================= */

+(void)toShortByta: (int16_t)data dest:(Byte*)dest;
+(void)toShortByta:(int16_t*) data withLen:(int)srcLen  dest:(Byte*)dest destLen:(int)destLen;

/* ========================= */

+(void)toIntByta: (int32_t)data dest:(Byte*)dest;
+(void)toIntByta:(int32_t*)data withLen:(int)srcLen  dest:(Byte*)dest destLen:(int)destLen;

/* ========================= */

+(void)toLongByta: (int64_t)data dest:(Byte*)dest;
+(void)toLongByta:(int64_t*) data  withLen:(int)srcLen  dest:(Byte*)dest destLen:(int)destLen;

/* ========================= */

+(void)toFloatByta: (float)data dest:(Byte*)dest;
+(void)toFloatByta:(float*) data  withLen:(int)srcLen  dest:(Byte*)dest destLen:(int)destLen;

/* ========================= */

+(void)toDoubleByta: (double)data dest:(Byte*)dest;
+(void)toDoubleByta:(double*)data  withLen:(int)srcLen  dest:(Byte*)dest destLen:(int)destLen;


@end
