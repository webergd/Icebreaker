//
//  UILabel+Ext.swift
//  SocialApp
//
//  Created by Wyatt Weber on 10/6/21.
//


import UIKit

extension UILabel {
    
    
    /// Causes label to delay x seconds after the fadeInAfter call is made, then fade into view.
    func fadeInAfter(seconds: Double, completion: () -> Void) {
        self.alpha = 0.0
        self.isHidden = false
        self.layer.cornerRadius = 5.0
        self.layer.masksToBounds = true
        
        //run loop that slowly increases Alpha of the label
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            UIView.animate(withDuration: 0.5, animations: {
                self.alpha = 1.0
//                self.backgroundColor = UIColor.white.withAlphaComponent(0.7)
            })
        }
    }
    
    func fadeInAfter(seconds: Double) {
        self.fadeInAfter(seconds: seconds) {
            // no completion
        }
    }
    
    
    /// Causes label to display for x seconds. Stays alpha of 1.0 for the specified time then fades out over another 1.5 seconds.
    func fadeOutAfter(seconds: Double) {
        self.isHidden = false
        self.alpha = 1.0
        
        //run loop that slowly reduces Alpha of the label
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            UIView.animate(withDuration: 0.5, animations: {
                self.alpha = 0.0
            }) {_ in
                // Once Alpha is zero, hide the label
                self.isHidden = true
            }
        }
    }
}
