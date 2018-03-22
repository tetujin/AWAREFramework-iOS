//
//  AWAREPlugin.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"


@protocol AWAREPluginDelegate <NSObject>
//- (instancetype)initWithPluginName:(NSString *)pluginName deviceId:(NSString*) deviceId;
//- (instancetype) initWithPluginName:(NSString *)pluginName awareStudy:(AWAREStudy *) study;
// - (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType;
- (instancetype) initWithAwareStudy:(AWAREStudy *)study
                         pluginName:(NSString *)pluginName
                         entityName:(NSString*)entityName
                             dbType:(AwareDBType) dbType;
- (BOOL) startAllSensorsWithSettings:(NSArray *)settings;
- (BOOL) stopAndRemoveAllSensors;
@end

@interface AWAREPlugin : AWARESensor <AWAREPluginDelegate, UIAlertViewDelegate> 

@property (strong, nonatomic) IBOutlet NSString* pluginName;
@property (strong, nonatomic) IBOutlet NSString* deviceId;

/**
 * Init
 */
// - (instancetype) initWithPluginName:(NSString *)pluginName awareStudy:(AWAREStudy *) study;
// - (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType;
- (instancetype) initWithAwareStudy:(AWAREStudy *)study
                         pluginName:(NSString *)pluginName
                         entityName:(NSString*)entityName
                             dbType:(AwareDBType) dbType;

- (NSString *) getDeviceId ;

/**
 * Add new AWARE Sensor
 */
- (void) addAnAwareSensor:(AWARESensor *) sensor ;


///**
// * Stop and Remove an AWARE sensor
// */
//- (void) stopAndRemoveAnAwareSensor:(NSString *) sensorName;

/**
 * Start All sensors
 */
//- (BOOL)startAllSensors:(double)upInterval withSettings:(NSArray *)settings;
- (BOOL) startAllSensorsWithSettings:(NSArray *)settings;

/**
 * Stop and remove all sensors
 */
- (BOOL)stopAndRemoveAllSensors;


//- (BOOL) startSensor:(double)upInterval withSettings:(NSArray *)settings;
- (BOOL) startSensorWithSettings:(NSArray *)settings;

- (BOOL) stopSensor;

- (NSArray * ) getSensors;

@end
