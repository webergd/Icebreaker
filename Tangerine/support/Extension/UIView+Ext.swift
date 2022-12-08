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
    
    func addShadow() {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: -1, height: 2)
        self.layer.shadowRadius = 1.8
        self.layer.shadowOpacity = 0.3
    }
    
    func addDashedBorder() {
        //first, remove any existing borders
        self.removeDashedBorder()
        
        print("addDashedBorder() called")
        let color = UIColor.separator.cgColor
        
        let shapeLayer:CAShapeLayer = CAShapeLayer()
        let frameSize = self.frame.size
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = 2
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineDashPattern = [6,3]
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 5).cgPath
        shapeLayer.name = "dashedBorder"
        
        self.layer.addSublayer(shapeLayer)
    }
    
    /// Alternative to addDashedBorder() that takes a passed frame size
    func addDashedBorder(with sideLength: CGFloat) {
        //first, remove any existing borders
        self.removeDashedBorder()
        let width: CGFloat =  sideLength
        let height:CGFloat = sideLength
        
        print("addDashedBorder() called")
        let color = UIColor.separator.cgColor
        
        let shapeLayer:CAShapeLayer = CAShapeLayer()
//        let frameSize = CGSize(width: sideLength, height: sideLength)
        let shapeRect = CGRect(x: 0, y: 0, width: width, height: height)
        
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: width/2, y: height/2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = 2
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineDashPattern = [6,3]
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 5).cgPath
        shapeLayer.name = "dashedBorder"
        
        self.layer.addSublayer(shapeLayer)
    }
    
    
    
    /// This doesn't exactly work right. It just makes the dotted line less bold. Need more experimenting. //I could potentially just move the border to the back instead of deleting. 
    func removeDashedBorder() {
//        self.layer.sublayers?.forEach { layer in
//           layer.removeFromSuperlayer()
//        }
        
        
        if let sublayers = self.layer.sublayers {

            for layer in sublayers {
                if layer.name == "dashedBorder" {
                    layer.isHidden = true
                    layer.removeFromSuperlayer()
//                    layer.borderColor = UIColor.clear.cgColor
                }
            }
        }
        
        
//        self.layer.removeFromSuperlayer()
        
        //self.layer.borderWidth = 0
    }
    
    
    /// Puts a box around the view to draw it to the user's attention
    public func addAttentionRectangle() {
        let targetControlSize: CGSize = CGSize(width: self.frame.width + 10.0, height: self.frame.height + 10.0)

        let k = DrawRectangle(frame: CGRect(
                origin: CGPoint(x: -5, y: -5),
                size: targetControlSize))

        k.backgroundColor = .clear
        k.isUserInteractionEnabled = false
        
        k.layer.name = "attentionRectangle"

        self.addSubview(k)
    }

    ///
    public func removeAttentionRectangle() {
        let subViews = self.subviews
        for sv in subViews {
            if sv.layer.name == "attentionRectangle" {
                sv.removeFromSuperview()
            }
        }
        
    }
    
    class DrawRectangle: UIView {

        override init(frame: CGRect) {
            super.init(frame: frame)
        }

        required public init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }

        override func draw(_ rect: CGRect) {

            
            guard let context = UIGraphicsGetCurrentContext() else {
                print("could not get graphics context")
                return
            }

            context.setStrokeColor(UIColor.systemBlue.cgColor)
            context.setLineWidth(5)
            context.stroke(rect.insetBy(dx: 0, dy: 0))
        }
        
    }
    
    
    

    @objc func userSwiped(_ gesture: UISwipeGestureRecognizer) {
        
            if gesture.direction == UISwipeGestureRecognizer.Direction.right {
                // go back to previous view by swiping right
                let vc: UIViewController? = self.parentViewController
                guard let vc = vc else {return}
                vc.dismissToRight()
            }
        
    }
    
    func attachDismissToRightSwipe(){
        let swipeViewGesture = UISwipeGestureRecognizer(target: self, action: #selector(userSwiped(_:)))
        self.addGestureRecognizer(swipeViewGesture)
       
    }
    
}
