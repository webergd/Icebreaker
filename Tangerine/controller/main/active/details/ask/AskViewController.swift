//
//  DetailViewController.swift
//  
//
//  Created by Wyatt Weber on 7/12/16.
//  Copyright © 2016 Insightful Inc. All rights reserved.
//
//  Displays the uploaded Ask data (photo, title, etc) as well as a graphical breakdown of the aggregated reviews from 3 Data Sets:
//  targetDemo, friends, allReviews

import UIKit

class AskViewController: UIViewController, UIScrollViewDelegate {
 
    @IBOutlet weak var askImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var askCaptionTextField: UITextField!
    @IBOutlet weak var askCaptionTopConstraint: NSLayoutConstraint!
    @IBOutlet var askView: UIView!
    @IBOutlet weak var askTimeRemainingLabel: UILabel!
    @IBOutlet weak var wearItImageView: UIImageView!
    @IBOutlet weak var tangerineScoreLabel: UILabel!
    
    
    // TARGET DEMO OUTLETS
    @IBOutlet weak var targetDemoTotalReviewsLabel: UILabel!
    @IBOutlet weak var targetDemoRatingLabel: UILabel!
//    @IBOutlet weak var targetDemoStrongYesPercentage: UILabel!
    @IBOutlet weak var targetDemo100Bar: UIView! // use this to pull the current width of the 100Bar
    @IBOutlet weak var tdRatingImage0: UIImageView!
    @IBOutlet weak var tdRatingImage1: UIImageView!
    @IBOutlet weak var tdRatingImage2: UIImageView!
    @IBOutlet weak var tdRatingImage3: UIImageView!
    @IBOutlet weak var tdRatingImage4: UIImageView!
  
    
    // FRIENDS OUTLETS
    @IBOutlet weak var friendsTotalReviewsLabel: UILabel!
    @IBOutlet weak var friendsRatingLabel: UILabel!
//    @IBOutlet weak var friendsStrongYesPercentage: UILabel!
    @IBOutlet weak var friends100Bar: UIView! // use this to pull the current width of the 100Bar
    @IBOutlet weak var fRatingImage0: UIImageView!
    @IBOutlet weak var fRatingImage1: UIImageView!
    @IBOutlet weak var fRatingImage2: UIImageView!
    @IBOutlet weak var fRatingImage3: UIImageView!
    @IBOutlet weak var fRatingImage4: UIImageView!

    // 'ALL REVIEWS' OUTLETS
    @IBOutlet weak var allReviewsTotalReviewsLabel: UILabel!
    @IBOutlet weak var allReviewsRatingLabel: UILabel!
//    @IBOutlet weak var allReviewsStrongYesPercentage: UILabel!
    @IBOutlet weak var allReviews100Bar: UIView! // use this to pull the current width of the 100Bar

    @IBOutlet weak var reviewsLabelWidthConstraint: UILabel!
    @IBOutlet weak var arRatingImage0: UIImageView!
    @IBOutlet weak var arRatingImage1: UIImageView!
    @IBOutlet weak var arRatingImage2: UIImageView!
    @IBOutlet weak var arRatingImage3: UIImageView!
    @IBOutlet weak var arRatingImage4: UIImageView!
    
    
    // OUTLETS TO USE LABELS AS BUTTONS
    @IBOutlet weak var targetDemoLabel: UILabel!
    @IBOutlet weak var friendsLabel: UILabel!
    @IBOutlet weak var allReviewsLabel: UILabel!
    // For these to work, user interaction must be enabled in attributes inspector
    
    // HELP OUTLETS
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var helpAskLabel1: UILabel!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var question: ActiveQuestion? 
    
    var sortType: dataFilterType = .allUsers // this will be adjusted prior to segue if user taps specific area
    
