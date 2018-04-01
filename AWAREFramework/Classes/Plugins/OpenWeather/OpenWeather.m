//
//  WeatherData.m
//  VQR
//
//  Created by Yuuki Nishiyama on 2014/12/02.
//  Copyright (c) 2014年 tetujin. All rights reserved.
//

#import "OpenWeather.h"
#import "AWAREKeys.h"
#import "EntityOpenWeather.h"
#import "AWAREDelegate.h"


NSString * const AWARE_PREFERENCES_STATUS_OPENWEATHER    = @"status_plugin_openweather_frequency";
NSString * const AWARE_PREFERENCES_OPENWEATHER_FREQUENCY = @"plugin_openweather_frequency";
NSString * const AWARE_PREFERENCES_OPENWEATHER_API_KEY   = @"api_key_plugin_openweather";

@implementation OpenWeather{
    IBOutlet CLLocationManager *locationManager;
    NSTimer* sensingTimer;
    NSDictionary* jsonWeatherData;
    NSDate* thisDate;
    double thisLat;
    double thisLon;
    NSString* identificationForOpenWeather;
    // NSString * userApiKey;
    NSMutableData * receivedData;
}

/** api */
NSString* OPEN_WEATHER_API_URL = @"http://api.openweathermap.org/data/2.5/weather?lat=%d&lon=%d&APPID=%@";
NSString* OPEN_WEATHER_API_DEFAULT_KEY = @"54e5dee2e6a2479e0cc963cf20f233cc";
/** sys */
NSString* KEY_SYS         = @"sys";
NSString* ELE_COUNTORY    = @"country";
NSString* ELE_SUNSET      = @"sunset";
NSString* ELE_SUNRISE      = @"sunrise";

/** weather */
NSString* KEY_WEATHER     = @"weather";
NSString* ELE_MAIN        = @"main";
NSString* ELE_DESCRIPTION = @"description";
NSString* ELE_ICON        = @"icon";

/** main */
NSString* KEY_MAIN        = @"main";
NSString* ELE_TEMP        = @"temp";
NSString* ELE_TEMP_MAX    = @"temp_max";
NSString* ELE_TEMP_MIN    = @"temp_min";
NSString* ELE_HUMIDITY    = @"humidity";
NSString* ELE_PRESSURE    = @"pressure";
/** wind */
NSString* KEY_WIND        = @"wind";
NSString* ELE_SPEED       = @"speed";
NSString* ELE_DEG         = @"deg";
/** rain */
NSString* KEY_RAIN        = @"rain";
NSString* KEY_SNOW        = @"snow";
NSString* ELE_3H          = @"3h";
/** clouds */
NSString* KEY_CLOUDS      = @"clouds";
NSString* ELE_ALL         = @"all";
/** city */
NSString* KEY_NAME        = @"name";

NSString* ZERO            = @"0";
    
int ONE_HOUR = 60*60;


