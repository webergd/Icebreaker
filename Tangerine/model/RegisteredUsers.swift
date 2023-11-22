//
//  RegisteredUsers.swift
//  Tangerine
//
//  Created by Mahmudul Hasan on 2022-06-26.
//

import Foundation
// Used in NetworkManager for fetching registered users
// we are storing registered users on a db with gcloud
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
