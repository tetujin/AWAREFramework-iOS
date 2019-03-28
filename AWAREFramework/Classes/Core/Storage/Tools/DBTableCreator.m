//
//  DBTableCreator.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2018/03/12.
//  Copyright © 2018 Yuuki NISHIYAMA. All rights reserved.
//

#import "DBTableCreator.h"

@implementation DBTableCreator{
    AWAREStudy * awareStudy;
    NSString* sensorName;
    NSString *tableName;
    NSString * baseCreateTableQueryIdentifier;
    NSMutableData * recievedData;
    __weak NSURLSession *session;
    TableCreateCallBack httpCallback;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study sensorName:(NSString *)name{
    self = [super init];
    if(self!=nil){
        awareStudy = study;
        sensorName = name;
        tableName = name;
        recievedData = [[NSMutableData alloc] init];
        baseCreateTableQueryIdentifier = [NSString stringWithFormat:@"create_table_query_identifier_%@",  sensorName];
        
        NSURLSessionConfiguration *sessionConfig = nil;
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:baseCreateTableQueryIdentifier];
        sessionConfig.sharedContainerIdentifier= @"com.awareframework.table.create.task.identifier";
        sessionConfig.timeoutIntervalForRequest = 10;
        sessionConfig.HTTPMaximumConnectionsPerHost = 10;
        sessionConfig.timeoutIntervalForResource = 10;
        sessionConfig.allowsCellularAccess = YES;
        
        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    return self;
}

- (void) setCallback:(TableCreateCallBack)callback{
    httpCallback = callback;
}

- (void) createTable:(NSString*) query {
    [self createTable:query withTableName:sensorName];
}

- (void) createTable:(NSString *)query withTableName:(NSString*) tableName {
    NSString *post = nil;
    NSData *postData = nil;
    NSMutableURLRequest *request = nil;
    NSString *postLength = nil;
    
    // Make a post query for creating a table
    post = [NSString stringWithFormat:@"device_id=%@&fields=%@", [awareStudy getDeviceId], query];
    postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    postLength = [NSString stringWithFormat:@"%ld", [postData length]];

    NSString * url = [self getWebserviceUrl];
    if (url == nil || [url isEqualToString:@""]) {
        if (awareStudy.isDebug) NSLog(@"[DBTableCreator:%@] Study URL is Empty", sensorName);
        return;
    }
    
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[self getCreateTableUrl:tableName]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];

    // Generate an unique identifier for background HTTP/POST on iOS
    [session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        if (dataTasks.count == 0) {
            NSURLSessionDataTask* dataTask = [self->session dataTaskWithRequest:request];
            [dataTask resume];
        }
    }];
}


- (NSString *)getCreateTableUrl:(NSString *)name{
    //    - create_table: creates a table if it doesn’t exist already
    return [NSString stringWithFormat:@"%@/%@/create_table", [self getWebserviceUrl], name];
}

- (NSString *)getWebserviceUrl{
    NSString* url = [awareStudy getStudyURL];
    if (url == NULL || [url isEqualToString:@""]) {
        if (awareStudy.isDebug ) NSLog(@"[Error] You did not have a StudyID. Please check your study configuration.");
        return @"";
    }
    return url;
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    completionHandler(NSURLSessionResponseAllow);
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    if ( responseCode == 200 ) {
        [session finishTasksAndInvalidate];
    } else {
        [session invalidateAndCancel];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    if (data != nil) {
        [recievedData appendData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if(error==nil){
        NSString * result = [[NSString alloc] initWithData:recievedData encoding:NSUTF8StringEncoding];
        NSLog(@"%@",result);
        if (httpCallback!=nil) {
            httpCallback(YES, recievedData, error);
        }
    }else{
        if (httpCallback!=nil) {
            httpCallback(NO, recievedData, error);
        }
    }
}


@end
