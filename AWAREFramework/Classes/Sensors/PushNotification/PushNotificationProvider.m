//
//  RemotePushNotificationManager.m
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/12/18.
//

#import "PushNotificationProvider.h"
#import "PushNotification.h"
#import "AWAREStudy.h"

@implementation PushNotificationProvider{
    NSString * pushNotificationSessionIdentifier;
    NSMutableData * receivedData;
    PNPSessionCompletionHandler completionHandler;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pushNotificationSessionIdentifier = @"push_notification_session_identifier";
        NSURLSessionConfiguration * sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:pushNotificationSessionIdentifier];
        _session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
        _session.configuration.allowsCellularAccess       = YES;
        _session.configuration.timeoutIntervalForRequest  = 10;
        _session.configuration.timeoutIntervalForResource = 10;
        receivedData = [[NSMutableData alloc] init];
    }
    return self;
}


- (void) registerToken:(NSString *)token
              deviceId:(NSString *)deviceId
             serverURL:(NSString *)url
            completion:(PNPSessionCompletionHandler)completion{
    // set HTTP/POST body information
    completionHandler = completion;
    receivedData = [[NSMutableData alloc] init];
    NSString * body    = [NSString stringWithFormat:@"{\"device_id\":\"%@\",\"platform\":1,\"token\":\"%@\"}", deviceId, token];
    NSURL * serverURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/token/register",url]];
    NSMutableURLRequest * request = [self getMutableURLRequestWithBody:body url:serverURL];
    _dataTask = [_session dataTaskWithRequest:request];
    [_dataTask resume];
}

- (void) unregisterTokenWithDeviceId:(NSString *)deviceId
                           serverURL:(NSURL *)url
                          completion:(PNPSessionCompletionHandler)completion{
    completionHandler = completion;
    receivedData = [[NSMutableData alloc] init];
    NSString * body    = [NSString stringWithFormat:@"{\"device_id\":\"%@\"}", deviceId];
    NSURL * serverURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/token/unregister",url]];
    NSMutableURLRequest * request = [self getMutableURLRequestWithBody:body url:serverURL];
    _dataTask = [_session dataTaskWithRequest:request];
    [_dataTask resume];
}


- (NSMutableURLRequest * _Nonnull) getMutableURLRequestWithBody:(NSString * _Nonnull)body
                                                            url:(NSURL * _Nonnull)url{
    NSData   * postData = [body dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSMutableData * mutablePostData = [[NSMutableData alloc] initWithData:postData];
    NSString * postLength = [NSString stringWithFormat:@"%tu", [mutablePostData length]];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setAllHTTPHeaderFields:@{@"Content-Type":@"application/json"}];
    [request setHTTPBody:mutablePostData];
    return request;
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
                                 didReceiveResponse:(NSURLResponse *)response
                                  completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
 
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode == 200) {
        completionHandler(NSURLSessionResponseAllow);
    } else {
        NSLog(@"[RemotePushNotificationManager] Response Code: %ld", httpResponse.statusCode);
        // httpResponse.
        completionHandler(NSURLSessionResponseCancel);
    }
}


- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    // NSLog(@"dataTask:didReceiveData");
    if (data != nil && receivedData != nil){
        [receivedData appendData:data];
    }
    
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    // NSLog(@"didBecomeInvalid");
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    // NSLog(@"task:didCompleteWithError");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->completionHandler != nil) {
            if (error != nil) {
                self->completionHandler(NO, self->receivedData, error);
            }else{
                self->completionHandler(YES, self->receivedData, error);
            }
            self->receivedData = [[NSMutableData alloc] init];
            self->completionHandler = nil;
        }
    });
}

@end
