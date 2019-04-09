//
//  AWAREUtils.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/23/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREUtils.h"
#import "AWAREKeys.h"
#import <CommonCrypto/CommonDigest.h>
#import <sys/utsname.h>

@implementation AWAREUtils


/**
 * This method sets application condition (background or foreground).
 *
 * @param state 'YES' is foreground. 'NO' is background.
 */
//+ (void)setAppState:(BOOL)state{
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setBool:state forKey:@"APP_STATE"];
//    if (state) {
//        NSLog(@"Application is in the foreground!");
//    }else{
//        NSLog(@"Application is in the background!");
//    }
//}


/**
 * This method returns application condition (background or foreground).
 *
 * @return 'YES' is foreground. 'NO' is background.
 */
+ (BOOL) getAppState {
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    return [defaults boolForKey:@"APP_STATE"];
    UIApplicationState appState = [[UIApplication sharedApplication] applicationState];
    switch (appState) {
        case UIApplicationStateActive:
            // NSLog(@"Application is in the foreground!");
            return YES;
        case UIApplicationStateInactive:
            // NSLog(@"Application is in the foreground!");
            return YES;
        case UIApplicationStateBackground:
            // NSLog(@"Application is in the background!");
            return NO;
        default:
            return NO;
    }
}



/**
 * This method sets application is in the foreground or not.
 *
 * @return state 'YES' is foreground. 'NO' is background.
 */
+ (BOOL)isForeground{
   UIApplicationState appState = [[UIApplication sharedApplication] applicationState];
    switch (appState) {
        case UIApplicationStateActive:
            return YES;
        case UIApplicationStateInactive:
            return NO;
        case UIApplicationStateBackground:
            return NO;
        default:
            return NO;
    }
}

/**
 * This method sets application condition in the background or not.
 *
 * @return state 'YES' is background, on the other hand 'NO' is foreground.
 */
+ (BOOL)isBackground{
    UIApplicationState appState = [[UIApplication sharedApplication] applicationState];
    switch (appState) {
        case UIApplicationStateActive:
            return NO;
        case UIApplicationStateInactive:
            return NO;
        case UIApplicationStateBackground:
            return YES;
        default:
            return NO;
    }
}

/**
 Provides current OS version such as iOS8.2, iOS9 or iOS9.1 with float value.
 (e.g., 8.2, 9.0, and 9.1)
 @return an os version of the device
 */
+ (float) getCurrentOSVersionAsFloat{
    float currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    return currentVersion;
}


/**
Provides a system UUID.
 
@discussion AWARE iOS uses this value as a device_id, but if a user uninstalls the AWARE iOS, this value will be change.
 
@return A system UUID with NSString (Sample: 37ce6bb8-d35f-4375-ae90-87219bb3f97b)
 */
+ (NSString *)getSystemUUID {
    NSString * uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    uuid = [uuid lowercaseString];
    return uuid;
}


/**
 This method generates an unixtimestamp value from NSDate.
 
 In the Objective-C, we can get a timestamp with [[NSDate new] timeIntervalSince1970].
 However, the value is 'float', and it is not the same format in the AWARE database.
 For fixing the problem, we have to calculate the timestamp . And also, we have to store the value to a LongLong (8bit) object 
 for preventing a cast error on the 32bit platfrom.
 In the Objective-C, a bit size of a Long value on 32bit devices (such as iPhoen4s, iPhone5 and iPhone5c) is 4bit.
 On the other hand, on the 64bit device (such as iPhone5s, iPhone6 and iPhone6s), the size is 8bit.
 If you cast the Float value(8bit) to a Long value(4bit) on the 32bit devices, you will get a wronge value.
 
 On the 32bit device, you should use a LongLong value insted of a Long value.
 The LongLong value is 8bit variable both 32bit and 64bit devices.
 
 @param nsdate Commonly you can make the value using [NSDate new] method.
 @return An unixtime stamp value (e.g., 1453141282.168 => 1453141282168)
 */
+ (NSNumber *)getUnixTimestamp:(NSDate *)nsdate{
    if (nsdate == nil) {
        return [self getUnixTimestamp:[NSDate new]];
    }
    NSTimeInterval timeStamp = [nsdate timeIntervalSince1970] * 1000;
    NSNumber* unixtime = [NSNumber numberWithLongLong:timeStamp];
    return unixtime;
}


/**
 This is a wrapper class of -getTargetNSDate:hour:minute:second:nextDay.
 
 @param nsDate   A NSDate value of a base date
 @param hour     An int value of a target special hour (0-24)
 @param nextDay  A 'YES' return a NSDate of next data, if the input NSDate is over the current time. On the other hand, A 'No' return a NSDate of today.
 @return A NSDate object based on the input values
 */
+ (NSDate *)getTargetNSDate:(NSDate *)nsDate hour:(int)hour nextDay:(BOOL)nextDay {
    return [self getTargetNSDate:nsDate hour:hour minute:0 second:0 nextDay:nextDay];
}


