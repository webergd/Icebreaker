//
//  UITableViewCell+Ext.swift
//  Tangerine
//
//  Created by Mahmudul Hasan on 2022-02-06.
//

import Foundation
import UIKit

extension UIView {
    // to show the loading
    private var loadingIndicator : UIActivityIndicatorView {
        get {
            let loadingIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
            loadingIndicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
            loadingIndicator.center = CGPoint(x: self.frame.width / 2, y: self.frame.height/2)
            let myTag = Int("1234\(self.tag)5678")
            // add a tag with respect to the calling view
            loadingIndicator.tag = myTag!
            addSubview(loadingIndicator)
            
            return loadingIndicator
        }
    }
    
    func showActivityIndicator(){
        self.loadingIndicator.startAnimating()
    }
    
    func hideActivityIndicator(){
        let myTag = Int("1234\(self.tag)5678")
        if let indicator = viewWithTag(myTag!){
            indicator.removeFromSuperview()
        }
    }
    
}
