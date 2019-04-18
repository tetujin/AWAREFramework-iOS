//
//  AppDelegate.swift
//  AWARE-InteractiveESM
//
//  Created by Yuuki Nishiyama on 2019/04/18.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let core = AWARECore.shared()
        core.requestPermissionForBackgroundSensing {
            core.requestPermissionForPushNotification()
            core.activate()
            
            let schedule = ESMSchedule()
            schedule.startDate  = Date()
            schedule.endDate    = Date().addingTimeInterval(60*60*24*30) // This schedule is valid 30 days
            schedule.scheduleId = "sample_esm"
            schedule.notificationBody = "Tap to answer."
            schedule.notificationTitle = "This is a scheduled ESM"
            // schedule.addHours([8,12,15,18,21])
            schedule.expirationThreshold = 0
            schedule.addESMs(self.generateESMItems())
            schedule.expirationThreshold = 60 as NSNumber
            
            let manager = ESMScheduleManager.shared()
            manager.debug = true
            manager.removeAllNotifications()
            manager.removeAllSchedulesFromDB()
            manager.add(schedule)
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
        
        return [likert]
    }
}

