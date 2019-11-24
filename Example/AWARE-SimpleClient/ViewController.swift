//
//  ViewController.swift
//  AWARE-SimpleClient
//
//  Created by Yuuki Nishiyama on 2019/03/30.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework

class ViewController: UIViewController {

    let manager = AWARESensorManager.shared()
    let study   = AWAREStudy.shared()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        manager.setSensorEventHandlerToAllSensors { (sensor, data) in
            if let data = data {
                print(sensor.getName()!, data)
            }
        }
        
    }
    
    @IBAction func pushedManualUploadButton(_ sender: UIButton) {
        manager.setSyncProcessCallbackToAllSensorStorages { (sensorName, status, process, error)  in
            print(sensorName, status, process)
        }
        manager.syncAllSensorsForcefully()
    }
    
    @IBAction func pushedResetButton(_ sender: UIButton) {
        
        if let studyURL = study.getURL(){
            study.join(withURL: studyURL) { (settings, status, error) in
                
                self.manager.stopAndRemoveAllSensors()
                
                self.manager.addSensors(with: self.study)
                
                /// [Option]
                // let location = Locations()
                // self.manager.add(location)
                
                self.manager.startAllSensors()
                self.manager.startAutoSyncTimer(withIntervalSecond: 15)
            }
        }
    }
}

