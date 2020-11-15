//
//  HeadphoneMotion.m
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2020/10/22.
//

#import "HeadphoneMotion.h"
#import "ObjectModels/AWAREHeadphoneMotionOM+CoreDataClass.h"
@import CoreMotion;

@implementation HeadphoneMotion

API_AVAILABLE(ios(14.0))
CMHeadphoneMotionManager * sensorManager;
double lastTimestamp;

NSArray * csvHeader;
NSArray * csvTypes;

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    
    AWAREStorage * storage = nil;
    
    csvHeader = @[
                @"timestamp", @"device_id",
                @"att_pitch", @"att_roll", @"att_yaw",
                @"att_q_x", @"att_q_y", @"att_q_z", @"att_q_w",
                @"att_rm_m11", @"att_rm_m12", @"att_rm_m13",
                @"att_rm_m21", @"att_rm_m22", @"att_rm_m23",
                @"att_rm_m31", @"att_rm_m32", @"att_rm_m33",
                @"gravity_x", @"gravity_y", @"gravity_z",
                @"heading",
                @"mag_x", @"mag_y", @"mag_z", @"mag_accuracy",
                @"rotation_x", @"rotation_y", @"rotation_z",
                @"location",
                @"user_acc_x", @"user_acc_y", @"user_acc_z",
                @"label"];

    csvTypes  = @[@(CSVTypeReal), @(CSVTypeText),
                  @(CSVTypeReal), @(CSVTypeReal), @(CSVTypeReal),
                   @(CSVTypeReal), @(CSVTypeReal), @(CSVTypeReal), @(CSVTypeReal),
                   @(CSVTypeReal), @(CSVTypeReal), @(CSVTypeReal),
                   @(CSVTypeReal), @(CSVTypeReal), @(CSVTypeReal),
                   @(CSVTypeReal), @(CSVTypeReal), @(CSVTypeReal),
                   @(CSVTypeReal), @(CSVTypeReal), @(CSVTypeReal),
                   @(CSVTypeReal),
                   @(CSVTypeReal), @(CSVTypeReal), @(CSVTypeReal),@(CSVTypeReal),
                   @(CSVTypeReal), @(CSVTypeReal), @(CSVTypeReal),
                   @(CSVTypeInteger),
                   @(CSVTypeReal), @(CSVTypeReal), @(CSVTypeReal),
                   @(CSVTypeText)];
    
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_HEADPHONE_MOTION];
    }else if(dbType == AwareDBTypeCSV){

        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_HEADPHONE_MOTION headerLabels:csvHeader headerTypes:csvTypes];
    }else{
//        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_HEADPHONE_MOTION];
        storage = [[SQLiteSeparatedStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_HEADPHONE_MOTION
                                                objectModelName:NSStringFromClass([AWAREHeadphoneMotionOM class])
                                                  syncModelName:NSStringFromClass([AWAREBatchDataOM class])
                                                      dbHandler:AWAREHeadphoneMotionCoreDataHandler.shared];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_HEADPHONE_MOTION
                             storage:storage];
    return self;
}

-(void)createTable{
    TCQMaker * maker = [[TCQMaker alloc] init];
    for (int i = 0; i<csvHeader.count; i++) {
        NSString * columnName = csvHeader[i];
        NSNumber * type = csvTypes[i];
        if ( ![columnName isEqualToString:@"timestamp"] &&
             ![columnName isEqualToString:@"device_id"]) {
            if (type.integerValue == CSVTypeText) {
                [maker addColumn:columnName type:TCQTypeText default:@"''"];
            }else if (type.integerValue == CSVTypeReal){
                [maker addColumn:columnName type:TCQTypeReal default:@"0"];
            }else if (type.integerValue == CSVTypeBlob || type.integerValue == CSVTypeInteger){
                [maker addColumn:columnName type:TCQTypeInteger default:@"0"];
            }
        }
    }
    if (self.storage != nil) {
        [self.storage createDBTableOnServerWithTCQMaker:maker];
    }
}


