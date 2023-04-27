//
//  AskReviewDetailsViewController.swift
//  
//
//  Created by Wyatt Weber on 6/22/17.
//  Copyright © 2017 Insightful Inc. All rights reserved.
//
//  Displays details about the selected Ask Review including any comments the reviewer entered

import UIKit

class AskReviewDetailsViewController: UIViewController, UINavigationControllerDelegate {

    // Outlets:
    @IBOutlet weak var reviewerImageView: UIImageView!
    @IBOutlet weak var reviewerAgeLabel: UILabel!
    @IBOutlet weak var reviewerRatingLabel: UILabel!
    @IBOutlet weak var reviewerNameLabel: UILabel!
    @IBOutlet weak var reviewerDemoLabel: UILabel!
    
    
    @IBOutlet weak var askImageView: UIImageView!
    @IBOutlet weak var askTitleLabel: UILabel!
    @IBOutlet weak var askSelectionLabel: UILabel!
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
        self.configureAskItems()
        
        //enables the user to swipe back to the previous View
        let swipeViewGesture = UISwipeGestureRecognizer(target: self, action: #selector(AskReviewDetailsViewController.userSwiped))
        reviewDetailsView.addGestureRecognizer(swipeViewGesture)
    }

    // Sending over 1 review and the ask prevents us from having to send all reviews
    //  as would be the case if we sent the whole Question.
    var review: AskReview? {
        didSet {
            // Update the view.
            self.configureReviewItems()
        }
    }
    
    var ask: Question? {
        didSet{
            self.configureAskItems()
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
                let selectionLabel = self.askSelectionLabel,
                let strongLabel = self.strongLabel,
                let commentsBodyLabel = self.commentsBodyLabel {
                
                // MARK: Need an if statement so if user is not a friend, profile picture and name are hidden
                reviewerImage.setFirebaseImage(for: thisReview.reviewer.profile_pic)

                nameLabel.text = thisReview.reviewerName
                
                ageLabel.text = String(thisReview.reviewerAge)
                
                // MARK: Hide this label if user is a friend
                demoLabel.text = thisReview.reviewerOrientation
                demoLabel.textColor = orientationSpecificColor(userOrientation: thisReview.reviewerOrientation)
                
                // displays the reviewing user's reviewerScore so that the local user can assess how much to trust the advice in the review
                ratingLabel.text = reviewerRatingToTangerines(rating: thisReview.reviewer.rating)
                selectionLabel.text = selectionToText(selection: thisReview.selection)
                strongLabel.text = strongToText(strong: thisReview.strong)
                commentsBodyLabel.text = thisReview.comments // this will probably need additional formatting so it looks right
            }

        } else { // We probably don't need this else statement
            print("Looks like review is nil")
        }
        
    }
    
    func configureAskItems() {
        if let thisImageView = self.askImageView,
            let thisLabel = self.askTitleLabel,
            let thisAsk = self.ask {
            
            thisImageView.setFirebaseGsImage(for: thisAsk.imageURL_1)
               
            thisLabel.text = thisAsk.title_1
        }
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func userSwiped() {
        self.dismissToRight()
        
//        self.dismiss(animated: true, completion: nil)
        
    }
}


