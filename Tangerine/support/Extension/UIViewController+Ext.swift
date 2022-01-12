//
//  UIViewController+Ext.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-26.
//

import UIKit
import Contacts
import FirebaseStorage

extension UIViewController {

    
    // for present our nice little alert
    func presentDismissAlertOnMainThread(title: String, message: String) {
        DispatchQueue.main.async {
            let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
             alertVC.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
             self.present(alertVC, animated: true)
        }
    }
    
    
    
    // to dismiss the keyboard
        func hideKeyboardOnOutsideTouch() {
            let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
        }
        
        @objc func dismissKeyboard() {
            view.endEditing(true)
        }
    
    
    // String to Image
    func convertBase64StringToImage (imageBase64String:String) -> UIImage {
       
        if imageBase64String == Constants.SYS_PERSON_ICON || imageBase64String.isEmpty{
            return UIImage(systemName: Constants.SYS_PERSON_ICON)!
        }
        
        let imageData = Data.init(base64Encoded: imageBase64String, options: .init(rawValue: 0))
        var image = UIImage()
        if imageData == nil {
            // sys icon, no change of being nil
            image = UIImage(systemName: Constants.SYS_PERSON_ICON)!
        }else{
            // not nil, so force unwrapping
            image = UIImage(data: imageData!)!
        }
        return image
    }
    
    
    // this formats any number like our db format if they are in other format
    func formatNumber(_ number: String) -> String {
        if(number.count<10){
            print(number)
        }
        // no matter what the format is, from opposite, the reverse 10 digit will always be correct number
        let rev = String(number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined().reversed())
        let tenDig = rev.subString(from: 0, to: 10) // got the 10 digit
        // reverse it again to get actual number
        let finalNumber = "+1\(String(tenDig.reversed()))"
        
        return finalNumber
    }
    
    // this formats any number like our db format if they are in other format
    // this function cuts the country code for phonenumber vc
    func formatNumberWOCC(_ number: String) -> String {
        if(number.count<10){
            print(number)
        }
        // no matter what the format is, from opposite, the reverse 10 digit will always be correct number
        let rev = String(number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined().reversed())
        let tenDig = rev.subString(from: 0, to: 10) // got the 10 digit
        // reverse it again to get actual number
        let finalNumber = "\(String(tenDig.reversed()))"
        
        return finalNumber
    }
    
    // fetches the thumbnail from contact
    func getProfileImageString(_ contact: CNContact)-> String {
        
        if let data = contact.thumbnailImageData{
            return data.base64EncodedString()
        }else{
            return Constants.SYS_PERSON_ICON
        }
    }// end of get pro pic
    
    
    func getAgeFromBdaySeconds(_ seconds: Double)-> Int{
        // make the age from bday
        let cal = Calendar.current
        let ageComponent = cal.dateComponents([.year], from: Date(timeIntervalSince1970: seconds), to: Date())
        
        return ageComponent.year ?? 0
    }
    
    func presentFromRight(_ viewControllerToPresent: UIViewController) {
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.moveIn
        transition.subtype = CATransitionSubtype.fromRight
        self.view.window!.layer.add(transition, forKey: kCATransition)

        present(viewControllerToPresent, animated: false)
    }
    
    func presentFromLeft(_ viewControllerToPresent: UIViewController) {
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
        self.view.window!.layer.add(transition, forKey: kCATransition)

        present(viewControllerToPresent, animated: false)
    }

    func dismissToRight() {
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.reveal
        transition.subtype = CATransitionSubtype.fromLeft
        self.view.window!.layer.add(transition, forKey: kCATransition)
        dismiss(animated: false)
    }
    
    func dismissToLeft() {
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromRight
        self.view.window!.layer.add(transition, forKey: kCATransition)
        dismiss(animated: false)
    }
    
    
    

}


