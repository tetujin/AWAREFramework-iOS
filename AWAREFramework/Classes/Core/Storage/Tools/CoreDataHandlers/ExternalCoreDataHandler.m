//
//  ExternalCoreDataHandler.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/05/21.
//

#import "ExternalCoreDataHandler.h"

static ExternalCoreDataHandler * sharedHandler;

@implementation ExternalCoreDataHandler

+ (ExternalCoreDataHandler * _Nonnull)sharedHandler {
    @synchronized(self){
        if (!sharedHandler){
            sharedHandler = [[ExternalCoreDataHandler alloc] init];
        }
    }
    return sharedHandler;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedHandler == nil) {
            sharedHandler= [super allocWithZone:zone];
            return sharedHandler;
        }
    }
    return nil;
}

@end
