//
//  VisitLocations.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "VisitLocations.h"
#import "EntityLocationVisit.h"

@implementation VisitLocations{
    IBOutlet CLLocationManager *locationManager;
}


- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"locations_visit"];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:@"locations_visit" entityName:NSStringFromClass([EntityLocationVisit class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            EntityLocationVisit * visitData = (EntityLocationVisit *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                                                                   inManagedObjectContext:childContext];
                                            
                                            visitData.device_id = [data objectForKey:@"device_id"];
                                            visitData.timestamp = [data objectForKey:@"timestamp"];
                                            visitData.double_latitude = [data objectForKey:@"double_latitude"];
                                            visitData.double_longitude = [data objectForKey:@"double_longitude"];
                                            visitData.provider = [data  objectForKey:@"provider"];
                                            visitData.accuracy = [data objectForKey:@"accuracy"];
                                            visitData.address = [data objectForKey:@"address"];
                                            visitData.name = [data objectForKey:@"name"];
                                            visitData.double_arrival = [data objectForKey:@"double_arrival"];
                                            visitData.double_departure = [data objectForKey:@"double_departure"];
                                            visitData.label = [data objectForKey:@"label"];
                                        }];
    }
    
    self = [self initWithAwareStudy:study
                         sensorName:@"locations_visit"
                            storage:storage];
    if(self != nil){
        // [self setCSVHeader:@[@"timestamp",@"device_id",@"double_latitude",@"double_longitude",@"double_arrival",@"double_departure",@"address",@"name",@"provider",@"accuracy",@"label"]];
    }
    
    return self;
}


- (void)createTable{
    NSString * query =
     @"_id integer primary key autoincrement,"
     "timestamp real default 0,"
     "device_id text default '',"
     "double_latitude real default 0,"
     "double_longitude real default 0,"
     "double_arrival real default 0,"
     "double_departure real default 0,"
     "address text default '',"
     "name text default '',"
     "provider text default '',"
     "accuracy integer default 0,"
    "label text default ''";
    [self.storage createDBTableOnServerWithQuery:query];
     // "UNIQUE (timestamp,device_id)"];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    // Initialize a location sensor
    if (locationManager == nil){
        locationManager = [[CLLocationManager alloc] init];
        
        // One of the following numbers: 100 (High accuracy); 102 (balanced); 104 (low power); 105 (no power, listens to others location requests)
        // http://stackoverflow.com/questions/3411629/decoding-the-cllocationaccuracy-consts
        //    GPS - kCLLocationAccuracyBestForNavigation;
        //    GPS - kCLLocationAccuracyBest;
        //    GPS - kCLLocationAccuracyNearestTenMeters;
        //    WiFi (or GPS in rural area) - kCLLocationAccuracyHundredMeters;
        //    Cell Tower - kCLLocationAccuracyKilometer;
        //    Cell Tower - kCLLocationAccuracyThreeKilometers;
        
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        locationManager.pausesLocationUpdatesAutomatically = NO;
        if ([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0) {
            //This variable is an important method for background sensing after iOS9
            locationManager.allowsBackgroundLocationUpdates = YES;
        }
        locationManager.activityType = CLActivityTypeOther;
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager requestAlwaysAuthorization];
        }
        // Set a movement threshold for new events.
        [locationManager startMonitoringVisits]; // This method calls didVisit.
    }
    return YES;
}

- (BOOL)stopSensor{
    if (locationManager != nil) {
        [locationManager stopMonitoringVisits];
    }
    return YES;
}

///////////////////////////

- (void)locationManager:(CLLocationManager *)manager
               didVisit:(CLVisit *)visit {
    
    CLGeocoder *ceo = [[CLGeocoder alloc]init];
    CLLocation *loc = [[CLLocation alloc]initWithLatitude:visit.coordinate.latitude longitude:visit.coordinate.longitude]; //insert your coordinates
    [ceo reverseGeocodeLocation:loc
              completionHandler:^(NSArray *placemarks, NSError *error) {
                  CLPlacemark * placemark = nil;
                  NSString * name = @"";
                  NSString * address = @"";
                  if (placemarks.count > 0) {
                      placemark = [placemarks objectAtIndex:0];
                      address = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
                      [self setLatestValue:address];
                      NSString* visitMsg = [NSString stringWithFormat:@"I am currently at %@", address];
                      // Set name
                      if (placemark.name != nil) {
                          //[visitDic setObject:placemark.name forKey:@"name"];
                          name = placemark.name;
                          if ([self isDebug]) {
                              NSLog( @"%@", visitMsg );
                              [AWAREUtils sendLocalNotificationForMessage:visitMsg soundFlag:YES];
                          }
                      }
                  }
                  
                  NSNumber * timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
                  NSNumber * depature = [AWAREUtils getUnixTimestamp:[visit departureDate]];
                  NSNumber * arrival = [AWAREUtils getUnixTimestamp:[visit arrivalDate]];
                  
                  /*
                   *  arrivalDate
                   *
                   *  Discussion:
                   *    The date when the visit began.  This may be equal to [NSDate
                   *    distantPast] if the true arrival date isn't available.
                   */
                  if([[visit departureDate] isEqualToDate:[NSDate distantPast]]){
                      arrival = @-1;
                      //                      [self sendLocalNotificationForMessage:[NSString stringWithFormat:@"departure date is %@",[NSDate distantPast]] soundFlag:NO];
                  }
                  
                  /*
                   *  departureDate
                   *
                   *  Discussion:
                   *    The date when the visit ended.  This is equal to [NSDate
                   *    distantFuture] if the device hasn't yet left.
                   */
                  
                  if([[visit arrivalDate] isEqualToDate:[NSDate distantFuture]]){
                      depature = @-1;
                      //                      [self sendLocalNotificationForMessage:[NSString stringWithFormat:@"departure date is %@",[NSDate distantFuture]] soundFlag:NO];
                  }
                  
                  dispatch_async(dispatch_get_main_queue(), ^{
                      NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
                      [dict setObject:[self getDeviceId] forKey:@"device_id"];
                      [dict setObject:timestamp forKey:@"timestamp"];
                      [dict setObject:@(visit.coordinate.latitude) forKey:@"double_latitude"];
                      [dict setObject:@(visit.coordinate.longitude) forKey:@"double_longitude"];// = [NSNumber numberWithDouble:];
                      [dict setObject:@"" forKey:@"provider"]; //visitData.provider = @"fused";
                      [dict setObject:@(visit.horizontalAccuracy) forKey:@"accuracy"];// visitData.accuracy = [NSNumber numberWithInt:visit.horizontalAccuracy];
                      [dict setObject:address forKey:@"address"];// visitData.address = address;
                      [dict setObject:name forKey:@"name"]; //forKey:(nonnull id<NSCopying>]visitData.name = name;
                      [dict setObject:arrival forKey:@"double_arrival"];//visitData.double_arrival = arrival;
                      [dict setObject:depature forKey:@"double_departure"]; // visitData.double_departure = depature;
                      [dict setObject:@"" forKey:@"label"]; //visitData.label = @"";
                      
                      // [self saveData:dict];
                      [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
                      [self setLatestData:dict];
                      
                  });
                  return;
              }];
}



@end
