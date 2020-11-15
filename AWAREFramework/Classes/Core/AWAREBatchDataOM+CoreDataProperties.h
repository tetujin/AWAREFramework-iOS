//
//  AWAREBatchDataOM+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2020/10/26.
//
//

#import "AWAREBatchDataOM+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface AWAREBatchDataOM (CoreDataProperties)

+ (NSFetchRequest<AWAREBatchDataOM *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSObject *batch_data;
@property (nonatomic) int32_t count;
@property (nonatomic) int64_t timestamp;

@end

NS_ASSUME_NONNULL_END
