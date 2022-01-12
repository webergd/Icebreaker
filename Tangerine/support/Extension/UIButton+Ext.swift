//
//  UIButton+Ext.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-26.
//

import UIKit

extension UIButton{
    
    func disable(){
        self.isEnabled = false
        self.backgroundColor = UIColor.systemGray.withAlphaComponent(0.7)
        
        self.layer.borderColor = UIColor.systemGray.cgColor
    }
    
    func enable(){
        self.isEnabled = true
        self.backgroundColor = UIColor.systemBlue.withAlphaComponent(1)
        
        self.layer.borderColor = UIColor.systemBlue.cgColor
    }
    
}
