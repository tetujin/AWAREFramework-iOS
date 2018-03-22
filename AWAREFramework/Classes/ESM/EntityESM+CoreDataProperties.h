//
//  EntityESM+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2017/09/23.
//
//

#import "EntityESM+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityESM (CoreDataProperties)

+ (NSFetchRequest<EntityESM *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSNumber *double_esm_user_answer_timestamp;
@property (nullable, nonatomic, copy) NSString *esm_checkboxes;
@property (nullable, nonatomic, copy) NSNumber *esm_expiration_threshold;
@property (nullable, nonatomic, copy) NSString *esm_flows;
@property (nullable, nonatomic, copy) NSString *esm_instructions;
@property (nullable, nonatomic, copy) NSString *esm_json;
@property (nullable, nonatomic, copy) NSNumber *esm_likert_max;
@property (nullable, nonatomic, copy) NSString *esm_likert_max_label;
@property (nullable, nonatomic, copy) NSString *esm_likert_min_label;
@property (nullable, nonatomic, copy) NSNumber *esm_likert_step;
@property (nullable, nonatomic, copy) NSNumber *esm_minute_step;
@property (nullable, nonatomic, copy) NSNumber *esm_na;
@property (nullable, nonatomic, copy) NSNumber *esm_number;
@property (nullable, nonatomic, copy) NSString *esm_quick_answers;
@property (nullable, nonatomic, copy) NSString *esm_radios;
@property (nullable, nonatomic, copy) NSNumber *esm_scale_max;
@property (nullable, nonatomic, copy) NSString *esm_scale_max_label;
@property (nullable, nonatomic, copy) NSNumber *esm_scale_min;
@property (nullable, nonatomic, copy) NSString *esm_scale_min_label;
@property (nullable, nonatomic, copy) NSNumber *esm_scale_start;
@property (nullable, nonatomic, copy) NSNumber *esm_scale_step;
@property (nullable, nonatomic, copy) NSString *esm_start_date;
@property (nullable, nonatomic, copy) NSString *esm_start_time;
@property (nullable, nonatomic, copy) NSNumber *esm_status;
@property (nullable, nonatomic, copy) NSString *esm_submit;
@property (nullable, nonatomic, copy) NSString *esm_time_format;
@property (nullable, nonatomic, copy) NSString *esm_title;
@property (nullable, nonatomic, copy) NSString *esm_trigger;
@property (nullable, nonatomic, copy) NSNumber *esm_type;
@property (nullable, nonatomic, copy) NSString *esm_url;
@property (nullable, nonatomic, copy) NSString *esm_user_answer;
@property (nullable, nonatomic, copy) NSNumber *timestamp;
@property (nullable, nonatomic, copy) NSString *esm_app_integration;
@property (nullable, nonatomic, retain) EntityESMSchedule *esm_schedule;

@end

NS_ASSUME_NONNULL_END
