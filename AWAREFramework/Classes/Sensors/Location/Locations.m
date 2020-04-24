//
//  Locations.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Locations.h"
#import "EntityLocation.h"
#import "AWAREEventLogger.h"


NSString * const AWARE_PREFERENCES_STATUS_LOCATION_GPS = @"status_location_gps";
NSString * const AWARE_PREFERENCES_FREQUENCY_GPS       = @"frequency_gps";
NSString * const AWARE_PREFERENCES_MIN_GPS_ACCURACY    = @"min_gps_accuracy";

@implementation Locations{
    NSTimer * locationTimer;
    double interval;
    double accuracy;
}

@synthesize locationManager = locationManager;

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    _saveAll = NO;
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"locations"];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp", @"device_id", @"double_latitude",
                             @"double_longitude", @"double_bearing", @"double_speed",
                             @"double_altitude", @"provider", @"accuracy", @"label"];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeText),@(CSVTypeReal),@(CSVTypeText)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:@"locations" headerLabels:header headerTypes:headerTypes];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study
                                            sensorName:@"locations"
                                            entityName:NSStringFromClass([EntityLocation class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            EntityLocation* entityLocation = (EntityLocation *)[NSEntityDescription
                                                                                                insertNewObjectForEntityForName:entity
                                                                                                inManagedObjectContext:childContext];
                                            
                                            entityLocation.device_id = [data objectForKey:@"device_id"];
                                            entityLocation.timestamp = [data objectForKey:@"timestamp"];
                                            entityLocation.double_latitude = [data objectForKey:@"double_latitude"];
                                            entityLocation.double_longitude = [data objectForKey:@"double_longitude"];
                                            entityLocation.double_bearing = [data objectForKey:@"double_bearing"];
                                            entityLocation.double_speed = [data objectForKey:@"double_speed"];
                                            entityLocation.double_altitude = [data objectForKey:@"double_altitude"];
                                            entityLocation.provider = [data objectForKey:@"provider"];
                                            entityLocation.accuracy = [data objectForKey:@"accuracy"];
                                            entityLocation.label = [data objectForKey:@"label"];
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:@"locations"
                             storage:storage];
    if (self) {
        interval = 180; /// 180sec(=3min)
        accuracy = 250; /// 250m
    }
    return self;
}


- (void) createTable{
    if([self isDebug]){
        NSLog(@"[%@] Create Table", [self getSensorName]);
    }
    NSString *query =
        @"_id integer primary key autoincrement,"
        "timestamp real default 0,"
        "device_id text default '',"
        "double_latitude real default 0,"
        "double_longitude real default 0,"
        "double_bearing real default 0,"
        "double_speed real default 0,"
        "double_altitude real default 0,"
        "provider text default '',"
        "accuracy real default 0,"
        "label text default ''";
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void)setParameters:(NSArray *)parameters{
    double frequency = [self getSensorSetting:parameters withKey:@"frequency_gps"];
    if(frequency != -1){
        interval = frequency;
    }
    
    /// Get a min gps accuracy from settings
    double minAccuracy = [self getSensorSetting:parameters withKey:@"min_gps_accuracy"];
    if ( minAccuracy > 0 ) {
        accuracy = minAccuracy;
    }
}

- (BOOL)startSensor{
    return [self startSensorWithInterval:interval accuracy:accuracy];
}

- (BOOL)startSensorWithInterval:(double)interval{
    return [self startSensorWithInterval:interval accuracy:accuracy];
}

- (BOOL)startSensorWithAccuracy:(double)accuracyMeter{
    return [self startSensorWithInterval:interval accuracy:accuracyMeter];
}

