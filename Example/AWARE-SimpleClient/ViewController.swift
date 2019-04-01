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
            if let sensor = sensor, let data = data {
                print(sensor.getName()!, data)
            }
        }
        
    }
    
    @IBAction func pushedManualUploadButton(_ sender: UIButton) {
        manager.setSyncProcessCallbackToAllSensorStorages { (sensorName, process, error) in
            print(sensorName!, process)
        }
        manager.syncAllSensorsForcefully()
    }
    
    @IBAction func pushedResetButton(_ sender: UIButton) {
        study.join(withURL: study.getURL()) { (settings, status, error) in
            self.manager.stopAndRemoveAllSensors()
            self.manager.addSensors(with: self.study)
            let location = Locations()
            self.manager.add(location)
            self.manager.startAllSensors()
            self.manager.startAutoSyncTimer(withIntervalSecond: 15)
        }
        
    }
    
    
}

