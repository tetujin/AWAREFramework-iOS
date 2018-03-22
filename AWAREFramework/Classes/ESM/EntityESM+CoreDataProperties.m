//
//  EntityESM+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2017/09/23.
//
//

#import "EntityESM+CoreDataProperties.h"

@implementation EntityESM (CoreDataProperties)

+ (NSFetchRequest<EntityESM *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EntityESM"];
}

@dynamic device_id;
@dynamic double_esm_user_answer_timestamp;
@dynamic esm_checkboxes;
@dynamic esm_expiration_threshold;
@dynamic esm_flows;
@dynamic esm_instructions;
@dynamic esm_json;
@dynamic esm_likert_max;
@dynamic esm_likert_max_label;
@dynamic esm_likert_min_label;
@dynamic esm_likert_step;
@dynamic esm_minute_step;
@dynamic esm_na;
@dynamic esm_number;
@dynamic esm_quick_answers;
@dynamic esm_radios;
@dynamic esm_scale_max;
@dynamic esm_scale_max_label;
@dynamic esm_scale_min;
@dynamic esm_scale_min_label;
@dynamic esm_scale_start;
@dynamic esm_scale_step;
@dynamic esm_start_date;
@dynamic esm_start_time;
@dynamic esm_status;
@dynamic esm_submit;
@dynamic esm_time_format;
@dynamic esm_title;
@dynamic esm_trigger;
@dynamic esm_type;
@dynamic esm_url;
@dynamic esm_user_answer;
@dynamic timestamp;
@dynamic esm_app_integration;
@dynamic esm_schedule;

@end
