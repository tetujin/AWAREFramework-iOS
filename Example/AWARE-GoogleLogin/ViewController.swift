//
//  ViewController.swift
//  AWARE-GoogleLogin
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
        let gLogin = GoogleLogin()
        if gLogin.isNeedLogin() {
            let gLoginViewController = AWAREGoogleLoginViewController()
            gLoginViewController.googleLogin = gLogin
            self.present(gLoginViewController, animated: true) {}
        }
    }

}

