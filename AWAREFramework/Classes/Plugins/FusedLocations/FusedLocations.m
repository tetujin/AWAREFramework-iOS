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


NSString * const AWARE_PREFERENCES_STATUS_GOOGLE_FUSED_LOCATION  = @"status_google_fused_location";
NSString * const AWARE_PREFERENCES_ACCURACY_GOOGLE_FUSED_LOCATION  = @"accuracy_google_fused_location";
NSString * const AWARE_PREFERENCES_FREQUENCY_GOOGLE_FUSED_LOCATION  = @"frequency_google_fused_location";

@implementation FusedLocations {
    NSTimer *locationTimer;
    IBOutlet CLLocationManager *locationManager;
    
    Locations * locationSensor;
    VisitLocations * visitLocationSensor;
    AWAREStudy * awareStudy;
    
    CLLocation * previousLocation;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_GOOGLE_FUSED_LOCATION
                        dbEntityName:NSStringFromClass([EntityLocation class])
                              dbType:dbType];
    awareStudy = study;
    if (self) {
        // Make a fused location sensor
        locationSensor = [[Locations alloc] initWithAwareStudy:awareStudy dbType:dbType];
        
        // Make a visit location sensor
        visitLocationSensor = [[VisitLocations alloc] initWithAwareStudy:awareStudy dbType:dbType];
        _intervalSec = 180;
        _accuracyMeter = 100;
        
        [self setTypeAsPlugin];
        
        [self addDefaultSettingWithBool:@NO key:AWARE_PREFERENCES_STATUS_GOOGLE_FUSED_LOCATION desc:@"true or false to activate or deactivate accelerometer sensor."];
        [self addDefaultSettingWithNumber:@0 key:AWARE_PREFERENCES_FREQUENCY_GOOGLE_FUSED_LOCATION desc:@"How frequently to fetch user's location (in seconds.)"];
        [self addDefaultSettingWithNumber:@102 key:AWARE_PREFERENCES_ACCURACY_GOOGLE_FUSED_LOCATION desc:@"One of the following numbers: 100 (high power): uses GPS only - works best outdoors, highest accuracy 102 (balanced): uses GPS, Network and Wifi - works both indoors and outdoors, good accuracy 104 (low power): uses only Network and WiFi - poorest accuracy, medium accuracy 105 (no power) - scavenges location requests from other apps."];
    }
    return self;
}

- (void)createTable{
    // Send a table create query
    [locationSensor createTable];
    
    //////////////////////////
    // Send a table create query
    [visitLocationSensor createTable];
}

- (void)setParameters:(NSArray *)parameters{
    // Get a sensing frequency for a location sensor
    double frequency = [self getSensorSetting:parameters withKey:@"frequency_google_fused_location"];
    if(frequency > 0){
        NSLog(@"Location sensing requency is %f ", frequency);
        _intervalSec = frequency;
    }
    int accuracyType = [self getSensorSetting:parameters withKey:@"accuracy_google_fused_location"];

    if(accuracyType == 100){
        _accuracy = kCLLocationAccuracyBest;
        _accuracyMeter = 0;
    }else if (accuracyType == 101) { // High accuracy
        _accuracy = kCLLocationAccuracyNearestTenMeters;
        _accuracyMeter = 10;
    } else if (accuracyType == 102) { //balanced
        _accuracy = kCLLocationAccuracyHundredMeters;
        _accuracyMeter = 100;
    } else if (accuracyType == 104) { //low power
        _accuracy = kCLLocationAccuracyKilometer;
        _accuracyMeter = 1000;
    } else if (accuracyType == 105) { //no power
        _accuracy = kCLLocationAccuracyThreeKilometers;
        _accuracyMeter = 3000;
    } else {
        _accuracy = kCLLocationAccuracyHundredMeters;
        _accuracyMeter = 100;
    }
}

-(BOOL)startSensor{
    return [self startSensorWithInterval:_intervalSec accuracy:_accuracy distanceFilter:_accuracyMeter];
}

