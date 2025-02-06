//
//  AppDelegate.swift
//  AWARE-SensingApp
//
//  Created by Yuuki Nishiyama on 2019/03/28.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import CoreData
import AWAREFramework

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var sensingStatus = true

    let sensorManager = AWARESensorManager.shared()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after applicatio
        // setup AWARECore
        
        let core = AWARECore.shared()
        core.requestPermissionForBackgroundSensing { (status) in
            core.requestPermissionForPushNotification(completion: nil)
            core.activate()
            
            let study = AWAREStudy.shared()
            
            study.setCleanOldDataType(cleanOldDataTypeDaily)
            study.setDebug(true)
            study.setStudyURL("https://")
            
            
            print(study.getCleanOldDataType())
            
            
            // init sensors
//            let accelerometer = Accelerometer(awareStudy: study)
//            accelerometer.setSensingIntervalWithHz(100)
//            accelerometer.setSavingIntervalWithSecond(1)
//            (accelerometer.storage as! SQLiteSeparatedStorage).fetchSizeAdjuster.setMaxFetchSize(10);
//            accelerometer.storage?.setDebug(true)
//            (accelerometer.storage as! SQLiteSeparatedStorage).useCompactDataSyncFormat = true
            
//            let gyroscope     = Gyroscope(awareStudy: study)
//            gyroscope.setSensingIntervalWithHz(100)
//            gyroscope.setSavingIntervalWithSecond(3)
//            (gyroscope.storage as! SQLiteSeparatedStorage).fetchSizeAdjuster.setMaxFetchSize(3);
             

//            let rotation     = Rotation(awareStudy: study)
//            rotation.setSensingIntervalWithHz(100)
//            rotation.setSavingIntervalWithSecond(3)
//            (rotation.storage as! SQLiteSeparatedStorage).fetchSizeAdjuster.setMaxFetchSize(3);
//            
//            let lAccelerometer     = LinearAccelerometer(awareStudy: study)
//            lAccelerometer.setSensingIntervalWithHz(100)
//            lAccelerometer.setSavingIntervalWithSecond(3)
//            (lAccelerometer.storage as! SQLiteSeparatedStorage).fetchSizeAdjuster.setMaxFetchSize(3);
            
//            let mag = Magnetometer(awareStudy: study)
//            mag.setSensingIntervalWithHz(100)
//            mag.setSavingIntervalWithSecond(3)
//            (mag.storage as! SQLiteSeparatedStorage).fetchSizeAdjuster.setMaxFetchSize(3);
//
            
            let location = Locations(awareStudy: study)
            location.setSensingAccuracyWithMeter(0)
            location.setSensingIntervalWithSecond(1)
            location.setDebug(true)
            self.sensorManager.add(location)
            
            let headphone = HeadphoneMotion(awareStudy: study)
            headphone.setSensingIntervalWithHz(100)
            headphone.setSavingIntervalWithSecond(1)
//            (headphone.storage as! SQLiteSeparatedStorage).fetchSizeAdjuster.setMaxFetchSize(30);
            headphone.storage?.setDebug(true)
            (headphone.storage as! SQLiteSeparatedStorage).useCompactDataSyncFormat = true
            
            //            let battery       = Battery()
            //            let screen        = Screen()
            //            let call          = Calls()
            //            let ambientNoise  = AmbientNoise()
            //            let activity      = IOSActivityRecognition()
            //            let step          = Pedometer()
            //            let bluetooth     = Bluetooth()
            //            let cal           = Calendar()
            //            let healthKit     = AWAREHealthKit()
            
            // add the sensors into AWARESensorManager
//            self.sensorManager.add([accelerometer,gyroscope,rotation,lAccelerometer,mag,headphone])
            self.sensorManager.add(headphone)
            //            self.sensorManager.add([accelerometer, gyroscope, battery, screen, call, ambientNoise, activity, step, bluetooth, cal, healthKit])
//            self.sensorManager.startAllSensors()
            
            // setup ESMs
            // generate ESMItem
//            let pam = ESMItem(asPAMESMWithTrigger: "pam")
//            pam.setTitle("How do you feeling now?")
//            pam.setInstructions("Please select an image.")
//            
//            // generate ESMSchedule
//            let esm = ESMSchedule()
//            esm.scheduleId = "schedule_1"
//            esm.startDate  = Date()
//            esm.endDate    = Date().addingTimeInterval(60*60*24*31)
//            esm.fireHours  = [8,12,21]
//            esm.expirationThreshold = 60
//            esm.addESM(pam)
//            esm.notificationTitle = "Tap to answer the question."
//            
//            // add the ESMSchedules into ESMScheduleManager
//            let esmManager = ESMScheduleManager.shared()
//            esmManager.deleteAllSchedules(withNotification: true)
//            esmManager.add(esm, withNotification: true)
            
        }
        
        // monitoring battery consumption
        let center = NotificationCenter.default
        center.addObserver(forName: NSNotification.Name(rawValue: ACTION_AWARE_BATTERY_CHANGED),
                           object: nil,
                           queue: .main) { (notification) in
                            if let userInfo = notification.userInfo{
                                if let data = userInfo[EXTRA_DATA] as? Dictionary<String,Any>{
                                    // get battery level data
                                    if let level = data["battery_level"] as? Int {
                                        // stop sensor if battery level is under 30%
                                        if level <= 30 {
                                            if self.sensingStatus {
                                                self.sensorManager.stopAllSensors()
                                                self.sensingStatus = false
                                            }
                                            // restart sensor if bettery level is over 30%
                                        }else{
                                            if !self.sensingStatus {
                                                self.sensorManager.startAllSensors()
                                                self.sensingStatus = true
                                            }
                                        }
                                    }
                                }
                            }
        }
        
        AWAREEventLogger.shared().logEvent(["class":"AppDelegate",
                                            "event":"application:didFinishLaunchingWithOptions:launchOptions"])
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        AWAREEventLogger.shared().logEvent(["class":"AppDelegate",
                                            "event":"applicationWillResignActive"])
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        AWAREEventLogger.shared().logEvent(["class":"AppDelegate",
                                            "event":"applicationDidEnterBackground"])
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        AWAREEventLogger.shared().logEvent(["class":"AppDelegate",
                                            "event":"applicationWillEnterForeground"])
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        AWAREEventLogger.shared().logEvent(["class":"AppDelegate",
                                            "event":"applicationDidBecomeActive"])
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        AWAREEventLogger.shared().logEvent(["class":"AppDelegate",
                                            "event":"applicationWillTerminate"])
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "AWARE_SensingApp")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

