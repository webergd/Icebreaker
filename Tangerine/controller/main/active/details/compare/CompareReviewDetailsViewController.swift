//
//  CompareReviewDetailsViewController.swift
//  
//
//  Created by Wyatt Weber on 6/23/17.
//  Copyright © 2017 Insightful Inc. All rights reserved.
//
//  Displays details about the selected Compare Review including any comments the reviewer entered

import UIKit

class CompareReviewDetailsViewController: UIViewController, UINavigationControllerDelegate {

    // Outlets:
    @IBOutlet weak var reviewerImageView: UIImageView!
    @IBOutlet weak var reviewerAgeLabel: UILabel!
    @IBOutlet weak var reviewerRatingLabel: UILabel!
    @IBOutlet weak var reviewerNameLabel: UILabel!
    @IBOutlet weak var reviewerDemoLabel: UILabel!
    
    @IBOutlet weak var selectionImageView: UIImageView!
    @IBOutlet weak var selectionTitleLabel: UILabel!
    @IBOutlet weak var strongLabel: UILabel!
    
    @IBOutlet weak var commentsTitleLabel: UILabel!
    @IBOutlet weak var commentsBodyLabel: UILabel!
    
    @IBOutlet var reviewDetailsView: UIView!
 
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureReviewItems()
        self.configureCompareItems()
        let swipeViewGesture = UISwipeGestureRecognizer(target: self, action: #selector(CompareReviewDetailsViewController.userSwiped))
        reviewDetailsView.addGestureRecognizer(swipeViewGesture)
    }
    // Sending over 1 review and the compare prevents us from having to send all reviews as would be the case if we sent the whole container.
    var review: CompareReview? {
        didSet {
            // Update the view.
            self.configureReviewItems()
        }
    }
    
    var compare: ActiveQuestion? {
        didSet{
            self.configureCompareItems()
        }
    }
    
    func configureReviewItems() {

        // unwraps the ask that the tableView sent over:
        if let thisReview = self.review {

            if let reviewerImage = self.reviewerImageView,
                let nameLabel = self.reviewerNameLabel,
                let ageLabel = self.reviewerAgeLabel,
                let demoLabel = self.reviewerDemoLabel,
                let ratingLabel = self.reviewerRatingLabel,
                let strongLabel = self.strongLabel,
                let commentsBodyLabel = self.commentsBodyLabel {
                
                // MARK: Need an if statement so if user is not a friend, profile picture and name are hidden
                reviewerImage.setFirebaseGsImage(for: thisReview.reviewer.profile_pic)
                
                
                nameLabel.text = thisReview.reviewerName
                
                ageLabel.text = String(thisReview.reviewerAge)
                
                // MARK: Hide this label if user is a friend
                demoLabel.text = thisReview.reviewerOrientation
                demoLabel.textColor = orientationSpecificColor(userOrientation: thisReview.reviewerOrientation)
                
                ratingLabel.text = "\(thisReview.reviewer.rating)"
                strongLabel.text = strongToText(strongYes: thisReview.strongYes, strongNo: thisReview.strongNo)
                commentsBodyLabel.text = thisReview.comments // this will probably need additional formatting so it looks right

            }

        } else { // We probably don't need this else statement
            print("Looks like review is nil")
        }
        
    }
    
    func configureCompareItems() {
        if let thisImageView = self.selectionImageView,
            let thisTitleLabel = self.selectionTitleLabel,
            let thisCompare = self.compare,
            let thisReview = self.review {
            
            thisImageView.image = selectionImage(selection: thisReview.selection, compare: thisCompare.question)
            thisTitleLabel.text = selectionTitle(selection: thisReview.selection, compare: thisCompare.question)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // 
    @objc func userSwiped() {
        self.dismiss(animated: true, completion: nil)
    }
}


