//
//  AskTableViewCell.swift
//  
//
//  Created by Wyatt Weber on 7/14/16.
//  Copyright © 2016 Insightful Inc. All rights reserved.
//
// This cell displays a Question that only has one image (an Ask) and data from the aggregated reviews that were created by users in the local user's targetDemo

import UIKit

class AskTableViewCell: UITableViewCell {

    
    // Some of these outlet names are confusing because they used to be used in a different data display arrangement
    // We can adjust these outlet names as necessary to make the code easier to understand.
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var numVotesLabel: UILabel!
    @IBOutlet weak var reviewsRequiredToUnlockLabel: UILabel!
    @IBOutlet weak var lockLabel: UILabel!
    @IBOutlet weak var wearItLabel: UILabel!
    @IBOutlet weak var wearItImageView: UIImageView!
    
    
    // Most of the outlets in this block are not used anymore but cannot just be deleted or commented out because of the underlying design in Interface Builder. They should be eliminated eventually:
    @IBOutlet weak var yesPercentage: UILabel!
    @IBOutlet weak var strongYesPercentage: UILabel!
    @IBOutlet weak var rating100Bar: UIView!
    @IBOutlet weak var ratingBar: UIView!
    @IBOutlet weak var ratingStrongBar: UIView!
    @IBOutlet weak var ratingBarTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var ratingStrongBarTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var yesPercentageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var strongYesPercentageTrailingConstraint: NSLayoutConstraint!
    
    // These outlets are for the dataDisplayTool aka the yellow hearts
    @IBOutlet weak var td100Bar: UIView!
    @IBOutlet weak var ratingValueLabel: UILabel!
    @IBOutlet weak var ratingImage0: UIImageView!
    @IBOutlet weak var ratingImage1: UIImageView!
    @IBOutlet weak var ratingImage2: UIImageView!
    @IBOutlet weak var ratingImage3: UIImageView!
    @IBOutlet weak var ratingImage4: UIImageView!
    
    
    func displayAskCellData(tangerineScore: TangerineScore){
        
        let tangerineScoreDataDisplayTool: DataDisplayTool = DataDisplayTool(
            icon0: ratingImage0,
            icon1: ratingImage1,
            icon2: ratingImage2,
            icon3: ratingImage3,
            icon4: ratingImage4,
            inverseOrientation: false,
            ratingValueLabel: ratingValueLabel)
        
        // displayData was rewritten for ask's but not compares
//        displayData(dataSet: dataSet,
//                    totalReviewsLabel: numVotesLabel,
//                    displayTool: targetDemoDataDisplayTool,
//                    displayBottom: false, // because it's an Ask and there is no bottom image data set to display
//                    ratingValueLabel: ratingValueLabel,
//                    dataFilterType: .targetDemo)

        
        displayTangerineScore(tangerineScore: tangerineScore,
                              totalReviewsLabel: numVotesLabel,
                              displayTool: tangerineScoreDataDisplayTool,
                              displayBottom: false,
                              ratingValueLabel: ratingValueLabel,
                              wearItLabel: wearItLabel,
                              wearItImageView: wearItImageView,
                              photoImageView: photoImageView,
                              isCompare: false)
        
        tangerineScoreDataDisplayTool.ratingValueLabel.text = "\(tangerineScore.scoreAsPercent)%"
        
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





















