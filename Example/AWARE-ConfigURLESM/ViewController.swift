//
//  ViewController.swift
//  AWARE-ConfigURLESM
//
//  Created by Yuuki Nishiyama on 2019/04/08.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = "https://www.ht.sfc.keio.ac.jp/~tetujin/esm/test.json"
        
        let iOSESM = IOSESM()
        iOSESM.setDebug(true)
        iOSESM.setErrorHandler { (error) in
            print("Error")
        }
        iOSESM.startSensor(withURL: url) {
            print("Ready")
            self.checkESMSchedules()
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForegroundNotification(notification:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkESMSchedules()
    }
    
    @objc func willEnterForegroundNotification(notification: NSNotification) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        checkESMSchedules()
    }
    
    func checkESMSchedules(){
        // check valid ESMs
        let schedules = ESMScheduleManager.shared().getValidSchedules()
        if schedules.count > 0 {
            let esmViewController = ESMScrollViewController()
            esmViewController.completionAlertMessage = "Thank you!"
            self.present(esmViewController, animated: true){}
        }
    }

}

