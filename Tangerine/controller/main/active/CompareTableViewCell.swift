//
//  CompareTableViewCell.swift
//  
//
//  Created by Wyatt Weber on 7/21/16.
//  Copyright © 2016 Insightful Inc. All rights reserved.
//
//  This cell displays two images (a Compare) and data from the aggregated reviews that were created by users in the local user's targetDemo
//
//  Normally a Compare is displayed with the first image in the top of the screen and the second image in the bottom of the screen
//  Here, because the cell is a horizontal rectangle, we display the first (top) image in the left of the cell and the second (bottom) image in the right of the cell.

import UIKit

class CompareTableViewCell: UITableViewCell {

    // MARK: Properties
    
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var title1Label: UILabel!
    @IBOutlet weak var percentImage1Label: UILabel!
    @IBOutlet weak var title2Label: UILabel!
    @IBOutlet weak var percentImage2Label: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var reviewsRequiredToUnlockLabel: UILabel!
    @IBOutlet weak var numVotesLabel: UILabel!
    @IBOutlet weak var leftWearItImageView: UIImageView!
    @IBOutlet weak var rightWearItImageView: UIImageView!
    @IBOutlet weak var leftWearItLabel: UILabel!
    @IBOutlet weak var rightWearItLabel: UILabel!
    

    @IBOutlet weak var centerDividerView: UIView!

    // Rating Image outlets (Hearts)
    // LEFT (image 1 or "top")
    
    @IBOutlet weak var leftTD100Bar: UIView!
    @IBOutlet weak var leftRatingImage0: UIImageView!
    @IBOutlet weak var leftRatingImage1: UIImageView!
    @IBOutlet weak var leftRatingImage2: UIImageView!
    @IBOutlet weak var leftRatingImage3: UIImageView!
    @IBOutlet weak var leftRatingImage4: UIImageView!
//    @IBOutlet weak var leftRatingValueLabel: UILabel!
    
    //RIGHT (image 2 or "bottom")
    @IBOutlet weak var rightTD100Bar: UIView!
    @IBOutlet weak var rightRatingImage0: UIImageView!
    @IBOutlet weak var rightRatingImage1: UIImageView!
    @IBOutlet weak var rightRatingImage2: UIImageView!
    @IBOutlet weak var rightRatingImage3: UIImageView!
    @IBOutlet weak var rightRatingImage4: UIImageView!
//    @IBOutlet weak var rightRatingValueLabel: UILabel!
    
    /// Unpacks the Data Set and displays it in form of yellow or black hearts
    func displayCompareCellData(tangerineScore: TangerineScore){
        
        let leftTangerineScoreDataDisplayTool: DataDisplayTool = DataDisplayTool(
            icon0: leftRatingImage0,
            icon1: leftRatingImage1,
            icon2: leftRatingImage2,
            icon3: leftRatingImage3,
            icon4: leftRatingImage4,
            inverseOrientation: false,
            ratingValueLabel: percentImage1Label)
        

        displayTangerineScore(tangerineScore: tangerineScore,
                              totalReviewsLabel: numVotesLabel,
                              displayTool: leftTangerineScoreDataDisplayTool,
                              displayBottom: false,
                              ratingValueLabel: percentImage1Label,
                              wearItLabel: leftWearItLabel,
                              wearItImageView: leftWearItImageView,
                              photoImageView: image1)
        
        leftTangerineScoreDataDisplayTool.ratingValueLabel.text = "\(tangerineScore.percentTop)%"
        
        
        let rightTangerineScoreDataDisplayTool: DataDisplayTool = DataDisplayTool(
            icon0: rightRatingImage0,
            icon1: rightRatingImage1,
            icon2: rightRatingImage2,
            icon3: rightRatingImage3,
            icon4: rightRatingImage4,
            inverseOrientation: true,
            ratingValueLabel: percentImage2Label)
        

        displayTangerineScore(tangerineScore: tangerineScore,
                              totalReviewsLabel: numVotesLabel,
                              displayTool: rightTangerineScoreDataDisplayTool,
                              displayBottom: true,
                              ratingValueLabel: percentImage2Label,
                              wearItLabel: rightWearItLabel,
                              wearItImageView: rightWearItImageView,
                              photoImageView: image2)
        
        rightTangerineScoreDataDisplayTool.ratingValueLabel.text = "\(tangerineScore.percentBottom)%"
        
        hideLosingRec(tangerineScore: tangerineScore)

    }
    
    /// Hides the wearIt imageView and Label for the side with the lower TangerineScore in order to avoid clutter
    func hideLosingRec(tangerineScore: TangerineScore) {
        switch tangerineScore.percentTop {
        case let x where x > tangerineScore.percentBottom:
            // img1 is the winner, so hide img2 (right) rec
            rightWearItLabel.text = ""
            rightWearItImageView.alpha = 0.0
        case let x where x < tangerineScore.percentBottom:
            // img2 is the winner, so hide img1 (left) rec
            leftWearItLabel.text = ""
            leftWearItImageView.alpha = 0.0
        default: print("tie")
            // in this case, functionality elsewhere hides the wearItImageView
            // and we want to display both wearItLabels
        }
    }

    /// Takes a Bool specifying whether the cell is locked or not, and uses it to hide or unhide data display labels as required
    func lockCell(_ hide: Bool, reviewsNeeded: Int) {
        leftTD100Bar.isHidden = hide
        percentImage1Label.isHidden = hide
        rightTD100Bar.isHidden = hide
        percentImage2Label.isHidden = hide
        centerDividerView.isHidden = hide
        leftWearItLabel.isHidden = hide
        rightWearItLabel.isHidden = hide
        leftWearItImageView.isHidden = hide
        rightWearItImageView.isHidden = hide
        reviewsRequiredToUnlockLabel.isHidden = !hide
        if hide == true {
            percentImage1Label.text = "🗝"
            percentImage2Label.text = "🗝"
            reviewsRequiredToUnlockLabel.text = "Please review \(reviewsNeeded) more user\(sIfNeeded(number: reviewsNeeded)) to unlock your results."
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

