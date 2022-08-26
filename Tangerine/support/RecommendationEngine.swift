//
//  RecommendationEngine.swift
//  Tangerine
//
//  Created by Wyatt Weber on 8/23/22.
//

import Foundation
import UIKit
import Firebase
import RealmSwift

/// The purpose of this class is to house the functions that generate two types of output:
/// 1. A TangerineScore which is a double (rounded to one decimal place) from 0.0 to 5.0 and represents the degree to which this app "thinks" the user should choose the item in question.
///     ex: a score of 5.0 is the most certain Tangerine can be that someone should choose an item while a score of 0.0 is the most certain Tangerine can be that the user should REJECT the item. A score of 2.5 is the LEAST CERTAIN about either choice that Tangerine can be.
/// 2. An ActionRec(ommendation) which is a String enum that can be one of 3 possbilities: Reject, Uncertain, Accept
public class RecomendationEngine {
    
    // for now, this lets us access the values of the TangerineScoreInputs fields throughout the app, since they are all default constants at this point anyway, and not user-specific
    public let tangerineScoreInputs = TangerineScoreInputs()
    
    init() {
        // there are no properties to initialize at this point. There will be later as we give members more control over how thier TangerineScores are calculated
    }
    
//    /// Determines the "weight" of the TangerineScore weighted average for the targetDemo sortType
//    let tdWeight: Double = 3.0
//    /// Determines the "weight" of the TangerineScore weighted average for the friends sortType
//    let fWeight: Double = 1.25
//    /// Determines the "weight" of the TangerineScore weighted average for the allReviewers sortType
//    let arWeight: Double = 1.0
//
//
//    // this is a computed property because Swift won't allow the source values to be used before a class instance is created
//    var coeffcientTotalsToDivideBy: Double {
//        return tdWeight + fWeight + arWeight
//    }
    

    
    // Our first attempt at generating a TangerineScore
    // One question is whether we should take in these objects or just the ReviewCollection itself
    //   another question is whether we feed these data sets to the Class itself - I'm leaning toward no on that
//    public func calcTangerineScore(targetDemoDataSet: isConsolidatedDataSet, friendsDataSet: isConsolidatedDataSet, allReviewersDataSet: isConsolidatedDataSet) -> TangerineScore {
//        let weightedTD = targetDemoDataSet.rating * tdWeight
//        let weightedF = friendsDataSet.rating * fWeight
//        let weightedAR = allReviewersDataSet.rating
//        
//        // MARK: This is going to be fucked up if any of these scores are not defined ie no reviews from that sortType yet. Need to account for that possiblity.
//        let rawValueToStore: Double = (weightedTD + weightedF + weightedAR) / coeffcientTotalsToDivideBy
//        
//        let tangerineScore: TangerineScore = TangerineScore(rawScore: rawValueToStore)
//        return tangerineScore
//    }
//
//    public func calcRecommendation(tS: TangerineScore) -> decisionRec {
//        switch tS.score {
//        case 0.0...highestRejectLimit.score: return .reject
//        case highestRejectLimit.score...lowestAcceptLimit.score: return .uncertain
//        case lowestAcceptLimit.score...5.0: return .accept
//        default: return .uncertain //probably could use some better error handling here
//        }
//    }
    
}

/// A TangerineScore is a double (rounded to one decimal place) from 0.0 to 5.0 and represents the degree to which this app "thinks" the user should choose the item in question. It also has a field for the number of reviews that went into calculating the score.
public struct TangerineScore {
    var rawScore: Double
    
    var numReviews: Int
    
    var score: Double {
        switch rawScore {
        case ..<0.0: return 0.0
        case  0.0...5.0: return rawScore.roundToPlaces(1)
        default: return 5.0
        }
    }
    
    /// score value converted to percent
    var scoreAsPercent: Int {
        let decimalPercent: Double = ((score / 5.0) * 100.0).roundToPlaces(0)
        return Int(decimalPercent)
    }
    
    var percentTop: Int {
        return scoreAsPercent
    }
    
    /// Also though of as percentAgainst for Asks
    var percentBottom: Int {
            return 100 - scoreAsPercent
    }
    
    // initializer for generic TangerineScore where numReviews is irrelevant
    init(rawScore: Double) {
        self.rawScore = rawScore
        self.numReviews = 0
    }
    
    init(rawScore: Double, numReviews: Int) {
        self.rawScore = rawScore
        self.numReviews = numReviews
    }
}

/// Stores the weighted coefficients used to calculate the Tangerine Score. As we give the user more control over these, we will need to initialize this object differently and in more complex ways.
/// This struct is basically a json that holds all the constants pertaining to the TangerineScore
public struct TangerineScoreInputs {
//    /// Determines the "weight" of the TangerineScore weighted average for the targetDemo sortType
//    let tdWeight: Double = 3.0
//    /// Determines the "weight" of the TangerineScore weighted average for the friends sortType
//    let fWeight: Double = 1.25
//    /// Determines the "weight" of the TangerineScore weighted average for the allReviewers sortType
//    let arWeight: Double = 1.0
    

    /// points added for being in orientation of the TargetDemo
    let orientationBump: Double = 8.0
    /// points to be subtracted for each year of age distance outside the target demo. Value is POSITIVE. Must be subtracted. 
    let ageSubtractionMultiplier: Double = 0.2 // 1 point for every 10 years
    /// points added for being a friend
    let friendBump: Double = 4.0
    /// This is the cutoff where we say that the marginal age distance matters less beyond this point
    let extraAgeDistanceThreshold: Double = 20.0
    
