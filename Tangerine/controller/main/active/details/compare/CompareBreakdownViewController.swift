//
//  CompareBreakdownViewController.swift
//  
//
//  Created by Wyatt Weber on 7/26/16.
//  Copyright © 2016 Insightful Inc. All rights reserved.
//
//  This appears as an overlay on top of CompareViewController to graphically display the review data from the aggregated reviews from 3 Data Sets: targetDemo, friends, allReviews


import UIKit

class CompareBreakdownViewController: UIViewController {

    // This outlet is here to enable swipe funtionality:
    @IBOutlet weak var compareBreakdownView: UIView!

    @IBOutlet weak var titleOneLabel: UILabel!
    @IBOutlet weak var titleTwoLabel: UILabel!

    // Some of the "Strong Vote" labels are commented out because we are currently not displaying this, but may A-B test this later.
    
    // Target Demographic Outlets:
    @IBOutlet weak var targetDemoLabel: UILabel!
    @IBOutlet weak var targetDemoView1: UIView!
    @IBOutlet weak var targetDemoView2: UIView!
    
    @IBOutlet weak var targetDemoNumReviewsLabel: UILabel!
    @IBOutlet weak var targetDemoRatingLabelTop: UILabel!
    @IBOutlet weak var targetDemoRatingLabelBottom: UILabel!
//    @IBOutlet weak var targetDemoStrongVotePercentageTop: UILabel!
//    @IBOutlet weak var targetDemoStrongVotePercentageBottom: UILabel!
    @IBOutlet weak var targetDemo100BarTop: UIView!
    @IBOutlet weak var tdRatingImage0Top: UIImageView!
    @IBOutlet weak var tdRatingImage1Top: UIImageView!
    @IBOutlet weak var tdRatingImage2Top: UIImageView!
    @IBOutlet weak var tdRatingImage3Top: UIImageView!
    @IBOutlet weak var tdRatingImage4Top: UIImageView!
    
    @IBOutlet weak var targetDemo100BarBottom: UIView!
    @IBOutlet weak var tdRatingImage0Bottom: UIImageView!
    @IBOutlet weak var tdRatingImage1Bottom: UIImageView!
    @IBOutlet weak var tdRatingImage2Bottom: UIImageView!
    @IBOutlet weak var tdRatingImage3Bottom: UIImageView!
    @IBOutlet weak var tdRatingImage4Bottom: UIImageView!
    
    // Friends Outlets
    @IBOutlet weak var friendsLabel: UILabel! // remove this
    @IBOutlet weak var friendsView1: UIView!
    @IBOutlet weak var friendsView2: UIView!
    
    @IBOutlet weak var friendsNumReviewsLabel: UILabel!
    @IBOutlet weak var friendsRatingLabelTop: UILabel!
    @IBOutlet weak var friendsRatingLabelBottom: UILabel!
//    @IBOutlet weak var friendsStrongVotePercentageTop: UILabel!
//    @IBOutlet weak var friendsStrongVotePercentageBottom: UILabel!
    @IBOutlet weak var friends100BarTop: UIView!
    @IBOutlet weak var fRatingImage0Top: UIImageView!
    @IBOutlet weak var fRatingImage1Top: UIImageView!
    @IBOutlet weak var fRatingImage2Top: UIImageView!
    @IBOutlet weak var fRatingImage3Top: UIImageView!
    @IBOutlet weak var fRatingImage4Top: UIImageView!
    
    @IBOutlet weak var friends100BarBottom: UIView!
    @IBOutlet weak var fRatingImage0Bottom: UIImageView!
    @IBOutlet weak var fRatingImage1Bottom: UIImageView!
    @IBOutlet weak var fRatingImage2Bottom: UIImageView!
    @IBOutlet weak var fRatingImage3Bottom: UIImageView!
    @IBOutlet weak var fRatingImage4Bottom: UIImageView!

    // All Reviews Outlets
    @IBOutlet weak var allReviewsLabel: UILabel! //remove this
    @IBOutlet weak var allReviewsView1: UIView!
    @IBOutlet weak var allReviewsView2: UIView!
    
