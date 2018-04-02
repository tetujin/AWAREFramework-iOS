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


- (void)createTable{
    TCQMaker *tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:@"esm_json"                         type:TCQTypeText    default:@"''"];
    [tcqMaker addColumn:@"esm_status"                       type:TCQTypeInteger default:@"0"];
    [tcqMaker addColumn:@"esm_expiration_threshold"         type:TCQTypeInteger default:@"0"];
    [tcqMaker addColumn:@"double_esm_user_answer_timestamp" type:TCQTypeReal    default:@"0"];
    [tcqMaker addColumn:@"esm_user_answer"                  type:TCQTypeText    default:@"''"];
    [tcqMaker addColumn:@"esm_trigger"                      type:TCQTypeText    default:@"''"];
    NSString * query = [tcqMaker getTableCreateQueryWithUniques:nil];
    [self.storage createDBTableOnServerWithQuery:query tableName:SENSOR_ESMS];
}

@end
