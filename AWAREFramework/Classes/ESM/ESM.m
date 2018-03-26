//
//  ESM.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/22.
//

#import "ESM.h"
#import "AWAREDelegate.h"

@implementation ESM

- (BOOL)setESMSchedule:(EntityESMSchedule *)esmSchedule{
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator =  delegate.persistentStoreCoordinator;
    
    NSMergePolicy *originalMergePolicy = context.mergePolicy;
    context.mergePolicy = NSOverwriteMergePolicy;
    
    NSError * error = nil;
    bool result = [context save:&error];
    context.mergePolicy = originalMergePolicy;
//    EntityESMSchedule * entityESMSchedule = (EntityESMSchedule *) [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMSchedule class])
    
    return result;
}

@end
