//
//  AppDelegate.swift
//  AWARE-JSONStorage
//
//  Created by Yuuki Nishiyama on 2019/09/24.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        AWARECore.shared().requestPermissionForBackgroundSensing { (status) in
            AWARECore.shared().activate()
            
            AWAREStudy.shared().setStudyURL("https://api.awareframework.com/index.php/webservice/index/1947/Op1dc3cTy41y")
            
            // let acc = Accelerometer(awareStudy: AWAREStudy.shared(), dbType: AwareDBTypeJSON)
            let acc = Accelerometer(awareStudy: AWAREStudy.shared(), dbType: AwareDBTypeCSV)
            acc.startSensor()
            acc.storage?.setDebug(true)
            
            acc.storage?.startSyncStorage(callback: { (name, status, progress, error) in
                print(name,status,progress,error)
            })
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

