//
//  AWAREFetchAdjuster.m
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/12/09.
//

#import "AWAREFetchSizeAdjuster.h"

@implementation AWAREFetchSizeAdjuster{
    NSString * sensor;
    NSString * key;
}

@synthesize totalSuccess;
@synthesize fetchSize;

- (instancetype)init{
    return [self initWithSensorName:[NSUUID UUID].UUIDString];
}

-(instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super init];
    if (self!=nil) {
        sensor = sensorName;
        key = [NSString stringWithFormat:@"AWARE_DATA_FETCH_SIZE_FOR_SYNC_%@", sensor];
        fetchSize = [self getStoredFetchSize];
        if (fetchSize <= 0) {
            fetchSize = 60;
            [self updateFetchSize:fetchSize];
        }
    }
    return self;
}

- (void)success{
    totalSuccess = totalSuccess + 1;
    if(self.debug) NSLog(@"[AWAREFetchSizeAdjuster] SUCCESS : %ld", totalSuccess);
    
    double threshold = logb((double)fetchSize);
    
    if(self.debug) NSLog(@"[AWAREFetchSizeAdjuster] THRESHOLD TO INCREASE FETCH SIZE : %f", threshold);
    if (totalSuccess >= threshold) {
        totalSuccess = 0;
        fetchSize = fetchSize + 1;
        if(self.debug) NSLog(@"[AWAREFetchSizeAdjuster] Fetch Size INCREASE : %ld", (long)fetchSize);
        [self updateFetchSize:fetchSize];
    }
}

- (void)failure{
    totalSuccess = 0;
    NSInteger tempFetchSize = fetchSize / 2;
    if(self.debug) NSLog(@"[AWAREFetchSizeAdjuster] Fetch Size REDUCE : %ld", (long)fetchSize);
    if (tempFetchSize <= 0) {
        fetchSize = 1;
        [self updateFetchSize:fetchSize];
    }else{
        fetchSize = tempFetchSize;
        [self updateFetchSize:fetchSize];
    }
}

- (NSInteger) getStoredFetchSize{
    return [[NSUserDefaults standardUserDefaults] integerForKey:key];
}

- (void) updateFetchSize:(NSInteger)fetchSize{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:fetchSize forKey:key];
    [defaults synchronize];
}

@end