    func configureView() {
        print("Configure called on AVC")
        // from this point until the end of the configureView method, "question" refers to the local unwrapped version of question
        guard let question = question else {
            print("container was nil")
            return
        }
       
        // unwraps the ask that the tableView sent over:
        if let thisAsk = self.question {
            
            // if Question is out of circulation, notify user
            if !thisAsk.question.is_circulating {
                
                let alertVC = UIAlertController(title: "Photo Suspended", message: "This photo was flagged as inappropriate so it is no longer receiving reviews.", preferredStyle: .alert)
                let gotItAction = UIAlertAction(title: "Got It", style: .default)
                alertVC.addAction(gotItAction)
                
                present(alertVC, animated: true, completion: nil)
            }
            
            
            if let thisLabel = self.titleLabel {
                thisLabel.text = thisAsk.question.title_1
            }
            
            // unwraps the imageView from the IBOutlet
            if let thisImageView = self.askImageView {
                
                downloadOrLoadFirebaseImage(
                    ofName: getFilenameFrom(qName: thisAsk.question.question_name, type: thisAsk.question.type),
                    forPath: thisAsk.question.imageURL_1) { image, error in
                        if let error = error{
                            print("Error: \(error.localizedDescription)")
                            return
                        }
                        
                        print("AVC ASK Image loaded for \(thisAsk.question.question_name)")
                        thisImageView.image = image!
                    }
                
            }
            // unwraps the timeRemaining from the IBOutlet
            if let thisTimeRemaining = self.askTimeRemainingLabel {
                thisTimeRemaining.text = "EXPIRES IN: \(calcTimeRemaining(thisAsk.question.created))"
            }
            
            if let thisCaptionTextField = self.askCaptionTextField {
                thisCaptionTextField.isHidden = thisAsk.question.captionText_1.isEmpty
                thisCaptionTextField.text = thisAsk.question.captionText_1
            }
            
            //            if let thisCaptionTopConstraint = self.askCaptionTopConstraint {
            //                thisCaptionTopConstraint.constant = askImageView.frame.height * CGFloat(thisAsk.question.yLoc_1)
            //            }
            // it looks like I was unwrapping it for no reason
            
            askCaptionTopConstraint.constant = askImageView.frame.height * CGFloat(thisAsk.question.yLoc_1)
            
            
            /// ---------- Heart Displays -----------
            
            //  The images are unwrapped first because a UIImage is always an optional.
            
            // Configure the Target Demo data display
            let targetDemoDataSet = pullConsolidatedData(from: question.reviewCollection, filteredBy: .targetDemo, type: .ASK) as! ConsolidatedAskDataSet
            
            if let thisTDRatingImage0 = tdRatingImage0, let thisTDRatingImage1 = tdRatingImage1, let thisTDRatingImage2 = tdRatingImage2,let thisTDRatingImage3 = tdRatingImage3, let thisTDRatingImage4 = tdRatingImage4 {
                
                let targetDemoDataDisplayTool: DataDisplayTool = DataDisplayTool(
                    icon0: thisTDRatingImage0,
                    icon1: thisTDRatingImage1,
                    icon2: thisTDRatingImage2,
                    icon3: thisTDRatingImage3,
                    icon4: thisTDRatingImage4,
                    inverseOrientation: false,
                    ratingValueLabel: targetDemoRatingLabel)
                
                targetDemoDataDisplayTool.displayIcons(forConsolidatedDataSet: targetDemoDataSet, forBottom: false)
                
                targetDemoDataSet.populateNumReviews(label: targetDemoTotalReviewsLabel)
                
                
                //                displayData(dataSet: targetDemoDataSet,
                //                            totalReviewsLabel: targetDemoTotalReviewsLabel,
                //                            displayTool: targetDemoDataDisplayTool,
                //                            displayBottom: false,
                //                            ratingValueLabel: targetDemoRatingLabel,
                //                            dataFilterType: .targetDemo)
            }
            
            // Configure the Friends data display
            let friendsDataSet = pullConsolidatedData(from: question.reviewCollection, filteredBy: .friends, type: .ASK) as! ConsolidatedAskDataSet
            
            if let thisFRatingImage0 = fRatingImage0, let thisFRatingImage1 = fRatingImage1, let thisFRatingImage2 = fRatingImage2,let thisFRatingImage3 = fRatingImage3, let thisFRatingImage4 = fRatingImage4 {
                
                let friendsDataDisplayTool: DataDisplayTool = DataDisplayTool(
                    icon0: thisFRatingImage0,
                    icon1: thisFRatingImage1,
                    icon2: thisFRatingImage2,
                    icon3: thisFRatingImage3,
                    icon4: thisFRatingImage4,
                    inverseOrientation: false,
                    ratingValueLabel: friendsRatingLabel)
                
                friendsDataDisplayTool.displayIcons(forConsolidatedDataSet: friendsDataSet, forBottom: false)
                
                friendsDataSet.populateNumReviews(label: friendsTotalReviewsLabel)
                
                //                displayData(dataSet: friendsDataSet,
                //                            totalReviewsLabel: friendsTotalReviewsLabel,
                //                            displayTool: friendsDataDisplayTool,
                //                            displayBottom: false,
                //                            ratingValueLabel: friendsRatingLabel,
                //                            dataFilterType: .friends)
            }
            
            // Configure the All Reviews data display
            let allReviewsDataSet = pullConsolidatedData(from: question.reviewCollection, filteredBy: .allUsers, type: .ASK) as! ConsolidatedAskDataSet
            
            if let thisARRatingImage0 = arRatingImage0, let thisARRatingImage1 = arRatingImage1, let thisARRatingImage2 = arRatingImage2,let thisARRatingImage3 = arRatingImage3, let thisARRatingImage4 = arRatingImage4 {
                
                let allReviewsDataDisplayTool: DataDisplayTool = DataDisplayTool(
                    icon0: thisARRatingImage0,
                    icon1: thisARRatingImage1,
                    icon2: thisARRatingImage2,
                    icon3: thisARRatingImage3,
                    icon4: thisARRatingImage4,
                    inverseOrientation: false,
                    ratingValueLabel: allReviewsRatingLabel)
                
                allReviewsDataDisplayTool.displayIcons(forConsolidatedDataSet: allReviewsDataSet, forBottom: false)
                
                allReviewsDataSet.populateNumReviews(label: allReviewsTotalReviewsLabel)
                
                
                //                displayData(dataSet: allReviewsDataSet,
                //                            totalReviewsLabel: allReviewsTotalReviewsLabel,
                //                            displayTool: allReviewsDataDisplayTool,
                //                            displayBottom: false,
                //                            ratingValueLabel: allReviewsRatingLabel,
                //                            dataFilterType: .allUsers)
            }
            
            let tangerineScore = question.reviewCollection.calcTangerineScore(inputs: TangerineScoreInputs(), requestedDemo: RealmManager.sharedInstance.getTargetDemo())
            
            let recommendation = generateRecommendation(from: tangerineScore, inputs: TangerineScoreInputs())
            
            loadRecommendation(imageView: wearItImageView, for: recommendation, isCompare: false)
            
            if tangerineScore.numReviews < 1 {
                tangerineScoreLabel.text = "No Votes Yet"
            } else {
                tangerineScoreLabel.text = "\(String(tangerineScore.scoreAsPercent))%"
            }
            
        } else {
            print("Looks like ask is nil")
        }
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        scrollView.delegate = self
//        self.configureView()
        
        //let swipeViewGesture = UISwipeGestureRecognizer(target: self, action: #selector(AskViewController.userSwiped))
        //askView.addGestureRecognizer(swipeViewGesture)
               
        
        // Gesture Recognizers for swiping left and right
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(AskViewController.userSwiped))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(AskViewController.userSwiped))
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        self.view.addGestureRecognizer(swipeLeft)
        
        // Gesture recognizers for tapping sortType labels to filter reviews
        let tdTap = UITapGestureRecognizer(target: self, action: #selector(AskViewController.userTappedTargetDemographicLabel))
        targetDemoLabel.addGestureRecognizer(tdTap)
        
        let friendsTap = UITapGestureRecognizer(target: self, action: #selector(AskViewController.userTappedFriendsLabel))
        friendsLabel.addGestureRecognizer(friendsTap)
        
        let arTap = UITapGestureRecognizer(target: self, action: #selector(AskViewController.userTappedAllReviewsLabel))
        allReviewsLabel.addGestureRecognizer(arTap)
        
        // Gesture Recognizers for tapping TangerineScore data to receive TS explanation
        let wearItImageViewTap = UITapGestureRecognizer(target: self, action: #selector(AskViewController.userTappedTangerineScore))
        wearItImageView.addGestureRecognizer(wearItImageViewTap)
        
        let tangerineScoreLabelTap = UITapGestureRecognizer(target: self, action: #selector(AskViewController.userTappedTangerineScore))
        tangerineScoreLabel.addGestureRecognizer(tangerineScoreLabelTap)

  
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        configureView()
    }
    
    // Allows the user to zoom within the scrollView that the user is manipulating at the time.
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.askImageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollView.setZoomScale(1.0, animated: true)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func helpButtonTapped(_ sender: Any) {
        
        let hidden = helpAskLabel1.isHidden

        if hidden {
            
            if let image = UIImage(named: "question circle green") {
                helpButton.setImage(image, for: .normal)
            }
                        
            self.helpAskLabel1.fadeInAfter(seconds: 0.0)
            
        } else {
            if let image = UIImage(named: "question circle blue") {
                helpButton.setImage(image, for: .normal)
            }
            
            self.helpAskLabel1.fadeOutAfter(seconds: 0.0)
        }
    }
    
    
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
        
    } //end of userSwiped
    
    // MARK: Disabled access to tableView of reviews for anonymity and simplicity.
    // Do not delete this functionality. It will be brought back for testing later to find out if members want this feature.
    @objc func userTappedTargetDemographicLabel(sender: UITapGestureRecognizer) {
        print("td label tapped")
//        self.sortType = .targetDemo
//        segueToNextViewController()
    }
    // MARK: Disabled access to tableView of reviews for anonymity and simplicity.
    // Do not delete this functionality. If will be brought back for testing later to find out if members want this feature.
    @objc func userTappedFriendsLabel(sender: UITapGestureRecognizer) {
        print("friends label tapped")
//        self.sortType = .friends
//        segueToNextViewController()
    }
    // MARK: Disabled access to tableView of reviews for anonymity and simplicity.
    // Do not delete this functionality. If will be brought back for testing later to find out if members want this feature.
    @objc func userTappedAllReviewsLabel(sender: UITapGestureRecognizer) {
        print("all users label tapped")
//        self.sortType = .allUsers
//        segueToNextViewController()
    }
    
    // add an attributed string to this later so I can imbed the good and bad icons
    /// Fires when user taps TangerineScore. Provides an explanation.
    @objc func userTappedTangerineScore(sender: UITapGestureRecognizer) {
        print("TangerineScore tapped")
        let alertVC = UIAlertController(title: "Tangerine Icon = WEAR IT. \nRed X icon = NOPE.", message: "\nTangerine calculated this score using a variety of factors including your preferences", preferredStyle: .alert)
        let gotItAction = UIAlertAction(title: "Got It", style: .default)
        alertVC.addAction(gotItAction)
        
        present(alertVC, animated: true, completion: nil)
    }
    
    func segueToNextViewController() {
        // sets the graphical view controller with the storyboard ID askReviewsTableViewController to nextVC
        let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "askReviewsTableViewController") as! AskReviewsTableViewController
        
        // sends this VC's container over to the next one
        nextVC.sortType = self.sortType
        nextVC.question = self.question
        print("sortType being sent to next VC is: \(self.sortType)")
        // pushes askBreakdownViewController onto the nav stack
        //self.navigationController?.pushViewController(nextVC, animated: true)
        nextVC.modalPresentationStyle = .fullScreen
        self.present(nextVC, animated: true, completion: nil)
    }
    
    // This method never gets called:
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        print("prepare for segue called in AskViewController")
        let controller = segue.destination as! AskReviewsTableViewController
        // Pass the current container to the AskReviewsTableViewController:
        //print("The container to be passed has a row type of: \(String(describing: container?.question.type))")
        controller.question = self.question
        controller.sortType = self.sortType // tells the tableView which reviews to display
        
    }
    
    /// enables member to navigate back to active questions list (same functionality as right swipe)
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismissToRight()
    }
    
}

