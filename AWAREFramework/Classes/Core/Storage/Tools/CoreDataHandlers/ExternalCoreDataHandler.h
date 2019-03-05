//
//  ExternalCoreDataHandler.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/05/21.
//

#import <Foundation/Foundation.h>
#import "BaseCoreDataHandler.h"

@interface ExternalCoreDataHandler :BaseCoreDataHandler

+ (ExternalCoreDataHandler * _Nonnull)sharedHandler;

@end
