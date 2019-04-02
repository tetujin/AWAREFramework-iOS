//
//  ViewController.swift
//  AWARE-DynamicESM
//
//  Created by Yuuki Nishiyama on 2019/03/28.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework

class ViewController: UIViewController {

    @IBOutlet weak var accLabel: UILabel!
    @IBOutlet weak var gyroLabel: UILabel!
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var screenLabel: UILabel!
    
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
        // check valid ESMs
        let schedules = ESMScheduleManager.shared().getValidSchedules()
        if schedules.count > 0 {
            let esmViewController = ESMScrollViewController()
            
            // set an original ESM generation handler
            esmViewController.originalESMViewGenerationHandler = {(esm, bottomESMViewPositionY, viewController) -> BaseESMView? in
//                if esm.esm_type?.intValue == 99 {
//                    let height = 100.0
//                    let width  = Double(viewController.view.frame.size.width);
//                    return BaseESMView.init(frame: CGRect(x:0.0, y:bottomESMViewPositionY, width:width, height:height),
//                                            esm: esm,
//                                            viewController: viewController)
//                }
                return nil
            }
            
            // set a answer completion handler
            esmViewController.answerCompletionHandler = {
                // delete the schedule when the answer is completed
                ESMScheduleManager.shared().deleteSchedule(withId: "sample_esm")
            }
            
            self.present(esmViewController, animated: true){}
        }
    }
}

