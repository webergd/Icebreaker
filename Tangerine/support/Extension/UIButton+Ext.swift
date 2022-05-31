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
    
    /// NOT CURRENTLY WORKING
    /// Sets the button's background color.
    /// There is no organic function to do this, only set background image.
    /// This creates an image of the color you specify and adds it to the button.
    func setBackgroundColor(_ color: UIColor, forState controlState: UIControl.State) {
        let colorImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in
            color.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 1, height: 1)).fill()
        }
        setBackgroundImage(colorImage, for: controlState)
    }

    
}
