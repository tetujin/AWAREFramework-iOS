//
//  AppDelegate.swift
//  AWARE-ScheduleESM
//
//  Created by Yuuki Nishiyama on 2019/04/03.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import CoreData
import AWAREFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let core = AWARECore.shared()
        core.requestPermissionForBackgroundSensing { (status) in
            core.requestPermissionForPushNotification(completion: nil)
            core.activate()
            
            let schedule = ESMSchedule()
            schedule.startDate  = Date()
            schedule.endDate    = Date().addingTimeInterval(60*60*24*30) // This schedule is valid 30 days
            schedule.scheduleId = "sample_esm"
            schedule.notificationBody = "Tap to answer."
            schedule.notificationTitle = "This is a scheduled ESM"
            schedule.addHours([8,12,15,18,21])
            schedule.addESMs(self.generateESMItems())
            schedule.expirationThreshold = 60 as NSNumber
            
            let manager = ESMScheduleManager.shared()
            manager.debug = true
            manager.removeAllSchedulesFromDB()
            manager.removeESMNotifications {
                manager.add(schedule)
            }
        }
        return true
    }
    
    func generateESMItems() -> Array<ESMItem>{
        /// Likert Scale
        let likert = ESMItem.init(asLikertScaleESMWithTrigger: "likert",
                                  likertMax: 5,
                                  likertMinLabel: "Good",
                                  likertMaxLabel: "Bad",
                                  likertStep: 1)
        likert.setTitle("How do you feeling now?")
        likert.setInstructions("Please select an item.")
        likert.setSubmitButtonName("Next")
        
        /// PAM
        let pam = ESMItem.init(asPAMESMWithTrigger: "pam")
        pam.setTitle("How are you feeling now?")
        pam.setInstructions("Please select an image.")
        pam.setSubmitButtonName("Next")
        
        /// Picture
        let picture = ESMItem.init(asPictureESMWithTrigger: "picture")
        picture.setInstructions("Please take a picture.")
        picture.setSubmitButtonName("Submit")
        
        /// Quick Answer (If the user selects `YES`, the Picture ESMItem will appear.)
        let quick = ESMItem.init(asQuickAnawerESMWithTrigger: "quick", quickAnswers: ["Yes","No"])
        quick.setTitle("Can you take a photo around you?")
        quick.setInstructions("Please select a button.")
        /// Set an interactive ESM which is changed flow based on a user answer if you want.
        /// This `-setFlowWith(items:answerKey:)` is applicable for all of ESMItems.
        quick.setFlowWith([picture], answerKey: ["Yes"])
        
        return [pam, likert, quick]
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
        let container = NSPersistentContainer(name: "AWARE_ScheduleESM")
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

