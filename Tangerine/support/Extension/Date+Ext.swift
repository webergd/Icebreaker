//
//  Date+Ext.swift
//  Tangerine
//
//  Created by Mahmudul Hasan on 2023-02-19.
//

import Foundation

extension Date {
    func convertToBFDateFormat()->String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy HH:MM a"

        return dateFormatter.string(from: self)
    }
}
