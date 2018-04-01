//
//  Orientation.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/22/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "Orientation.h"

NSString * const AWARE_PREFERENCES_STATUS_ORIENTATION = @"status_orientation";
NSString * const AWARE_PREFERENCES_FREQUENCY_ORIENTATION = @"frequency_orientation";
NSString * const AWARE_PREFERENCES_FREQUENCY_HZ_ORIENTATION = @"frequency_hz_orientation";

@implementation Orientation{
    NSString * KEY_ORIENTATION_TIMESTAMP;
    NSString * KEY_ORIENTATION_DEVICE_ID;
    NSString * KEY_ORIENTATION_STATUS;
    NSString * KEY_ORIENTATION_LABEL;
}

/** Initializer */
- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_ORIENTATION];
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_ORIENTATION
                             storage:storage];
    if (self) {
        KEY_ORIENTATION_TIMESTAMP = @"timestamp";
        KEY_ORIENTATION_DEVICE_ID = @"device_id";
        KEY_ORIENTATION_STATUS = @"orientation_status";
        KEY_ORIENTATION_LABEL = @"label";
        // [self setCSVHeader:@[KEY_ORIENTATION_TIMESTAMP,KEY_ORIENTATION_DEVICE_ID,KEY_ORIENTATION_STATUS,KEY_ORIENTATION_LABEL]];
    }
    return self;
}

- (void) createTable {
    NSMutableString * query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", KEY_ORIENTATION_TIMESTAMP]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_ORIENTATION_DEVICE_ID]];
    [query appendString:[NSString stringWithFormat:@"%@ integer default 0,", KEY_ORIENTATION_STATUS]];
    [query appendString:[NSString stringWithFormat:@"%@ text default ''", KEY_ORIENTATION_LABEL]];
    // [query appendString:@"UNIQUE (timestamp,device_id)"];
    // [super createTable:query];
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void)setParameters:(NSArray *)parameters{
    
}

- (BOOL) startSensor{
    //    [self setBufferSize:5];
    
    // Start and set an orientation monitoring
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    return YES;
}


// Stop sensor
- (BOOL)stopSensor{
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIDeviceOrientationDidChangeNotification
                                                object:nil];
    return YES;
}


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

// https://happyteamlabs.com/blog/ios-using-uideviceorientation-to-determine-orientation/

// 0 = UIDeviceOrientationUnknown,
// 1 = UIDeviceOrientationPortrait,            // Device oriented vertically, home button on the bottom
// 2 = UIDeviceOrientationPortraitUpsideDown,  // Device oriented vertically, home button on the top
// 3 = UIDeviceOrientationLandscapeLeft,       // Device oriented horizontally, home button on the right
// 4 = UIDeviceOrientationLandscapeRight,      // Device oriented horizontally, home button on the left
// 5 = UIDeviceOrientationFaceUp,              // Device oriented flat, face up
// 6 = UIDeviceOrientationFaceDown             // Device oriented flat, face down

- (void) orientationDidChange: (id) sender {
    NSNumber * deviceOrientation = @0;
    NSString * label = @"";
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationUnknown:
            deviceOrientation = @0;
            label = @"unknown";
            break;
        case UIDeviceOrientationPortrait:
            deviceOrientation = @1;
            label = @"portrait";
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            deviceOrientation = @2;
            label = @"portrait_upside_down";
            break;
        case UIDeviceOrientationLandscapeLeft:
            deviceOrientation = @3;
            label = @"land_scape_left";
            break;
        case UIDeviceOrientationLandscapeRight:
            deviceOrientation = @4;
            label = @"land_scape_right";
            break;
        case UIDeviceOrientationFaceUp:
            deviceOrientation = @5;
            label = @"face_up";
            break;
        case UIDeviceOrientationFaceDown:
            deviceOrientation = @6;
            label = @"face_down";
            break;
        default:
            deviceOrientation = @0;
            label = @"unknown";
            break;
    }
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_ORIENTATION_TIMESTAMP];
    [dict setObject:[self getDeviceId] forKey:KEY_ORIENTATION_DEVICE_ID];
    [dict setObject:deviceOrientation forKey:KEY_ORIENTATION_STATUS];
    [dict setObject:label forKey:KEY_ORIENTATION_LABEL];
    [self setLatestValue:label];
    // [self saveData:dict];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:YES];
    [self setLatestData:dict];
    
    SensorEventCallBack callback = [self getSensorEventCallBack];
    if (callback!=nil) {
        callback(dict);
    }
}

@end
