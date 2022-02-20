//
//  ContinueButton.swift
//  Tangerine
//
//  Created by Mahmudul Hasan on 2022-02-19.
//

import UIKit

class ContinueButton: UIButton {

    // default init
    override init(frame: CGRect){
        super.init(frame: frame)
        configure()
    }
    
    // this is a must when subclassing UIKit widgets/component
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    init(title: String){
        super.init(frame: .zero)
        self.setTitle(title, for: .normal)
        configure()
    }
    
    func configure(){
        layer.backgroundColor = UIColor.systemBlue.cgColor
        
        layer.cornerRadius = 6.0
        titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        
        self.setTitleColor(.white, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 15)
        
        // determines whether the view's autoresizign mask is translated into auto layout constrants
        self.widthAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    
}
