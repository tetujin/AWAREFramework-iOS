//
//  ViewController.swift
//  AWARE-InteractiveESM
//
//  Created by Yuuki Nishiyama on 2019/04/18.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        // Check valid ESMs
        let schedules = ESMScheduleManager.shared().getValidSchedules()
        if schedules.count > 0 {
            // Generate a ViewController
            let esmViewController = ESMScrollViewController()
            // Set an ESM completion handler
            esmViewController.setESMCompletionHandler { (answer) in
                if answer.esm_trigger     == "likert" &&
                   answer.esm_user_answer == "3"{
                    let item = ESMItem.init(asTextESMWithTrigger: "text")
                    item.setTitle("Why did you select the number?")
                    esmViewController.insertNextESM(item)
                }
            }
            // Move to the ViewController
            self.present(esmViewController, animated: true){}
        }
    }

}

