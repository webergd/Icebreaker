//
//  ReviewCollection.swift
//  Tangerine
//
//  Created by Wyatt Weber on 7/8/20.
//  Copyright © 2020 Insightful Inc. All rights reserved.
//
//  A ReviewCollection's primary purpose is to hold Reviews and aggregate info regarding the contents of those Reviews.
//  Every Question (Ask or Compare) has a ReviewCollection.

import Foundation
import UIKit




public class ReviewCollection {
    var reviewCollectionType: askOrCompare
    var reviews: [isAReview]
    
    /// Creates an empty RC
    init(type: askOrCompare) {
        reviews = [] //keep in mind, this is empty, not optional
        reviewCollectionType = type
    }
    
    /// This initializer is for reviewCollections downloaded from firestore for the localMyUser's Questions
    init(reviewList: [isAReview], type: askOrCompare){
        reviews = reviewList
        reviewCollectionType = type
    }
    
    /// Returns a Bool indicating whether or not the passed Review was created by a reviewer whose age and orientation fall within the constraints of the specified targetDemo.
    func inTargetDemo(review: isAReview) -> Bool {
        
        let myTargetDemo = RealmManager.sharedInstance.getTargetDemo()
        
        if review.reviewerAge <= myTargetDemo.min_age_pref || review.reviewerAge >= myTargetDemo.max_age_pref {
            return false // skips the rest of the code in this method
        }
        
        
        //  static let ORIENTATIONS = ["Straight Woman","Straight Man","Lesbian","Gay Man","Other"]
        
        // This switch statement checks which orientation the reviewer was, and if we are trying to pull from that demographic, it returns true (since we already know they are in the appropriate age range)
        
        switch review.reviewerOrientation {
        case Constants.ORIENTATIONS[0]:
            if myTargetDemo.straight_woman_pref {return true}
        case Constants.ORIENTATIONS[1]:
            if myTargetDemo.straight_man_pref {return true}
        case Constants.ORIENTATIONS[2]:
            if myTargetDemo.gay_woman_pref {return true}
        case Constants.ORIENTATIONS[3]:
            if myTargetDemo.gay_man_pref {return true}
            // the reviewer was in the age range but was not in any of my preferred orientations
        default:
            return false
        }
        return false
    }
    
    
    /// Returns an array of reviews that belong to the specified sortType (targetDemo, friends, allUsers). Some reviews can belong to multiple sortTypes, for example, a reviewer could be in the local user's targetDemo, as well as friends with the local user. In that case the review could be in all 3 sortTypes because the revier is also a member of allUsers.
    func filterReviews(by sortType: dataFilterType) -> [isAReview] {
        var filteredReviewsArray: [isAReview] = []
        var index: Int = 0
        switch sortType {
        case .allUsers: return self.reviews
        case .targetDemo:
            for review in reviews {
                if self.inTargetDemo(review: review) {
                    print("appending a \(String(describing: review.reviewerOrientation)) to the array")
                    filteredReviewsArray.append(review)
                }
                index += 1
            }
        case .friends:
            for review in reviews {
                if friends(with: review.reviewer.username) {
                    filteredReviewsArray.append(review)
                }
                index += 1
            }
        }
        
        return filteredReviewsArray
    }
    /// Returns aggregated data within the age and orientation demographic specified in the arguments:
    func pullConsolidatedAskData(requestedDemo: TargetDemo, friendsOnly: Bool) -> ConsolidatedAskDataSet {
        
        let lowestAge: Int = requestedDemo.min_age_pref
        let highestAge: Int = requestedDemo.max_age_pref
        let straightWomen: Bool = requestedDemo.straight_woman_pref
        let straightMen: Bool = requestedDemo.straight_man_pref
        let gayWomen: Bool = requestedDemo.gay_woman_pref
        let gayMen: Bool = requestedDemo.gay_man_pref
        let other: Bool = requestedDemo.other_pref
        
        //  MARK: Friends Only filter not yet implemented //
        // What I forsee for this is to create/call a function that checks to see if a review is from a friend (likely by searching a friend list for this specific user name) and then in the loop where we look at each review, if friendsOnly is true, call the friend search function on each review to decide whether we should count it or not It will be similar to the Demo switch but will have to either be encompassing it, or bypassing it separately. Because if I want all my friends, I don't care if they are 90 years old or straight or female or whatever so what's the point in checking if they are.
        
        // These are doubles so we can do fraction math on them without them rounding automatically to zero
        var countYes: Double = 0.0
        var countNo: Double = 0.0
        
        var countStrongYes: Double = 0.0
        var countStrongNo: Double = 0.0
        
        var countAge: Double = 0.0
        
        var countSW: Double = 0.0
        var countSM: Double = 0.0
        var countGW: Double = 0.0
        var countGM: Double = 0.0
        var countOT: Double = 0.0
        
    reviewLoop: for r in reviews {
        let review = r as! AskReview //this way we can access all properties of an AskReview
        
        // the isTargetDemo method could be incorporated into this method to shorten/sugar it
        
        // This guard statement skips this iteration if review is outside the selected age
        guard review.reviewerAge >= lowestAge && review.reviewerAge <= highestAge else {
            continue reviewLoop // sends us back to the top of the loop
        }
        
        
        // If we're looking for just friends, check if the reviewer is in the myFriendNames list and if they aren't abort this iteration ("continue" is misleading) and jump back to the top of the loop to look at th next review.
        if friendsOnly {
            guard friends(with: review.reviewer.username) else {
                continue reviewLoop // sends us back to the top of the loop
            }
        }
        
        
        // This switch statement checks which orientation demo the reviewer was, and if we aren't
        //  trying to pull from that demo, we go back to the beginning of the for loop.
        // If we are trying to pull from that demo, we increment that demo's count and move on.
        switch review.reviewerOrientation {
        case Constants.ORIENTATIONS[0]:
            if straightWomen == false {continue reviewLoop}
            countSW += 1
        case Constants.ORIENTATIONS[1]:
            if straightMen == false {continue reviewLoop}
            countSM += 1
        case Constants.ORIENTATIONS[2]:
            if gayWomen == false {continue reviewLoop}
            countGW += 1
        case Constants.ORIENTATIONS[3]:
            if gayMen == false {continue reviewLoop}
            countGM += 1
        case Constants.ORIENTATIONS[4]:
            if other == false {continue reviewLoop}
            countOT += 1
            
        default:
            continue reviewLoop
        }
        
        countAge += Double(review.reviewerAge) // we just add up all the ages for now, divide them out later
        
        switch review.selection {
        case .yes: countYes += 1 //counted a yes
        case .no: countNo += 1 // counted a no
        }
        
        // We need this because the strong property is optional.
        // Basically, if strong is nil, we'll increment neither.
        if let strong = review.strong {
            switch strong {
            case .yes: countStrongYes += 1
            case .no: countStrongNo += 1
            }
        }
        
    }
        
        let countReviews = countYes + countNo
        
        if countReviews > 0 {
            return ConsolidatedAskDataSet(percentYes: Int(100 * (countYes / countReviews)),
                                          percentStrongYes: Int(100 * countStrongYes / countReviews),
                                          percentStrongNo: Int(100 * countStrongNo / countReviews),
                                          averageAge: (countAge / countReviews),
                                          percentSW: Int(100 * countSW / countReviews),
                                          percentSM: Int(100 * countSM / countReviews),
                                          percentGW: Int(100 * countGW / countReviews),
                                          percentGM: Int(100 * countGM / countReviews),
                                          percentOT: Int(100 * countOT / countReviews),
                                          numReviews: Int(countReviews))
        } else {
            // Return zeros if there are no reviews yet
            return ConsolidatedAskDataSet(percentYes: 0,
                                          percentStrongYes: 0,
                                          percentStrongNo: 0,
                                          averageAge: 0.0,
                                          percentSW: 0,
                                          percentSM: 0,
                                          percentGW: 0,
                                          percentGM: 0,
                                          percentOT: 0,
                                          numReviews: 0)
        }
    }
    
    
    /// Returns aggregated data within the age and orientation demographic specified in the arguments:
    func pullConsolidatedCompareData(requestedDemo: TargetDemo, friendsOnly: Bool)-> ConsolidatedCompareDataSet {
        
        let lowestAge: Int = requestedDemo.min_age_pref
        let highestAge: Int = requestedDemo.max_age_pref
        let straightWomen: Bool = requestedDemo.straight_woman_pref
        let straightMen: Bool = requestedDemo.straight_man_pref
        let gayWomen: Bool = requestedDemo.gay_woman_pref
        let gayMen: Bool = requestedDemo.gay_man_pref
        let other: Bool = requestedDemo.other_pref
        
        
        
        //  MARK: Friends Only filter not yet implemented //
        //  See pullConsolidatedAskData method for lengthier comment on this //
        
        var countTop: Double = 0.0
        var countBottom: Double = 0.0
        
        var countStrongYesTop: Double = 0.0
        var countStrongYesBottom: Double = 0.0
        var countStrongNoTop: Double = 0.0
        var countStrongNoBottom: Double = 0.0
        
        var countAge: Double = 0.0
        
        var countSW: Double = 0.0
        var countSM: Double = 0.0
        var countGW: Double = 0.0
        var countGM: Double = 0.0
        var countOT: Double = 0.0
        
    reviewLoop: for r in reviews {
        let review = r as! CompareReview //this way we can access all properties of a CompareReview
        
        // This guard statement skips this iteration if review is outside the selected age
        guard review.reviewerAge >= lowestAge && review.reviewerAge <= highestAge else {
            continue reviewLoop // sends us back to the top of the loop
        }
        
        // If we're looking for just friends, check if the reviewer is in the myFriendNames list and if they aren't abort this iteration ("continue" is misleading) and jump back to the top of the loop to look at th next review.
        if friendsOnly {
            guard friends(with: review.reviewer.username) else {
                continue reviewLoop // sends us back to the top of the loop
            }
        }
        
        // This switch statement checks which orientation demo the reviewer was, and if we aren't trying to pull from that demo, we go back to the beginning of the for loop.
        // If we are trying to pull from that demo, we increment that demo's count and move on.
        switch review.reviewerOrientation {
        case Constants.ORIENTATIONS[0]:
            if straightWomen == false {continue reviewLoop}
            countSW += 1
        case Constants.ORIENTATIONS[1]:
            if straightMen == false {continue reviewLoop}
            countSM += 1
        case Constants.ORIENTATIONS[2]:
            if gayWomen == false {continue reviewLoop}
            countGW += 1
        case Constants.ORIENTATIONS[3]:
            if gayMen == false {continue reviewLoop}
            countGM += 1
        case Constants.ORIENTATIONS[4]:
            if other == false {continue reviewLoop}
            countOT += 1
        default:
            // MARK: Need to implement functionality to count the .other category also. It was a late addition and is not captured in much of the data analysis yet. (Though it does currently work if we're checking in a review is from the targetDemographic.
            continue reviewLoop
        }
        
        countAge += Double(review.reviewerAge) // we just add up all the ages for now, divide them out later
        
        switch review.selection {
        case .top:
            countTop += 1 //counted a top
            if review.strongYes == true {countStrongYesTop += 1}
            if review.strongNo == true {countStrongNoBottom += 1}
        case .bottom:
            countBottom += 1 //counted a bottom
            if review.strongYes == true {countStrongYesBottom += 1}
            if review.strongNo == true {countStrongNoTop += 1}
        }
        
    }
        
        let countReviews = countTop + countBottom
        
        // Strong No functionality is not fully implemented as of now. We need to decide if it's "too mean" or "negative," or if customers actually want this.
        
        if countReviews > 0 {
            
            return ConsolidatedCompareDataSet(countTop: Int(countTop),countBottom: Int(countBottom),percentTop: Int(100 * countTop / countReviews),
                                              percentStrongYesTop: Int(100 * countStrongYesTop / countReviews),
                                              percentStrongYesBottom: Int(100 * countStrongYesBottom / countReviews),
                                              //percentStrongNoTop: Int(100 * countStrongNoTop / countReviews),
                                              //percentStrongNoBottom: Int(100 * countStrongNoBottom / countReviews),
                                              averageAge: (Double(countAge / countReviews)),
                                              percentSW: Int(100 * countSW / countReviews),
                                              percentSM: Int(100 * countSM / countReviews),
                                              percentGW: Int(100 * countGW / countReviews),
                                              percentGM: Int(100 * countGM / countReviews),
                                              percentOT: Int(100 * countOT / countReviews),
                                              numReviews: Int(countReviews))
            
            
        } else {
            return ConsolidatedCompareDataSet(countTop: Int(countTop),
                                              countBottom: Int(countBottom),
                                              percentTop: 0,
                                              percentStrongYesTop: 0,
                                              percentStrongYesBottom: 0,
                                              //percentStrongNoTop: 0,
                                              //percentStrongNoBottom: 0,
                                              averageAge: 0,// consider returning -1 or some indicator for label to display NA
                                              percentSW: 0,
                                              percentSM: 0,
                                              percentGW: 0,
                                              percentGM: 0,
                                              percentOT: 0,
                                              numReviews: 0)
        }
    }
    
