//
//  FitbitData.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/01/21.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "FitbitData.h"
#import "Fitbit.h"
#import "EntityFitbitData+CoreDataClass.h"

@implementation FitbitData{
    NSString * identificationForFitbitData;
    NSDateFormatter *dateFormat;
    NSDateFormatter *timeFormat;
    NSMutableData * sleepResponse;
    NSMutableData * stepsResponse;
    NSMutableData * caloriesResponse;
    NSMutableData * heartResponse;
    
    NSDate * sleepLastSyncTime;
    NSDate * stepsLastSyncTime;
    NSDate * caloriesSyncTime;
    NSDate * heartrateSyncTime;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"fitbit_data"];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:@"fitbit_data" entityName:NSStringFromClass([EntityFitbitData class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            EntityFitbitData * entityFitbitData = (EntityFitbitData *)[NSEntityDescription
                                                                                                       insertNewObjectForEntityForName:entity
                                                                                                       inManagedObjectContext:childContext];
                                            entityFitbitData.device_id = [self getDeviceId];
                                            entityFitbitData.timestamp = [data objectForKey:@"timestamp"];
                                            entityFitbitData.device_id = [data objectForKey:@"device_id"];
                                            entityFitbitData.fitbit_data = [data objectForKey:@"fitbit_data"];
                                            entityFitbitData.fitbit_data_type = [data objectForKey:@"fitbit_data_type"];
                                            entityFitbitData.fitbit_id = [data objectForKey:@"fitbit_id"];
                                        }];
    }
    self = [super initWithAwareStudy:study
                          sensorName:@"fitbit_data"
            storage:storage];
    if(self != nil){
        identificationForFitbitData = @"";
        
        dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd"];
        
        timeFormat = [[NSDateFormatter alloc] init];
        [timeFormat setDateFormat:@"HH:mm"];
        
        sleepResponse = [[NSMutableData alloc] init];
        stepsResponse = [[NSMutableData alloc] init];
        caloriesResponse = [[NSMutableData alloc] init];
        heartResponse = [[NSMutableData alloc] init];
    }
    return self;
}


- (void)createTable{
    
    TCQMaker * tcq = [[TCQMaker alloc] init];
    [tcq addColumn:@"fitbit_id" type:TCQTypeText default:@"''"];
    [tcq addColumn:@"fitbit_data_type" type:TCQTypeText default:@"''"];
    [tcq addColumn:@"fitbit_data" type:TCQTypeText default:@"''"];
    [self.storage createDBTableOnServerWithTCQMaker:tcq];
    // [super createTable:tcq.getDefaudltTableCreateQuery];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    return YES;
}

- (BOOL)stopSensor{
    return YES;
}


//////////////////////////////////////////////////////

+ (NSDate *) getLastSyncSteps{
    return [FitbitData getLastQueryDateWithKey:@"steps"];
}

+ (NSDate *) getLastSyncCalories{
    return [FitbitData getLastQueryDateWithKey:@"calories"];
}

+ (NSDate *) getLastSyncHeartrate{
    return [FitbitData getLastQueryDateWithKey:@"heartrate"];
}

+ (NSDate *) getLastSyncSleep{
    return [FitbitData getLastQueryDateWithKey:@"sleep"];
}

////////////////////////////////////////////////////
+ (void) setLastSyncSteps:(NSDate *)date{
    [FitbitData setLastQueryDate:date withKey:@"steps"];
}

+ (void) setLastSyncCalories:(NSDate *)date{
    [FitbitData setLastQueryDate:date withKey:@"calories"];
}

+ (void) setLastSyncHeartrate:(NSDate *)date{
    [FitbitData setLastQueryDate:date withKey:@"heartrate"];
}

+ (void) setLastSyncSleep:(NSDate *)date{
    [FitbitData setLastQueryDate:date withKey:@"sleep"];
}

//////////////////////////////////////////////////

- (void) getCaloriesWithStart:(NSDate*)start
                       end:(NSDate *)end
                    period:(NSString *)period
               detailLevel:(NSString *)detailLevel{
    caloriesSyncTime = end;
    // start = [self getLastQueryDateWithKey:@"calories"];
    [self getActivityWithDataType:@"calories"
                     ResourcePath:@"activities/calories"
                            start:start
                              end:end
                           period:nil
                      detailLevel:detailLevel];
}