/**
 This method generate a specific NSDate based on the input values (hour, minute, second).
 NOTE: This method offten is used in schedulers.
 
 // [Sample1]
 // Current time is 8AM.
 NSDate * now = [NSDate new]; // Get today's NSDate
 NSDate * tommorowSevenAM = [AWAREUtils getTargetNSDate:now hour:7 minute:0 second:0 nextDay:YES];
 
 // [Sample2]
 // Current time is 8AM.
 NSDate * now = [NSDate new]; // Get today's NSDate
 NSDate * todaySevenAM = [AWAREUtils getTargetNSDate:now hour:7 minute:0 second:0 nextDay:NO];
 
 // [Sample3]
 // Current time is 8AM.
 NSDate * now = [NSDate new]; // Get today's NSDate
 NSDate * todayNineAM = [AWAREUtils getTargetNSDate:now hour:9 minute:0 second:0 nextDay:YES];
 
 // [Sample4]
 // Current time is 8AM.
 NSDate * now = [NSDate new]; // Get today's NSDate
 NSDate * todayNineAM = [AWAREUtils getTargetNSDate:now hour:9 minute:0 second:0 nextDay:NO];
 
 @param nsDate   A NSDate value of a base date
 @param hour     An int value of a target special hour (0-24)
 @param minute   An int value of a target special minute (0-60)
 @param second   An int value of a target special second (0-60)
 @param nextDay  A 'YES' return a NSDate of next data, if the input NSDate is over the current time. On the other hand, A 'No' return a NSDate of today.
 @return A NSDate object based on the input values
 */
+ (NSDate *) getTargetNSDate:(NSDate *) nsDate
                              hour:(int) hour
                            minute:(int) minute
                            second:(int) second
                           nextDay:(BOOL)nextDay {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComps = [calendar components:NSCalendarUnitYear   |
                                                       NSCalendarUnitMonth  |
                                                       NSCalendarUnitDay    |
                                                       NSCalendarUnitHour   |
                                                       NSCalendarUnitMinute |
                                                       NSCalendarUnitSecond
                                              fromDate:nsDate];
    [dateComps setDay:dateComps.day];
    [dateComps setHour:hour];
    [dateComps setMinute:minute];
    [dateComps setSecond:second];
    NSDate * targetNSDate = [calendar dateFromComponents:dateComps];
    //    return targetNSDate;
    
    if (nextDay) {
        if ([targetNSDate timeIntervalSince1970] < [nsDate timeIntervalSince1970]) {
            [dateComps setDay:dateComps.day + 1];
            NSDate * tomorrowNSDate = [calendar dateFromComponents:dateComps];
            return tomorrowNSDate;
        }else{
            return targetNSDate;
        }
    }else{
        return targetNSDate;
    }
    
}



/**
 * An hash method of SHA1
 *
 * This source code is refered from the [web-page]( http://www.makebetterthings.com/iphone/how-to-get-md5-and-sha1-in-objective-c-ios-sdk/ ).
 * Also, Google Calendar Plugin is using this method for make an hash object.
 *
 * @param input A NSString object for hasing
 *
 */
+ (NSString*) sha1:(NSString*)input{
    return [self sha1:input debug:NO];
}

+ (NSString*) sha1:(NSString*)input debug:(BOOL)debug
{
    if (debug) { NSLog(@"Before: %@", input); }
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    if (debug) { NSLog(@"After: %@", output); }
    
    return output;
    
}


/**
 * An hash method of MD5
 *
 * This source code is refered from the [web-page]( http://www.makebetterthings.com/iphone/how-to-get-md5-and-sha1-in-objective-c-ios-sdk/ ).
 *
 * @param input A NSString object for hasing
 *
 */
+ (NSString *) md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}


/**
 * An email format checker
 *
 * @param  str A NSString object for checking an existence of email addresses
 * @return An existance of email address in the inputed text as a boolean value
 */
+ (BOOL)validateEmailWithString:(NSString *)str
{
    if (!str || [str length] == 0) {
        return NO;
    }
    
    BOOL stricterFilter = NO;
    
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];

    return [emailTest evaluateWithObject:str];
}


/**
 * http://stackoverflow.com/questions/11197509/ios-how-to-get-device-make-and-model
 */
