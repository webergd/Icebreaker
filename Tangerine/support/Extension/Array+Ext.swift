//
//  Array+Ext.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-05.
//

import Foundation

// to make any array spilit by this size
extension Array {
    func chunked(by chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}
