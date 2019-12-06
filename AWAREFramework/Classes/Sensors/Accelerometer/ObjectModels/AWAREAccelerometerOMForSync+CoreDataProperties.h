//
//  AWAREAccelerometerOMForSync+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2019/12/06.
//
//

#import "AWAREAccelerometerOMForSync+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface AWAREAccelerometerOMForSync (CoreDataProperties)

+ (NSFetchRequest<AWAREAccelerometerOMForSync *> *)fetchRequest;

@property (nonatomic) int32_t count;
@property (nonatomic) int64_t timestamp;
@property (nullable, nonatomic, retain) NSArray *batch_data;
@property (nullable, nonatomic, copy) NSDate *date;

@end

NS_ASSUME_NONNULL_END
