//
//  AWARECoreDataUploader.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/30/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWAREStudy.h"
#import "AWAREDataUploader.h"
#import "AWAREUploader.h"

typedef enum: NSInteger {
    AwareDBConditionNormal = 0,
    AwareDBConditionInserting = 1,
    AwareDBConditionUpDating = 3,
    AwareDBConditionCounting = 4,
    AwareDBConditionFetching = 5,
    AwareDBConditionDeleting = 6
} AwareDBCondition;


@interface AWARECoreDataManager : AWAREUploader <AWAREDataUploaderDelegate>

// - (instancetype) initWithAwareStudy:(AWAREStudy *) study sensorName:(NSString *)sensorName dbEntityName:(NSString *) entityName;

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                        sensorName:(NSString *)name
                      dbEntityName:(NSString *)entity;

- (bool) saveDataWithArray:(NSArray*)array;
- (bool) saveData:(NSDictionary *)data;
- (void) insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString*) entity;

@end
