//
//  EntityESMAnswerHistory+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2018/04/02.
//
//

#import "EntityESMAnswerHistory+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityESMAnswerHistory (CoreDataProperties)

+ (NSFetchRequest<EntityESMAnswerHistory *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *fire_hour;
@property (nullable, nonatomic, copy) NSString *schedule_id;
@property (nullable, nonatomic, copy) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
