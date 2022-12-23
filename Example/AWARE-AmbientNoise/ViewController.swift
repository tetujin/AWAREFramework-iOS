//
//  ViewController.swift
//  AWARE-AmbientNoise
//
//  Created by Yuuki Nishiyama on 2019/06/12.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework
import Speech

class ViewController: UIViewController {

    let noiseSensor = AmbientNoise()
    let manager = AWARESensorManager.shared()
    let core = AWARECore.shared()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // please add following lines to receive update events
        noiseSensor.setSensorEventHandler { sensor, data in
            if let d = data {
                print(d)
//                if let rms = d["double_rms"] {
//                    print(rms)
//                }
            }
        }
        
        // please add following lines to use raw audio file
        // noiseSensor.saveRawData(true)
        noiseSensor.setAudioFileGenerationHandler { url in
            if let url = url {
                print(url)
            }
        }

        // start sensors
        manager.add(noiseSensor)
        manager.startAllSensors()

        // for background sensing
        core.requestPermissionForBackgroundSensing{ state in
            print(state)
            self.core.activate()
        }
        
        
    }
}
