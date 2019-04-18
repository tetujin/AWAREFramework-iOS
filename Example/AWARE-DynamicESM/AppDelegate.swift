//
//  AppDelegate.swift
//  AWARE-DynamicESM
//
//  Created by Yuuki Nishiyama on 2019/03/28.
//  Copyright © 2019 tetujin. All rights reserved.
//
//  This is a sample application (DynamicESM) using ESM with sensor data.
//  In this example, this application sends a notification based on device usage.
//  If a user uses the phone more than 10 min in a session, this application sends
//  a push notification and survey on the phone. The survey is valid only 30 minutes.

import UIKit
import CoreData
import AWAREFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let core = AWARECore.shared()
        core.requestPermissionForBackgroundSensing {
            core.requestPermissionForPushNotification()
            core.activate()
            
            /// If user uses smartphone over 60 second,
            /// this application makes a notification as an ESM
            let deviceUsage = DeviceUsage()
            deviceUsage.startSensor()
            // set a sensor handler
            deviceUsage.setSensorEventHandler { (sensor, data) in
                if let data = data {
                    let time = data["elapsed_device_on"] as! Double
                    if time > 60.0 * 1000.0 { // 60 second
                        print("More than 60 seconds")
                        self.setSurvey()
                        self.setNotification()
                    } else {
                        print("Less than 60 seconds")
                    }
                }
            }
            
            let manager = AWARESensorManager.shared()
            manager.add(deviceUsage)
        }
        
        
        return true
    }
    
    
    func setSurvey(){
        // generate a survey
        let pam = ESMItem.init(asPAMESMWithTrigger: "pam")
        pam.setTitle("How do you feeling now?")
        pam.setInstructions("Please select an image.")

        let expireSec = TimeInterval(60*30)
        
        let schedule = ESMSchedule()
        schedule.startDate  = Date()
        schedule.endDate    = Date().addingTimeInterval(expireSec) // This ESM valid 30 min
        schedule.scheduleId = "sample_esm"
        schedule.addESM(pam)
        
        let manager = ESMScheduleManager.shared()
        if manager.getValidSchedules().count == 0 {
            manager.add(schedule)
        }
    }
    
    func setNotification(){
        // send notification
        let content = UNMutableNotificationContent()
        content.title = "Hello, how do you feeling now?"
        content.body  = "Tap to answer the question."
        content.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let notifId = UUID().uuidString
        let request = UNNotificationRequest(identifier: notifId,
                                            content: content,
                                            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            
        });
        
        // Remove the delivered notification if the time is over the expiration time
        Timer.scheduledTimer(withTimeInterval: 60.0 * 30.0, repeats: false, block: { (timer) in
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notifId])
            let iconNum = UIApplication.shared.applicationIconBadgeNumber
            if iconNum > 0 {
                UIApplication.shared.applicationIconBadgeNumber =  iconNum - 1
            }
        })
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
        // Saves changes in the application's managed object context before the application terminates.
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
        let container = NSPersistentContainer(name: "AWARE_DynamicESM")
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

