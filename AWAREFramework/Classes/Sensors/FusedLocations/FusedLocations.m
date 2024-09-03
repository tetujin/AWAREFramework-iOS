//
//  FusedLocations.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/18/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
#import "FusedLocations.h"
#import "Locations.h"
#import "EntityLocation.h"

NSString * const AWARE_PREFERENCES_STATUS_GOOGLE_FUSED_LOCATION    = @"status_google_fused_location";
NSString * const AWARE_PREFERENCES_ACCURACY_GOOGLE_FUSED_LOCATION  = @"accuracy_google_fused_location";
NSString * const AWARE_PREFERENCES_FREQUENCY_GOOGLE_FUSED_LOCATION = @"frequency_google_fused_location";

NSString * const AWARE_PREFERENCES_RELATIVE_LOCATION_GOOGLE_FUSED_LOCATION = @"relative_location_google_fused_location";

NSString * const AWARE_PREFERENCES_RELATIVE_LOCATION_LATLON_GOOGLE_FUSED_LOCATION = @"relative_location_latlon_google_fused_location";

@implementation FusedLocations {
    NSTimer           * locationTimer;
    CLLocationManager * locationManager;
    CLLocation        * previousLocation;
    bool needRelativeLocation;
    CLLocation        * referenceLocation;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    _locationSensor = [[Locations alloc] initWithAwareStudy:study dbType:dbType];
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_GOOGLE_FUSED_LOCATION
                             storage:_locationSensor.storage];
    if (self) {
        _saveAll             = NO;
        _intervalSec         = 180;
        _distanceFilter      = kCLDistanceFilterNone;
        _accuracy            = kCLLocationAccuracyHundredMeters;
    }
    
    needRelativeLocation = [self needRelativeLocation];
    
    return self;
}

- (void)createTable{
    /// carete a database table on a remote server
    [_locationSensor createTable];
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
    
    needRelativeLocation = [self needRelativeLocation];
    if (needRelativeLocation) {
        referenceLocation = [self getReferencePointForRelativeLocation];
    }
    
    /// Set a movement threshold for new events.
    // [locationManager startMonitoringVisits]; // This method calls didVisit.
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
        // [locationManager stopMonitoringVisits];
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
    
    [self setSensingState:NO];
    
    return YES;
}

- (void) startSyncDB{
    [_locationSensor startSyncDB];
    // [super startSyncDB];
}

- (void)stopSyncDB{
    [_locationSensor stopSyncDB];
    // [super stopSyncDB];
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
    if (self.label != nil) {
        [dict setObject:self.label forKey:@"label"];
    }else{
        [dict setObject:@"" forKey:@"label"];
    }
    
    NSString * latestData = [NSString stringWithFormat:@"%f, %f, %f",
                             location.coordinate.latitude,
                             location.coordinate.longitude,
                             location.speed];
    
    if (needRelativeLocation){
        if (referenceLocation == nil) {
            if (location.coordinate.latitude != 0 && location.coordinate.longitude != 0) {
                [self setReferencePointForRelativeLocation:location];
                referenceLocation = [self getReferencePointForRelativeLocation];
            }else{
                return;
            }
        }
        
        double relativeLat = referenceLocation.coordinate.latitude  - location.coordinate.latitude;
        double relativeLon = referenceLocation.coordinate.longitude - location.coordinate.longitude;
        double relativeAlt = referenceLocation.altitude - location.altitude;
        // NSLog(@"%f, %f, %f", relativeLat, relativeLon, relativeAlt);
        
        [dict setObject:@(relativeLat) forKey:@"double_latitude"];
        [dict setObject:@(relativeLon) forKey:@"double_longitude"];
        [dict setObject:@(relativeAlt) forKey:@"double_altitude"];
        
        latestData = [NSString stringWithFormat:@"%f, %f, %f",
                                 relativeLat,
                                 relativeLon,
                                 location.speed];
    }
    
    [_locationSensor.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:NO];
    [_locationSensor setLatestData:dict];
    
    [self setLatestValue:latestData];
    if ([self isDebug]) NSLog(@"[locations] %@", latestData);
    
    
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, dict);
    }
}

- (void)locationManager:(CLLocationManager *)manager
               didVisit:(CLVisit *)visit {
}

- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        if (locationManager != nil) {
            [locationManager startUpdatingLocation];
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


- (void)disableRelativeLocation {
    needRelativeLocation = false;
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:false forKey:AWARE_PREFERENCES_RELATIVE_LOCATION_GOOGLE_FUSED_LOCATION];
    [defaults synchronize];
}

- (void)enableRelativeLocation {
    needRelativeLocation = true;
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:true forKey:AWARE_PREFERENCES_RELATIVE_LOCATION_GOOGLE_FUSED_LOCATION];
    [defaults synchronize];
}

- (bool)needRelativeLocation {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey: AWARE_PREFERENCES_RELATIVE_LOCATION_GOOGLE_FUSED_LOCATION];
}

- (void)setReferencePointForRelativeLocation:(CLLocation *) location {
    if (location != nil) {
        double lat = location.coordinate.latitude;
        double lon = location.coordinate.longitude;
        double alt = location.altitude;
        NSDictionary * refLocationAsDict = [[NSDictionary alloc] initWithObjects:@[@(lat),@(lon), @(alt), @(1)]
                                                                         forKeys:@[@"lat", @"lon", @"alt", @"version"]];
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:refLocationAsDict
                     forKey:AWARE_PREFERENCES_RELATIVE_LOCATION_LATLON_GOOGLE_FUSED_LOCATION];
        [defaults synchronize];
    }
}

- (CLLocation *) getReferencePointForRelativeLocation{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary<NSString *,id> * refLocationAsDict = [defaults dictionaryForKey:AWARE_PREFERENCES_RELATIVE_LOCATION_LATLON_GOOGLE_FUSED_LOCATION];
    if (refLocationAsDict != nil) {
        NSNumber * lat = [refLocationAsDict objectForKey:@"lat"];
        NSNumber * lon = [refLocationAsDict objectForKey:@"lon"];
        NSNumber * alt = [refLocationAsDict objectForKey:@"alt"];
        if (lat != nil && lon != nil && alt != nil) {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat.doubleValue, lon.doubleValue);
            CLLocation * location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                                  altitude:alt.doubleValue
                                                        horizontalAccuracy:0
                                                          verticalAccuracy:0
                                                                 timestamp:[NSDate date]];
            return location;
        }
    }
    return nil;
}

@end
