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
    func displayCellData(dataSet: ConsolidatedCompareDataSet){
        
        let leftTargetDemoDataDisplayTool: DataDisplayTool = DataDisplayTool(
            icon0: leftRatingImage0,
            icon1: leftRatingImage1,
            icon2: leftRatingImage2,
            icon3: leftRatingImage3,
            icon4: leftRatingImage4,
            inverseOrientation: false,
            ratingValueLabel: percentImage1Label)
        leftTargetDemoDataDisplayTool.displayIcons(dataSet: dataSet, forBottom: false)
        
        // Changes the rating labels to percents instead of 0.0 to 5.0 ratings
        leftTargetDemoDataDisplayTool.ratingValueLabel.text = "\(dataSet.percentTop)%"
        
        let rightTargetDemoDataDisplayTool: DataDisplayTool = DataDisplayTool(
            icon0: rightRatingImage0,
            icon1: rightRatingImage1,
            icon2: rightRatingImage2,
            icon3: rightRatingImage3,
            icon4: rightRatingImage4,
            inverseOrientation: true,
            ratingValueLabel: percentImage2Label)
        rightTargetDemoDataDisplayTool.displayIcons(dataSet: dataSet, forBottom: true)
        
        rightTargetDemoDataDisplayTool.ratingValueLabel.text = "\(dataSet.percentBottom)%"


        let largeFontSize: CGFloat = 17.0
        let smallFontSize: CGFloat = 17.0
        
//        percentImage1Label.font = percentImage1Label.font.withSize(smallFontSize)
//        percentImage2Label.font = percentImage1Label.font.withSize(smallFontSize)
        
        // MARK: Adjust this to control winner image etc
        switch dataSet.percentTop {
        case let x where x > dataSet.percentBottom: percentImage1Label.font = percentImage1Label.font.withSize(largeFontSize)
        case let x where x < dataSet.percentBottom: percentImage2Label.font = percentImage1Label.font.withSize(largeFontSize)
        default: print("tie")
        }
    }

    /// Takes a Bool specifying whether the cell is locked or not, and uses it to hide or unhide data display labels as required
    func lockCell(_ hide: Bool, reviewsNeeded: Int) {
        leftTD100Bar.isHidden = hide
        percentImage1Label.isHidden = hide
        rightTD100Bar.isHidden = hide
        percentImage2Label.isHidden = hide
        centerDividerView.isHidden = hide
//        numVotesLabel.isHidden = hide
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

