//
//  LocalTextStorageHelper.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/16/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWAREDebugMessageLogger.h"

@interface LocalFileStorageHelper : NSObject

- (instancetype) initWithStorageName:(NSString *) storageName;

// An array list for a buffer
//@property (weak, nonatomic) NSMutableArray * bufferArray;
- (void) setCSVHeader:(NSArray *) headers;

- (NSData *) getCSVData;

/// create file
- (BOOL) createNewFile:(NSString*)fileName;

/// clear file
- (bool) clearFile:(NSString *) fileName;

/// save data
- (bool) saveDataWithArray:(NSArray*) array;
- (bool) saveData:(NSDictionary *)data;
- (bool) saveData:(NSDictionary *)data toLocalFile:(NSString *)fileName;
- (BOOL) appendLine:(NSString *)line;

// get sensor data
- (NSMutableString *) getSensorDataForPost;
- (NSMutableString *) fixJsonFormat:(NSMutableString *) clipedText;
- (NSInteger) getMaxDateLength;
- (uint64_t) getFileSize;
- (uint64_t) getFileSizeWithName:(NSString*) name;

// set and get mark
- (void) setNextMark;
- (void) resetMark;
- (int)  getMarker;

// set and get a losted text length
- (int) getLostedTextLength;
- (void) setLostedTextLength:(int)lostedTextLength;

// set debug tracker
- (void) trackDebugEventsWithDMLogger:(AWAREDebugMessageLogger *) logger;

// get sensor storage name and path
- (NSString *) getSensorName;
- (NSString *) getFilePath;

// set buffer and db lock
- (void) setBufferSize:(int) size;
//- (void)dbLock;
//- (void)dbUnlock;

@end
