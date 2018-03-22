//
//  EntityESMAnswer+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/17/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityESMAnswer.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityESMAnswer (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *double_esm_user_answer_timestamp;
@property (nullable, nonatomic, retain) NSNumber *esm_expiration_threshold;
@property (nullable, nonatomic, retain) NSString *esm_json;
@property (nullable, nonatomic, retain) NSNumber *esm_status;
@property (nullable, nonatomic, retain) NSString *esm_trigger;
@property (nullable, nonatomic, retain) NSString *esm_user_answer;
@property (nullable, nonatomic, retain) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
