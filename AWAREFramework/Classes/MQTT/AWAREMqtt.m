//
//  AWAREMqtt.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/10/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREMqtt.h"
#import "AWAREKeys.h"

@implementation AWAREMqtt

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self loadMqttServerInfo];
    }
    return self;
}



- (BOOL) loadMqttServerInfo {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    // if Study ID is new, AWARE adds new Device ID to the AWARE server.
    _mqttServer = [userDefaults objectForKey:KEY_MQTT_SERVER];
    _oldStudyId = [userDefaults objectForKey:KEY_STUDY_ID];
    _mqttPassword = [userDefaults objectForKey:KEY_MQTT_PASS];
    _mqttUserName = [userDefaults objectForKey:KEY_MQTT_USERNAME];
    _mqttPort = [userDefaults objectForKey:KEY_MQTT_PORT];
    _mqttKeepAlive = [userDefaults objectForKey:KEY_MQTT_KEEP_ALIVE];
    _mqttQos = [userDefaults objectForKey:KEY_MQTT_QOS];
    _studyId = [userDefaults objectForKey:KEY_STUDY_ID];
    return YES;
}

- (void) saveMqttServerInfo:(NSArray *) settings {
    for (int i=0; i<[settings count]; i++) {
        NSDictionary *settingElement = [settings objectAtIndex:i];
        NSString *setting = [settingElement objectForKey:@"setting"];
        NSString *value = [settingElement objectForKey:@"value"];
        if([setting isEqualToString:@"mqtt_password"]){
            _mqttPassword = value;
        }else if([setting isEqualToString:@"mqtt_username"]){
            _mqttUserName = value;
        }else if([setting isEqualToString:@"mqtt_server"]){
            _mqttServer = value;
        }else if([setting isEqualToString:@"mqtt_server"]){
            _mqttServer = value;
        }else if([setting isEqualToString:@"mqtt_port"]){
            _mqttPort = [NSNumber numberWithInt:[value intValue]];
        }else if([setting isEqualToString:@"mqtt_keep_alive"]){
            _mqttKeepAlive = [NSNumber numberWithInt:[value intValue]];
        }else if([setting isEqualToString:@"mqtt_qos"]){
            _mqttQos = [NSNumber numberWithInt:[value intValue]];
        }else if([setting isEqualToString:@"study_id"]){
            _studyId = value;
        }
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:_mqttServer forKey:KEY_MQTT_SERVER];
    [userDefaults setObject:_mqttPassword forKey:KEY_MQTT_PASS];
    [userDefaults setObject:_mqttUserName forKey:KEY_MQTT_USERNAME];
    [userDefaults setObject:_mqttPort forKey:KEY_MQTT_PORT];
    [userDefaults setObject:_mqttKeepAlive forKey:KEY_MQTT_KEEP_ALIVE];
    [userDefaults setObject:_mqttQos forKey:KEY_MQTT_QOS];
    [userDefaults setObject:_studyId forKey:KEY_STUDY_ID];
    [userDefaults synchronize];
}




