//
//  StreamReader.m
//  StreamReader
//
//  Created by Yuuki Nishiyama on 2020/01/16.
//  Copyright © 2020 Yuuki Nishiyama. All rights reserved.
//

#import "StreamLineReader.h"

//static unsigned char const BRLineReaderDelimiter = '\n';

@implementation StreamLineReader
{
    NSString * filePath;
    NSFileHandle * handler;
    NSMutableData * buffer;
    NSStringEncoding encoding;
    UInt64 chunkSize;
    NSString * lineTrimCharacter;
}

@synthesize lastRange;

- (instancetype)initWithFile:(NSString *)filePath encoding:(NSStringEncoding)encoding{
//    return [self initWithFile:filePath encoding:encoding chunkSize:4096 lineTrimCharacter:@"\n"];
    return [self initWithFile:filePath encoding:encoding chunkSize:256 lineTrimCharacter:@"\n"];
}
- (instancetype)initWithFile:(NSString *)filePath
                    encoding:(NSStringEncoding)encoding
                   chunkSize:(UInt64)chunkSize
           lineTrimCharacter:(NSString *)c
{
    self = [super init];
    if (self) {
        self->filePath = filePath;
        self->encoding = encoding;
        self->chunkSize = chunkSize;
        self->lineTrimCharacter = c;
        handler = [NSFileHandle fileHandleForReadingAtPath:filePath];
        buffer = [[NSMutableData alloc] init];
    }
    
    return self;
}


- (NSString *)readLine
{
    NSData * elimiterData = [self->lineTrimCharacter dataUsingEncoding:NSUTF8StringEncoding];

    [handler seekToFileOffset: lastRange.location];
    
    BOOL atEof = NO;
    while (!atEof) {
        NSRange range = [buffer rangeOfData:elimiterData options:NSDataSearchBackwards range:NSMakeRange(0, buffer.length)];
        if (range.location != NSNotFound) {
            // [buffer subdataWithRange:NSMakeRange(0, range.location)];
            NSData * subBuffer = [buffer subdataWithRange:NSMakeRange(0, range.location)];
            NSString * line = [[NSString alloc] initWithData:subBuffer encoding:NSUTF8StringEncoding];
            buffer = [[buffer subdataWithRange:NSMakeRange(range.location+1, buffer.length-range.location-1)] mutableCopy];
            return line;
        }
        NSData * tmpData = [handler readDataOfLength:self->chunkSize];
        lastRange = NSMakeRange(handler.offsetInFile,self->chunkSize);
        
        if(tmpData.length > 0){
            [buffer appendData:tmpData];
        }else{
            atEof = YES;
            if (buffer.length > 0) {
                NSString * line = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
                buffer = nil;
                return line;
            }
        }
    }
    
    return nil;
}

- (void)setLineSearchPosition:(NSUInteger)position
{
    lastRange = NSMakeRange(position, 0);
    buffer = [[NSMutableData alloc] init];
}

@end
