//
//  EntityESMAnswerBC+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2016/12/18.
//
//

#import "EntityESMAnswerBC+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityESMAnswerBC (CoreDataProperties)

+ (NSFetchRequest<EntityESMAnswerBC *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSNumber *double_esm_user_answer_timestamp;
@property (nullable, nonatomic, copy) NSString *esm_checkboxes;
@property (nullable, nonatomic, copy) NSNumber *esm_expiration_threshold;
@property (nullable, nonatomic, copy) NSString *esm_instructions;
@property (nullable, nonatomic, copy) NSNumber *esm_likert_max;
@property (nullable, nonatomic, copy) NSString *esm_likert_max_label;
@property (nullable, nonatomic, copy) NSString *esm_likert_min_label;
@property (nullable, nonatomic, copy) NSNumber *esm_likert_step;
@property (nullable, nonatomic, copy) NSString *esm_quick_answers;
@property (nullable, nonatomic, copy) NSString *esm_radios;
@property (nullable, nonatomic, copy) NSNumber *esm_scale_max;
@property (nullable, nonatomic, copy) NSString *esm_scale_max_label;
@property (nullable, nonatomic, copy) NSNumber *esm_scale_min;
@property (nullable, nonatomic, copy) NSString *esm_scale_min_label;
@property (nullable, nonatomic, copy) NSNumber *esm_scale_start;
@property (nullable, nonatomic, copy) NSNumber *esm_scale_step;
@property (nullable, nonatomic, copy) NSNumber *esm_status;
@property (nullable, nonatomic, copy) NSString *esm_submit;
@property (nullable, nonatomic, copy) NSString *esm_title;
@property (nullable, nonatomic, copy) NSString *esm_trigger;
@property (nullable, nonatomic, copy) NSNumber *esm_type;
@property (nullable, nonatomic, copy) NSString *esm_user_answer;
@property (nullable, nonatomic, copy) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
