//
//  AWAREHeadphoneMotionOM+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2020/10/26.
//
//

#import "AWAREHeadphoneMotionOM+CoreDataProperties.h"

@implementation AWAREHeadphoneMotionOM (CoreDataProperties)

+ (NSFetchRequest<AWAREHeadphoneMotionOM *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AWAREHeadphoneMotionOM"];
}

@dynamic timestamp;
@dynamic device_id;
@dynamic label;
@dynamic att_pitch;
@dynamic att_roll;
@dynamic att_yaw;
@dynamic att_q_x;
@dynamic att_q_y;
@dynamic att_q_z;
@dynamic att_q_w;
@dynamic att_rm_m11;
@dynamic att_rm_m12;
@dynamic att_rm_m13;
@dynamic att_rm_m21;
@dynamic att_rm_m22;
@dynamic att_rm_m23;
@dynamic att_rm_m31;
@dynamic att_rm_m32;
@dynamic att_rm_m33;
@dynamic gravity_x;
@dynamic gravity_y;
@dynamic gravity_z;
@dynamic heading;
@dynamic mag_x;
@dynamic mag_y;
@dynamic mag_z;
@dynamic mag_accuracy;
@dynamic rotation_x;
@dynamic rotation_y;
@dynamic rotation_z;
@dynamic location;
@dynamic user_acc_x;
@dynamic user_acc_y;
@dynamic user_acc_z;

@end
