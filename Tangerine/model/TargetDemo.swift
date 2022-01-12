//
//  TargetDemo.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-06-25.
//

import Foundation
import RealmSwift

@objcMembers public class TargetDemo : Object, Codable{
    
    // for realm
    
    override init() {
        super.init()
    }
    
    
    internal init(straight_woman_pref: Bool = false, straight_man_pref: Bool = false, gay_woman_pref: Bool = false, gay_man_pref: Bool = false, other_pref: Bool = false, min_age_pref: Int = 18, max_age_pref: Int = 99) {
        self.straight_woman_pref = straight_woman_pref
        self.straight_man_pref = straight_man_pref
        self.gay_woman_pref = gay_woman_pref
        self.gay_man_pref = gay_man_pref
        self.other_pref = other_pref
        self.min_age_pref = min_age_pref
        self.max_age_pref = max_age_pref
    }
    
    /// Returns a generic TargetDemo object that encompasses all possible users. (all orientations set to true, age range set to min and max allowed ages)
    init(returnAllUsers: Bool = true) {
        self.straight_woman_pref = true
        self.straight_man_pref = true
        self.gay_woman_pref = true
        self.gay_man_pref = true
        self.other_pref = true
        self.other_pref = true
        self.min_age_pref = 18
        self.max_age_pref = 99
    }
    
    
    dynamic public var straight_woman_pref = false
    dynamic public var straight_man_pref = false
    dynamic public var gay_woman_pref = false
    dynamic public var gay_man_pref = false
    dynamic public var other_pref = false
    
    dynamic public var min_age_pref = 18
    dynamic public var max_age_pref = 99
    
    
}