- (instancetype) initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_OPEN_WEATHER];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_PLUGIN_OPEN_WEATHER entityName:NSStringFromClass([EntityOpenWeather class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            
                                            EntityOpenWeather * weatherData = (EntityOpenWeather *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                                                                 inManagedObjectContext:childContext];
                                            
                                            weatherData.device_id =         [data objectForKey:@"device_id"];
                                            weatherData.timestamp =         [data objectForKey:@"timestamp"];
                                            weatherData.city =              [data objectForKey:@"city"];
                                            weatherData.temperature =       [data objectForKey:@"temperature"];
                                            weatherData.temperature_max =   [data objectForKey:@"temperature_max"];
                                            weatherData.temperature_min =   [data objectForKey:@"temperature_min"];
                                            weatherData.unit =              [data objectForKey:@"unit"];
                                            weatherData.humidity =          [data objectForKey:@"humidity"];
                                            weatherData.pressure =          [data objectForKey:@"pressure"];
                                            weatherData.wind_speed =        [data objectForKey:@"wind_speed"];
                                            weatherData.wind_degrees =      [data objectForKey:@"wind_degrees"];
                                            weatherData.cloudiness =        [data objectForKey:@"cloudiness"];
                                            weatherData.weather_icon_id =   [data objectForKey:@"weather_icon_id"];
                                            weatherData.weather_description=[data objectForKey:@"weather_description"];
                                            weatherData.rain =              [data objectForKey:@"rain"];
                                            weatherData.snow =              [data objectForKey:@"snow"];
                                            weatherData.sunrise =           [data objectForKey:@"sunrise"];
                                            weatherData.sunset =            [data objectForKey:@"sunset"];
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_OPEN_WEATHER
                             storage:storage];
    if (self) {
        locationManager = nil;
        receivedData = [[NSMutableData alloc] init];
        identificationForOpenWeather = @"http_for_open_weather_";
//        [self setCSVHeader:@[@"timestamp",
//                             @"device_id",
//                             @"city",
//                             @"temperature",
//                             @"temperature_max",
//                             @"temperature_min",
//                             @"unit",
//                             @"humidity",
//                             @"pressure",
//                             @"wind_speed",
//                             @"wind_degrees",
//                             @"cloudiness",
//                             @"rain",
//                             @"snow",
//                             @"sunrise",
//                             @"sunset",
//                             @"weather_icon_id",
//                             @"weather_description"
//                             ]];
        [self updateWeatherData:[NSDate new] Lat:0 Lon:0];
        _apiKey = nil;
        _frequencyMin = 15;
        
//        [self setTypeAsPlugin];
//        [self addDefaultSettingWithBool:@NO key:AWARE_PREFERENCES_STATUS_OPENWEATHER desc:@"(boolean) to activate / deactivate the plugin."];
//        [self addDefaultSettingWithNumber:@15 key:AWARE_PREFERENCES_OPENWEATHER_FREQUENCY desc:@"weather check interval in minutes."];
//        [self addDefaultSettingWithString:@"54e5dee2e6a2479e0cc963cf20f233cc" key:AWARE_PREFERENCES_OPENWEATHER_API_KEY desc:@" get a valid key at http://openweathermap.org/"];
        
    }
    return self;
}


- (void) createTable{
    if ([self isDebug]) {
        NSLog(@"Create a table of OpenWeather Map Plugin");
    }
    NSString *query = [[NSString alloc] init];
    query =
    @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "city text default '',"
    "temperature real default 0,"
    "temperature_max real default 0,"
    "temperature_min real default 0,"
    "unit text default '',"
    "humidity real default 0,"
    "pressure real default 0,"
    "wind_speed real default 0,"
    "wind_degrees real default 0,"
    "cloudiness real default 0,"
    "rain real default 0,"
    "snow real default 0,"
    "sunrise real default 0,"
    "sunset real default 0,"
    "weather_icon_id int default 0,"
    "weather_description text default ''";
    //"UNIQUE (timestamp,device_id)";
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void)setParameters:(NSArray *)parameters{
    if(parameters != nil){
        double min = [self getSensorSetting:parameters withKey:@"plugin_openweather_frequency"];
        if (min > 0) {
            _frequencyMin = min;
        }
        for (NSDictionary * param in parameters) {
            if ([[param objectForKey:@"setting"] isEqualToString:@"api_key_plugin_openweather"]) {
                _apiKey = [param objectForKey:@"value"];
            }
        }
    }
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    
    AWAREDelegate *delegate=(AWAREDelegate*)[UIApplication sharedApplication].delegate;
    AWARECore * core = delegate.sharedAWARECore;
    locationManager = core.sharedLocationManager;
    
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:_frequencyMin * 60
                                                    target:self
                                                  selector:@selector(getNewWeatherData)
                                                  userInfo:nil
                                                   repeats:YES];
    [self getNewWeatherData];
    return YES;
}

- (BOOL)stopSensor{
    // stop a sensing timer
    [sensingTimer invalidate];
    sensingTimer = nil;
    
    return YES;
}


