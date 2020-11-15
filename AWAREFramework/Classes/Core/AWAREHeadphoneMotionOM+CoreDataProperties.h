//
//  AWAREHeadphoneMotionOM+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2020/10/26.
//
//

#import "AWAREHeadphoneMotionOM+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface AWAREHeadphoneMotionOM (CoreDataProperties)

+ (NSFetchRequest<AWAREHeadphoneMotionOM *> *)fetchRequest;

@property (nonatomic) int64_t timestamp;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *label;
@property (nonatomic) double att_pitch;
@property (nonatomic) double att_roll;
@property (nonatomic) double att_yaw;
@property (nonatomic) double att_q_x;
@property (nonatomic) double att_q_y;
@property (nonatomic) double att_q_z;
@property (nonatomic) double att_q_w;
@property (nonatomic) double att_rm_m11;
@property (nonatomic) double att_rm_m12;
@property (nonatomic) double att_rm_m13;
@property (nonatomic) double att_rm_m21;
@property (nonatomic) double att_rm_m22;
@property (nonatomic) double att_rm_m23;
@property (nonatomic) double att_rm_m31;
@property (nonatomic) double att_rm_m32;
@property (nonatomic) double att_rm_m33;
@property (nonatomic) double gravity_x;
@property (nonatomic) double gravity_y;
@property (nonatomic) double gravity_z;
@property (nonatomic) double heading;
@property (nonatomic) double mag_x;
@property (nonatomic) double mag_y;
@property (nonatomic) double mag_z;
@property (nonatomic) int16_t mag_accuracy;
@property (nonatomic) double rotation_x;
@property (nonatomic) double rotation_y;
@property (nonatomic) double rotation_z;
@property (nonatomic) int16_t location;
@property (nonatomic) double user_acc_x;
@property (nonatomic) double user_acc_y;
@property (nonatomic) double user_acc_z;

@end

NS_ASSUME_NONNULL_END
