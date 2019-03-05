//
//  CoreDataHandler.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/04/03.
//

#import <Foundation/Foundation.h>
#import "BaseCoreDataHandler.h"

///////////////////////////////////////////
//// Normal CoreData Handler
@interface CoreDataHandler : BaseCoreDataHandler

+ (CoreDataHandler * _Nonnull)sharedHandler;

@end