    @IBOutlet weak var allReviewsNumReviewsLabel: UILabel!

    @IBOutlet weak var allReviewsRatingLabelTop: UILabel!
    @IBOutlet weak var allReviewsRatingLabelBottom: UILabel!

    @IBOutlet weak var allReviews100BarTop: UIView!
    @IBOutlet weak var arRatingImage0Top: UIImageView!
    @IBOutlet weak var arRatingImage1Top: UIImageView!
    @IBOutlet weak var arRatingImage2Top: UIImageView!
    @IBOutlet weak var arRatingImage3Top: UIImageView!
    @IBOutlet weak var arRatingImage4Top: UIImageView!
    
    @IBOutlet weak var allReviews100BarBottom: UIView!
    @IBOutlet weak var arRatingImage0Bottom: UIImageView!
    @IBOutlet weak var arRatingImage1Bottom: UIImageView!
    @IBOutlet weak var arRatingImage2Bottom: UIImageView!
    @IBOutlet weak var arRatingImage3Bottom: UIImageView!
    @IBOutlet weak var arRatingImage4Bottom: UIImageView!
    
    @IBOutlet weak var compareTimeRemainingLabel: UILabel!
    
    var sortType: dataFilterType = .allUsers // this will be adjusted prior to segue if user taps specific area
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.isOpaque = false
        view.backgroundColor = .clear
        
        //bring the individual panels forward so the user can click to filter review results
        view.bringSubviewToFront(targetDemoView1)
        view.bringSubviewToFront(friendsView1)
        view.bringSubviewToFront(allReviewsView1)
        view.bringSubviewToFront(targetDemoView2)
        view.bringSubviewToFront(friendsView2)
        view.bringSubviewToFront(allReviewsView2)
        
        self.configureView()
        sortType = .allUsers // this should always be the default
        
        // The below selectors need to be updated to be swift 4 compliant
        // More info here:
        // https://stackoverflow.com/questions/44379348/the-use-of-swift-3-objc-inference-in-swift-4-mode-is-deprecated
        
