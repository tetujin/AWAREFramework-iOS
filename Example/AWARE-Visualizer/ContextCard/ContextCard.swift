//
//  ContextCardView.swift
//  Vita
//
//  Created by Yuuki Nishiyama on 2018/06/22.
//  Copyright © 2018 Yuuki Nishiyama. All rights reserved.
//

import UIKit
import Charts
import AWAREFramework

@IBDesignable class ContextCard: UIView {

    @IBOutlet weak var baseStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var indicatorView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var spaceView: UIView!
    @IBOutlet weak var indicatorHeightLayoutConstraint: NSLayoutConstraint!
    
    override init(frame:CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    
    required init(coder aCoder: NSCoder) {
        super.init(coder: aCoder)!
        setup()
    }
    
    func setup() {
        let view = Bundle.main.loadNibNamed("ContextCard", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
        
        let height = frame.height - titleLabel.frame.height - spaceView.frame.height
        // print(height)
        indicatorHeightLayoutConstraint.isActive = false
        self.heightAnchor.constraint(equalToConstant:height).isActive = true
    }
}
