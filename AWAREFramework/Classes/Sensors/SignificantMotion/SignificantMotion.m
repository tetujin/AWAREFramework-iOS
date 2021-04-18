//
//  SignificantMotion.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2019/07/31.
//

#import "SignificantMotion.h"
#import "EntitySignificantMotion+CoreDataClass.h"

NSString * const ACTION_AWARE_SIGNIFICANT_MOTION_START = @"ACTION_AWARE_SIGNIFICANT_MOTION_START";
NSString * const ACTION_AWARE_SIGNIFICANT_MOTION_END   = @"ACTION_AWARE_SIGNIFICANT_MOTION_END";
NSString * const AWARE_PREFERENCES_STATUS_SIGNIFICANT_MOTION = @"status_significant_motion";

@implementation SignificantMotion{
    CMMotionManager * manager;
    NSMutableArray  * buffer;
    BOOL LAST_SIGMOTION_STATE;
    double SIGMOTION_THRESHOLD;
    SignificantMotionStartHandler startHandler;
    SignificantMotionEndHandler endHandler;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    /**
     * NOTE: This sensor is using `significant` as DB name, but the sensor name is `significant_motion`.
     * For using same configurations on AWARE Android, the name of storage and sensor is using the different names.
     */
    NSString * sensorName = @"significant_motion";
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON){
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:sensorName];
    }else if (dbType == AwareDBTypeCSV){
        NSArray * headerLabels = @[@"timestamp",@"device_id",@"is_moving"];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeInteger)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:sensorName headerLabels:headerLabels headerTypes:headerTypes];
    }else{
        NSString * entityName = NSStringFromClass([EntitySignificantMotion class]);
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:sensorName entityName:entityName insertCallBack:^(NSDictionary *dataDict, NSManagedObjectContext *childContext, NSString *entity) {
            if (dataDict != nil) {
                EntitySignificantMotion * sigEntity = (EntitySignificantMotion *)[NSEntityDescription
                                                                          insertNewObjectForEntityForName:entity
                                                                          inManagedObjectContext:childContext];
                [sigEntity setValuesForKeysWithDictionary:dataDict];
            }
        }];
    }
    
    self = [super initWithAwareStudy:study sensorName:sensorName storage:storage];
    if (self != nil) {
        manager = [[CMMotionManager alloc] init];
        buffer  = [[NSMutableArray alloc] init];
        _CURRENT_SIGMOTION_STATE = false;
        LAST_SIGMOTION_STATE     = false;
        SIGMOTION_THRESHOLD      = 1.0f;
    }
    return self;
}

- (void)createTable{
    if ([self isDebug]) {
        NSLog(@"[%@] Create Table", [self getSensorName]);
    }
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:@"is_moving" type:TCQTypeInteger default:@"0"];
    if (self.storage != nil){
        NSString * query = [maker getDefaudltTableCreateQuery];
        [self.storage createDBTableOnServerWithQuery:query tableName:@"significant"];
    }
}

- (void)setParameters:(NSArray *)parameters{
    
}

- (BOOL)startSensor{
    if ([self isDebug]) NSLog(@"[%@] Start Sensor!", [self getSensorName]);
    if (![manager isDeviceMotionAvailable]) {
        if ([self isDebug]) NSLog(@"[%@] device motion is not supported on this device", [self getSensorName]);
        return NO;
    }
    
    // SENSOR_DELAY_UI = 60ms = 0.06s
    manager.deviceMotionUpdateInterval = 0.06f;

    NSOperationQueue * queue = [NSOperationQueue currentQueue];
    [manager startDeviceMotionUpdatesToQueue:queue withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[%@] %@", [self getSensorName],[error debugDescription]);
        }else{
            if (motion != nil) {
                double x = motion.userAcceleration.x * 9.8;
                double y = motion.userAcceleration.y * 9.8;
                double z = motion.userAcceleration.z * 9.8;
                
                double mSignificantEnergy = sqrt(x * x + y * y + z * z);
                
                if (self->buffer!=nil) {
                    [self->buffer addObject:@(mSignificantEnergy)];
                    if (self->buffer.count > 40) {
                        //remove oldest value
                        [self->buffer removeObjectAtIndex:0];
                        
                        double max_energy = -1;
                        for (NSNumber * e in self->buffer) {
                            if (e!=nil) {
                                if (e.doubleValue >= max_energy) max_energy = e.doubleValue;
                            }
                        }
                        
                        if (max_energy >= self->SIGMOTION_THRESHOLD) {
                            self->_CURRENT_SIGMOTION_STATE = true;
                        } else if (max_energy < self->SIGMOTION_THRESHOLD) {
                            self->_CURRENT_SIGMOTION_STATE = false;
                        }
                        
                        if (self->_CURRENT_SIGMOTION_STATE != self->LAST_SIGMOTION_STATE){
                            if ([self isDebug]) NSLog(@"[%@] A significant motion occured!", [self getSensorName]);
                            
                            // save data
                            NSNumber * now = [AWAREUtils getUnixTimestamp:[NSDate new]];
                            NSMutableDictionary * data = [[NSMutableDictionary alloc] init];
                            [data setObject:now forKey:@"timestamp"];
                            [data setObject:[self getDeviceId] forKey:@"device_id"];
                            [data setObject:@(self->_CURRENT_SIGMOTION_STATE) forKey:@"is_moving"];
                            if (self.label != nil) {
                                [data setObject:self.label forKey:@"label"];
                            }else{
                                [data setObject:@"" forKey:@"label"];
                            }
                            if (self.storage!=nil) {
                                [self.storage saveDataWithDictionary:data buffer:NO saveInMainThread:YES];
                            }
                            
                            // broadcast
                            if (self->_CURRENT_SIGMOTION_STATE) {
                                [NSNotificationCenter.defaultCenter postNotificationName:ACTION_AWARE_SIGNIFICANT_MOTION_START object:nil];
                                if (self->startHandler != nil) self->startHandler();
                            }else{
                                [NSNotificationCenter.defaultCenter postNotificationName:ACTION_AWARE_SIGNIFICANT_MOTION_END object:nil];
                                if (self->endHandler != nil) self->endHandler();
                            }
                            SensorEventHandler handler = [self getSensorEventHandler];
                            if(handler != nil){
                                handler(self, data);
                            }
                        }
                        
                        self->LAST_SIGMOTION_STATE = self->_CURRENT_SIGMOTION_STATE;
                    }
                }else{
                    NSLog(@"[%@] `buffer` variable is null", [self getSensorName]);
                }

            }else{
                NSLog(@"[%@] motion data is null",[self getSensorName]);
            }
        }
    }];
    return YES;
}

- (BOOL)stopSensor{
    if (manager!=nil) {
        [manager stopAccelerometerUpdates];
    }
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    [self setSensingState:NO];
    return YES;
}

- (void)setSignificantMotionStartHandler:(SignificantMotionStartHandler)handler{
    startHandler = handler;
}

- (void)setSignificantMotionEndHandler:(SignificantMotionEndHandler)handler{
    endHandler = handler;
}

@end
