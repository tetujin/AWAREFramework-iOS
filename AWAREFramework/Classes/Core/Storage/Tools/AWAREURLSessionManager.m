//
//  AWARESessionConfigManager.m
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2020/05/17.
//

#import "AWAREURLSessionManager.h"

static AWAREURLSessionManager * shared;

@implementation AWAREURLSessionManager {
    NSMutableArray<NSURLSession * > * _Nonnull urlSessions;
}

+ (AWAREURLSessionManager * _Nonnull)shared{
    @synchronized(self){
        if (!shared){
            shared = [[AWAREURLSessionManager alloc] init];
        }
    }
    return shared;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (shared == nil) {
            shared= [super allocWithZone:zone];
            return shared;
        }
    }
    return nil;
}

- (instancetype)init{
    self = [super init];
    if (self != nil) {
        urlSessions = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) addURLSession:(NSURLSession * _Nonnull)urlSession {
    [urlSessions addObject:urlSession];
}

- (NSURLSession * _Nullable) getURLSession:(NSString * _Nonnull) sessionIdentifier {
    for (NSURLSession * urlSession in urlSessions) {
        if (urlSession.configuration.identifier != nil) {
            if ([sessionIdentifier isEqualToString:urlSession.configuration.identifier]){
                return urlSession;
            }
        }
    }
    return nil;
}

@end
