//
//  SSLManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/6/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "SSLManager.h"

@implementation SSLManager

- (bool)installCRTWithTextOfQRCode:(NSString *)text {
    NSLog(@"%@", text);
    // https://api.awareframework.com/index.php/webservice/index/502/Fuvl8P6Atay0
    
    NSArray *elements = [text componentsSeparatedByString:@"/"];
    if (elements.count > 2) {
        if ([[elements objectAtIndex:0] isEqualToString:@"https:"] || [[elements objectAtIndex:0] isEqualToString:@"http:"]) {
            return [self installCRTWithAwareHostURL:[elements objectAtIndex:2]];
        }
    }
    return NO;
}

- (bool)installCRTWithAwareHostURL:(NSString *)url {
    if ([url isEqualToString:@"api.awareframework.com"]) {
        url = @"awareframework.com";
    }
    NSURL * awareCrtUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/public/server.crt", url]];
    [[UIApplication sharedApplication] openURL:awareCrtUrl];
    
//    NSError *error = nil;
//    int responseCode = 0;
//    NSString* cerStr = @"";
//    
//    @autoreleasepool {
//        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
//        [request setURL:awareCrtUrl];
//        [request setHTTPMethod:@"POST"];
//        [request setTimeoutInterval:60*3];
//        NSHTTPURLResponse *response = nil;
//        NSData *resData = [NSURLConnection sendSynchronousRequest:request
//                                                returningResponse:&response error:&error];
//        cerStr = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
//        responseCode = (int)[response statusCode];
//    }
//    
//    if(responseCode == 200){
//        NSLog(@"SSL: %@", cerStr);
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString *directory = [paths objectAtIndex:0];
//        NSString *filePath = [directory stringByAppendingPathComponent:@"server.crt"];
//        BOOL successful = [cerStr writeToFile:filePath atomically:NO];
//        if (successful) {
//            return YES;
//        }else{
//            return NO;
//        }
//    }else{
//        return NO;
//    }
    return YES;
}

@end
