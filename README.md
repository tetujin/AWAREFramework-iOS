# AWAREFramework

[![CI Status](http://img.shields.io/travis/tetujin/AWAREFramework.svg?style=flat)](https://travis-ci.org/tetujin/AWAREFramework)
[![Version](https://img.shields.io/cocoapods/v/AWAREFramework.svg?style=flat)](http://cocoapods.org/pods/AWAREFramework)
[![License](https://img.shields.io/cocoapods/l/AWAREFramework.svg?style=flat)](http://cocoapods.org/pods/AWAREFramework)
[![Platform](https://img.shields.io/cocoapods/p/AWAREFramework.svg?style=flat)](http://cocoapods.org/pods/AWAREFramework)

[AWARE](http://www.awareframework.com/) is iOS and Android framework dedicated to instrument, infer, log and share mobile context information, for application developers, researchers and smartphone users. AWARE captures hardware-, software-, and human-based data (ESM). They transform data into information you can understand.

## Supported Sensors
* Accelerometer
* Gyroscope
* Magnetometer
* Gravity
* Rotation
* Motion Activity
* Pedometer
* Location
* Barometer
* Battery
* Network
* Call
* Bluetooth
* Processor
* Proximity
* Timezone
* Wifi
* Screen Events
* Microphone (Ambient Noise)
* Heartrate (BLE)
* Calendar
* Contact
* [Fitbit](https://dev.fitbit.com/)
* [Google Login](https://developers.google.com/identity/sign-in/ios/)
* Memory
* [NTPTime](https://github.com/jbenet/ios-ntp)
* [OpenWeatherMap](https://openweathermap.org/api)

## Example Apps
* [SensingApp](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-SensingApp)
* [SimpleClient](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-SimpleClient)
* [RichClient (aware-client-ios-v2)](https://github.com/tetujin/aware-client-ios-v2)
* [DynamicESM](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-DynamicESM)
* [ScheduleESM](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-ScheduleESM)
* [CustomESM](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-CustomESM)
* [CustomSensor](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-CustomSensor)
* [Visualizer](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-Visualizer)

## How To Use

To run the example project, clone the repo, and run `pod install` from the Example directory first.

### Example 1: Initialize sensors and save sensor data to the local database
Just the following code, your application can collect sensor data in the background. The data is saved in a local-storage.
```objective-c
/// Example1 (Objective-C): Accelerometer ///
Accelerometer * accelerometer = [[Accelerometer alloc] init];
[accelerometer setSensorEventHandler:^(AWARESensor *sensor, NSDictionary *data) {
    NSLog(@"%@",data.debugDescription);
}];
[accelerometer startSensor];
```
```swift
/// Example1  (Swift): Accelerometer ///
let accelerometer = Accelerometer()
accelerometer.setSensorEventHandler { (sensor, data) in
    print(data)
}
accelerometer.startSensor()
```
### Example 2: Sync local-database and AWARE Server

AWARECore, AWAREStudy, and AWARESensorManager are singleton instances for managing sensing/synchronization schedule in the library. You can access the instances via AWAREDelegate. The AWAREDelegate is described in the Installation section.  
```objective-c
AWARECore  * core  = [AWARECore sharedCore];
AWAREStudy * study = [AWAREStudy sharedStudy];
AWARESensorManager * manager = [AWARESensorManager sharedSensorManager];
```

```swift
let core    = AWARECore.shared()
let study   = AWAREStudy.shared()
let manager = AWARESensorManager.shared()
```

AWAREFramework-iOS allows us to synchronize your application and AWARE server by adding a server URL to AWAREStudy. About AWARE server, please check our [website](http://www.awareframework.com/).

```objective-c
/// Example2 (Objective-C): Accelerometer + AWARE Server ///
[study setStudyURL:@"https://api.awareframework.com/index.php/webservice/index/STUDY_ID/PASS"];
Accelerometer * accelerometer = [[Accelerometer alloc] initWithStudy:study];
[accelerometer startSensor];

[accelerometer startSyncDB]; 
// or
[manager addSensor:accelerometer];
```
```swift
/// Example2 (Swift): Accelerometer + AWARE Server ///
study.setStudyURL("https://api.awareframework.com/index.php/webservice/index/STUDY_ID/PASS")
let accelerometer = Accelerometer(awareStudy: study)
accelerometer.startSensor()
accelerometer.startSyncDB()
// or
manager.add(accelerometer)
```

### Example 3: Apply settings on AWARE Dashboard

Moreover, this library allows us to apply the settings on AWARE Dashboard by using -joinStuyWithURL:completion method.


```objective-c
/// Example3 (Objective-C): AWARE Dashboard ////
NSString * url = @"https://api.awareframework.com/index.php/webservice/index/STUDY_ID/PASS";
[study joinStudyWithURL:url completion:^(NSArray *settings, AwareStudyState state, NSError * _Nullable error) {
    [manager addSensorsWithStudy:study];
    [manager startAllSensors];
}];

```
```swift
/// Example3 (Swift): AWARE Dashboard ////
let url = "https://api.awareframework.com/index.php/webservice/index/STUDY_ID/PASS"
study.join(withURL: url, completion: { (settings, studyState, error) in
    manager.addSensors(with: study)
    manager.startAllSensors()
})
```

## Installation

AWAREFramework is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'AWAREFramework', :git=>'https://github.com/tetujin/AWAREFramework-iOS.git'
```

First, add permissions on Xcode for the background sensing (NOTE: the following permissions are minimum requirements)

* Info.plist
    * Privacy - Location Always and When In Use Usage Description
    * Privacy - Location Always Usage Description
![Image](./Screenshots/info_plist_location.png)

* Capabilities/Background Modes
    * Location updates
![Image](./Screenshots/background_modes.png)

Second, inherit AWAREDelegate at AppDelegate (or equivalent method) as follows.

Objective-C
```objective-c
/// AppDelegate.h ///
@import UIKit;
@import AWAREFramework;

@interface AppDelegate: AWAREDelegate <UIApplicationDelegate>

@end
```
```objective-c
/// AppDelegate.m ///
#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    AWARECore * core = [AWARECore sharedCore];
    [core activate];
    return YES;
}

@end
```

Swift
```swift
import UIKit
import AWAREFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate{

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        super.application(application, didFinishLaunchingWithOptions: launchOptions)
        let core = AWARECore.shared()
        core.activate()
        return true
    }
}
```

Finally, call permission requests for the location sensor when the app is opened in first time. (e.g., -viewDidLoad on UIViewController)

Objective-C
```objective-c
AWARECore * core = [AWARECore sharedCore];
[core requestPermissionForBackgroundSensing]; // for background sensing
[core requestPermissionForPushNotification]; // for notifications
```
    
Swift    
```swift
let core = AWARECore.shared()
core.requestPermissionForBackgroundSensing{
    core.requestPermissionForPushNotification()
}
```

## Experience Sampling Method (ESM)

This library supports ESM. The method allows us to make questions in your app at certain times.   The following code shows to a radio type question at 9:00, 12:00, 18:00, and 21:00 every day as an example. Please access our website for learning more information about the ESM.

```objective-c
/// Objective-C: Initialize an ESMSchedule ///
ESMSchedule * schedule = [[ESMSchedule alloc] init];
schedule.notificationTitle   = @"notification title";
schedule.notificationBody    = @"notification body";
schedule.scheduleId          = @"schedule_id";
schedule.expirationThreshold = @60;
schedule.startDate           = [NSDate now];
schedule.endDate             = [[NSDate alloc] initWithTimeIntervalSinceNow:60*60*24*10];
schedule.fireHours           = @[@9,@12,@18,@21];

/// Make an ESMItem ///
ESMItem * radio = [[ESMItem alloc] initAsRadioESMWithTrigger:@"1_radio"
radioItems:@[@"A",@"B",@"C",@"D",@"E"]];
[radio setTitle:@"ESM title"];
[radio setInstructions:@"some instructions"];

/// Add the ESMItem to ESMSchedule ///
[schedule addESMs:@[radio]];

/// Add the ESMSchedule to ESMScheduleManager ///
ESMScheduleManager * esmManager = [ESMScheduleManager sharedESMScheduleManager];
[esmManager addSchedule:schedule];
```

```swift
/// Swift ///
let schdule = ESMSchedule()
schdule.notificationTitle   = "notification title"
schdule.notificationBody    = "notification body"
schdule.scheduleId          = "schedule_id"
schdule.expirationThreshold = 60
schdule.startDate           = Date.init()
schdule.endDate             = Date.init(timeIntervalSinceNow: 60*60*24*10)
schdule.fireHours           = [9,12,18,21]

let radio = ESMItem(asRadioESMWithTrigger: "1_radio", radioItems: ["A","B","C","D","E"])
radio.setTitle("ESM title")
radio.setInstructions("some instructions")
schdule.addESM(radio)

let esmManager = ESMScheduleManager.shared()
// esmManager.removeAllNotifications()
// esmManager.removeAllESMHitoryFromDB()
// esmManager.removeAllSchedulesFromDB()
esmManager.add(schdule)
```

Please call the following chunk of code for appearing ESMScrollViewController (e.g., at -viewDidAppear: ).

```objective-c
/// Objective-C: check valid ESMs and show ESMScrollViewController ///
ESMScheduleManager * esmManager = [ESMScheduleManager sharedESMScheduleManager];
NSArray * schdules = [esmManager getValidSchedules];
if (schdules.count > 0) {
    /** initialize ESMScrollView */
    ESMScrollViewController * esmView  = [[ESMScrollViewController alloc] init];
    /** move to ESMScrollView */
    [self presentViewController:esmView animated:YES completion:nil];
    /** or, following code if your project using Navigation Controller */
    // [self.navigationController pushViewController:esmView animated:YES];
}
```
```swift
/// Swift ///
let schedules = ESMScheduleManager.shared().getValidSchedules() {
if(schedules.count > 0){
    let esmViewController = ESMScrollViewController()
    self.present(esmViewController, animated: true){}
}

```

### Supported ESM Types
This library supports 16 typs of ESMs.  You can see the screenshots from the [link](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Screenshots/esms)

*  Text
*  Radio
*  Checkbox
*  Likert Scale
*  Quick Answer
*  Scale
*  DateTime
*  PAM
*  Numeric
*  Web
*  Date
*  Time
*  Clock
*  Picture
*  Audio
*  Video

## Author

Yuuki Nishiyama <yuuki.nishiyama@oulu.fi>

## License

AWAREFramework is available under the Apache2 license. See the LICENSE file for more info.
