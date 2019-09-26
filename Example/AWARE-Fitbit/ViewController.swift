//
//  ViewController.swift
//  AWARE-Fitbit
//
//  Created by Yuuki Nishiyama on 2019/04/02.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if Fitbit.isNeedLogin() {
            let fitbit = Fitbit()
            fitbit.setDebug(true)
            
            AWARESensorManager.shared().add(fitbit)
            fitbit.startSensor()
//            fitbit.requestLogin(with: self) { (tokens) in
//                fitbit.startSensor()
//            }
        }        
    }
}

