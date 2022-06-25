//
//  Section.swift
//  Bazaarface
//
//  Created by Mahmudul Hasan on 2022-06-19.
//

import Foundation

struct Section: Hashable {
    let category: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(category)
    }
    
    func headerTitleText(count: Int = 0) -> String {
        guard count > 0 else {
            return category.uppercased()
        }
        return "\(category) (\(count))".uppercased()
    }
}
