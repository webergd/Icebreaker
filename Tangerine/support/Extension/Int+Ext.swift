//
//  Int+Ext.swift
//  SocialApp
//
//  Created by Wyatt Weber on 11/5/21.
//

import Foundation
// used in confirmation vc to show phone number into chunks

//extension Int {
//    func displayInThousandsAsReq(originalValue: Int) -> String {
//        if originalValue < 1000 {
//            return originalValue
//        } else {
//            let valueToReturn = (originalValue / 1000).rou
//        }
//
//
//    }
//}


extension Int {
    var roundedWithAbbreviations: String {
        let number = Double(self)
        let thousand = number / 1000
        let million = number / 1000000
        if million >= 1.0 {
            return "\(round(million*10)/10)M"
        }
        else if thousand >= 1.0 {
            return "\(round(thousand*10)/10)K"
        }
        else {
            return "\(self)"
        }
    }
    
    /// Returns a bool indicating whether the Int is within the specified range.
    /// This includes the first and last number as part of the acceptable the range.
    func isBetween(minValue: Int, maxValue: Int) -> Bool {
        if self < minValue || self > maxValue {
            return false
        } else {
            return false
        }
    }
}