- (BOOL) startSensorWithInterval:(double)intervalSecond
                        accuracy:(CLLocationAccuracy)accuracy
                  distanceFilter:(int)fiterMeter{
    // Initialize a location sensor
    if (locationManager == nil){
        // AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        locationManager = [[CLLocationManager alloc] init];
        // Get a sensing accuracy for a location sensor
        
        // One of the following numbers: 100 (High accuracy); 102 (balanced); 104 (low power); 105 (no power, listens to others location requests)
        // http://stackoverflow.com/questions/3411629/decoding-the-cllocationaccuracy-consts
        //    GPS - kCLLocationAccuracyBestForNavigation;
        //    GPS - kCLLocationAccuracyBest;
        //    GPS - kCLLocationAccuracyNearestTenMeters;
        //    WiFi (or GPS in rural area) - kCLLocationAccuracyHundredMeters;
        //    Cell Tower - kCLLocationAccuracyKilometer;
        //    Cell Tower - kCLLocationAccuracyThreeKilometers;
        locationManager.delegate = self;
        locationManager.desiredAccuracy = accuracy;
        locationManager.pausesLocationUpdatesAutomatically = NO;
        if ([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0) {
            //This variable is an important method for background sensing after iOS9
            locationManager.allowsBackgroundLocationUpdates = YES;
        }
        locationManager.activityType = CLActivityTypeOther;
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager requestAlwaysAuthorization];
        }
        
        locationManager.distanceFilter = fiterMeter;
        
        [locationSensor saveAuthorizationStatus:[CLLocationManager authorizationStatus]];
        
        // Set a movement threshold for new events.
        [locationManager startMonitoringVisits]; // This method calls didVisit.
        [locationManager startMonitoringSignificantLocationChanges];
        [locationManager startUpdatingLocation];
        
        if(intervalSecond > 0){
            locationTimer = [NSTimer scheduledTimerWithTimeInterval:intervalSecond
                                                             target:self
                                                           selector:@selector(getGpsData:)
                                                           userInfo:nil
                                                            repeats:YES];
            return YES;
        }
    }
    return NO;
}


- (BOOL)stopSensor{
    if (locationManager != nil) {
        [locationManager stopUpdatingHeading];
        [locationManager stopUpdatingLocation];
        [locationManager stopMonitoringVisits];
    }
    
    if (locationTimer != nil) {
        [locationTimer invalidate];
        locationTimer = nil;
    }
    
    locationManager = nil;
    
    return YES;
}

- (void) syncAwareDB {
    [visitLocationSensor syncAwareDB];
    [locationSensor syncAwareDB];
    [super syncAwareDB];
}

- (BOOL)syncAwareDBInForeground{
    if(![visitLocationSensor syncAwareDBInForeground]){
        return NO;
    }
    
    if(![locationSensor syncAwareDBInForeground]){
        return NO;
    }
    
    if(![super syncAwareDBInForeground]){
        return NO;
    }
    

    
    return YES;
}

- (NSString *) getSyncProgressAsText{
    return [self getSyncProgressAsText:@"locations"];
}


/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////



- (void) getGpsData: (NSTimer *) theTimer {
    if([self isDebug]){
        NSLog(@"Get a location");
    }
    CLLocation* location = [locationManager location];
    [self saveLocation:location];
    
    if(location == nil && previousLocation != nil){
        [self saveLocation:previousLocation];
        // [AWAREUtils sendLocalNotificationForMessage:@"Location data is null!!" soundFlag:YES];
    }
    
    if(location != nil){
        previousLocation = location;
    }
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    for (CLLocation* location in locations) {
        [self saveLocation:location];
    }
}

- (void) saveLocation:(CLLocation *)location{

    // save location data by using location sensor
    int accuracy = (location.verticalAccuracy + location.horizontalAccuracy) / 2;
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"double_latitude"];
    [dict setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"double_longitude"];
    [dict setObject:[NSNumber numberWithDouble:location.course] forKey:@"double_bearing"];
    [dict setObject:[NSNumber numberWithDouble:location.speed] forKey:@"double_speed"];
    [dict setObject:[NSNumber numberWithDouble:location.altitude] forKey:@"double_altitude"];
    [dict setObject:@"fused" forKey:@"provider"];
    [dict setObject:[NSNumber numberWithInt:accuracy] forKey:@"accuracy"];
    [dict setObject:@"" forKey:@"label"];
    [locationSensor saveData:dict];
    [locationSensor setLatestData:dict];
    
    [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",
                          location.coordinate.latitude,
                          location.coordinate.longitude,
                          location.speed]];
    
    if ([self isDebug]) {
        [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"Location: %f, %f, %f",
                                                     location.coordinate.latitude,
                                                     location.coordinate.longitude,
                                                     location.speed]
                                          soundFlag:NO];
    }
}

- (void)locationManager:(CLLocationManager *)manager
               didVisit:(CLVisit *)visit {

    [visitLocationSensor locationManager:manager didVisit:visit];
    
}


- (bool)isUploading:(CLAuthorizationStatus ) state{
    if([locationSensor isUploading] || [visitLocationSensor isUploading]){
        return YES;
    }else{
        return NO;
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


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [locationSensor saveAuthorizationStatus:status];
}


///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

- (void)saveDummyData{
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:@0 forKey:@"double_latitude"];
    [dict setObject:@0 forKey:@"double_longitude"];
    [dict setObject:@0 forKey:@"double_bearing"];
    [dict setObject:@0 forKey:@"double_speed"];
    [dict setObject:@0 forKey:@"double_altitude"];
    [dict setObject:@"fused" forKey:@"provider"];
    [dict setObject:@0 forKey:@"accuracy"];
    [dict setObject:@"dummy" forKey:@"label"];
    [locationSensor saveData:dict];
}


@end