- (void) getStepsWithStart:(NSDate*)start
                       end:(NSDate *)end
                    period:(NSString *)period
               detailLevel:(NSString *)detailLevel{
    
    stepsLastSyncTime = end;

    // activities-steps, activities-calories, activities-heartrate,sleep-efficie
    // start = [self getLastQueryDateWithKey:@"steps"];
    [self getActivityWithDataType:@"steps"
                     ResourcePath:@"activities/steps"
                            start:start
                              end:end
                           period:nil
                      detailLevel:detailLevel];
}

- (void) getHeartrateWithStart:(NSDate*)start
                           end:(NSDate *)end
                        period:(NSString *)period
                   detailLevel:(NSString *)detailLevel{
    ///////////////////////////////////////////////
    heartrateSyncTime = end;
    // start = [self getLastQueryDateWithKey:@"heartrate"];
    [self getActivityWithDataType:@"heartrate"
                     ResourcePath:@"activities/heart"
                            start:start
                              end:end
                           period:nil //@"15min"
                      detailLevel:detailLevel];
}

- (void) getSleepWithStart:(NSDate*)start
                       end:(NSDate *)end
                    period:(NSString *)period
               detailLevel:(NSString *)detailLevel{
    sleepLastSyncTime = end;
//    start = [self getLastQueryDateWithKey:@"sleep"];
    [self getActivityWithDataType:@"sleep"
                     ResourcePath:@"sleep/efficiency"
                            start:start
                              end:end
                           period:nil
                      detailLevel:nil];
}



/**
 * Get Activities Data from Fitbit Developer API
 *
 * @discussion Example URL is "https://api.fitbit.com/1/user/[user-id]/activities/date/[date].json". Please read a document of Fitbit ("https://dev.fitbit.com/docs/activity/".)
 * 
 GET /1/user/[user-id]/[resource-path]/date/[date]/[period].json
 GET /1/user/[user-id]/[resource-path]/date/[base-date]/[end-date].json
 GET /1/user/[user-id]/[resource-path]/date/[date]/[date]/[detail-level]/time/[start-time]/[end-time].json
 
 * @param resourcePath
 * @param start start date
 */

- (BOOL) getActivityWithDataType:(NSString *)type
                    ResourcePath:(NSString *)resourcePath
                               start:(NSDate *)start
                                 end:(NSDate *)end
                              period:(NSString *)period
                         detailLevel:(NSString *)detailLevel{
    NSString * userId = [Fitbit getFitbitUserId];
    NSString* token = [Fitbit getFitbitAccessToken];
    
    //if([start isEqualToDate:end]){
    //    start = [[NSDate alloc] initWithTimeInterval:- sinceDate:start];
    //}
    
    if (userId == nil || token == nil) {
        NSString * msg = [NSString stringWithFormat:@"[Error: %@] User ID and Access Token do not exist. Please **login** again to get these.", [self getSensorName]];
        NSLog(@"%@",msg);
        return NO;
    }
    
    /////// create a Fitbit API query ///////////
    //  /1/user/[user-id]/[resource-path]/date/[base-date]/[end-date].json
    NSMutableString * urlStr = [[NSMutableString alloc] initWithString:@"https://api.fitbit.com"];
    
    if( start!=nil && end!=nil && period==nil && detailLevel!=nil){
        // https://api.fitbit.com/1/user/-/[resource-path]/date/[date]/[date]/[detail-level]/time/[start-time]/[end-time].json
        [urlStr appendFormat:@"/1/user/%@/%@/date/%@/%@/%@/time/%@/%@.json",
         userId,
         resourcePath,
         [dateFormat stringFromDate:start],
         [dateFormat stringFromDate:end],
         detailLevel,
         [timeFormat stringFromDate:start],
         [timeFormat stringFromDate:end]];
        NSLog(@"%@",urlStr);
    } else if ( start != nil && end != nil && period == nil ) {
        [urlStr appendFormat:@"/1/user/%@/%@/date/%@/%@.json",
                                            userId,
                                            resourcePath,
                                            [dateFormat stringFromDate:start],
                                            [dateFormat stringFromDate:end]];
    //  /1/user/[user-id]/[activities/heart]/date/[base-date]/[end-date]/[period].json
    } else if ( start!=nil && end!=nil && period!=nil) {
        [urlStr appendFormat:@"/1/user/%@/%@/date/%@/%@/%@.json",
         userId,
         resourcePath,
         [dateFormat stringFromDate:start],
         [dateFormat stringFromDate:end],
         period];
    // ERROR
    } else if ( start!=nil && end ==nil && period==nil && detailLevel==nil){
        [urlStr appendFormat:@"/1/user/%@/%@/date/%@.json",
         userId,
         resourcePath,
         [dateFormat stringFromDate:start]];
    } else {
        NSLog(@"Error: Query Format Error");
        return NO;
    }
    
    
    
    NSURL*	url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    if(token == nil) return NO;
    if(userId == nil) return NO;
    
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"GET"];
    
    __weak NSURLSession *session = nil;
    // NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSessionConfiguration *sessionConfig = nil;
    // identificationForFitbitData = [NSString stringWithFormat:@"%@%f", identificationForFitbitData, [[NSDate new] timeIntervalSince1970]];
    identificationForFitbitData = type;
    
    //if ([AWAREUtils isBackground]) {
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identificationForFitbitData];
        sessionConfig.timeoutIntervalForRequest = 180.0;
        sessionConfig.timeoutIntervalForResource = 60.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 60;
        sessionConfig.allowsCellularAccess = YES;
        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:Nil];
        NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
        [dataTask resume];
