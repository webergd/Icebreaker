//
//  Friend.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-05.
//

import UIKit
import RealmSwift

// enum for checking if default / recent or none
@objc enum SendStatus : Int, RealmEnum{
    case DEFAULT = 1
    case RECENT = 2
    case NONE = 0
}


@objcMembers class Friend : Object{

    dynamic var imageString: String! // the photoURL or contacts pic
    
    dynamic var displayName = "User" //
    dynamic var username: String!
    dynamic var rating = 0 // many of them won't have it, so escaping nil value
    dynamic var review = 0
    
    dynamic var phoneNumberField: String! // phone number
    dynamic var dobMills : Double = 0
    
    dynamic var sendStatus : SendStatus = SendStatus.NONE
    
    override class func primaryKey() -> String? {
        return "username"
    }
    

}
