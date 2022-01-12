//
//  Person.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-27.
//

import Foundation
import RealmSwift

// an enum for friend status check

@objc public enum Status : Int, RealmEnum{
    case REQUESTED = 1 // I added
    case INVITED = 2 // I invited
    case BLOCKED = 3// I blocked
    case FRIEND = 4// We are connected
    case PENDING = 5// He added
    case REGISTERED = 6 // registered with app
    case GOT_BLOCKED = 7 // he blocked
    case NONE = 0// match nothing
    
    var description: String {
        switch self {
                case .REQUESTED:
                    return "REQUESTED"
                case .INVITED:
                    return "INVITED"
                case .BLOCKED:
                    return "BLOCKED"
                case .FRIEND:
                    return "FRIEND"
                case .PENDING:
                    return "PENDING"
                case .REGISTERED:
                    return "REGISTERED"
                case .GOT_BLOCKED:
                    return "GOT_BLOCKED"
                case .NONE:
                    return "NONE"
                }
        }
}

// a Person is the class that shows our Contact List
@objcMembers class Person : Object{

    dynamic var imageString: String! // the photoURL or contacts pic
    
    dynamic var displayName = "Tap to invite me to Tangerine!" // default for iOS contacts
    dynamic var username: String!
    dynamic var phoneNumberField = "0" // phone number

    
    dynamic var status : Status = Status.NONE
    
    override class func primaryKey() -> String? {
        return "username"
    }
    
}

//xxrandomguy
