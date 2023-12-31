//
//  Profile.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-24.
//

import Foundation
import RealmSwift
import Firebase

// Contains information about YOU
// as the name suggests
@objcMembers public class Profile : Object{

    
    override init() {
        super.init()
    }
    
    dynamic var pid = 0
    
    dynamic var birthday : Double = 0
    dynamic var display_name = ""
    dynamic var username = ""
    
    dynamic var profile_pic = ""
    dynamic var reviews = 0
    dynamic var rating : Double = 0
    dynamic var reviewCredits: Int = 0
    dynamic var lastReviewedTime: Int64 = 0 // we'll turn into timestamp by FieldValue
    
    dynamic var created : Int64 = 0 // Later Turns into Timestamp by firebase function and we save as seconds in RealmManager, see LoginVC
    dynamic var orientation = Constants.ORIENTATIONS.last!
    dynamic var phone_number = ""
    dynamic var isSeeder = false
    
    override public class func primaryKey() -> String? {
        return "pid"
    }
    
    
    
    internal init(pid: Int = 0, birthday: Double = 0, display_name: String = "", username: String = "", profile_pic: String = "", reviews: Int = 0, rating: Double = 0, created: Int64 = 0, orientation: String = "Other", phone_number: String = "", isSeeder: Bool) {
        self.pid = pid
        self.birthday = birthday
        self.display_name = display_name
        self.username = username
        self.profile_pic = profile_pic
        self.reviews = reviews
        self.rating = rating
        self.created = created
        self.orientation = orientation
        self.phone_number = phone_number
        self.isSeeder = isSeeder
    }
}
