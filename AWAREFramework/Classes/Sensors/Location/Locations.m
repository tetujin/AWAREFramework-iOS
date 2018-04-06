//
//  Locations.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Locations.h"
#import "EntityLocation.h"


NSString * const AWARE_PREFERENCES_STATUS_LOCATION_GPS = @"status_location_gps";
NSString * const AWARE_PREFERENCES_FREQUENCY_GPS = @"frequency_gps";
NSString * const AWARE_PREFERENCES_MIN_GPS_ACCURACY = @"min_gps_accuracy";

@implementation Locations{
    NSTimer *locationTimer;
    IBOutlet CLLocationManager *locationManager;
    double interval;
    double accuracy;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"locations"];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp", @"device_id", @"double_latitude", @"double_longitude", @"double_bearing", @"double_speed", @"double_altitude", @"provider", @"accuracy", @"label"];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:@"locations" withHeader:header];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:@"locations" entityName:NSStringFromClass([EntityLocation class])
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
        interval = 180; // 180sec(=3min)
        accuracy = 250; // 250m
    }
    return self;
}


- (void) createTable{
    // Send a query for creating table
    if([self isDebug]){
        NSLog(@"[%@] Create Table", [self getSensorName]);
    }
    NSString *query = [[NSString alloc] init];
    query =
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
        // "UNIQUE (timestamp,device_id)";
//    [super createTable:query];
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void)setParameters:(NSArray *)parameters{
    double frequency = [self getSensorSetting:parameters withKey:@"frequency_gps"];
    if(frequency != -1){
        interval = frequency;
    }
    
    // Get a min gps accuracy from settings
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

- (BOOL)startSensorWithInterval:(double)interval accuracy:(double)accuracyMeter{
    // Set and start a location sensor with the senseing frequency and min GPS accuracy
    if ([self isDebug]) {
        NSLog(@"[%@] Start Location Sensor!", [self getSensorName]);
    }
    
    if (nil == locationManager){
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        
        // extern const CLLocationAccuracy kCLLocationAccuracyBestForNavigation
        // extern const CLLocationAccuracy kCLLocationAccuracyBest;
        // extern const CLLocationAccuracy kCLLocationAccuracyNearestTenMeters;
        // extern const CLLocationAccuracy kCLLocationAccuracyHundredMeters;
        // extern const CLLocationAccuracy kCLLocationAccuracyKilometer;
        // extern const CLLocationAccuracy kCLLocationAccuracyThreeKilometers;
        /*
         if (accuracyMeter == 0) {
         locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
         } else if (accuracyMeter > 0 && accuracyMeter <= 5){
         locationManager.desiredAccuracy = kCLLocationAccuracyBest;
         } else if (accuracyMeter > 10 && accuracyMeter <= 25 ){
         locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
         } else if (accuracyMeter > 25 && accuracyMeter <= 100 ){
         locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
         } else if (accuracyMeter > 100 && accuracyMeter <= 1000){
         locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
         } else if (accuracyMeter > 1000 && accuracyMeter <= 3000){
         locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
         } else {
         locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
         }
         */
        
        if (accuracyMeter == 0) {
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        } else if (accuracyMeter <= 5){
            locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        } else if (accuracyMeter <= 25 ){
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        } else if (accuracyMeter <= 100 ){
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        } else if (accuracyMeter <= 1000){
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        } else if (accuracyMeter <= 3000){
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        } else {
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        }

        
        locationManager.pausesLocationUpdatesAutomatically = NO;
        CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        // NSLog(@"OS:%f", currentVersion);
        if (currentVersion >= 9.0) {
            //This variable is an important method for background sensing after iOS9
            locationManager.allowsBackgroundLocationUpdates = YES;
        }
        
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager requestAlwaysAuthorization];
        }
        
        /**
         * Check an authorization of location sensor
         * https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/#//apple_ref/c/tdef/CLAuthorizationStatus
         */
        [self saveAuthorizationStatus:[CLLocationManager authorizationStatus]];
        
//        if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined ){
//            [self saveDebugEventWithText:@":Location sensor's authorization is not determined" type:DebugTypeWarn label:@""];
//        }else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ){
//            [self saveDebugEventWithText:@"Location sensor's authorization is restrcted" type:DebugTypeWarn label:@""];
//        }else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ){
//            [self saveDebugEventWithText:@"Location sensor's authorization is denied" type:DebugTypeWarn label:@""];
//        }else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized ){
//            [self saveDebugEventWithText:@"Location sensor's authorization is authorized (always)" type:DebugTypeWarn label:@""];
//        }else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways){
//            [self saveDebugEventWithText:@"Location sensor's authorization is authorized always" type:DebugTypeWarn label:@""];
//        }else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse){
//            [self saveDebugEventWithText:@"Location sensor's authorization is authorized when in use" type:DebugTypeWarn label:@""];
//        }else {
//            [self saveDebugEventWithText:@"Location sensor's authorization is unknown" type:DebugTypeWarn label:@""];
//        }
        
        
        // Set a movement threshold for new events.
        locationManager.distanceFilter = accuracyMeter; // meter
        // locationManager.activityType = CLActivityTypeFitness;
        
        // Start Monitoring
        // [locationManager startMonitoringSignificantLocationChanges];
        
        // [locationManager startUpdatingLocation];
        // [locationManager startUpdatingHeading];
        // [_locationManager startMonitoringVisits];
        
        [self getGpsData:nil];
        
        if(interval > 0){
            locationTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                             target:self
                                                           selector:@selector(getGpsData:)
                                                           userInfo:nil
                                                            repeats:YES];
            [self getGpsData:nil];
        }else{
            [locationManager startUpdatingLocation];
        }
        
    }
    return YES;
}


