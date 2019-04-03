//
//  CustomESM.swift
//  AWARE-CustomESM
//
//  Created by Yuuki Nishiyama on 2019/04/02.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework

class CustomESM: BaseESMView {
    
    var button:UIButton?
    
    var isPushed = false
    
    override init!(frame: CGRect, esm: EntityESM!, viewController: UIViewController!) {
        
        button = UIButton(frame: CGRect.init(x: 0, y: 0, width: frame.size.width, height: 100))
        
        super.init(frame: frame, esm: esm, viewController: viewController)
        
        button?.setTitle("Push Me!", for: .normal)
        button?.setTitleColor(.blue , for: .normal)
        button?.addTarget(self, action: #selector(buttonEvent(_:)), for: UIControl.Event.touchUpInside)
        self.mainView.addSubview(button!)
        self.refreshSizeOfRootView()
    }
    
    @objc func buttonEvent(_ sender: UIButton) {
        if !isPushed {
            button?.setTitle("Pushed", for: .normal)
            isPushed = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        // fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
    }
    
    override func getUserAnswer() -> String! {
        if isPushed {
            return "pushed"
        }else{
            return "not pushed"
        }
    }

}
