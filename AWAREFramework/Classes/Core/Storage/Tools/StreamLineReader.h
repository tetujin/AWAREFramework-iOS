//
//  StreamReader.h
//  StreamReader
//
//  Created by Yuuki Nishiyama on 2020/01/16.
//  Copyright © 2020 Yuuki Nishiyama. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface StreamLineReader : NSObject

@property (readonly) NSRange lastRange;

- (instancetype)initWithFile:(NSString *)filePath encoding:(NSStringEncoding)encoding;
- (instancetype)initWithFile:(NSString *)filePath encoding:(NSStringEncoding)encoding chunkSize:(UInt64)chunkSize lineTrimCharacter:(NSString *)c;

- (NSString * _Nullable)readLine;
- (void)setLineSearchPosition:(NSUInteger)position;

@end


NS_ASSUME_NONNULL_END
