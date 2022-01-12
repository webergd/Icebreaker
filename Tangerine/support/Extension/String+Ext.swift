//
//  String+Ext.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-27.
//

import Foundation

// to substring a text

// used in confirmation vc to show phone number into chunks
extension String {
    func subString(from: Int, to: Int) -> String {
       let startIndex = self.index(self.startIndex, offsetBy: from)
       let endIndex = self.index(self.startIndex, offsetBy: to)
       return String(self[startIndex..<endIndex])
    }
}
