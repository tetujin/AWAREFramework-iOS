//
//  AppDelegate.swift
//  AWARE-HealthKit
//
//  Created by Yuuki Nishiyama on 2019/07/23.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let manager = AWARESensorManager.shared()
        let study = AWAREStudy.shared()
//        study.join(withURL: "https://api.awareframework.com/index.php/webservice/index/2560/mvmt1hQgGqb2", completion: { (settings, status, error) in
//
//            let healthKit = AWAREHealthKit(awareStudy: study)
//            healthKit.fetchIntervalSecond = 180;
//
//            let tenDaysAge = Date().addingTimeInterval(-1*60*60*24*10)
//            healthKit.setLastFetchTimeForAll(tenDaysAge)
//
//            manager.add(healthKit)
//            manager.createDBTablesOnAwareServer()
//            manager.startAllSensors()
//            healthKit.setDebug(true)
//        })
        
        let healthKit = AWAREHealthKit(awareStudy: study)
        healthKit.requestAuthorization { result, error in
            
            healthKit.fetchIntervalSecond = 180;
            healthKit.setDebug(true)
            let tenDaysAge = Date().addingTimeInterval(-1*60*60*24*10)
            healthKit.setLastFetchTimeForAll(tenDaysAge)
            
            
            manager.add(healthKit)
            manager.createDBTablesOnAwareServer()
            manager.startAllSensors()
        }
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { (timer) in
            
            DispatchQueue.main.async {
                let manager = AWARESensorManager.shared()
                manager.setSyncProcessCallbackToAllSensorStorages({ (sensorName, state, progress, error)  in
                    NSLog(sensorName, progress);
                })
                manager.syncAllSensorsForcefully()
            }
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

