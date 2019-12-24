//
//  PushNotificationResponder.m
//  AppAuth
//
//  Created by Yuuki Nishiyama on 2019/12/20.
//

#import "PushNotificationResponder.h"
#import "../../Core/AWARECore.h"
#import "../../Core/Sensor/AWARESensorManager.h"
#import "../../Core/Study/AWAREStudy.h"
#import "../../Core/Utility/AWAREUtils.h"
#import "../../Core/Utility/AWAREStatusMonitor.h"
#import "../../Core/Utility/AWAREEventLogger.h"

@implementation PushNotificationResponder

@synthesize helpMessageTitle;
@synthesize helpMessageBody;

- (instancetype)init{
    self = [super init];
    if (self != nil) {
        helpMessageTitle = @"[HELP] Please Open AWARE";
        helpMessageBody  = @"Sensor modules are suspended due to an unexpected reason. For reactivating these sensors, please open AWARE.";
    }
    return self;
}

- (void)responseWithPayload:(NSDictionary<NSString *,id> *) payload{
    AWARESilentPNPayload * awarePayload = [[AWARESilentPNPayload alloc] initWithPayload:payload];
    if(awarePayload.version > 0){
        [self executeOperationsV1:awarePayload];
    }
    [AWAREEventLogger.shared logEvent:@{@"class":@"PushNotificationResponder",
                                        @"event":@"executeOperations",
                                        @"payload":payload}];
}

- (void) executeOperationsV1:(AWARESilentPNPayload * _Nonnull)awarePayload{
    if (awarePayload.operations != nil) {
        for (NSDictionary * op in awarePayload.operations) {
            NSString * cmd = [op objectForKey:@"cmd"];
            if (cmd != nil) {
                if ( [cmd isEqualToString:@"sync-all-sensors"]) {
                    [AWARESensorManager.sharedSensorManager syncAllSensorsForcefully];
                } else if ( [cmd isEqualToString:@"sync-sensor"]) {
                    NSArray * targets = [op objectForKey:@"targets"];
                    if (targets != nil) {
                        for (NSString * target in targets) {
                            if (target != nil) {
                                [[AWARESensorManager.sharedSensorManager getSensor:target] startSyncDB];
                            }
                        }
                    }
                } else if ( [cmd isEqualToString:@"start-all-sensors"]) {
                    [AWARESensorManager.sharedSensorManager startAllSensors];
                } else if ( [cmd isEqualToString:@"stop-all-sensors"]) {
                    [AWARESensorManager.sharedSensorManager stopAllSensors];
                } else if ( [cmd isEqualToString:@"reactivate-core"]) {
                    // check application status
                    NSDictionary<NSString *, id> * lastSignal = [[AWAREStatusMonitor.shared getLatestData] mutableCopy];
                    [AWARECore.sharedCore reactivate];
                     // [AWARESensorManager.sharedSensorManager stopAllSensors];
                     // [AWARESensorManager.sharedSensorManager startAllSensors];
                    if (lastSignal != nil) {
                        NSNumber * lastTimestamp = [lastSignal objectForKey:@"timestamp"];
                        if (lastTimestamp != nil) {
                            double uwLastTimestamp = lastTimestamp.doubleValue;
                            double currentTimestamp = NSDate.new.timeIntervalSince1970 * 1000.0;
                            double gap = currentTimestamp - uwLastTimestamp;
                            if (gap > 60 * 10 * 1000) { // 10 min
                                NSDate * zero = [AWAREUtils getTargetNSDate:NSDate.new hour:0 nextDay:NO];
                                NSDate * six  = [AWAREUtils getTargetNSDate:NSDate.new hour:8 nextDay:NO];
                                NSDate * now = NSDate.new;
                                NSLog(@"[%@][%@][%@]", zero, six, now);
                                if(zero<=now && six>=now){
                                    [AWAREUtils sendLocalPushNotificationWithTitle:helpMessageTitle
                                                                              body:helpMessageBody
                                                                      timeInterval:3
                                                                           repeats:NO
                                                                        identifier:@"com.awareframework.ios.help.reboot.notification"
                                                                             clean:YES sound:nil];
                                    [AWAREEventLogger.shared logEvent:@{@"class":@"PushNotificationResponder",
                                                                        @"event":@"SendHelpMessage",
                                                                        @"reason":@"Midnight"}];
                                }else{
                                    [AWAREUtils sendLocalPushNotificationWithTitle:helpMessageTitle
                                                                              body:helpMessageBody
                                                                      timeInterval:3
                                                                           repeats:NO
                                                                        identifier:@"com.awareframework.ios.help.reboot.notification"
                                                                             clean:YES sound:UNNotificationSound.defaultSound];
                                    [AWAREEventLogger.shared logEvent:@{@"class":@"PushNotificationResponder",
                                                                        @"event":@"SendHelpMessage"}];
                                }
                                
                            }
                        }
                    }
                } else if ( [cmd isEqualToString:@"push-msg"]){
                    NSDictionary <NSString *, NSString *> * msg = [op objectForKey:@"msg"];
                    if (msg != nil) {
                        NSString * title = [msg objectForKey:@"title"];
                        NSString * body  = [msg objectForKey:@"body"];
                        [AWAREUtils sendLocalPushNotificationWithTitle:title body:body timeInterval:0.1 repeats:false];
                    }
                } else if ( [cmd isEqualToString:@"sync-config"]){
                    [AWAREStudy.sharedStudy refreshStudySettings];
                }
            }
        }
    }
}

@end



@implementation AWARESilentPNPayload : NSObject

@synthesize version;
@synthesize operations;

- (instancetype)initWithPayload:(NSDictionary<NSString *,id> *)payload{
    self = [super init];
    if (self!=nil) {
        version = [self getVersion:payload];
        operations = [self getOperations:payload];
    }
    return self;
}

- (double) getVersion:(NSDictionary <NSString *, id> * _Nonnull)payload {
    NSDictionary<NSString *, id> * aware = [payload objectForKey:@"aware"];
    if (aware!=nil) {
        NSNumber * v = [aware objectForKey:@"v"];
        if (v!=nil) {
            return v.doubleValue;
        }
    }
    return 0;
}

- (NSArray<NSDictionary<NSString *, id> *> *)getOperations:(NSDictionary<NSString *, id> * _Nonnull) payload{
    NSLog(@"%@", payload.description);
    NSDictionary<NSString *, id> * aware = [payload objectForKey:@"aware"];
    if (aware!=nil) {
        return [aware objectForKey:@"ops"];
    }
    return nil;
}

@end
