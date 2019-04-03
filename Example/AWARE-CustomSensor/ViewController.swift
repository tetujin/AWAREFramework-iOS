//
//  ViewController.swift
//  AWARE-CustomSensor
//
//  Created by Yuuki Nishiyama on 2019/04/02.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func pushedExportDB(_ sender: UIButton) {
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        var activityItems = Array<URL>();
        activityItems.append(URL(fileURLWithPath: documentPath))
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
    
}