- (BOOL)stopSensor{
    // Stop a sensing timer
    [locationTimer invalidate];
    locationTimer = nil;
    
    // Stop location sensors
    [locationManager stopUpdatingHeading];
    [locationManager stopUpdatingLocation];
    locationManager = nil;
    
    return YES;
}


///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////


- (void) getGpsData: (NSTimer *) theTimer {
    //[sdManager addLocation:[_locationManager location]];
    CLLocation* location = [locationManager location];
    [self saveLocation:location];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    for (CLLocation* location in locations) {
        [self saveLocation:location];
    }
}

- (void) saveLocation:(CLLocation *)location{

    double accuracy = (location.verticalAccuracy + location.horizontalAccuracy) / 2;
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"double_latitude"];
    [dict setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"double_longitude"];
    [dict setObject:[NSNumber numberWithDouble:location.course] forKey:@"double_bearing"];
    [dict setObject:[NSNumber numberWithDouble:location.speed] forKey:@"double_speed"];
    [dict setObject:[NSNumber numberWithDouble:location.altitude] forKey:@"double_altitude"];
    [dict setObject:@"gps" forKey:@"provider"];
    [dict setObject:@(accuracy) forKey:@"accuracy"];
    [dict setObject:@"" forKey:@"label"];
    [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f", location.coordinate.latitude, location.coordinate.longitude, location.speed]];
    [self setLatestData:dict];
    
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
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



//- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//    if (newHeading.headingAccuracy < 0)
//        return;
////    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
////                                       newHeading.trueHeading : newHeading.magneticHeading);
////    [sdManager addSensorDataMagx:newHeading.x magy:newHeading.y magz:newHeading.z];
////    [sdManager addHeading: theHeading];
//}



- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self saveAuthorizationStatus:status];
}



