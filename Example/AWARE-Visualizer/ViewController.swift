//
//  ViewController.swift
//  AWARE-Visualizer
//
//  Created by Yuuki Nishiyama on 2019/04/03.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework

class ViewController: UIViewController {
    
    var card:ScatterChartCard? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        reloadContextCard()
    }
    
    @IBAction func pushedRefreshButton(_ sender: Any) {
        reloadContextCard()
    }
    
    func reloadContextCard(){
        if let c = self.card {
            c.removeFromSuperview()
            self.card = nil
        }
        
        let manager = AWARESensorManager.shared()
        if let sensor = manager.getSensor(SENSOR_AMBIENT_NOISE) {
            self.card = ScatterChartCard(frame: CGRect(x:0,
                                                       y:0,
                                                       width: self.view.frame.width,
                                                       height: 400))
            self.card?.setTodaysChart(sensor: sensor, keys: ["double_rms"])
            self.card?.titleLabel.text = "Ambient Noise"
            self.card?.isUserInteractionEnabled = false
            self.view.addSubview(self.card!)
            self.card?.baseStackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor,  constant: 0).isActive  = true
            self.card?.baseStackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0).isActive = true
            
//            sensor.storage.fetchTodaysData { (sensorName, data, start, end, error) in
//                DispatchQueue.main.async {
//
//                }
//            }
            
        }
    }
}

