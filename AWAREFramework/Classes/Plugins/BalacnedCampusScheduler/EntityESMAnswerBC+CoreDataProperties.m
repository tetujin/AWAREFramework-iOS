//
//  EntityESMAnswerBC+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2016/12/18.
//
//

#import "EntityESMAnswerBC+CoreDataProperties.h"

@implementation EntityESMAnswerBC (CoreDataProperties)

+ (NSFetchRequest<EntityESMAnswerBC *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EntityESMAnswerBC"];
}

@dynamic device_id;
@dynamic double_esm_user_answer_timestamp;
@dynamic esm_checkboxes;
@dynamic esm_expiration_threshold;
@dynamic esm_instructions;
@dynamic esm_likert_max;
@dynamic esm_likert_max_label;
@dynamic esm_likert_min_label;
@dynamic esm_likert_step;
@dynamic esm_quick_answers;
@dynamic esm_radios;
@dynamic esm_scale_max;
@dynamic esm_scale_max_label;
@dynamic esm_scale_min;
@dynamic esm_scale_min_label;
@dynamic esm_scale_start;
@dynamic esm_scale_step;
@dynamic esm_status;
@dynamic esm_submit;
@dynamic esm_title;
@dynamic esm_trigger;
@dynamic esm_type;
@dynamic esm_user_answer;
@dynamic timestamp;

@end
