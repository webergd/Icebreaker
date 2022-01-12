//
//  UIPickerView+Ext.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-03.
//

import UIKit

extension UIPickerView {
    func disable(){
        self.isUserInteractionEnabled = false
        self.alpha = 0.7
        
    }
    
    func enable(){
        self.isUserInteractionEnabled = true
        self.alpha = 1
    }
}
