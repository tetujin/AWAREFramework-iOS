//
//  QuickSyncExecutorr.m
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/12/21.
//

#import "QuickSyncExecutor.h"

@implementation QuickSyncExecutor{
    AWAREStudy * awareStudy;
    NSString   * sensorName;
    NSString   * baseSyncDataQueryIdentifier;
}

@synthesize debug;
@synthesize executorCallback;
@synthesize session;
@synthesize dataTask;

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                        sensorName:(NSString *)name{
    self = [super init];
    if (self != nil) {
        awareStudy = study;
        sensorName = name;
        debug      = [study isDebug];
        
        // Set session configuration
        NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
        // config.sharedContainerIdentifier= @"com.awareframework.sync.task.identifier";
        config.allowsCellularAccess = YES;
        
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return self;
}

- (void)syncWithData:(NSData *)data callback:(SyncExecutorCallback)callback{
    
    executorCallback = callback;
    
    NSString * deviceId = [awareStudy getDeviceId];
    NSString * baseURL  = [awareStudy getStudyURL];
    
    NSLog(@"[%@] %@", sensorName, baseURL);

    if (baseURL == nil || [baseURL isEqualToString:@""]) {
        NSLog(@"[%@] The base URL is null", sensorName);
        if (callback != nil) {
            callback(@{@"result":@(NO),
                       @"name":self->sensorName,
                       @"error":@"NOO URL"});
        }
        return;
    }

    NSString * url = [NSString stringWithFormat:@"%@/%@/insert", baseURL, sensorName];
    
    // set HTTP/POST body information
    NSString * post     = [NSString stringWithFormat:@"device_id=%@&data=", deviceId];
    NSData   * postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSMutableData * mutablePostData = [[NSMutableData alloc] initWithData:postData];
    [mutablePostData appendData:data]; // <-- this data should be JSON format
    NSString * postLength = [NSString stringWithFormat:@"%tu", [mutablePostData length]];
    
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:mutablePostData];
    
    dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data,
                                                              NSURLResponse * _Nullable response,
                                                              NSError * _Nullable error) {
        if (self->executorCallback != nil) {
            // NSLog(@"%d",NSThread.isMainThread);
            NSString * response = @"";
            if (data != nil) {
                response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error != nil) {
                    self->executorCallback(@{@"result":@(NO),
                                              @"name":self->sensorName,
                                              @"error":error.debugDescription,
                                              @"response":response});
                }else{

                    self->executorCallback(@{@"result":@(YES),
                                              @"name":self->sensorName,
                                              @"response":response});
                }
                self->executorCallback = nil;
            });
        }
    }];
    
    [dataTask resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    if (debug) {
        NSLog(@"[%@] ---> %3.2f%%", sensorName, (double)totalBytesSent/(double)totalBytesExpectedToSend*100.0f);
    }
}

@end