        let swipeViewGesture = UISwipeGestureRecognizer(target: self, action: #selector(CompareBreakdownViewController.userSwiped))
        compareBreakdownView.addGestureRecognizer(swipeViewGesture)
        
        
        // Gesture Recognizers for swiping left and right
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(CompareBreakdownViewController.userSwiped))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(CompareBreakdownViewController.userSwiped))
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        self.view.addGestureRecognizer(swipeLeft)
        
        // Gesture recognizers for tapping sortType labels to filter reviews
        let td1Tap = UITapGestureRecognizer(target: self, action: #selector(CompareBreakdownViewController.userTappedTargetDemographic1Label))
        targetDemoView1.addGestureRecognizer(td1Tap)
        
        let friends1Tap = UITapGestureRecognizer(target: self, action: #selector(CompareBreakdownViewController.userTappedFriends1Label))
        friendsView1.addGestureRecognizer(friends1Tap)
        
        let ar1Tap = UITapGestureRecognizer(target: self, action: #selector(CompareBreakdownViewController.userTappedAllReviews1Label))
        allReviewsView1.addGestureRecognizer(ar1Tap)
        
        let td2Tap = UITapGestureRecognizer(target: self, action: #selector(CompareBreakdownViewController.userTappedTargetDemographic2Label))
        targetDemoView2.addGestureRecognizer(td2Tap)
        
        let friends2Tap = UITapGestureRecognizer(target: self, action: #selector(CompareBreakdownViewController.userTappedFriends2Label))
        friendsView2.addGestureRecognizer(friends2Tap)
        
        let ar2Tap = UITapGestureRecognizer(target: self, action: #selector(CompareBreakdownViewController.userTappedAllReviews2Label))
        allReviewsView2.addGestureRecognizer(ar2Tap)
    }
    
    var question: ActiveQuestion? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func configureView() {

        guard let question = question else {
            print("container was nil")
            return
        }
        
        // unwraps the compare that the tableView sent over:
        if let thisCompare = self.question{
            
            if let titleLabel1 = titleOneLabel,
                let titleLabel2 = titleTwoLabel {
                titleLabel1.text = thisCompare.question.title_1
                titleLabel2.text = thisCompare.question.title_2
            }
            
            // unwraps the timeRemaining from the IBOutlet
            if let thisTimeRemaining = self.compareTimeRemainingLabel {
                thisTimeRemaining.text = "EXPIRES IN: \(calcTimeRemaining(thisCompare.question.created))"
            }
                 
            // Configure TARGET DEMO data display:
            let targetDemoDataSet = pullConsolidatedData(from: question.reviewCollection, filteredBy: .targetDemo, type: .COMPARE) as! ConsolidatedCompareDataSet
            
            if let numRevLabel = targetDemoNumReviewsLabel {
                numRevLabel.text = "Target Demo:  \(targetDemoDataSet.numReviews)"
            }
            /// unwraps all the TD labels and image views
            if let thisTDRatingImage0Top = tdRatingImage0Top, let thisTDRatingImage1Top = tdRatingImage1Top, let thisTDRatingImage2Top = tdRatingImage2Top,let thisTDRatingImage3Top = tdRatingImage3Top, let thisTDRatingImage4Top = tdRatingImage4Top, let thisTDRatingImage0Bottom = tdRatingImage0Bottom, let thisTDRatingImage1Bottom = tdRatingImage1Bottom, let thisTDRatingImage2Bottom = tdRatingImage2Bottom, let thisTDRatingImage3Bottom = tdRatingImage3Bottom, let thisTDRatingImage4Bottom = tdRatingImage4Bottom {
                /// plugs the outlets into a newly created DataDisplayTool
                let targetDemoDataDisplayToolTop = DataDisplayTool(
                    icon0: thisTDRatingImage0Top,
                    icon1: thisTDRatingImage1Top,
                    icon2: thisTDRatingImage2Top,
                    icon3: thisTDRatingImage3Top,
                    icon4: thisTDRatingImage4Top,
                    inverseOrientation: false,
                    ratingValueLabel: targetDemoRatingLabelTop)
                // Note that we're using .displayIcons rather than .displayData because this is a compare. Not the most intuitive structure.
                // The code would be more readible if we change either Ask or Compare so they both use the same method name to display.
                /// Displays the passed targetDemoDataSet graphically using the DataDisplayTool
                targetDemoDataDisplayToolTop.displayIcons(dataSet: targetDemoDataSet, forBottom: false)
                
                let targetDemoDataDisplayToolBottom = DataDisplayTool(
                    icon0: thisTDRatingImage0Bottom,
                    icon1: thisTDRatingImage1Bottom,
                    icon2: thisTDRatingImage2Bottom,
                    icon3: thisTDRatingImage3Bottom,
                    icon4: thisTDRatingImage4Bottom,
                    inverseOrientation: false,
                    ratingValueLabel: targetDemoRatingLabelBottom)
                // Note that we're using .displayIcons rather than .displayData because this is a compare. Not the most intuitive structure.
                targetDemoDataDisplayToolBottom.displayIcons(dataSet: targetDemoDataSet, forBottom: true)
            } else {
                print("could not unwrap UIImageViews")
            }//end of target demo rating images unwrapping
            
            // Configure FRIENDS data display:
            let friendsDataSet = pullConsolidatedData(from: question.reviewCollection, filteredBy: .friends, type: .COMPARE) as! ConsolidatedCompareDataSet
            
            if let numRevLabel = friendsNumReviewsLabel {
                numRevLabel.text = "Friends:  \(friendsDataSet.numReviews)"
            }
            
            if let thisFRatingImage0Top = fRatingImage0Top, let thisFRatingImage1Top = fRatingImage1Top, let thisFRatingImage2Top = fRatingImage2Top,let thisFRatingImage3Top = fRatingImage3Top, let thisFRatingImage4Top = fRatingImage4Top, let thisFRatingImage0Bottom = fRatingImage0Bottom, let thisFRatingImage1Bottom = fRatingImage1Bottom, let thisFRatingImage2Bottom = fRatingImage2Bottom, let thisFRatingImage3Bottom = fRatingImage3Bottom, let thisFRatingImage4Bottom = fRatingImage4Bottom {
                
                let friendsDataDisplayToolTop = DataDisplayTool(
                    icon0: thisFRatingImage0Top,
                    icon1: thisFRatingImage1Top,
                    icon2: thisFRatingImage2Top,
                    icon3: thisFRatingImage3Top,
                    icon4: thisFRatingImage4Top,
                    inverseOrientation: false,
                    ratingValueLabel: friendsRatingLabelTop)
                // Note that we're using .displayIcons rather than .displayData because this is a compare. Not the most intuitive structure.
                friendsDataDisplayToolTop.displayIcons(dataSet: friendsDataSet, forBottom: false)
                
                let friendsDataDisplayToolBottom = DataDisplayTool(
                    icon0: thisFRatingImage0Bottom,
                    icon1: thisFRatingImage1Bottom,
                    icon2: thisFRatingImage2Bottom,
                    icon3: thisFRatingImage3Bottom,
                    icon4: thisFRatingImage4Bottom,
                    inverseOrientation: false,
                    ratingValueLabel: friendsRatingLabelBottom)
                // Note that we're using .displayIcons rather than .displayData because this is a compare. Not the most intuitive structure.
                friendsDataDisplayToolBottom.displayIcons(dataSet: friendsDataSet, forBottom: true)
            } else {
                print("could not unwrap UIImageViews")
            }//end of friends rating images unwrapping
            
            // Configure ALL REVIEWS data display:
            let allReviewsDataSet = pullConsolidatedData(from: question.reviewCollection, filteredBy: .allUsers, type: .COMPARE) as! ConsolidatedCompareDataSet
            
            if let numRevLabel = allReviewsNumReviewsLabel {
                numRevLabel.text = "All Reviewers:  \(allReviewsDataSet.numReviews)"
            }
            
            if let thisARRatingImage0Top = arRatingImage0Top, let thisARRatingImage1Top = arRatingImage1Top, let thisARRatingImage2Top = arRatingImage2Top,let thisARRatingImage3Top = arRatingImage3Top, let thisARRatingImage4Top = arRatingImage4Top, let thisARRatingImage0Bottom = arRatingImage0Bottom, let thisARRatingImage1Bottom = arRatingImage1Bottom, let thisARRatingImage2Bottom = arRatingImage2Bottom, let thisARRatingImage3Bottom = arRatingImage3Bottom, let thisARRatingImage4Bottom = arRatingImage4Bottom {
                
                let allReviewsDataDisplayToolTop = DataDisplayTool(
                    icon0: thisARRatingImage0Top,
                    icon1: thisARRatingImage1Top,
                    icon2: thisARRatingImage2Top,
                    icon3: thisARRatingImage3Top,
                    icon4: thisARRatingImage4Top,
                    inverseOrientation: false,
                    ratingValueLabel: allReviewsRatingLabelTop)
                // Note that we're using .displayIcons rather than .displayData because this is a compare. Not the most intuitive structure.
                allReviewsDataDisplayToolTop.displayIcons(dataSet: allReviewsDataSet, forBottom: false)
                
                let allReviewsDataDisplayToolBottom = DataDisplayTool(
                    icon0: thisARRatingImage0Bottom,
                    icon1: thisARRatingImage1Bottom,
                    icon2: thisARRatingImage2Bottom,
                    icon3: thisARRatingImage3Bottom,
                    icon4: thisARRatingImage4Bottom,
                    inverseOrientation: false,
                    ratingValueLabel: allReviewsRatingLabelBottom)
                // Note that we're using .displayIcons rather than .displayData because this is a compare. Not the most intuitive structure.
                allReviewsDataDisplayToolBottom.displayIcons(dataSet: allReviewsDataSet, forBottom: true)
            } else {
                print("could not unwrap UIImageViews")
            }//end of all reviews rating images unwrapping
  
        } else {
            print("Looks like ask is nil")
        }
    
    } // End of configureView()
    
    /// This is not currently being called. We need to find the best way to show the user which photo was the winner.
    func displayWinningImage(in winningImageView: UIImageView, with winningTitleLabel: UILabel, using dataSet: ConsolidatedCompareDataSet){
        // This only comes into play when using the method for CompareBreakdownVC
        switch dataSet.winner {
        case .photo1Won: print()
            // I should add a tangerine emoji to the title of the winner
        case .photo2Won: print()
        case .itsATie: print()
        }
    }
 

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Enables user to swipe forward or back (left forward, right back)
    @objc func userSwiped(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if swipeGesture.direction == UISwipeGestureRecognizer.Direction.right {
                // go back to previous view by swiping right
                self.dismissToRight()
                
//                self.dismiss(animated: true, completion: nil)
                
            } else if swipeGesture.direction == UISwipeGestureRecognizer.Direction.left {
                // MARK: Disabled access to tableView of reviews for anonymity and simplicity.
                // Do not delete this functionality. If will be brought back for testing later to find out if members want this feature.
//                sortType = .allUsers // on left swipe show all reviews (may want to change this to targetDemo instead)
//                segueToNextViewController()
            }

        }
    } // end of userSwiped
    
    
    // MARK: Disabled access to tableView of reviews for anonymity and simplicity.
    // Do not delete this functionality. If will be brought back for testing later to find out if members want this feature.
    @objc func userTappedTargetDemographic1Label(sender: UITapGestureRecognizer) {
        print("td label tapped")
//        self.sortType = .targetDemo
//        segueToNextViewController()
    }
    // MARK: Disabled access to tableView of reviews for anonymity and simplicity.
    // Do not delete this functionality. If will be brought back for testing later to find out if members want this feature.
    @objc func userTappedFriends1Label(sender: UITapGestureRecognizer) {
        print("friends label tapped")
//        self.sortType = .friends
//        segueToNextViewController()
    }
    // MARK: Disabled access to tableView of reviews for anonymity and simplicity.
    // Do not delete this functionality. If will be brought back for testing later to find out if members want this feature.
    @objc func userTappedAllReviews1Label(sender: UITapGestureRecognizer) {
        print("all users label tapped")
//        self.sortType = .allUsers
//        segueToNextViewController()
    }
     
    
    @objc func userTappedTargetDemographic2Label(sender: UITapGestureRecognizer) {
//        print("td label tapped")
//        self.sortType = .targetDemo
//        segueToNextViewController()
    }
    
    @objc func userTappedFriends2Label(sender: UITapGestureRecognizer) {
//        print("friends label tapped")
//        self.sortType = .friends
//        segueToNextViewController()
    }
    
    @objc func userTappedAllReviews2Label(sender: UITapGestureRecognizer) {
//    print("all users label tapped")
//    self.sortType = .allUsers
//    segueToNextViewController()
}
    
    func segueToNextViewController() {
        print("segue to next VC called inside of CompareBreakdownVC")
        // sets the graphical view controller with the storyboard ID askReviewsTableViewController to nextVC
        // This nextVC doesn't do anything
        
        let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "compareReviewsTableViewController") as! CompareReviewsTableViewController
        
        // sends this VC's Question over to the next one
        nextVC.sortType = self.sortType
        nextVC.question = self.question
        nextVC.modalPresentationStyle = .fullScreen
        self.presentFromRight(nextVC)
//        self.present(nextVC, animated: true, completion: nil)
   //     performSegue(withIdentifier: "showCompareReviewsTableViewController", sender: self)
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let controller = segue.destination as! CompareReviewsTableViewController
//        controller.sortType = self.sortType
//        controller.question = self.question
//    }
}