- (void) connectMqttServer {
//    self.client = [[MQTTClient alloc] initWithClientId:_mqttUserName cleanSession:YES];
//    [self.client setPort:[_mqttPort intValue]];
//    [self.client setKeepAlive:[_mqttKeepAlive intValue]];
//    [self.client setPassword:_mqttPassword];
//    [self.client setUsername:_mqttUserName];
//    [self.client setCleanSession:FALSE];
//    // define the handler that will be called when MQTT messages are received by the client
//    [self.client setMessageHandler:^(MQTTMessage *message) {
//        NSString *text = message.payloadString;
//        NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
//        NSDictionary * dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
//        NSLog(@"%@",dic);
//        NSArray *array = [dic objectForKey:KEY_SENSORS];
//        NSArray *plugins = [dic objectForKey:KEY_PLUGINS];
//        // save sensors and pluging information to the localstorage
//        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//        [userDefaults setObject:array forKey:KEY_SENSORS];
//        [userDefaults setObject:plugins forKey:KEY_PLUGINS];
//        [userDefaults synchronize];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // Refreh sensors
////            [_sensorManager stopAllSensors];
////            [self initList];
////            [self.tableView reloadData];
////            [self sendLocalNotificationForMessage:@"AWARE study is updated via MQTT." soundFlag:NO];
//        });
//    }];
//    
//    [self.client connectToHost:_mqttServer
//             completionHandler:^(MQTTConnectionReturnCode code) {
//                 if (code == ConnectionAccepted) {
//                     NSLog(@"Connected to the MQTT server!");
//                     // when the client is connected, send a MQTT message
//                     //Study specific subscribes
//                     [self.client subscribe:[NSString stringWithFormat:@"%@/%@/broadcasts",_studyId,_mqttUserName] withQos:[_mqttQos intValue] completionHandler:^(NSArray *grantedQos) {
//                         //                         NSLog(grantedQos.description);
//                     }];
//                     [self.client subscribe:[NSString stringWithFormat:@"%@/%@/esm", _studyId, _mqttUserName] withQos:[_mqttQos intValue]  completionHandler:^(NSArray *grantedQos) {
//                         //                         NSLog(grantedQos.description);
//                     }];
//                     [self.client subscribe:[NSString stringWithFormat:@"%@/%@/configuration",_studyId,_mqttUserName]  withQos:[_mqttQos intValue] completionHandler:^(NSArray *grantedQos) {
//                         //                         NSLog(grantedQos.description);
//                     }];
//                     [self.client subscribe:[NSString stringWithFormat:@"%@/%@/#",_studyId,_mqttUserName] withQos:[_mqttQos intValue]  completionHandler:^(NSArray *grantedQos) {
//                         //                         NSLog(grantedQos.description);
//                     }];
//                     
//                     
//                     //Device specific subscribes
//                     [self.client subscribe:[NSString stringWithFormat:@"%@/esm", _mqttUserName] withQos:[_mqttQos intValue] completionHandler:^(NSArray *grantedQos) {
//                         //                         NSLog(grantedQos.description);
//                     }];
//                     [self.client subscribe:[NSString stringWithFormat:@"%@/broadcasts", _mqttUserName] withQos:[_mqttQos intValue] completionHandler:^(NSArray *grantedQos) {
//                         //                         NSLog(grantedQos.description);
//                     }];
//                     [self.client subscribe:[NSString stringWithFormat:@"%@/configuration", _mqttUserName] withQos:[_mqttQos intValue] completionHandler:^(NSArray *grantedQos) {
//                         //                         NSLog(grantedQos.description);
//                     }];
//                     [self.client subscribe:[NSString stringWithFormat:@"%@/#", _mqttUserName] withQos:[_mqttQos intValue] completionHandler:^(NSArray *grantedQos) {
//                         //                         NSLog(grantedQos.description);
//                     }];
//                     //                                 [self uploadSensorData];
//                 }
//             }];
}


- (void) disconnectMqttServer{
//    if ([_client connected]) {
//        [_client disconnectWithCompletionHandler:^(NSUInteger code) {
//            NSLog(@"disconnected!");
//            [_client unsubscribe:[NSString stringWithFormat:@"%@/%@/broadcasts",_studyId,_mqttUserName] withCompletionHandler:^{
//                //
//            }];
//            [_client unsubscribe:[NSString stringWithFormat:@"%@/%@/esm", _studyId, _mqttUserName] withCompletionHandler:^{
//                //                         NSLog(grantedQos.description);
//            }];
//            [_client unsubscribe:[NSString stringWithFormat:@"%@/%@/configuration",_studyId, _mqttUserName]  withCompletionHandler:^ {
//                //                         NSLog(grantedQos.description);
//            }];
//            [_client unsubscribe:[NSString stringWithFormat:@"%@/%@/#",_studyId,_mqttUserName] withCompletionHandler:^ {
//                //                         NSLog(grantedQos.description);
//            }];
//            
//            
//            //Device specific subscribes
//            [self.client unsubscribe:[NSString stringWithFormat:@"%@/esm", _mqttUserName] withCompletionHandler:^{
//                //                         NSLog(grantedQos.description);
//            }];
//            [self.client unsubscribe:[NSString stringWithFormat:@"%@/broadcasts", _mqttUserName] withCompletionHandler:^{
//                //                         NSLog(grantedQos.description);
//            }];
//            [self.client unsubscribe:[NSString stringWithFormat:@"%@/configuration", _mqttUserName] withCompletionHandler:^ {
//                //                         NSLog(grantedQos.description);
//            }];
//            [self.client unsubscribe:[NSString stringWithFormat:@"%@/#", _mqttUserName] withCompletionHandler:^{
//                //                         NSLog(grantedQos.description);
//            }];
//            //                                 [self uploadSensorData];
//            
//        }];
//    }
}

/**
 Local push notification method
 @param message text message for notification
 @param sound type of sound for notification
 */
- (void)sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag {
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    localNotification.repeatInterval = 0;
    if(soundFlag) {
        localNotification.soundName = UILocalNotificationDefaultSoundName;
    }
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}



@end