/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////



- (void) getNewWeatherData {
    if (locationManager != nil) {
        CLLocation* location = [locationManager location];
        NSDate *now = [NSDate new];
        [self updateWeatherData:now
                            Lat:location.coordinate.latitude
                            Lon:location.coordinate.longitude];
    }
}

- (void)updateWeatherData:(NSDate *)date Lat:(double)lat Lon:(double)lon
{
    thisDate = date;
    thisLat = lat;
    thisLon = lon;
    if( lat !=0  &&  lon != 0){
        [self getWeatherJSONStr:lat lon:lon];
    }
}

- (void) getWeatherJSONStr:(double)lat
                             lon:(double)lon{
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
    NSString *postLength = nil;
    
    // Set settion configu and HTTP/POST body.
    NSURLSessionConfiguration *sessionConfig = nil;
    
    identificationForOpenWeather = [NSString stringWithFormat:@"%@", identificationForOpenWeather];//@%f", identificationForOpenWeather, [[NSDate new] timeIntervalSince1970]];
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identificationForOpenWeather];
    sessionConfig.timeoutIntervalForRequest = 180.0;
    sessionConfig.timeoutIntervalForResource = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60;
    sessionConfig.allowsCellularAccess = YES;
    sessionConfig.discretionary = YES;
    
    NSString *url = @"";
    if(_apiKey == nil){
        url = [NSString stringWithFormat:OPEN_WEATHER_API_URL, (int)lat, (int)lon, OPEN_WEATHER_API_DEFAULT_KEY];
    }else{
        url = [NSString stringWithFormat:OPEN_WEATHER_API_URL, (int)lat, (int)lon, _apiKey];
    }

    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    // set HTTP/POST body information
    if([self isDebug]){
        NSLog(@"--- [%@] This is background task ----", [self getSensorName] );
    }
    session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];

}



- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    completionHandler(NSURLSessionResponseAllow);
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    if (responseCode == 200) {
        [session finishTasksAndInvalidate];
        if([self isDebug]){
            NSLog(@"[%@] Got Weather Information from API!", [self getSensorName]);
        }
    }else{
        [session invalidateAndCancel];
        receivedData = [[NSMutableData alloc] init];
    }

//    [super URLSession:session
//             dataTask:dataTask
//   didReceiveResponse:response
//    completionHandler:completionHandler];
    
//    [session finishTasksAndInvalidate];
//    [session invalidateAndCancel];
//    completionHandler(NSURLSessionResponseAllow);
}


-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    if(data != nil){
        [receivedData appendData:data];
    }
    // [super URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    
    if (receivedData != nil){
        NSError * e = nil;
        jsonWeatherData = [NSJSONSerialization JSONObjectWithData:receivedData
                                                          options:NSJSONReadingAllowFragments
                                                            error:&e];
        
        if ( jsonWeatherData == nil) {
            if ([self isDebug]) {
                NSLog( @"%@", e.debugDescription );
                // [self sendLocalNotificationForMessage:e.debugDescription soundFlag:NO];
            }
            return;
        }
        
        if ([self isDebug]) {
            // [self sendLocalNotificationForMessage:@"Get Weather Information" soundFlag:NO];
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
            [dict setObject:unixtime forKey:@"timestamp"];
            [dict setObject:[self getDeviceId] forKey:@"device_id"];
            [dict setObject:[self getName] forKey:@"city"];
            [dict setObject:[self getTemp] forKey:@"temperature"];
            [dict setObject:[self getTempMax] forKey:@"temperature_max"];
            [dict setObject:[self getTempMax] forKey:@"temperature_min"];
            [dict setObject:@"" forKey:@"unit"];
            [dict setObject:[self getHumidity] forKey:@"humidity"];
            [dict setObject:[self getPressure] forKey:@"pressure"];
            [dict setObject:[self getWindSpeed] forKey:@"wind_speed"];
            [dict setObject:[self getWindDeg] forKey:@"wind_degrees"];
            [dict setObject:[self getClouds] forKey:@"cloudiness"];
            [dict setObject:[self getWeatherIcon] forKey:@"weather_icon_id"];
            [dict setObject:[self getWeatherDescription] forKey:@"weather_description"];
            [dict setObject:[self getRain] forKey:@"rain"];
            [dict setObject:[self getSnow] forKey:@"snow"];
            [dict setObject:[self getSunRise] forKey:@"sunrise"];
            [dict setObject:[self getSunSet] forKey:@"sunset"];
            
            [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
            [self setLatestData:dict];
            
            SensorEventCallBack callback = [self getSensorEventCallBack];
            if (callback!=nil) {
                callback(dict);
            }
        });
    }
}


