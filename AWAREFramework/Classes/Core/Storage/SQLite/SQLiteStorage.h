//
//  SQLiteStorage.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/30.
//

#import <UIKit/UIKit.h>
#import "AWAREStorage.h"

@interface SQLiteStorage : AWAREStorage <AWAREStorageDelegate>

@property NSManagedObjectContext *mainQueueManagedObjectContext;
@property NSManagedObjectContext *writeQueueManagedObjectContext;

typedef void (^InsertEntityCallBack)(NSDictionary *dataDict, NSManagedObjectContext * childContext, NSString* entity );

- (instancetype)initWithStudy:(AWAREStudy *)study sensorName:(NSString *)name entityName:(NSString *) entity insertCallBack:(InsertEntityCallBack)insertCallBack;

@end
