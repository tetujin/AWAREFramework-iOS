//
//  MultiESMObject.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/23/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "MultiESMObject.h"
#import "SingleESMObject.h"

@implementation MultiESMObject

- (instancetype)initWithEsmText:(NSString*) esmText
{
    _esms = [[NSMutableArray alloc] init];
    self = [super init];
    if (self) {
        [self setEsmsWithText:esmText];
    }
    return self;
}

- (BOOL) setEsmsWithText:(NSString*) esmText {
    _esmStr = esmText;
    NSData *data = [esmText dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id object = [NSJSONSerialization
                 JSONObjectWithData:data
                 options:0
                 error:&error];
    if(error) {
        /* JSON was malformed, act appropriately here */
        NSLog(@"JSON format error!");
        return NO;
    }
    NSArray *results = object;
    NSLog(@"====== Hello ESM !! =======");
    for (NSDictionary *dic in results) {
        SingleESMObject *esmObject = [[SingleESMObject alloc] initWithEsm:dic];
        [_esms addObject:esmObject];
    }
    return YES;
}

@end
