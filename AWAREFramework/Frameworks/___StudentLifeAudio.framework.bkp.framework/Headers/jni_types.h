#ifndef __JNI_TYPES_H__
#define __JNI_TYPES_H__

#ifdef USE_JNI

#include <jni.h>

#else

typedef int jint;
#ifdef _LP64 /* 64-bit */
typedef long jlong;
#else
typedef long long jlong;
#endif

typedef signed char jbyte;

typedef unsigned char   jboolean;
typedef unsigned short  jchar;
typedef short           jshort;
typedef float           jfloat;
typedef double          jdouble;

typedef jint            jsize;

#endif

#endif
