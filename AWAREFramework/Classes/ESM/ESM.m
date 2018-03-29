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
    self = [super initWithAwareStudy:study
                          sensorName:@"esms"
                        dbEntityName:NSStringFromClass([EntityESMAnswer class])
                              dbType:AwareDBTypeSQLite
                          bufferSize:0];
    if(self != nil){
        
    }
    return self;
}

@end