    /// higest TangerineScore that the RecommendationEngine will still recommend Reject
    let highestRejectLimit = TangerineScore(rawScore: 2.0)
    /// lowest TangerineScore that the RecommendationEngine will still recommend Accept
    let lowestAcceptLimit = TangerineScore(rawScore: 3.5)
}

public enum decisionRec: String {
    case reject = "Nope"
    case uncertain = ""
    case accept = "Wear It!"
}

/// Returns the opposite of the passed decisionRec. Used for compare bottom images.
public func invertDecisionRec(decRec: decisionRec) -> decisionRec {
    switch decRec {
    case .reject:
        return .accept
    case .uncertain:
        return .uncertain
    case .accept:
        return .reject
    }
}

public func generateRecommendation(from tangerineScore: TangerineScore, inputs: TangerineScoreInputs) -> decisionRec {
    
    // without this, the system evaluates 0/0 = 1. If there are no reviews, we are definitely uncertain.
    // And at 1 review, let's not give it the seal of approval yet. The user will still be able to see the numerical Tangerine Score.
    if tangerineScore.numReviews <= 1 {
        return decisionRec.uncertain
    }
    
    switch tangerineScore.score {
    case 0.0...inputs.highestRejectLimit.score: return decisionRec.reject
    case inputs.highestRejectLimit.score...inputs.lowestAcceptLimit.score: return decisionRec.uncertain
    case inputs.lowestAcceptLimit.score...5.0: return decisionRec.accept
    default:
        // Should never happen. Consider throwing an error here.
        print("tangerine score was outside of range 0.0 to 5.0. Could not make a recommendation.")
        return decisionRec.uncertain
    }
}

public func displayTangerineScore(tangerineScore: TangerineScore,
                    totalReviewsLabel: UILabel,
                    displayTool: DataDisplayTool,
                    displayBottom: Bool,
                    ratingValueLabel: UILabel,
                    wearItLabel: UILabel,
                    wearItImageView: UIImageView,
                    photoImageView: UIImageView) {
    
    // generate a Tangerine Recommendation using the score and the member's parameters
    var recommendation: decisionRec = generateRecommendation(from: tangerineScore, inputs: TangerineScoreInputs())
    print("recommendation generated as: \(recommendation.rawValue)")
    
    
    totalReviewsLabel.text = " \(String(tangerineScore.numReviews)) review\(addPluralS(numberOfItems: tangerineScore.numReviews))"
    
    
    displayTool.displayIcons(forTangerineScore: tangerineScore, forBottom: displayBottom)

    
    if tangerineScore.numReviews < 1 {
        ratingValueLabel.text = ""
//        ratingValueLabel.font = ratingValueLabel.font.withSize(12.0)
    } else {
//        ratingValueLabel.font = ratingValueLabel.font.withSize(17.0)
        ratingValueLabel.text = String(tangerineScore.score)
    }
    

    if recommendation == .uncertain {
        // to be used if we want to display an sfSymbol for .uncertain
//        if let unwrappedImg = UIImage(systemName: "brain")?.withTintColor(.systemGray) {
//            let textAttachment = NSTextAttachment()
//            textAttachment.image = unwrappedImg
//            wearItLabel.attributedText = NSAttributedString(attachment: textAttachment)
//            // may want to increase the font size at some point
//        } else {
//            wearItLabel.text = "?"
//        }

        wearItLabel.text = recommendation.rawValue
    } else {
        if displayBottom {
            // if there is a decision, the bottom should be the opposite of the recommendation created for the passed Tangerine Score. The hideLosingRec() method in CompareTableViewCell will hide either rec visuals if they are not the winner.
            recommendation = invertDecisionRec(decRec: recommendation)
            print("displayBottom is true. inverted decision rec. recommendation is now \(recommendation)")
        }
        wearItLabel.text = recommendation.rawValue
    }
    
    loadRecommendation(imageView: wearItImageView, for: recommendation)
    
    if recommendation == .accept {
        addCircleBorder(view: photoImageView, color: .systemOrange)
    } else {
        removeCircleBorder(view: photoImageView)
    }
    
//    switch recommendation {
//    case .reject:
//        wearItImageView.isHidden = false
//        wearItImageView.image = UIImage(systemName: "xmark.circle")
//        wearItImageView.tintColor = .systemRed
//        removeCircleBorder(view: photoImageView)
//    case .uncertain:
//        wearItImageView.isHidden = true
//        removeCircleBorder(view: photoImageView)
//    case .accept:
//        wearItImageView.isHidden = false
//        wearItImageView.image = UIImage(named: "Tangerine.slice")
//        addCircleBorder(view: photoImageView, color: .systemOrange)
//    }
    
}

/// Sets up the wearItImageView with the right image and whether it's visible
public func loadRecommendation(imageView: UIImageView, for recommendation: decisionRec) {
    switch recommendation {
    case .reject:
        imageView.isHidden = false
        imageView.image = UIImage(systemName: "xmark.circle")
        imageView.tintColor = .systemRed
    case .uncertain:
        imageView.isHidden = true
    case .accept:
        imageView.isHidden = false
        imageView.image = UIImage(named: "Tangerine.slice")

    }
}



