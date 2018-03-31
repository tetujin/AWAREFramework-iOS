//
//  ESM.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/22.
//

#import "ESM.h"
#import "AWAREDelegate.h"
#import "EntityESMAnswer.h"

@implementation ESM

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                            dbType:(AwareDBType)dbType{
    
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_ESMS];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_ESMS entityName:NSStringFromClass([EntityESMAnswer class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_ESMS
                             storage:storage];
    if(self != nil){
        
    }
    return self;
}

@end