    func calcTangerineScore(inputs: TangerineScoreInputs, requestedDemo: TargetDemo) -> TangerineScore {
        // Unpack inputs
        //        /// Determines the "weight" of the TangerineScore weighted average for the targetDemo sortType
        //        let tdWeight = inputs.tdWeight
        //        /// Determines the "weight" of the TangerineScore weighted average for the friends sortType
        //        let fWeight = inputs.fWeight
        //        /// Determines the "weight" of the TangerineScore weighted average for the allReviewers sortType
        //        let arWeight = inputs.arWeight
        //
        //        var tdScore: Double = 0.0
        //        var fScore: Double = 0.0
        //        var arScore: Double = 0.0
        
        /// Used as the yes count for the top image in compares
        var weightedYesCount: Double = 0.0
        /// Used as the yes count for the bottom image in compares (you can also think of it as "No's" for the top image
        var weightedNoCount: Double = 0.0
        
        // Iterate through all the reviews
    reviewLoop: for r in reviews {
        
        /// Holds all the "bumps" that we give the review baseed on how valuable we deem it to be.
        var reviewWeightedValue: Double = 10.0 // we subtract 1 point for every 10 years of age distance. By starting at 11, we ensure the weighted value can never be negative, because even if someone is 90 years off, (which is bascially impossible already, especially while limiting users to 18-99 years old), the value will still be positive and the review will still count for something.
        // in the future we could possibly allow this to go negative if we want to view a specific user or type of user's inoput as negative (as in "tell me to do the opposite of whatever x person said" haha
        
        
        // Add points for being in the orientation of TD
        if inTargetOrientation(targetDemo: requestedDemo, orientation: r.reviewerOrientation) {
            reviewWeightedValue += inputs.orientationBump
        }
        
        // AGE DISTANCE: Subtract points based on how far out of TD the reviewer's age is. If reviewer is in the TD, points subtracted will be zero.
        var pointsToSubtractForAgeDist = 0.0
        
        let ageDistance = Double(ageDistance(of: r.reviewerAge, from: requestedDemo.min_age_pref, to: requestedDemo.max_age_pref))
        
        // value is set to zero if the age distance is less than the extraAgeDistanceThreshold, which is currently 20)
        let extraAgeDistance = max(ageDistance - inputs.extraAgeDistanceThreshold, 0.0)
        
        // emphasizes small age distance differences (like getting a 36 year old when you wanted a 25 year old) but minimizes large age distances (when you wanted a 25 year old, a 65 year old is not that much better than a 90 year old)
        pointsToSubtractForAgeDist = ((ageDistance - extraAgeDistance) + (0.5 * extraAgeDistance)) * inputs.ageSubtractionMultiplier
        
        // subtract the amount
        reviewWeightedValue -= pointsToSubtractForAgeDist
        
        // END OF AGE DISTANCE
        
        // Add points for the review coming from a friend
        if friends(with: r.reviewerName) {
            reviewWeightedValue += inputs.friendBump
        }
        
        if reviewCollectionType == .ask {
            let askReview = r as! AskReview //this way we can access all properties of an AskReview
            switch askReview.selection {
            case .yes: weightedYesCount += reviewWeightedValue
            case .no: weightedNoCount += reviewWeightedValue
            }
        } else {
            let compareReview = r as! CompareReview //this way we can access all properties of an CompareReview
            switch compareReview.selection {
            case .top: weightedYesCount += reviewWeightedValue
            case .bottom: weightedNoCount += reviewWeightedValue
            }
        }
    }
        /// calculates the percent of total weight that is YES, then multiplies by 5 to get a number from 0.0 to 5.0
        let rawScore: Double = (weightedYesCount / (weightedYesCount + weightedNoCount)) * 5.0
        
        return TangerineScore(rawScore: rawScore, numReviews: self.reviews.count)
    }
    
    
}