/// Start a location sensor with the senseing frequency and min GPS accuracy
- (BOOL)startSensorWithInterval:(double)interval accuracy:(double)accuracyMeter{
    if ([self isDebug]) {
        NSLog(@"[%@] Start Location Sensor!", [self getSensorName]);
    }
    
    self->interval = interval;
    self->accuracy = accuracyMeter;
    
    if (nil != locationManager){
        [self stopSensor];
    }

    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    
    if (accuracyMeter >= 3000) {
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    } else if (accuracyMeter >= 1000){
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    } else if (accuracyMeter >= 100 ){
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    } else if (accuracyMeter >= 10  ) {
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    } else if (accuracyMeter >= 5   ) {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    } else if (accuracyMeter == 0   ) {
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    } else {
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    }
    
    /// Set a movement threshold for new events.
    locationManager.distanceFilter = accuracyMeter; // meter
    
    locationManager.pausesLocationUpdatesAutomatically = NO;
    CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (currentVersion >= 9.0) {
        locationManager.allowsBackgroundLocationUpdates = YES;
    }
    
    if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [locationManager requestAlwaysAuthorization];
    }
    
    [self saveAuthorizationStatus:[CLLocationManager authorizationStatus]];
    
    /// set ActivityType
    // locationManager.activityType = CLActivityTypeFitness;
    
    /// start Monitoring
    [locationManager startMonitoringSignificantLocationChanges];
    
    [locationManager startUpdatingLocation];
    
    if(self->interval > 0){
        locationTimer = [NSTimer scheduledTimerWithTimeInterval:self->interval
                                                         target:self
                                                       selector:@selector(getGpsData:)
                                                       userInfo:nil
                                                        repeats:YES];
        [self getGpsData:nil];
    }
    
    [self setSensingState:YES];
    return YES;
}


- (BOOL)stopSensor{
    /// stop a sensing timer
    [locationTimer invalidate];
    locationTimer = nil;
    
    /// stop location sensors
    [locationManager stopUpdatingLocation];
    locationManager = nil;
    
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    
    [self setSensingState:NO];
    
    return YES;
}

- (void) getGpsData: (NSTimer *) theTimer {
    if (_lastLocation != nil) {
        [self saveLocation:_lastLocation];
    }else{
        _lastLocation = [locationManager location];
        if (_lastLocation != nil) {
            [self saveLocation:_lastLocation];
        }
    }
}

- (void) locationManager:(CLLocationManager *)manager
      didUpdateLocations:(NSArray<CLLocation *> *)locations{
    if (locations != nil) {
        for (CLLocation* location in locations) {
            _lastLocation = location;
            /// If the interval value is less than or equal to 0, all of the location data will be saved.
            if (self->interval <= 0 || _saveAll) {
                [self saveLocation:location];
            }
        }
    }
}

- (void) saveLocation:(CLLocation * _Nonnull)location{
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:@(location.coordinate.latitude)  forKey:@"double_latitude"];
    [dict setObject:@(location.coordinate.longitude) forKey:@"double_longitude"];
    [dict setObject:@(location.course) forKey:@"double_bearing"];
    [dict setObject:@(location.speed) forKey:@"double_speed"];
    [dict setObject:@(location.altitude) forKey:@"double_altitude"];
    [dict setObject:@"gps" forKey:@"provider"];
    [dict setObject:@(location.horizontalAccuracy) forKey:@"accuracy"];
    [dict setObject:@"" forKey:@"label"];
    
    [self setLatestData:dict];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:NO];

    [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",
                          location.coordinate.latitude,
                          location.coordinate.longitude,
                          location.speed]];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                         forKey:EXTRA_DATA];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_LOCATIONS
                                                        object:nil
                                                      userInfo:userInfo];
    
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, dict);
    }
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self saveAuthorizationStatus:status];
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        if (locationManager != nil) {
            [locationManager startUpdatingLocation];
        }
    }else{
        NSLog(@"[%@] Location API is not allowed to access this app in the background condition.", self.getSensorName);
    }
}

- (void) saveAuthorizationStatus:(CLAuthorizationStatus ) status {
    [AWAREEventLogger.shared logEvent:@{@"class":@"Locations",
                                        @"event":@"saveAuthorizationStatus",@"status":@(status)}];
}

@end
