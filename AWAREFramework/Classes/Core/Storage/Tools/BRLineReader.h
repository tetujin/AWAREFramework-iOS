//
//  BRLineReader.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/04/09.
//
// https://code.i-harness.com/ja/q/fef6e

#import <Foundation/Foundation.h>

@interface BRLineReader : NSObject

@property (readonly, nonatomic) NSData *data;
@property (readonly, nonatomic) NSUInteger linesRead;
@property (strong, nonatomic) NSCharacterSet *lineTrimCharacters;
@property (readonly, nonatomic) NSStringEncoding stringEncoding;

- (instancetype)initWithFile:(NSString *)filePath encoding:(NSStringEncoding)encoding;
- (instancetype)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
- (NSString *)readLine;
- (NSString *)readTrimmedLine;
- (void)setLineSearchPosition:(NSUInteger)position;

@end
