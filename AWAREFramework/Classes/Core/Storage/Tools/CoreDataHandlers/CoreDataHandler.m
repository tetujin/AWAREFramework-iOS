//
//  CoreDataHandler.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/04/03.
//

#import "CoreDataHandler.h"
#import <UserNotifications/UserNotifications.h>

static CoreDataHandler * sharedHandler;

@implementation CoreDataHandler

+ (CoreDataHandler * _Nonnull)sharedHandler {
    @synchronized(self){
        if (!sharedHandler){
            sharedHandler = [[CoreDataHandler alloc] init];
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