//    }else{
//        sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
//        sessionConfig.timeoutIntervalForRequest = 180.0;
//        sessionConfig.timeoutIntervalForResource = 60.0;
//        sessionConfig.HTTPMaximumConnectionsPerHost = 60;
//        sessionConfig.allowsCellularAccess = YES;
//        sessionConfig.allowsCellularAccess = YES;
//        sessionConfig.discretionary = YES;
//        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:Nil];
//        [[session dataTaskWithRequest:request  completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
//            [session finishTasksAndInvalidate];
//            [session invalidateAndCancel];
//            [self saveData:data response:response error:error type:type];
//        }] resume];
//    }
    
    return YES;
}


- (void) saveData:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error type:(NSString *)type{

    @try {
        if(error != nil){
            // NSString *errorStr = [[NSString alloc] initWithData:data  encoding: NSUTF8StringEncoding];
            NSLog(@"%@",error.debugDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self isDebug]) {
//                    [self sendLocalNotificationForMessage:[NSString stringWithFormat:@"[%@]%@",type,error.debugDescription] soundFlag:NO];
                }
            });
            return;
        }else if(data != nil){
            NSData *jsonData = data; // [responseString dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *error = nil;
            NSDictionary *activities = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                       options:NSJSONReadingAllowFragments error:&error];
            if (error != nil) {
                NSLog(@"failed to parse JSON: %@", error.debugDescription);
                return;
            }
            
            if([activities objectForKey:@"errors"]!=nil){
                NSLog(@"%@",activities.debugDescription);
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self isDebug]) {
//                    [self sendLocalNotificationForMessage:[NSString stringWithFormat:@"Fitbit plugin got %@ data (%ld bytes)", type, data.length] soundFlag:NO];
                }
            });
            
            NSString *responseString = [[NSString alloc] initWithData:data  encoding: NSUTF8StringEncoding];
            NSLog(@"Success: %@", responseString);
            
            NSDate * now = [NSDate new];
        
            NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
            [dict setObject:[AWAREUtils getUnixTimestamp:now] forKey:@"timestamp"]; //timestamp
            [dict setObject:[self getDeviceId] forKey:@"device_id"];  //    device_id
            [dict setObject:responseString forKey:@"fitbit_data"];    //    fitbit_data
            [dict setObject:type forKey:@"fitbit_data_type"];  //    fitbit_data_type
            [dict setObject:[Fitbit getFitbitUserId] forKey:@"fitbit_id"];          //    fitbit_id
            
            if([type isEqualToString:@"steps"]){
                [self setLastQueryDate:stepsLastSyncTime withKey:type];
            }else if([type isEqualToString:@"calories"]){
                [self setLastQueryDate:caloriesSyncTime  withKey:type];
            }else if([type isEqualToString:@"heartrate"]){
                [self setLastQueryDate:heartrateSyncTime withKey:type];
            }else if([type isEqualToString:@"sleep"]){
                [self setLastQueryDate:sleepLastSyncTime withKey:type];
            }
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                                 forKey:EXTRA_DATA];
            [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"action.aware.plugin.fitbit.get.activity.%@",type]
                                                                object:nil
                                                              userInfo:userInfo];
            NSLog(@"%@",[NSString stringWithFormat:@"action.aware.plugin.fitbit.get.activity.%@",type]);
            dispatch_async(dispatch_get_main_queue(), ^{
                // [self saveData:dict];
                [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
            });
        }else{
            
//            NSDictionary * debugMsg = @{@"debug":@"no response", @"type":type};
//            if([responseString isEqualToString:@""]){
//                debugMsg = @{@"debug":@"no response", @"type":type};
//            }else if(responseString != nil){
//                debugMsg = @{@"debug":responseString, @"type":type};
//            }
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"action.aware.plugin.fitbit.get.activity.debug"
//                                                                object:nil
//                                                              userInfo:debugMsg];
        }
    } @catch (NSException *exception) {
    } @finally {
    }
}



- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    NSString * identifier = session.configuration.identifier;
    // NSLog(@"[%@] session:dataTask:didReceiveResponse:completionHandler:",identifier);
    
    completionHandler(NSURLSessionResponseAllow);
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    if (responseCode == 200) {
        NSLog(@"[%d] Success",responseCode);
        [session finishTasksAndInvalidate];
    }else{
        [session invalidateAndCancel];
        // clear
        NSLog(@"[%d] %@", responseCode, response.debugDescription);
        if([identifier isEqualToString:@"steps"]){
            stepsResponse = [[NSMutableData alloc] init];
        }else if([identifier isEqualToString:@"calories"]){
            caloriesResponse = [[NSMutableData alloc] init];
        }else if([identifier isEqualToString:@"heartrate"]){
            heartResponse = [[NSMutableData alloc] init];
        }else if([identifier isEqualToString:@"sleep"]){
            sleepResponse = [[NSMutableData alloc] init];
        }
    }
    // [super URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}




-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    // @"steps"@"calories"
    // @"heartrate"@"sleep"
    NSString * identifier = session.configuration.identifier;
    if([identifier isEqualToString:@"steps"]){
        [stepsResponse appendData:data];
    }else if([identifier isEqualToString:@"calories"]){
        [caloriesResponse appendData:data];
    }else if([identifier isEqualToString:@"heartrate"]){
        [heartResponse appendData:data];
    }else if([identifier isEqualToString:@"sleep"]){
        [sleepResponse appendData:data];
    }
    // [super URLSession:session dataTask:dataTask didReceiveData:data];
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{

    NSString * identifier = session.configuration.identifier;
    
    if (self.isDebug && error != nil) {
//        [self sendLocalNotificationForMessage:error.debugDescription soundFlag:NO];
//        [self saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Error:%@ ",identifier,error.debugDescription] type:DebugTypeInfo label:identifier];
    }
    
    // NSLog(@"[%@]URLSession:task:didCompleteWithError",identifier);
    NSData * data = nil;
    if([identifier isEqualToString:@"steps"]){
        data = stepsResponse;
    }else if([identifier isEqualToString:@"calories"]){
        data = caloriesResponse;
    }else if([identifier isEqualToString:@"heartrate"]){
        data = heartResponse;
    }else if([identifier isEqualToString:@"sleep"]){
        data = sleepResponse;
    }
    ////////////////////////////////////////////////////
    
    if(data != nil){
        ////// save data ///////
        [self saveData:data response:nil error:error type:identifier];
    }else{
        NSLog(@"data is nil @ FitbitData plugin");
//        [self saveDebugEventWithText:[NSString stringWithFormat:@"[%@] data is nil",identifier] type:DebugTypeInfo label:identifier];
    }
    
    // clear
    if([identifier isEqualToString:@"steps"]){
        stepsResponse = [[NSMutableData alloc] init];
    }else if([identifier isEqualToString:@"calories"]){
        caloriesResponse = [[NSMutableData alloc] init];
    }else if([identifier isEqualToString:@"heartrate"]){
        heartResponse = [[NSMutableData alloc] init];
    }else if([identifier isEqualToString:@"sleep"]){
        sleepResponse = [[NSMutableData alloc] init];
    }
    
    // [super URLSession:session task:task didCompleteWithError:error];
    
}


//////////////////////////////////////////////////////////////


- (void) setLastQueryDate:(NSDate *)date withKey:(NSString *)key{
    NSUserDefaults * userDefualts = [NSUserDefaults standardUserDefaults];
    [userDefualts setObject:date forKey:[NSString stringWithFormat:@"fitbit.last.query.data.%@",key]];
}

+ (NSDate *) getLastQueryDateWithKey:(NSString *)key{
    NSUserDefaults * userDefualts = [NSUserDefaults standardUserDefaults];
    NSDate * date = (NSDate *)[userDefualts objectForKey:[NSString stringWithFormat:@"fitbit.last.query.data.%@",key]];
    if(date != nil){
        return date;
    }else{
        return [NSDate new];
    }
}


+ (void) setLastQueryDate:(NSDate *)date withKey:(NSString *)key{
    NSUserDefaults * userDefualts = [NSUserDefaults standardUserDefaults];
    [userDefualts setObject:date forKey:[NSString stringWithFormat:@"fitbit.last.query.data.%@",key]];
}

@end
