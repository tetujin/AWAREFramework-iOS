//
//  EntityConversation+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2018/05/24.
//
//

#import "EntityConversation+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityConversation (CoreDataProperties)

+ (NSFetchRequest<EntityConversation *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *timestamp;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSNumber *datatype;
@property (nullable, nonatomic, copy) NSNumber *double_energy;
@property (nullable, nonatomic, copy) NSNumber *inference;
@property (nullable, nonatomic, retain) NSData *blob_feature;
@property (nullable, nonatomic, copy) NSNumber *double_convo_start;
@property (nullable, nonatomic, copy) NSNumber *double_convo_end;

@end

NS_ASSUME_NONNULL_END