//
//- (void)URLSession:(NSURLSession *)session
//              task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
//    [session finishTasksAndInvalidate];
//    [session invalidateAndCancel];
//    
//    
//}
//
//- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
//    if (error != nil) {
//        if([self isDebug]){
//            NSLog(@"[%@] the session did become invaild with error: %@", [self getSensorName], error.debugDescription);
//        }
//    }
//    [session invalidateAndCancel];
//    [session finishTasksAndInvalidate];
//}



- (NSString *) getCountry
{
    NSString* value = [[jsonWeatherData valueForKey:KEY_SYS] valueForKey:ELE_COUNTORY];
    if(value != nil){
        return value;
    }else{
        return @"0";
    }
}

- (NSString *) getWeather
{
    NSString *value = [[[jsonWeatherData valueForKey:KEY_WEATHER] objectAtIndex:0] valueForKey:ELE_MAIN];
    if (value != nil) {
        return value;
    }else{
        return @"0";
    }
}


- (NSNumber *) getWeatherIcon
{
    NSNumber * value  = @0;
    @try {
        if(value != nil){
            value =  @([[[[jsonWeatherData valueForKey:KEY_WEATHER] objectAtIndex:0] valueForKey:ELE_ICON] integerValue]);
        }
    } @catch (NSException *exception) {
        value = @0;
    }
    return value;
}

- (NSString *) getWeatherDescription
{
    NSString * value= [[[jsonWeatherData valueForKey:KEY_WEATHER] objectAtIndex:0] valueForKey:ELE_DESCRIPTION];
    if(value != nil){
        return  value;
    }else{
        return @"0";
    }
}

- (NSNumber *) getTemp
{
   // NSLog(@"--> %@", [self convertKelToCel:[[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP]]);
    double temp = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_TEMP] doubleValue];
    return [NSNumber numberWithDouble:temp];
}

- (NSNumber *) getTempMax
{
    double maxTemp = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_TEMP_MAX] doubleValue];
    return [NSNumber numberWithDouble:maxTemp];
//    return [self convertKelToCel:[[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP_MAX]];
}

- (NSNumber *) getTempMin
{
    double minTemp = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_TEMP_MIN] doubleValue];
    return [NSNumber numberWithDouble:minTemp];
//    return [self convertKelToCel:[[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP_MIN]];
}

- (NSNumber *) getHumidity
{
    //NSLog(@"--> %@",  [[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_HUMIDITY]);
    double humidity = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_HUMIDITY] doubleValue];
    return [NSNumber numberWithDouble:humidity];
//    return [[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_HUMIDITY];
}

- (NSNumber *) getPressure
{
    double pressure = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_PRESSURE] doubleValue];
    return [NSNumber numberWithDouble:pressure];
//    return [[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_PRESSURE];
}

- (NSNumber *) getWindSpeed
{
    double windSpeed = [[[jsonWeatherData valueForKey:KEY_WIND] objectForKey:ELE_SPEED] doubleValue];
    return [NSNumber numberWithDouble:windSpeed];
//    return [[jsonWeatherData valueForKey:KEY_WIND] valueForKey:ELE_SPEED];
}

