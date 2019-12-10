//
//  AWAREFetchAdjuster.h
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/12/09.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWAREFetchSizeAdjuster : NSObject

@property (readonly) NSInteger totalSuccess;
@property (readonly) NSInteger fetchSize;
@property BOOL debug;

- (instancetype) initWithSensorName:(NSString *)sensorName;
- (void) success;
- (void) failure;

@end

NS_ASSUME_NONNULL_END
