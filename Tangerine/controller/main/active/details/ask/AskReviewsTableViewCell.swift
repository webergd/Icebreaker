//
//  AskReviewsTableViewCell.swift
//  
//
//  Created by Wyatt Weber on 6/22/17.
//  Copyright © 2017 Insightful Inc. All rights reserved.
//
//  A cell in the Ask Reviews TableView Controller for displaying an individual Review.

import UIKit

class AskReviewsTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    @IBOutlet weak var reviewerImageView: UIImageView!
    @IBOutlet weak var reviewerNameLabel: UILabel!
    @IBOutlet weak var reviewerAgeLabel: UILabel!
    @IBOutlet weak var commentExistsLabel: UILabel!
    @IBOutlet weak var strongExistsLabel: UILabel!
    @IBOutlet weak var voteLabel: UILabel!
    @IBOutlet weak var cellBackgroundView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
   
}





















