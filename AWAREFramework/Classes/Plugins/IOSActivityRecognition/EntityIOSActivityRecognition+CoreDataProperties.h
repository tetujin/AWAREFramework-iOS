//
//  EntityIOSActivityRecognition+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 9/19/16.
//
//

#import "EntityIOSActivityRecognition+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityIOSActivityRecognition (CoreDataProperties)

+ (NSFetchRequest<EntityIOSActivityRecognition *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *activities;
@property (nullable, nonatomic, copy) NSNumber *automotive;
@property (nullable, nonatomic, copy) NSNumber *confidence;
@property (nullable, nonatomic, copy) NSNumber *cycling;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *label;
@property (nullable, nonatomic, copy) NSNumber *running;
@property (nullable, nonatomic, copy) NSNumber *stationary;
@property (nullable, nonatomic, copy) NSNumber *timestamp;
@property (nullable, nonatomic, copy) NSNumber *unknown;
@property (nullable, nonatomic, copy) NSNumber *walking;

@end

NS_ASSUME_NONNULL_END
