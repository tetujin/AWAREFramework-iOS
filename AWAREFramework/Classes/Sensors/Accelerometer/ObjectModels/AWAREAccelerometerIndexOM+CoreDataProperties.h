//
//  AWAREAccelerometerIndexOM+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2019/12/05.
//
//

#import "AWAREAccelerometerIndexOM+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface AWAREAccelerometerIndexOM (CoreDataProperties)

+ (NSFetchRequest<AWAREAccelerometerIndexOM *> *)fetchRequest;

@property (nonatomic) int32_t count;
@property (nullable, nonatomic, copy) NSDate *date;
@property (nonatomic) BOOL synced;
@property (nonatomic) int64_t timestamp;
@property (nullable, nonatomic, retain) NSSet<AWAREAccelerometerOM *> *data;

@end

@interface AWAREAccelerometerIndexOM (CoreDataGeneratedAccessors)

- (void)addDataObject:(AWAREAccelerometerOM *)value;
- (void)removeDataObject:(AWAREAccelerometerOM *)value;
- (void)addData:(NSSet<AWAREAccelerometerOM *> *)values;
- (void)removeData:(NSSet<AWAREAccelerometerOM *> *)values;

@end

NS_ASSUME_NONNULL_END
