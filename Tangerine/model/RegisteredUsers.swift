//
//  RegisteredUsers.swift
//  Tangerine
//
//  Created by Mahmudul Hasan on 2022-06-26.
//

import Foundation

struct Root: Codable{
    let status: Bool!
    let message: String!
    let data: [RegisteredUsers]?
}

struct RegisteredUsers: Codable {
    let username: String!
    let phone: String!
    let entryID: Int!
}
