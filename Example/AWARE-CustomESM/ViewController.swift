//
//  ViewController.swift
//  AWARE-CustomESM
//
//  Created by Yuuki Nishiyama on 2019/04/02.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework

class ViewController: UIViewController {

    var esmAppeared = false
    
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
        esmAppeared = false
        UIApplication.shared.applicationIconBadgeNumber = 0
        checkESMSchedules()
    }
    
    func checkESMSchedules(){
        let schedules = ESMScheduleManager.shared().getValidSchedules()
        if(schedules.count > 0){
            let esmViewController = ESMScrollViewController()
            /// Generate Original ESM
            esmViewController.originalESMViewGenerationHandler = {(esm, positionY, viewController) -> BaseESMView? in
                if esm.esm_type?.intValue == 99 {
                    let height = 100.0
                    let width  = Double(viewController.view.frame.size.width)
                    let frame  = CGRect(x:0.0, y:positionY, width:width, height:height)
                    return CustomESM(frame: frame, esm: esm, viewController: viewController)
                }
                return nil
            }
            /// Handle the survey completion
            esmViewController.answerCompletionHandler = {
                self.esmAppeared = true
            }
            
            if !esmAppeared {
                self.present(esmViewController, animated: true){}
            }
        }
    }
}

