//
//  FitbitDevice.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/01/21.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "FitbitDevice.h"
#import "Fitbit.h"
#import "EntityFitbitDevice+CoreDataClass.h"

@implementation FitbitDevice{
    NSString * identificationForFitbitDevice;
    NSMutableData * responseData;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"fitbit_device"];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:@"fitbit_device" entityName:NSStringFromClass([EntityFitbitDevice class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            EntityFitbitDevice* entityFitbitDevice = (EntityFitbitDevice *)[NSEntityDescription
                                                                                                            insertNewObjectForEntityForName:entity
                                                                                                            inManagedObjectContext:childContext];
                                            
                                            entityFitbitDevice.timestamp = [data objectForKey:@"timestamp"];
                                            entityFitbitDevice.device_id = [data objectForKey:@"device_id"];
                                            entityFitbitDevice.fitbit_id = [data objectForKey:@"fitbit_id"];
                                            entityFitbitDevice.fitbit_version = [data objectForKey:@"fitbit_version"];
                                            entityFitbitDevice.fitbit_battery = [data objectForKey:@"fitbit_battery"];
                                            entityFitbitDevice.fitbit_mac = [data objectForKey:@"fitbit_mac"];
                                            entityFitbitDevice.fitbit_last_sync = [data objectForKey:@"fitbit_last_sync"];
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:@"fitbit_device"
                             storage:storage];
    if(self != nil){
        identificationForFitbitDevice = @"";
        responseData = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)createTable{
    TCQMaker * tcq = [[TCQMaker alloc] init];
    [tcq addColumn:@"fitbit_id" type:TCQTypeText default:@"''"];
    [tcq addColumn:@"fitbit_version" type:TCQTypeText default:@"''"];
    [tcq addColumn:@"fitbit_battery" type:TCQTypeText default:@"''"];
    [tcq addColumn:@"fitbit_mac" type:TCQTypeText default:@"''"];
    [tcq addColumn:@"fitbit_last_sync" type:TCQTypeText default:@"''"];
    [self.storage createDBTableOnServerWithTCQMaker:tcq];
    // [super createTable:tcq.getDefaudltTableCreateQuery];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    // [self getDeviceInfo];
    
    return YES;
}

- (BOOL)stopSensor{
    return YES;
}


/////////////////////////////////////////////////////////////////////


- (BOOL) getDeviceInfo {
    
    NSString * userId = [Fitbit getFitbitUserId];
    NSString* token = [Fitbit getFitbitAccessToken];
    
    
    /////// create a Fitbit API query ///////////
    //  /1/user/[user-id]/[resource-path]/date/[base-date]/[end-date].json
    NSMutableString * urlStr = [[NSMutableString alloc] initWithString:@"https://api.fitbit.com"];
    [urlStr appendFormat:@"/1/user/%@/devices.json",userId];
    
    NSURL*	url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"GET"];
    
    if(token == nil){
        return NO;
    }
    if(userId == nil){
        return NO;
    }
    
    __weak NSURLSession *session = nil;
    NSURLSessionConfiguration *sessionConfig = nil;
//    identificationForFitbitDevice = [NSString stringWithFormat:@"fitbit.query.device.%f", [[NSDate new] timeIntervalSince1970]];
    identificationForFitbitDevice = [NSString stringWithFormat:@"fitbit.query.device"];
    
    
    if ([AWAREUtils isBackground]) {
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identificationForFitbitDevice];
        sessionConfig.timeoutIntervalForRequest = 180.0;
        sessionConfig.timeoutIntervalForResource = 60.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 60;
        sessionConfig.allowsCellularAccess = YES;
        sessionConfig.allowsCellularAccess = YES;
        sessionConfig.discretionary = YES;
        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:Nil];
        NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
        [dataTask resume];
    }else{
        sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.timeoutIntervalForRequest = 180.0;
        sessionConfig.timeoutIntervalForResource = 60.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 60;
        sessionConfig.allowsCellularAccess = YES;
        sessionConfig.allowsCellularAccess = YES;
        sessionConfig.discretionary = YES;
        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:Nil];
        [[session dataTaskWithRequest:request  completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
            [session finishTasksAndInvalidate];
            [session invalidateAndCancel];
            [self saveData:data response:response error:error];
        }] resume];
    }
    return YES;
}


- (void) saveData:(NSData *) data response:(NSURLResponse *)response error:(NSError *)error{
    NSString *responseString = [[NSString alloc] initWithData:data  encoding: NSUTF8StringEncoding];
    NSLog(@"Success: %@", responseString);
    
    @try {
        if(responseString != nil){
            NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *error = nil;
            NSArray *devices = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingAllowFragments error:&error];
            if (error != nil) {
                NSLog(@"failed to parse JSON: %@", error.debugDescription);
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self isDebug]) {
                    // [self sendLocalNotificationForMessage:@"Fitbit plugin got device data" soundFlag:NO];
                }
            });
            
            if( devices != nil){
                for (NSDictionary * device in devices) {
                    NSString * fitbitId = @"";
                    NSString * fitbitVersion = @"";
                    NSString * fitbitBattery = @"";
                    NSString * fitbitMac = @"";
                    NSString * fitbitLastSync = @"";
                    if([device objectForKey:@"id"] != nil) fitbitId = [device objectForKey:@"id"];
                    if([device objectForKey:@"deviceVersion"] != nil) fitbitVersion = [device objectForKey:@"deviceVersion"];
                    if([device objectForKey:@"battery"] != nil ) fitbitBattery = [device objectForKey:@"battery"] ;
                    if([device objectForKey:@"mac"] != nil) fitbitMac = [device objectForKey:@"mac"];
                    if([device objectForKey:@"lastSyncTime"] != nil) fitbitLastSync = [device objectForKey:@"lastSyncTime"];
                    
                    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
                    [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"]; //timestamp
                    [dict setObject:[self getDeviceId] forKey:@"device_id"];  //    device_id
                    [dict setObject:fitbitId forKey:@"fitbit_id"];
                    [dict setObject:fitbitVersion forKey:@"fitbit_version"];
                    [dict setObject:fitbitBattery forKey:@"fitbit_battery"];
                    [dict setObject:fitbitMac forKey:@"fitbit_mac"];
                    [dict setObject:fitbitLastSync forKey:@"fitbit_last_sync"];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // [self saveData:dict];
                        [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
                    });
                }
            }
        }
    } @catch (NSException *exception) {
        // [Fitbit refreshToken];
    } @finally {
        
    }
}

/////////////////////////////////////////////////////////////////////


- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    completionHandler(NSURLSessionResponseAllow);
    
    NSString * identifier = session.configuration.identifier;
    if([identifier isEqualToString:identificationForFitbitDevice]){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        int responseCode = (int)[httpResponse statusCode];
        if (responseCode == 200) {
            [session finishTasksAndInvalidate];
            NSLog(@"[%d] Success",responseCode);
        }else{
            // clear
            [session invalidateAndCancel];
            NSLog(@"[%d] %@", responseCode, response.debugDescription);
            responseData = [[NSMutableData alloc] init];
        }

    }
    // [super URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    NSString * identifier = session.configuration.identifier;
    if([identifier isEqualToString:identificationForFitbitDevice]){
        [responseData appendData:data];
    }
    // [super URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    NSString * identifier = session.configuration.identifier;
    if ([identifier isEqualToString:identificationForFitbitDevice]) {
        NSData * data = [responseData copy];
        [self saveData:data response:nil error:error];
        responseData = [[NSMutableData alloc] init];
    }
    // [super URLSession:session task:task didCompleteWithError:error];
}

//////////////////////////////////////////////////////////////////////


@end
