# AWAREFramework

[![CI Status](http://img.shields.io/travis/tetujin/AWAREFramework.svg?style=flat)](https://travis-ci.org/tetujin/AWAREFramework)
[![Version](https://img.shields.io/cocoapods/v/AWAREFramework.svg?style=flat)](http://cocoapods.org/pods/AWAREFramework)
[![License](https://img.shields.io/cocoapods/l/AWAREFramework.svg?style=flat)](http://cocoapods.org/pods/AWAREFramework)
[![Platform](https://img.shields.io/cocoapods/p/AWAREFramework.svg?style=flat)](http://cocoapods.org/pods/AWAREFramework)

[AWARE](http://www.awareframework.com/) is an OS and Android framework dedicated to instrument, infer, log and share mobile context information, for application developers, researchers and smartphone users. AWARE captures hardware-, software-, and human-based data. They transform data into information you can understand.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


Just the following code, your application can collect sensor data in the background.

Objective-C:
```objective-c
/// Example: Accelerometer ///
Accelerometer * accelerometer = [[Accelerometer alloc] init];
[accelerometer startSensor];
[accelerometer setSensorEventCallBack:^(NSDictionary *data) {
    NSLog(@"%@",data.debugDescription);
}];
```

Swift:
```swift
coming soon
```

In addition, you can connect your application to AWARE server for collecting data remotely. About AWARE server, please check our [website](http://www.awareframework.com/).

Objective-C:
```objective-c
/// Example: Accelerometer + AWARE Server ///
AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
AWAREStudy * study = delegate.sharedAWARECore.sharedAwareStudy;
[study setWebserviceServer:@"https://api.awareframework.com/index.php/webservice/index/STUDY_ID/PASS"];

Accelerometer * accelerometer = [[Accelerometer alloc] initWithStudy:study];
[accelerometer startSensor];

[accelerometer startSyncDB]; // NOTE: By using this method, the sync is called only one time. To syncing continuously, you need to use AWARESensorManager or call the method yourself using NSTimer.
```

Swift:
```swift
coming soon
```

## Requirements
* More than iOS 10

## Installation

1. AWAREFramework is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'AWAREFramework', :git=>'https://github.com/tetujin/AWAREFramework-iOS.git'
```

2. Add permissions on Xcode for the background sensing (NOTE: the following permissions are minimum requirements)

    * Info.plist
        * Privacy - Location Always and When In Use Usage Description
       * Privacy - Location Always Usage Description

    * Capabilities/Background Modes
       * Location updates

3. For collecting your activities data in the background, your AppDelegate needs to succeed AWAREDelegate class.

Objective-C
```objective-c
/// AppDelegate.h ///
@import UIKit;
@import AWAREFramework;

@interface AWAREFrameworkAppDelegate: AWAREDelegate <UIApplicationDelegate>

@end
```
```objective-c
/// AppDelegate.m ///
#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [super applicationWillResignActive:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [super applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [super applicationWillEnterForeground:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [super applicationDidBecomeActive:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [super applicationWillTerminate:application];
}

@end
```

Swift
```swift
coming soon
```

4. Your application needs to call permission request for the location sensor using following code when the application is opened first time. 

Objective-C
```objective-c
AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
AWARECore * core = delegate.sharedAWARECore;
[core requestBackgroundSensing];
```
    
Swift    
```swift
coming soon
```

5. All set

## How to use


## Author

tetujin, tetujin@ht.sfc.keio.ac.jp

## License

AWAREFramework is available under the Apache2 license. See the LICENSE file for more info.