- (void) saveAuthorizationStatus:(CLAuthorizationStatus ) status {
    if(status == kCLAuthorizationStatusNotDetermined ){
//        [self saveDebugEventWithText:@"Location sensor's authorization is not determined" type:DebugTypeWarn label:@""];
        
        //        NSString * title = @"Location Sensor Error";
        //        NSString * message = @"Please allow to use location sensor on AWARE client iOS from 'Settings > AWARE > Location> Always'";
        //        [self saveDebugEventWithText:@"Location sensor's authorization is restrcted" type:DebugTypeWarn label:@""];
        //        if([AWAREUtils isBackground]){
        //            [AWAREUtils sendLocalNotificationForMessage:message title:title soundFlag:YES
        //                                               category:nil fireDate:[NSDate new] repeatInterval:0 userInfo:nil iconBadgeNumber:1];
        //        }else{
        //            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
        //                                                                message:message
        //                                                               delegate:nil
        //                                                      cancelButtonTitle:@"OK"
        //                                                      otherButtonTitles:nil];
        //            [alertView show];
        //        }
        ////////////////// kCLAuthorizationStatusRestricted ///////////////////////
    }else if (status == kCLAuthorizationStatusRestricted ){
//        NSString * title = @"Location Sensor Error";
//        NSString * message = @"Please allow to use location sensor on AWARE client iOS from 'Settings > AWARE > Location> Always'";
        // [self saveDebugEventWithText:@"Location sensor's authorization is restrcted" type:DebugTypeWarn label:@""];
        if([AWAREUtils isBackground]){
            // [AWAREUtils sendLocalNotificationForMessage:message title:title soundFlag:NO
            //                                     category:nil fireDate:[NSDate new] repeatInterval:0 userInfo:nil iconBadgeNumber:1];
        }else{
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
//                                                                message:message
//                                                               delegate:nil
//                                                      cancelButtonTitle:@"Close"
//                                                      otherButtonTitles:nil];
//            [alertView show];
        }
        ///////////////// kCLAuthorizationStatusDenied //////////////////////////////
    }else if (status == kCLAuthorizationStatusDenied ){
        
//        NSString * title = @"Location Sensor Error";
//        NSString * message = @"Please turn on the location service from 'Settings > General > Privacy > Location Services'";
        // [self saveDebugEventWithText:@"Location sensor's authorization is denied" type:DebugTypeWarn label:@""];
        if([AWAREUtils isBackground]){
//            [AWAREUtils sendLocalNotificationForMessage:message title:title soundFlag:NO
//                                               category:nil fireDate:[NSDate new] repeatInterval:0 userInfo:nil iconBadgeNumber:1];
        }else{
            // UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
            // [alertView show];
        }
        //////////////////// kCLAuthorizationStatusAuthorized /////////////////////////
    }else if (status == kCLAuthorizationStatusAuthorizedAlways){
        // [ self saveDebugEventWithText:@"Location sensor's authorization is authorized always" type:DebugTypeWarn label:@""];
        //        NSString * title = @"Location Sensor";
        //        NSString * message = @"Location service setting is correct! Thank you for your cooperation";
        //        if([AWAREUtils isBackground]){
        //            [AWAREUtils sendLocalNotificationForMessage:message title:title soundFlag:YES
        //                                               category:nil fireDate:[NSDate new] repeatInterval:0 userInfo:nil iconBadgeNumber:1];
        //        }else{
        //            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //             [alertView show];
        //        }
        
        /////////////////// kCLAuthorizationStatusAuthorizedWhenInUse ///////////////////
    }else if (status == kCLAuthorizationStatusAuthorizedWhenInUse){
        // [self saveDebugEventWithText:@"Location sensor's authorization is authorized when in use" type:DebugTypeWarn label:@""];
//        NSString * title = @"Location Sensor Error";
//        NSString * message = @"Please allow to use location sensor 'Always' on AWARE client iOS from 'Settings > AWARE > Location> Always'";
        // [self saveDebugEventWithText:@"Location sensor's authorization is denied" type:DebugTypeWarn label:@""];
        if([AWAREUtils isBackground]){
//            [AWAREUtils sendLocalNotificationForMessage:message title:title soundFlag:NO
//                                               category:nil fireDate:[NSDate new] repeatInterval:0 userInfo:nil iconBadgeNumber:1];
        }else{
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
//                                                                message:message
//                                                               delegate:nil
//                                                      cancelButtonTitle:@"Close"
//                                                      otherButtonTitles:nil];
//            [alertView show];
        }
        
        //////////////////// Unknown ///////////////////////////////
    }else {
        // [self saveDebugEventWithText:@"Location sensor's authorization is unknown" type:DebugTypeWarn label:@""];
    }
}


@end