-(BOOL)startSensor{
//    if (self) {
//        if (@available(iOS 14.0, *)) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                sensorManager = [[CMHeadphoneMotionManager alloc] init];
//            });
//        } else {
//            // Fallback on earlier versions
//        }
//    }
    
    if (@available(iOS 14.0, *)) {
        
        NSLog(@"%d", [NSThread isMainThread]);
        
        sensorManager = [[CMHeadphoneMotionManager alloc] init];
    
        if (sensorManager.isDeviceMotionAvailable){
            [sensorManager startDeviceMotionUpdatesToQueue:NSOperationQueue.currentQueue
                                               withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
                if (motion != nil && error == nil){
                    NSMutableDictionary * data = [[NSMutableDictionary alloc] init];
                    [data setObject:[AWAREUtils getUnixTimestamp:[NSDate now]] forKey:@"timestamp"];
                    [data setObject:[self getDeviceId] forKey:@"device_id"];
                    [data setObject:@(motion.attitude.pitch) forKey:@"att_pitch"];
                    [data setObject:@(motion.attitude.roll)  forKey:@"att_roll"];
                    [data setObject:@(motion.attitude.yaw)   forKey:@"att_yaw"];
                    [data setObject:@(motion.attitude.quaternion.x) forKey:@"att_q_x"];
                    [data setObject:@(motion.attitude.quaternion.y) forKey:@"att_q_y"];
                    [data setObject:@(motion.attitude.quaternion.z) forKey:@"att_q_z"];
                    [data setObject:@(motion.attitude.quaternion.w) forKey:@"att_q_w"];
                    [data setObject:@(motion.attitude.rotationMatrix.m11) forKey:@"att_rm_m11"];
                    [data setObject:@(motion.attitude.rotationMatrix.m12) forKey:@"att_rm_m12"];
                    [data setObject:@(motion.attitude.rotationMatrix.m13) forKey:@"att_rm_m13"];
                    [data setObject:@(motion.attitude.rotationMatrix.m21) forKey:@"att_rm_m21"];
                    [data setObject:@(motion.attitude.rotationMatrix.m22) forKey:@"att_rm_m22"];
                    [data setObject:@(motion.attitude.rotationMatrix.m23) forKey:@"att_rm_m23"];
                    [data setObject:@(motion.attitude.rotationMatrix.m31) forKey:@"att_rm_m31"];
                    [data setObject:@(motion.attitude.rotationMatrix.m32) forKey:@"att_rm_m32"];
                    [data setObject:@(motion.attitude.rotationMatrix.m33) forKey:@"att_rm_m33"];
                    [data setObject:@(motion.gravity.x) forKey:@"gravity_x"];
                    [data setObject:@(motion.gravity.y) forKey:@"gravity_y"];
                    [data setObject:@(motion.gravity.y) forKey:@"gravity_z"];
                    [data setObject:@(motion.heading) forKey:@"heading"];
                    [data setObject:@(motion.magneticField.field.x) forKey:@"mag_x"];
                    [data setObject:@(motion.magneticField.field.y) forKey:@"mag_y"];
                    [data setObject:@(motion.magneticField.field.z) forKey:@"mag_z"];
                    [data setObject:@(motion.magneticField.accuracy) forKey:@"mag_accuracy"];
                    [data setObject:@(motion.rotationRate.x) forKey:@"rotation_x"];
                    [data setObject:@(motion.rotationRate.y) forKey:@"rotation_y"];
                    [data setObject:@(motion.rotationRate.z) forKey:@"rotation_z"];
                    [data setObject:@(motion.sensorLocation) forKey:@"location"];
                    [data setObject:@(motion.userAcceleration.x) forKey:@"user_acc_x"];
                    [data setObject:@(motion.userAcceleration.y) forKey:@"user_acc_y"];
                    [data setObject:@(motion.userAcceleration.z) forKey:@"user_acc_z"];
                    if (self.label != nil) {
                        [data setObject:self.label forKey:@"label"];
                    }else{
                        [data setObject:@"" forKey:@"label"];
                    }
                    
                    [self setLatestValue:[NSString stringWithFormat:
                                          @"%f, %f, %f",
                                          motion.userAcceleration.x,
                                          motion.userAcceleration.y,
                                          motion.userAcceleration.z]];
                    
                    [self setLatestData:data];
                    
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:data
                                                                         forKey:EXTRA_DATA];
                    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_HEADPHONE_MOTION
                                                                        object:nil
                                                                      userInfo:userInfo];
                    
                    SensorEventHandler handler = [self getSensorEventHandler];
                    if (handler!=nil) {
                        handler(self, data);
                    }
                    
                    [self.storage saveDataWithDictionary:data buffer:YES saveInMainThread:NO];
                    
                }else{
                    NSLog(@"[headphone_motion] %@:%ld", [error domain], (long)[error code]);
                }
                
            }];
            return YES;
        }
    }
    return NO;
}

-(BOOL)stopSensor{
    if (@available(iOS 14.0, *)) {
        if (sensorManager != nil){
            [sensorManager stopDeviceMotionUpdates];
        }
        sensorManager = nil;
        return true;
    }
    return YES;
}


- (void)headphoneMotionManagerDidConnect:(CMHeadphoneMotionManager *)manager API_AVAILABLE(ios(14.0)){
    NSLog(@"-headphoneMotionManagerDidConnect:");
}


- (void)headphoneMotionManagerDidDisconnect:(CMHeadphoneMotionManager *)manager API_AVAILABLE(ios(14.0)){
    NSLog(@"-headphoneMotionManagerDidConnect:");
}


@end

static AWAREHeadphoneMotionCoreDataHandler * shared;
@implementation AWAREHeadphoneMotionCoreDataHandler
+ (AWAREHeadphoneMotionCoreDataHandler * _Nonnull)shared {
    @synchronized(self){
        if (!shared){
            shared =  (AWAREHeadphoneMotionCoreDataHandler *)[[BaseCoreDataHandler alloc] initWithDBName:@"AWARE_HeadphoneMotion"];
        }
    }
    return shared;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (shared == nil) {
            shared= [super allocWithZone:zone];
            return shared;
        }
    }
    return nil;
}

@end
