//
//  FusedLocations.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/18/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
#import "FusedLocations.h"
#import "Locations.h"
#import "VisitLocations.h"
#import "EntityLocation.h"
#import "EntityLocationVisit.h"

NSString * const AWARE_PREFERENCES_STATUS_GOOGLE_FUSED_LOCATION    = @"status_google_fused_location";
NSString * const AWARE_PREFERENCES_ACCURACY_GOOGLE_FUSED_LOCATION  = @"accuracy_google_fused_location";
NSString * const AWARE_PREFERENCES_FREQUENCY_GOOGLE_FUSED_LOCATION = @"frequency_google_fused_location";

@implementation FusedLocations {
    NSTimer           * locationTimer;
    CLLocationManager * locationManager;
    CLLocation        * previousLocation;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    _locationSensor = [[Locations alloc] initWithAwareStudy:study dbType:dbType];
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_GOOGLE_FUSED_LOCATION
                             storage:_locationSensor.storage];
    if (self) {
        _visitLocationSensor = [[VisitLocations alloc] initWithAwareStudy:study dbType:dbType];
        _saveAll             = NO;
        _intervalSec         = 180;
        _distanceFilter      = kCLDistanceFilterNone;
        _accuracy            = kCLLocationAccuracyHundredMeters;
    }
    return self;
}

- (void)createTable{
    /// carete a database table on a remote server
    [_locationSensor createTable];
    /// create a database table on a remote server
    [_visitLocationSensor createTable];
}

- (void)setParameters:(NSArray *)parameters{
    /// Get a sensing frequency for a location sensor
    double frequency = [self getSensorSetting:parameters withKey:@"frequency_google_fused_location"];
    if(frequency > 0){
        _intervalSec = frequency;
    }
    int accuracyType = [self getSensorSetting:parameters withKey:@"accuracy_google_fused_location"];
    
    /// 100 (High accuracy); 102 (balanced); 104 (low power); 105 (no power, listens to others location requests)
    if(accuracyType == 100){
        _accuracy = kCLLocationAccuracyBest;
    }else if (accuracyType == 101) { // High accuracy
        _accuracy = kCLLocationAccuracyNearestTenMeters;
    } else if (accuracyType == 102) { //balanced
        _accuracy = kCLLocationAccuracyHundredMeters;
    } else if (accuracyType == 104) { //low power
        _accuracy = kCLLocationAccuracyKilometer;
    } else if (accuracyType == 105) { //no power
        _accuracy = kCLLocationAccuracyThreeKilometers;
    } else {
        _accuracy = kCLLocationAccuracyHundredMeters;
    }
}

-(BOOL)startSensor{
    return [self startSensorWithInterval:_intervalSec];
}

- (BOOL)startSensorWithInterval:(double)intervalSecond{
    return [self startSensorWithInterval:intervalSecond accuracy:_accuracy];
}

- (BOOL)startSensorWithInterval:(double)intervalSecond accuracy:(CLLocationAccuracy)accuracy{
    return [self startSensorWithInterval:intervalSecond accuracy:accuracy distanceFilter:_distanceFilter];
}

- (BOOL) startSensorWithInterval:(double)intervalSecond
                        accuracy:(CLLocationAccuracy)accuracy
                  distanceFilter:(int)distanceFilter{
    if (locationManager != nil){
        [self stopSensor];
    }
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = accuracy;
    locationManager.distanceFilter  = distanceFilter;
    locationManager.pausesLocationUpdatesAutomatically = NO;
    locationManager.allowsBackgroundLocationUpdates    = YES;
    locationManager.activityType = CLActivityTypeOther;
    
    if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [locationManager requestAlwaysAuthorization];
    }
    
    /// Set a movement threshold for new events.
    [locationManager startMonitoringVisits]; // This method calls didVisit.
    [locationManager startUpdatingLocation];
    
    if(intervalSecond > 0){
        locationTimer = [NSTimer scheduledTimerWithTimeInterval:intervalSecond
                                                         target:self
                                                       selector:@selector(getGpsData:)
                                                       userInfo:nil
                                                        repeats:YES];
        return YES;
    }
    return NO;
}


- (BOOL)stopSensor{
    if (locationManager != nil) {
        [locationManager stopUpdatingLocation];
        [locationManager stopMonitoringVisits];
    }
    
    if (locationTimer != nil) {
        [locationTimer invalidate];
        locationTimer = nil;
    }
    
    locationManager = nil;
    
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    if (self.locationSensor.storage != nil) {
        [self.locationSensor.storage saveBufferDataInMainThread:YES];
    }
    if (self.visitLocationSensor.storage != nil) {
        [self.visitLocationSensor.storage saveBufferDataInMainThread:YES];
    }
    
    [self setSensingState:NO];
    
    return YES;
}

- (void) startSyncDB{
    [_visitLocationSensor startSyncDB];
    [_locationSensor startSyncDB];
    [super startSyncDB];
}

- (void)stopSyncDB{
    [_visitLocationSensor stopSyncDB];
    [_locationSensor stopSyncDB];
    [super stopSyncDB];
}

- (void) getGpsData: (NSTimer *) theTimer {
    if([self isDebug]){
        NSLog(@"Get a location");
    }
    
    if (previousLocation != nil) {
        CLLocation* location = [locationManager location];
        [self saveLocation:location];
        if (location != nil) {
            previousLocation = location;
        }
    }else{
        [self saveLocation:previousLocation];
    }
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    for (CLLocation* location in locations) {
        previousLocation = location;
        if (_intervalSec <= 0 || _saveAll) {
            [self saveLocation:location];
        }
    }
}

- (void) saveLocation:(CLLocation *)location{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:@(location.coordinate.latitude) forKey:@"double_latitude"];
    [dict setObject:@(location.coordinate.longitude) forKey:@"double_longitude"];
    [dict setObject:@(location.course) forKey:@"double_bearing"];
    [dict setObject:@(location.speed) forKey:@"double_speed"];
    [dict setObject:@(location.altitude) forKey:@"double_altitude"];
    [dict setObject:@"fused" forKey:@"provider"];
    [dict setObject:@(location.horizontalAccuracy) forKey:@"accuracy"];
    [dict setObject:@"" forKey:@"label"];
    [_locationSensor.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:NO];
    [_locationSensor setLatestData:dict];
    
    [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",
                          location.coordinate.latitude,
                          location.coordinate.longitude,
                          location.speed]];
    
    if ([self isDebug]) {
        NSLog(@"[locations] %f, %f, %f",location.coordinate.latitude,location.coordinate.longitude,location.speed);
    }
    
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, dict);
    }
}

- (void)locationManager:(CLLocationManager *)manager
               didVisit:(CLVisit *)visit {
    
    [_visitLocationSensor locationManager:manager didVisit:visit];
    
}

- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        if (locationManager != nil) {
            [locationManager startUpdatingLocation];
            [locationManager startMonitoringVisits];
        }
    }
}


//- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//    if (newHeading.headingAccuracy < 0)
//        return;
//    //    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
//    //                                       newHeading.trueHeading : newHeading.magneticHeading);
//    //    [sdManager addSensorDataMagx:newHeading.x magy:newHeading.y magz:newHeading.z];
//    //    [sdManager addHeading: theHeading];
//}


@end
