//
//  Question.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-05-06.
//

import Foundation
import Firebase

/// Converts the Int version of the Question type into the string type. 1 = .ASK and 2 = .COMPARE
public enum QType : Int, Codable{
    case ASK = 1
    case COMPARE = 2
   
    var description: String {
        switch self {
            case .ASK:
                return "ASK"
            case .COMPARE:
                return "COMPARE"
        }
    }
}


enum SwipeStatus: Int, Codable{
    case RIGHT = 1
    case LEFT = 2
    case REPORT = 0
    
    var description: String {
        switch self {
            case .RIGHT:
                return "RIGHT"
            case .LEFT:
                return "LEFT"
            case .REPORT:
                return "REPORT"
        }
    }
}


public protocol isQuestion{
    /// Fields common to all Questions
    var question_name: String { get set }
    // will be the name of user
    var creator: String { get set }
    
    // target demo
    //var targetDemo: TargetDemo {get set}
    
    /// type of question
    var type: QType { get set}
    var isLocked: Bool {get set}
    
    /// cloud function will fill this
    var created: Int64 { get set}
    /// persons getting the questions, default empty
    //var recipients: List<String>  { get set}// ie usersSentTo
    //var q_reviewed: List<String> {get set} // person reviewed this question, helps on filter
    /// number of reports, default zero, no report
    var reports: Int { get set}
    /// number of reviews, default zero
    var reviews: Int { get set}
    /// is in circulation? Default true
    var is_circulating: Bool { get set}
    
}



public class Question : Codable, isQuestion{

    public var question_name: String = ""
    
    public  var creator: String = ""
    
    // Realm ask it to be optional, object must be optional in realm
    public var targetDemo : TargetDemo?
    
    public var type: QType = .ASK
    
    public var isLocked: Bool = true
    
    
    public var created: Int64 = 0
    
    var recipients = [String]()
    
    var usersNotReviewedBy = [String]()
    
    public var reports: Int = 0
    
    public var reviews: Int = 0
    
    public var is_circulating: Bool = false
    
    //
    //    // ONLY FOR LOCAL
    //    weak var reviewCollection: ReviewCollection?
    //
    
    // for ASK, use only 1 set of the below fields
    // for Compare
    
    dynamic var title_1 = ""
    dynamic var imageURL_1 = ""
    dynamic var captionText_1 = ""
    dynamic var yLoc_1 : Double = 0.0
    
    dynamic var title_2 = ""
    dynamic var imageURL_2 = ""
    dynamic var captionText_2 = ""
    dynamic var yLoc_2 : Double = 0.0
    
    
    // the generic one
    
    init(firebaseDict: [String:Any]) {
        
        self.question_name = firebaseDict["question_name"] as! String
        self.creator = firebaseDict["creator"] as! String
        
        
        let tdMap = firebaseDict["targetDemo"] as! [String:Any]
        
        // make the TD
        self.targetDemo = TargetDemo(straight_woman_pref: tdMap["straight_woman_pref"] as! Bool, straight_man_pref: tdMap["straight_man_pref"] as! Bool, gay_woman_pref: tdMap["gay_woman_pref"] as! Bool, gay_man_pref: tdMap["gay_man_pref"] as! Bool, other_pref: tdMap["other_pref"] as! Bool, min_age_pref: tdMap["min_age_pref"] as! Int, max_age_pref: tdMap["max_age_pref"] as! Int)
        

        self.type = QType(rawValue: firebaseDict["type"] as! Int) ?? .ASK
//        print("just converted \(question_name).type from Int in firestore to a string on the client")
//        print("int value was \(firebaseDict["type"] as! Int)")
//        print("converted string value was \(self.type)")
        
        self.isLocked = firebaseDict["isLocked"] as? Bool ?? true
        
        let createdTime = firebaseDict["created"] as? Timestamp ?? Timestamp(date: Date())
        
        self.created = createdTime.seconds
        
        let recipientsArray = firebaseDict[Constants.QUES_RECEIP_KEY] as! [String]
        
        var rlist = [String]()
        rlist.append(contentsOf: recipientsArray)
        
        
        self.recipients = rlist
        
        
        if let usersNotReviewedArray = firebaseDict[Constants.QUES_USERS_NOT_REVIEWED_BY_KEY] as? [String]{
        var unrList = [String]()
        unrList.append(contentsOf: usersNotReviewedArray)
            
        self.usersNotReviewedBy = unrList
        }else{
            print("error unwrapping downloaded usersNotReviewedBy list for \(self.question_name). \nStored an empty array to it instead: [String]()")
            self.usersNotReviewedBy = [String]()
        }
        
        
        self.reports = firebaseDict["reports"] as! Int
        self.reviews = firebaseDict["reviews"] as! Int
        self.is_circulating = firebaseDict["is_circulating"] as! Bool
        
        self.title_1 = firebaseDict["title_1"] as! String
        self.imageURL_1 = firebaseDict["imageURL_1"] as! String
        self.captionText_1 = firebaseDict["captionText_1"] as! String
        self.yLoc_1 = firebaseDict["yLoc_1"] as! Double
        
        self.title_2 = firebaseDict["title_2"] as! String
        self.imageURL_2 = firebaseDict["imageURL_2"] as! String
        self.captionText_2 = firebaseDict["captionText_2"] as! String
        self.yLoc_2 = firebaseDict["yLoc_2"] as! Double
    }
    
    
    
    // Ask
    
    internal init(question_name: String, title_1: String = "", imageURL_1: String = "", captionText_1: String = "", yLoc_1: Double = 0.0, creator: String, recipients: [String]) {
        
        // save defaults
        self.question_name = question_name
        self.targetDemo = RealmManager.sharedInstance.getTargetDemo()
        self.created = Int64(Date().timeIntervalSince1970) // fill by cloud function
        self.reports = 0
        self.reviews = 0
        self.is_circulating = true
        
        
        self.title_1 = title_1
        self.imageURL_1 = imageURL_1
        self.captionText_1 = captionText_1
        self.yLoc_1 = yLoc_1
        
        self.creator = creator
        self.type = QType.ASK
        self.recipients = recipients
        self.usersNotReviewedBy = [String]()
    }
    
    // Compare
    internal init(question_name: String, title_1: String = "", imageURL_1: String = "", captionText_1: String = "", yLoc_1: Double = 0.0, title_2: String = "", imageURL_2: String = "", captionText_2: String = "", yLoc_2: Double = 0.0, creator: String, recipients: [String]) {
        
        // save defaults
        self.question_name = question_name
        self.targetDemo = RealmManager.sharedInstance.getTargetDemo()
        self.created = Int64(Date().timeIntervalSince1970) // fill by cloud function
        self.reports = 0
        self.reviews = 0
        self.is_circulating = true
        
        self.title_1 = title_1
        self.imageURL_1 = imageURL_1
        self.captionText_1 = captionText_1
        self.yLoc_1 = yLoc_1
        self.title_2 = title_2
        self.imageURL_2 = imageURL_2
        self.captionText_2 = captionText_2
        self.yLoc_2 = yLoc_2
        
        
        self.creator = creator
        self.type = QType.COMPARE
        self.recipients = recipients
        self.usersNotReviewedBy = [String]()
    }
    

    
}


