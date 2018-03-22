//
//  Observer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/6/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "Observer.h"
#import "AWAREUtils.h"
#import "AWAREDelegate.h"

@implementation Observer{
    AWAREStudy * awareStudy;
    NSString* KEY_TIMESTAMP;
    NSString* KEY_DEVICE_ID;
    NSString* KEY_LABEL;
}

-(instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:@"aware_observer"
                        dbEntityName:nil
                              dbType:AwareDBTypeTextFile];
    if(self != nil){
        awareStudy = study;
        KEY_TIMESTAMP = @"timestamp";
        KEY_DEVICE_ID = @"device_id";
        KEY_LABEL = @"label";
        
        [self setCSVHeader:@[KEY_TIMESTAMP, KEY_DEVICE_ID]];
    }
    return self;
}

-(void)createTable{
    NSMutableString *query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendFormat:@"%@ real default 0,", KEY_TIMESTAMP];
    [query appendFormat:@"%@ text default '',", KEY_DEVICE_ID];
    [query appendFormat:@"%@ text default ''", KEY_LABEL];
//    [query appendFormat:@"UNIQUE (timestamp,device_id)"];
    [self createTable:query];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    return YES;
}

- (BOOL) stopSensor{
    return YES;
}


//////////////////////////////////////////
//////////////////////////////////////////

- (bool)sendSurvivalSignal{
    return [self sendSurvivalSignalWithLabel:@""];
}

- (bool) sendSurvivalSignalWithCategory:(NSString *)category message:(NSString *)message{
    NSString * label = [NSString stringWithFormat:@"{\"category\":\"%@\",\"message\":\"%@\"}", category, message];
    NSLog(@"%@", label);
    return [self sendSurvivalSignalWithLabel:label];
}

- (bool)sendSurvivalSignalWithLabel:(NSString *) label{
    if(label == nil){
        label = @"";
    }
    
    // Make a survial signal
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_TIMESTAMP];
    [dic setObject:[self getDeviceId] forKey:KEY_DEVICE_ID];
    [dic setObject:label forKey:KEY_LABEL];
    
    // Convert the query to JSON format string
    NSMutableArray * array = [[NSMutableArray alloc] init];
    [array addObject:dic];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array
                                                       options:0// Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString *jsonString = @"";
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    // Make a HTTP/POST body
    NSString *post = [NSString stringWithFormat:@"device_id=%@&data=%@", [self getDeviceId], jsonString];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    
    // Make a HTTP/POST header
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[self getInsertUrl:[self getSensorName]]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    // Set a HTTP/POST session
    __weak NSURLSession *session = nil;
    // session = [NSURLSession sharedSession];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.allowsCellularAccess = YES;
    session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:Nil];
    
    
    [[session dataTaskWithRequest: request  completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
        [session finishTasksAndInvalidate];
        [session invalidateAndCancel];
        
        if ([self isDebug]) {
            if (response && ! error) {
                NSString *responseString = [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding];
                NSLog(@"Success: %@", responseString);
                [self sendLocalNotificationForMessage:@"[Success] Send a survival signal." soundFlag:NO];
                [self saveDebugEventWithText:@"ping is succeed" type:DebugTypeInfo label:@""];
            }else{
                [self sendLocalNotificationForMessage:@"[Fail] Send a survival signal" soundFlag:NO];
                [self saveDebugEventWithText:@"ping is failed" type:DebugTypeInfo label:@""];
            }
        }
    }] resume];
    return YES;
}

- (bool)sendComplianceState{
    
    // o"internet":true,
    // o "wifi":true,
    // o"network":true,
    // o "location_gps":true,
    // o "location_network":false
    // "airplane":false,
    // "roaming":false,
    // "bt":true,
    
    // sensors' permission:
    //  o location
    //  - picture
    //  o wifi
    //  - bluetooth
    //  o network
    //  - keyboard
    //  - contact
    //  - calendar
    //  - microphone
    //  - healthkit
    //  - music
    //  - motion
    //  - homekit
    //  - speech
    //  - reminder
    
    // device setting:
    //  o low power mode
    //  o background reresh
    //  o notification
    //  - storage
    
    AWAREDelegate * delegate = (AWAREDelegate *)[UIApplication sharedApplication].delegate;
    bool wifi = [delegate.sharedAWARECore checkWifiStateWithViewController:nil];
    bool location = [delegate.sharedAWARECore checkLocationSensorWithViewController:nil];
    bool notification = [delegate.sharedAWARECore checkNotificationSettingWithViewController:nil];
    bool lowPower = [delegate.sharedAWARECore checkLowPowerModeWithViewController:nil];
    bool backgroundRefresh = [delegate.sharedAWARECore checkBackgroundAppRefreshWithViewController:nil];
    bool network = [awareStudy isNetworkReachable];
    
    if(lowPower){
        lowPower = NO;
    }else{
        lowPower = YES;
    }
    
    NSDictionary * dict = [[NSDictionary alloc] initWithObjects:@[@(network),@(wifi),@(location),@(location),@(network),@(notification),@(backgroundRefresh)]
                                                        forKeys:@[@"internet",@"wifi",@"location_gps",@"location_network",@"network",@"notification",@"background_refresh"]];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:0// Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString *jsonString = @"";
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    [self sendSurvivalSignalWithLabel:jsonString];
    
    return YES;
}

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler{
    
    // http://stackoverflow.com/questions/19507207/how-do-i-accept-a-self-signed-ssl-certificate-using-ios-7s-nsurlsession-and-its
    
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
        SecTrustRef trust = [protectionSpace serverTrust];
        NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    }
}



@end
