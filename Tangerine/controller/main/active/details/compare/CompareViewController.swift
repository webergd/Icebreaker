//
//  CompareViewController.swift
//  
//
//  Created by Wyatt Weber on 7/22/16.
//  Copyright © 2016 Insightful Inc. All rights reserved.
//

import UIKit

class CompareViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var compareView: UIView!
    @IBOutlet weak var topView: UIView!
    
    @IBOutlet weak var topScrollView: UIScrollView!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var topCaptionTextField: UITextField!
    @IBOutlet weak var topCaptionTextFieldTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bottomScrollView: UIScrollView!
    @IBOutlet weak var bottomImageView: UIImageView!
    @IBOutlet weak var bottomCaptionTextField: UITextField!
    @IBOutlet weak var bottomCaptionTextFieldTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var votes1Label: UILabel!
    @IBOutlet weak var votes2Label: UILabel!
    
    @IBOutlet weak var timeRemainingLabel: UILabel!
    
    @IBOutlet weak var winnerImageTop: UIImageView!
    @IBOutlet weak var winnerImageBottom: UIImageView!
    
    @IBOutlet weak var helpSwipeLeftForDetailsLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var question: ActiveQuestion? {
        didSet {
            // Update the view when the Question is updated.
            self.configureView()
        }
    }
    
    var isCirculating: Bool?
    
    @IBAction func unwindToCompareVC(segue: UIStoryboardSegue) {}
    
    func configureView() -> Void {
        
        // unwraps the compare that the tableView sent over:
        guard let question = question else {
            print("question was nil")
            return
        }
        
        isCirculating = question.question.is_circulating
        
        let td = RealmManager.sharedInstance.getTargetDemo()
        var consolidateCD = question.reviewCollection.pullConsolidatedCompareData(requestedDemo: td, friendsOnly: false)
        
        // if the targetDemo dataset has no reviews, pull the data for all reviews
        if consolidateCD.numReviews < 1 {
            consolidateCD = question.reviewCollection.pullConsolidatedCompareData(requestedDemo: TargetDemo(returnAllUsers: true), friendsOnly: false)
        }
        
        guard let thisCompare = self.question else {
            print("the compare is nil")
            return
        }
        

        
        // unwraps images from the compare and sends to IBOutlets
        if let thisImageView = self.topImageView {
            thisImageView.setFirebaseGsImage(for: thisCompare.question.imageURL_1)

        }
        
        if let thisImageView = self.bottomImageView {
            thisImageView.setFirebaseGsImage(for: thisCompare.question.imageURL_2)
            
        }
        
        
        
        // unwraps labels from the compare and sends to IBOutlets
        if let thisLabel = self.votes1Label {
            thisLabel.text = "\(consolidateCD.countTop)"
        }
        if let thisLabel = self.votes2Label {
            thisLabel.text = "\(consolidateCD.countBottom)"
        }
        if let thisLabel = self.timeRemainingLabel {
            thisLabel.text = "\(calcTimeRemaining(thisCompare.question.created))"
        }
        
        
        
        // Configure TARGET DEMO data display:
        
        let targetDemoDataSet = pullConsolidatedData(from: question.reviewCollection, filteredBy: .targetDemo, type: .COMPARE) as! ConsolidatedCompareDataSet
        if let thisTopScoreLabel = self.votes1Label,
           let thisBottomScoreLabel = self.votes2Label {
            if consolidateCD.numReviews > 0 {
                thisTopScoreLabel.text = "\(targetDemoDataSet.percentTop) %"
                thisBottomScoreLabel.text = "\(targetDemoDataSet.percentBottom) %"
            } else {
                thisTopScoreLabel.text = "No Votes Yet"
                thisBottomScoreLabel.text = "No Votes Yet"
            }
        }
        
        // Configure TANGERINE SCORE Data Display
        
        let tangerineScoreDataSet = question.reviewCollection.calcTangerineScore(inputs: TangerineScoreInputs(), requestedDemo: RealmManager.sharedInstance.getTargetDemo())
        if let thisTopScoreLabel = self.votes1Label,
           let thisBottomScoreLabel = self.votes2Label {
            if consolidateCD.numReviews > 0 {
                thisTopScoreLabel.text = "\(tangerineScoreDataSet.percentTop) %"
                thisBottomScoreLabel.text = "\(tangerineScoreDataSet.percentBottom) %"
            } else {
                thisTopScoreLabel.text = "No Votes Yet"
                thisBottomScoreLabel.text = "No Votes Yet"
            }
        }
        
        
        // I had to unwrap the tangerine images from this same ViewController in order to
        // modify their attributes inside an if-then or switch-case:
        if let topFruitFlag = winnerImageTop, let bottomFruitFlag = winnerImageBottom {
            
            //                print("consolidatedCD has winner of: \(consolidateCD.winner)")
            //                switch consolidateCD.winner {
            //                case CompareWinner.photo1Won:
            //                    topFruitFlag.isHidden = false
            //                    bottomFruitFlag.isHidden = true
            //                case CompareWinner.photo2Won:
            //                    topFruitFlag.isHidden = true
            //                    bottomFruitFlag.isHidden = false
            //                case CompareWinner.itsATie:
            //                    topFruitFlag.isHidden = true
            //                    bottomFruitFlag.isHidden = true
            //                }
            
            
            let compareRec = generateCompareRecommendation(from: tangerineScoreDataSet, inputs: TangerineScoreInputs())
            
            // unhide both images
            topFruitFlag.isHidden = false
            bottomFruitFlag.isHidden = false
            
            // then hide the appropriate one (or both)
            clearWearItDataIfNotAccept(decisionRec: compareRec.topImageRec, wearItLabel: nil, wearItImageView: topFruitFlag, questionImageView: nil)
            clearWearItDataIfNotAccept(decisionRec: compareRec.bottomImageRec, wearItLabel: nil, wearItImageView: bottomFruitFlag, questionImageView: nil)
            
//            // then hide what we need to
//            switch img1Rec {
//            case .reject:
//                topFruitFlag.isHidden = true
//                bottomFruitFlag.isHidden = false
//            case .uncertain:
//                topFruitFlag.isHidden = true
//                bottomFruitFlag.isHidden = true
//            case .accept:
//                topFruitFlag.isHidden = false
//                bottomFruitFlag.isHidden = true
//            }
            
            
        }
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        

        
        self.configureView()
        topScrollView.delegate = self
        bottomScrollView.delegate = self
        
        let swipeViewGesture = UISwipeGestureRecognizer(target: self, action: #selector(CompareViewController.userSwiped))
        compareView.addGestureRecognizer(swipeViewGesture)
        
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(CompareViewController.userSwiped))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(CompareViewController.userSwiped))
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        self.view.addGestureRecognizer(swipeLeft)
        
        // Gesture Recognizers for tapping TangerineScore data to receive TS explanation
        let winnerImageTopTap = UITapGestureRecognizer(target: self, action: #selector(CompareViewController.userTappedTangerineScore))
        winnerImageTop.addGestureRecognizer(winnerImageTopTap)
        
        let votes1LabelTap = UITapGestureRecognizer(target: self, action: #selector(CompareViewController.userTappedTangerineScore))
        votes1Label.addGestureRecognizer(votes1LabelTap)
        
        let winnerImageBottomTap = UITapGestureRecognizer(target: self, action: #selector(CompareViewController.userTappedTangerineScore))
        winnerImageBottom.addGestureRecognizer(winnerImageBottomTap)
        
        let votes2LabelTap = UITapGestureRecognizer(target: self, action: #selector(CompareViewController.userTappedTangerineScore))
        votes2Label.addGestureRecognizer(votes2LabelTap)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        // show help label
        let inWaitTime: Double = 2.0
        let outWaitTime: Double = 2.5
        
        // fade in doesn't seem to work in viewDidAppear. It's something with the current thread.
        self.helpSwipeLeftForDetailsLabel.fadeInAfter(seconds: inWaitTime)
        self.helpSwipeLeftForDetailsLabel.fadeOutAfter(seconds: outWaitTime)
        
        
        
        // DISPLAY THE COMPARE IMAGE CAPTIONS
        // If we show the captions in an earlier method like viewDidLoad, autolayout has not yet modfied the size of the imageViews
        //  to work without the status bar or something, so the captions get placed in the wrong spot.
        // It is still a little choppy with the captions appearing a split second after so we probably should either fade them in
        //  or get to the bottom of why the image size is changing when the view loads, or at the very least being able to predict the
        //  size that the images will be once they load so that we can calculate an accurate caption location.
        
        guard let thisCompare = self.question else {
            print("the compare is nil")
            return
        }
        // Top Image - set Y location of caption
        if let thisCaptionTopConstraint = self.topCaptionTextFieldTopConstraint {
            thisCaptionTopConstraint.constant = calcCaptionTextFieldTopConstraint(imageViewFrameHeight: topImageView.frame.height, captionYLocation: CGFloat(thisCompare.question.yLoc_1))
            
            //for troubleshooting purposes only
            //                _ = topImageView.frame.height
            //                _ = topCaptionTextFieldTopConstraint.constant
            print("nothing")
        }
        // Top Image - set caption text
        if let thisCaptionTextField = self.topCaptionTextField {
            thisCaptionTextField.text = thisCompare.question.captionText_1
            thisCaptionTextField.isHidden = thisCompare.question.captionText_1.isEmpty
        }
        
        // Bottom Image - set Y location of caption
        if let thisCaptionTopConstraint = self.bottomCaptionTextFieldTopConstraint {
            thisCaptionTopConstraint.constant = bottomImageView.frame.height * CGFloat(thisCompare.question.yLoc_2)
        }
        // Bottom Image - set caption text
        if let thisCaptionTextField = self.bottomCaptionTextField {
            thisCaptionTextField.isHidden = thisCompare.question.captionText_2.isEmpty
            thisCaptionTextField.text = thisCompare.question.captionText_2
        }

        // if Question is out of circulation, notify user
        if let iC = isCirculating {
            
            if !iC {
                
                let alertVC = UIAlertController(title: "Photo Suspended", message: "Your photo is temporarily on hold from recieving community reviews, pending an administrative check for potential inappropriate content. Please return for updates later.", preferredStyle: .alert)
                let gotItAction = UIAlertAction(title: "Got It", style: .default)
                alertVC.addAction(gotItAction)
                
                present(alertVC, animated: true, completion: nil)
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Allows the user to zoom within the scrollView that the user is manipulating at the time.
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView == topScrollView {
            return self.topImageView
        } else {
            return self.bottomImageView
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        topScrollView.setZoomScale(1.0, animated: true)
        bottomScrollView.setZoomScale(1.0, animated: true)
    }
    
    @objc func userSwiped(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if swipeGesture.direction == UISwipeGestureRecognizer.Direction.right {
                // go back to previous view by swiping right
                self.dismissToRight()
            } else if swipeGesture.direction == UISwipeGestureRecognizer.Direction.left {
                // sets the graphical view controller with the storyboard ID "compareBreakdownViewController" to nextVC
                helpSwipeLeftForDetailsLabel.isHidden = true
                let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "compareBreakdownViewController") as! CompareBreakdownViewController
                // pushes askBreakdownViewController onto the nav stack
                nextVC.question = self.question
                nextVC.modalPresentationStyle = .overCurrentContext
                
                /// This enables segue to take place from the right rather than up from the bottom which is the default
                self.presentFromRight(nextVC)
                // MARK: Could use improvement
                // Such that the CompareBreakdownVC justs slides over the top of CompareViewController, rather than watching the CompareViewController slide to the left and out of the way as the CompareBreakdownViewcontroler slides in to replace it.
            }
        }
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
    
    /// segues back to the active questions table vc
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismissToRight()
    }
    
    
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        print("prepare for segue called in CompareViewController")
    //        let controller = segue.destination as! CompareBreakdownViewController
    //        // Pass the selected object to the new view controller:
    //        controller.question = self.question
    //    }
}
