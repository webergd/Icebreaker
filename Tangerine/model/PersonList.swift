//
//  PersonList.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-27.
//

import Foundation
import RealmSwift


// This class holds the connection_list value from firestore
// the collectionList docID is the username
// and it holds the rest 3 data
@objcMembers class PersonList : Object{
    
    dynamic var username: String!
    dynamic var profile_pic: String! // the photoURL or contacts pic
    
    dynamic var display_name: String! //
    dynamic var status : Status = Status.NONE
    
    override class func primaryKey() -> String? {
        return "username"
    }
    
}
