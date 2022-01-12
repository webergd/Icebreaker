//
//  Review.swift
//  Tangerine
//
//  Created by Wyatt Weber on 7/8/20.
//  Copyright © 2020 Insightful Inc. All rights reserved.
//
//  REVIEW
//  This file contains several structures, all relating to the idea of a user reviewing another user's Question and giving them feedback
//  The isAReview protocol enabled us to treat AskReviews and Compare reviews interchangeably in many situations.
//  AskReview and CompareReview are so similar, it could be tempting to merge them into one object type "Review." Thus far they have been kept separate for 2 reasons:
//      1. So that the .yes/.no selection and the .top/.bottom selection can be separate which makes the code more readable than TRUE or FALSE which has to be interpreted.
//      2. So that we can add additional features to these review types. Strong Yes/No is a possible example since in a CompareReview we are rating 2 photos. Are they both Strong or only one of them?
// Report is fairly self explanatory and still needs to be full implemented.
// ReviewID is a Tuple for keeping track of specific reviews.

import Foundation
import UIKit

// During normal app operation this is not used. Only on deleting a Questions should its reviews be entered into the reviewArchives table
// The reason for this is to store potentially useful data for follow on monetization.
var reviewArchivesArray: [isAReview] = [] // Nothing done with this thus far....

/// a "Review" is a protocol that governs AskReview's and CompareReview's
///      NOTE: To get the usernName of the reviewer, you must read review.reviewer.username.     reviewerName is the DISPLAY name. 
public protocol isAReview {
    var reviewID: ReviewID {get}
    var reviewerName: String {get} // this is displayName, NOT USERNAME
    var reviewerOrientation: String {get}
    var reviewerAge: Int {get}
    var comments: String {get set}
    var reviewer: Profile {get set}

    // MARK: We will need to implement a dateCreated field at some point also
    // as of now, knowing when the Question was created is good enough.
}

/// ReviewID is a Tuple for indentifying of specific reviews containing the reviewer's username and the reviewed question's questionName. No two reviews will have the same ReviewID. Normally when accessing this property, we only need to access one of the fields at the present time, and the other field can be deduced based on context.
public struct ReviewID {
    let questionName: String
    let reviewerUserName: String //this is just the reviewer's username
}

public struct Report : Codable{
    var type: reportType
    var questionName: String
    // MARK: Will eventually need a String to hold a comment.
}

/// These are the different reasons for reporting a Question as inappropriate.
public enum reportType: String, CaseIterable, Codable {
    case nudity = "Nudity"
    case demeaning = "Demeaning Content"
    case notRelevant = "Not Relevant"
    case other = "Other"
    case cancel = "Cancel" //Used in the drop down menu. Not an actual report type.
    
    
    
    
}

/// an "AskReview" is a review of an Ask from a single individual.
/// AskReviews are held in an array of AskReviews that is part of the Ask.
/// This array is known as the Ask's "reviewCollection"
public struct AskReview: isAReview {
    
    public var reviewID: ReviewID
    var selection: yesOrNo
    var strong: yesOrNo?
    public var reviewer: Profile
    public var reviewerName: String {return reviewer.display_name }
    public var reviewerOrientation: String { return reviewer.orientation }
    public var reviewerAge: Int { getAgeFromBdaySeconds(reviewer.birthday) }
    public var comments: String
    
    /// For new AskReviews created by localMyUser
    init(selection sel: yesOrNo, strong strg: yesOrNo?, comments c: String, questionName: String) {
        selection = sel
        strong = strg
        reviewer = RealmManager.sharedInstance.getProfile()
        comments = c
        reviewID = ReviewID(questionName: questionName, reviewerUserName: reviewer.username)
    }
    
    /// For AskReviews created by others downloaded from the database
    init(selection selString: String, strong strongString: String?, reviewer: Profile, comments: String, questionName: String){
        
        // checking to ensure it's not something besides a .yes/.no is accomplished in the method that calls this. There is probably a more robust way to refactor.
        switch selString {
        case "yes": self.selection = .yes
        default: self.selection = .no
        }
        
        switch strongString {
        case "yes": strong = .yes
        case "no": strong = .no
        default: strong = nil
        }

        self.reviewer = reviewer
        self.comments = comments

        reviewID = ReviewID(questionName: questionName, reviewerUserName: reviewer.username)
    }

}


func getAgeFromBdaySeconds(_ seconds: Double)-> Int{
    // make the age from bday
    let cal = Calendar.current
    let ageComponent = cal.dateComponents([.year], from: Date(timeIntervalSince1970: seconds), to: Date())
    
    return ageComponent.year ?? 0
}

// a "CompareReview" is a review of an Compare from a single individual
// CompareReviews are held in an array of CompareReviews that is part of the Compare.
// This array is known as the Compare's "reviewCollection"

public struct CompareReview: isAReview {
    
    public var reviewID: ReviewID
    var selection: topOrBottom
    var strongYes: Bool
    var strongNo: Bool
    public var reviewer: Profile
    public var reviewerName: String {return reviewer.display_name }
    public var reviewerOrientation: String { return reviewer.orientation }
    public var reviewerAge: Int { getAgeFromBdaySeconds(reviewer.birthday) }
    public var comments: String
    
    /// For new CompareReviews created by localMyUser, that we are sending to Firebase
    init(selection sel: topOrBottom, strongYes strgY: Bool, strongNo strgN: Bool, comments c: String, questionName: String) {
        selection = sel
        strongYes = strgY
        strongNo = strgN
        comments = c
        reviewer = RealmManager.sharedInstance.getProfile()
        reviewID = ReviewID(questionName: questionName, reviewerUserName: reviewer.username)

    }
    
    /// For CompareReviews created by others downloaded from the database
    init(selection selString: String, strongYes strgY: Bool, strongNo strgN: Bool, reviewer: Profile, comments: String, questionName: String) {
        
        switch selString {
        case "top": self.selection = .top
        default: self.selection = .bottom
        }
        
        strongYes = strgY
        strongNo = strgN
        
        self.comments = comments
        self.reviewer = reviewer

        reviewID = ReviewID(questionName: questionName, reviewerUserName: reviewer.username)
    }
    
}