+ (NSString*) deviceName {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
    
    static NSDictionary* deviceNamesByCode = nil;
    
    if (!deviceNamesByCode) {
        
        deviceNamesByCode = @{@"i386"      :@"Simulator",
                              @"iPod1,1"   :@"iPod Touch",      // (Original)
                              @"iPod2,1"   :@"iPod Touch",      // (Second Generation)
                              @"iPod3,1"   :@"iPod Touch",      // (Third Generation)
                              @"iPod4,1"   :@"iPod Touch",      // (Fourth Generation)
                              @"iPhone1,1" :@"iPhone",          // (Original)
                              @"iPhone1,2" :@"iPhone",          // (3G)
                              @"iPhone2,1" :@"iPhone",          // (3GS)
                              @"iPad1,1"   :@"iPad",            // (Original)
                              @"iPad2,1"   :@"iPad 2",          //
                              @"iPad3,1"   :@"iPad",            // (3rd Generation)
                              @"iPhone3,1" :@"iPhone 4",        // (GSM)
                              @"iPhone3,3" :@"iPhone 4",        // (CDMA/Verizon/Sprint)
                              @"iPhone4,1" :@"iPhone 4s",       //
                              @"iPhone5,1" :@"iPhone 5",        // (model A1428, AT&T/Canada)
                              @"iPhone5,2" :@"iPhone 5",        // (model A1429, everything else)
                              @"iPad3,4"   :@"iPad",            // (4th Generation)
                              @"iPad2,5"   :@"iPad Mini",       // (Original)
                              @"iPhone5,3" :@"iPhone 5c",       // (model A1456, A1532 | GSM)
                              @"iPhone5,4" :@"iPhone 5c",       // (model A1507, A1516, A1526 (China), A1529 | Global)
                              @"iPhone6,1" :@"iPhone 5s",       // (model A1433, A1533 | GSM)
                              @"iPhone6,2" :@"iPhone 5s",       // (model A1457, A1518, A1528 (China), A1530 | Global)
                              @"iPhone7,1" :@"iPhone 6 Plus",   //
                              @"iPhone7,2" :@"iPhone 6",        //
                              @"iPhone8,1" :@"iPhone 6s",   //
                              @"iPhone8,2" :@"iPhone 6s Plus",        //
                              @"iPhone8,4" :@"iPhone SE",
                              @"iPhone9,1" :@"iPhone 7",
                              @"iPhone9,3" :@"iPhone 7",
                              @"iPhone9,2" :@"iPhone 7 Plus",
                              @"iPhone9,4" :@"iPhone 7 Plus",
                              @"iPad4,1"   :@"iPad Air",        // 5th Generation iPad (iPad Air) - Wifi
                              @"iPad4,2"   :@"iPad Air",        // 5th Generation iPad (iPad Air) - Cellular
                              @"iPad4,4"   :@"iPad Mini",       // (2nd Generation iPad Mini - Wifi)
                              @"iPad4,5"   :@"iPad Mini"        // (2nd Generation iPad Mini - Cellular)
                              };
    }
    
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    
    if (!deviceName) {
        // Not found on database. At least guess main device type from string contents:
        
        if ([code rangeOfString:@"iPod"].location != NSNotFound) {
            deviceName = @"iPod Touch";
        }
        else if([code rangeOfString:@"iPad"].location != NSNotFound) {
            deviceName = @"iPad";
        }
        else if([code rangeOfString:@"iPhone"].location != NSNotFound){
            deviceName = @"iPhone";
        }
    }
    
    if (deviceName == nil) {
        deviceName = @"";
    }
    return deviceName;
}


+ (BOOL)checkURLFormat:(NSString *)urlStr{
    if (urlStr == nil) return NO;
    
    NSError *error = nil;
    NSString *URLPattern = @"(http://|https://){1}[\\w\\.\\-/:]+";
    NSRegularExpression *regularExpressionForPickOut = [NSRegularExpression regularExpressionWithPattern:URLPattern options:0 error:&error];
    NSArray *matchesInString = [regularExpressionForPickOut matchesInString:urlStr options:0 range:NSMakeRange(0, urlStr.length)];
    if (matchesInString.count > 0) {
        return YES;
    }else{
        return NO;
    }
}


+ (NSDictionary*)getDictionaryFromURLParameter:(NSURL *)url{
    
    if (url == nil) {
        return nil;
    }
    
    NSString * query = [url query];
    
    if (query){
        NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
        NSArray* parameters = [query componentsSeparatedByString:@"&"];
        for (NSString* parameter in parameters){
            if (parameter.length > 0){
                NSArray* elements = [parameter componentsSeparatedByString:@"="];
                id key = [elements[0] stringByRemovingPercentEncoding];
                id value = (elements.count == 1 ? @YES : [elements[1] stringByRemovingPercentEncoding]);
                // stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                // id key = [elements[0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [result setObject:value forKey:key];
            }
        }
        return [result copy];
    }
    else{
        return nil;
    }
}


+ (NSString *)stringByAddingPercentEncoding:(NSString *)string{
    return [AWAREUtils stringByAddingPercentEncoding:string unreserved:@""];
}

+ (NSString *)stringByAddingPercentEncoding:(NSString *)string unreserved:(NSString*)unreserved{
    // NSString *unreserved = @"-._~/?{}[]\"\':, ";
    // NSString *unreserved = @"";
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet
                                      alphanumericCharacterSet];
    [allowed addCharactersInString:unreserved];
    return [string stringByAddingPercentEncodingWithAllowedCharacters:allowed];
}



@end

