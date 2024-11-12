//
//  ViewController.swift
//  AWARE-SensingApp
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
        
        AWARESensorManager.shared().syncAllSensorsForcefully()
    }

    override func viewDidAppear(_ animated: Bool) {
        
        AWARESensorManager.shared().syncAllSensorsForcefully()
        
        checkESMSchedules()
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (timer) in
            let manager = AWARESensorManager.shared()
            manager.setSensorEventHandlerToAllSensors { (sensor, data) in
                if let data = data {
                    let sensorName = sensor.getName()
                    // show accelerometer data
                    if SENSOR_ACCELEROMETER == sensorName {
                        if  let x = data["double_values_0"] as? Double,
                            let y = data["double_values_1"] as? Double,
                            let z = data["double_values_2"] as? Double {
                            self.accLabel.text = "\(String(format: "%.2f", x)),\(String(format: "%.2f", y)),\(String(format: "%.2f", z))"
                        }
                        // show gyroscope data
                    } else if SENSOR_GYROSCOPE == sensorName {
                        if  let x = data["double_values_0"] as? Double,
                            let y = data["double_values_1"] as? Double,
                            let z = data["double_values_2"] as? Double {
                            self.gyroLabel.text = "\(String(format: "%.2f", x)),\(String(format: "%.2f", y)),\(String(format: "%.2f", z))"
                        }
                        // show battery data
                    } else if SENSOR_BATTERY == sensorName {
                        if  let level = data["battery_level"] as? Double {
                            self.batteryLabel.text = "\(level)"
                        }
                        // show screen event
                    } else if SENSOR_SCREEN == sensorName {
                        if let status = data["screen_status"] as? Int {
                            self.screenLabel.text = "\(status)"
                        }
                    } else if SENSOR_PLUGIN_HEADPHONE_MOTION == sensorName {
//                        print(data);
//                        if  let x = data["double_values_0"] as? Double,
//                            let y = data["double_values_1"] as? Double,
//                            let z = data["double_values_2"] as? Double {
//                            print("\(String(format: "%.2f", x)),\(String(format: "%.2f", y)),\(String(format: "%.2f", z))")
//                        }
                    }
                }
            }

        }
    }
    
    @IBAction func didChangeSwitch(_ sender: UISwitch) {
        if (sender.isOn){
            AWARESensorManager.shared().startAllSensors()
        }else{
            AWARESensorManager.shared().stopAllSensors()
            AWARESensorManager.shared().setDebugToAllSensors(true)
            AWARESensorManager.shared().setSyncProcessCallbackToAllSensorStorages { sensorName, progress, a, error in
                switch (progress) {
                case .cancel:
                    print("cancel")
                case .complete:
                    print("complete")
                case .continue:
                    print("continue")
                case .error:
                    print("error")
                case .locked:
                    print("locked")
                case .unknown:
                    print("unknown")
                case .uploading:
                    print("uploading")
                @unknown default:
                    print("unknown---")
                }
                
                print(sensorName, progress.rawValue, a, error ?? "")
            }
            AWARESensorManager.shared().syncAllSensorsForcefully()
            
        }
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
            self.navigationController?.pushViewController(esmViewController, animated: true)
        }
    }
    
}