- (NSNumber *) getWindDeg
{
    double windDeg = [[[jsonWeatherData valueForKey:KEY_WIND] objectForKey:ELE_DEG] doubleValue];
    return [NSNumber numberWithDouble:windDeg];
//    return [[jsonWeatherData valueForKey:KEY_WIND] valueForKey:ELE_DEG];
}

- (NSNumber *) getRain
{
    double rain =  [[[jsonWeatherData valueForKey:KEY_RAIN] objectForKey:ELE_3H] doubleValue];
    return [NSNumber numberWithDouble:rain];
//    return [[jsonWeatherData valueForKey:KEY_RAIN] valueForKey:ELE_3H];
}

- (NSNumber *) getSnow
{
    double snow =  [[[jsonWeatherData valueForKey:KEY_SNOW] objectForKey:ELE_3H] doubleValue];
    return [NSNumber numberWithDouble:snow];
//    return [[jsonWeatherData valueForKey:KEY_RAIN] valueForKey:ELE_3H];
}

- (NSNumber *) getClouds
{
    double cloudiness = [[[jsonWeatherData valueForKey:KEY_CLOUDS] objectForKey:ELE_ALL] doubleValue];
    return [NSNumber numberWithDouble:cloudiness];
//    return [[jsonWeatherData valueForKey:KEY_CLOUDS] valueForKey:ELE_ALL];
}


- (NSNumber *) getSunRise
{
    double value = [[[jsonWeatherData valueForKey:KEY_SYS] valueForKey:ELE_SUNRISE] doubleValue];
    return [NSNumber numberWithDouble:value];
}

- (NSNumber *) getSunSet
{
    double value = [[[jsonWeatherData valueForKey:KEY_SYS] valueForKey:ELE_SUNSET] doubleValue];
    return [NSNumber numberWithDouble:value];
}


- (NSString *) getName
{
    NSString * cityName = [jsonWeatherData valueForKey:KEY_NAME];
    if (cityName == nil) {
        cityName = @"";
    }
    return cityName;
}

- (NSString *) convertKelToCel:(NSString *) kelStr
{
    //return kelStr;
    if(kelStr != nil){
        float kel = kelStr.floatValue;
        return [NSString stringWithFormat:@"%f",(kel-273.15)];
    }else{
        return nil;
    }
}

- (bool) isNotNil
{
    if(jsonWeatherData==nil){
        return false;
    }else{
        return true;
    }
}

- (bool) isNil
{
    if(jsonWeatherData==nil){
        return true;
    }else{
        return false;
    }
}

- (bool) isOld:(int)gap
{
    NSDate *now = [NSDate date];
    NSTimeInterval delta = [now timeIntervalSinceDate:thisDate];
    if(delta > gap){
        return true;
    }else{
        return false;
    }
}

- (NSString *)description
{
    return [jsonWeatherData description];
}


///////////////////////////////////////////
-  (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
  completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                              NSURLCredential * _Nullable credential)) completionHandler{
    // http://stackoverflow.com/questions/19507207/how-do-i-accept-a-self-signed-ssl-certificate-using-ios-7s-nsurlsession-and-its
    
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        
        NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
        SecTrustRef trust = [protectionSpace serverTrust];
        NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
        
        // NSArray *certs = [[NSArray alloc] initWithObjects:(id)[[self class] sslCertificate], nil];
        // int err = SecTrustSetAnchorCertificates(trust, (CFArrayRef)certs);
        // SecTrustResultType trustResult = 0;
        // if (err == noErr) {
        //    err = SecTrustEvaluate(trust, &trustResult);
        // }
        
        // if ([challenge.protectionSpace.host isEqualToString:@"aware.ht.sfc.keio.ac.jp"]) {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // } else if ([challenge.protectionSpace.host isEqualToString:@"r2d2.hcii.cs.cmu.edu"]) {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // } else if ([challenge.protectionSpace.host isEqualToString:@"api.awareframework.com"]) {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // } else {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // }
        
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    }
}


@end
