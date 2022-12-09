//
//  ReviewAskViewController.swift
//  
//
//  Created by Wyatt Weber on 6/28/17.
//  Copyright © 2017 Insightful Inc. All rights reserved.
//
//  Displays a Compare that has been created by other users, so that it can be reviewed by local user.
//  Essentially this is "Red View"


import UIKit
import FirebaseFirestore
//import QuartzCore // I only did this to try and show rounded corners in interface builder

class ReviewCompareViewController: UIViewController, UIScrollViewDelegate, UITextViewDelegate {
    
    // for calling methods of BLUEVC
    weak var blueVC: ReviewOthersVC?
    
    @IBOutlet var mainView: UIView!
    
    // TopView's outlets:
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var topScrollView: UIScrollView!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var topCaptionTextField: UITextField!
    @IBOutlet weak var topCaptionTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topSelectionImageView: UIImageView!
    
    // BottomView's outlets:
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var bottomScrollView: UIScrollView!
    @IBOutlet weak var bottomImageView: UIImageView!
    @IBOutlet weak var bottomCaptionTextField: UITextField!
    @IBOutlet weak var bottomCaptionTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomSelectionImageView: UIImageView!
    
    
    
    // Additional information labels and images outlets
    @IBOutlet weak var lockedContainersLabel: UILabel!
    @IBOutlet weak var strongImageView: UIImageView!
    @IBOutlet weak var obligatoryReviewsRemainingLabel: UILabel!
    
    
    // Link the background views to the code so we can crop them into circles:
    @IBOutlet weak var topLeftBackgroundView: UIView!
    @IBOutlet weak var topCenterBackgroundView: UIView!
    @IBOutlet weak var topRightBackgroundView: UIView!
    @IBOutlet weak var bottomRightBackgroundView: UIView!
    @IBOutlet weak var bottomCenterBackgroundView: UIView!
    //    @IBOutlet weak var bottomLeftBackgroundView: UIView!
    @IBOutlet weak var bottomLeftBackgroundView: UIView!
    
    @IBOutlet weak var helpBackgroundView: UIView!
    
    // Help Display Outlets
    @IBOutlet weak var helpReviewOptimizationLabel: UILabel!
    @IBOutlet weak var helpTapToReviewLabel: UILabel!
    @IBOutlet weak var helpLockedQuestionsLabel: UILabel!
    @IBOutlet weak var helpReviewsRemainingLabel: UILabel!
    @IBOutlet weak var helpReturnToMainMenuLabel: UILabel!
    @IBOutlet weak var helpReportLabel: UILabel!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var glassView: UIView!
    
    // So that we can add Attention rectangles around them as required
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    
    
    
    // the loading
    var topIndicator: UIActivityIndicatorView!
    var bottomIndicator: UIActivityIndicatorView!
    
    var question: Question?
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    var strongFlag: Bool = false
    
    
    let enterCommentConstant: String = "Enter optional comments here."
    let backgroundCirclesAlphaValue: CGFloat = 0.75
    var strongOriginalSize: CGFloat = 70.0 // this is a placeholder value, updated in viewDidLoad()
    
    var commentWritten: String!
    
    var recipientList = [String]()
    var usersNotReviewedList = [String]()
    
    var ud = UserDefaults.standard
    
    func configureView() {
        strongImageView.isHidden = true
        topCenterBackgroundView.isHidden = true
        strongFlag = false
        
        // unwraps the Compare that the tableView sent over:
        if let thisCompare = question {
            // if saved image is found, load it.
            // else download it
            
            topIndicator.startAnimating()
            
            loadCaptions(
                within: topView,
                caption: Caption(text: thisCompare.captionText_1, yLocation: thisCompare.yLoc_1),
                captionTextField: topCaptionTextField,
                captionTopConstraint: topCaptionTopConstraint)
            
            // if saved image is found, load it.
            bottomIndicator.startAnimating()
            
            
            
            loadCaptions(
                within: bottomView,
                caption: Caption(text: thisCompare.captionText_2, yLocation: thisCompare.yLoc_2),
                captionTextField: bottomCaptionTextField,
                captionTopConstraint: bottomCaptionTopConstraint)
            
            lockedContainersLabel.text = "🗝" + String(describing: lockedQuestionsCount)
            
            
            if obligatoryQuestionsToReviewCount == 0 {
                obligatoryReviewsRemainingLabel.text = String(describing: myProfile.reviewCredits) + "🐿️"
                helpReviewsRemainingLabel.text = reviewCreditsHelpText(on: true)
            }else {
                obligatoryReviewsRemainingLabel.text = String(describing: obligatoryQuestionsToReviewCount) + "📋"
                helpReviewsRemainingLabel.text = reviewCreditsHelpText(on: false)
            }
            
            
//            obligatoryReviewsRemainingLabel.text = String(describing: obligatoryQuestionsToReviewCount) + "📋"
            
            startTopImageLoading(thisCompare)
            startBottomImageLoading(thisCompare)
            
        }
        
        
    }
    
    func startTopImageLoading(_ thisCompare: Question){
        print("startTopImageLoading called")
        downloadOrLoadFirebaseImage(
            ofName: getFilenameFrom(qName: thisCompare.question_name, type: thisCompare.type),
            forPath: thisCompare.imageURL_1) { [weak self] image, error in
                
                guard let self = self else {return}
                
                if let error = error{
                    print("Error: \(error.localizedDescription)")
                    self.checkAndLoadTopAgain(getFilenameFrom(qName: thisCompare.question_name, type: thisCompare.type))
                    return
                }
                
                print("RCVC Image Downloaded for \(thisCompare.question_name)")
                // hide the indicator as we have the image now
                self.topIndicator.stopAnimating()
                self.topImageView.image = image
            }
    }
    
    // checks if we've been able to download the top image already, if not try again
    func checkAndLoadTopAgain(_ filename: String){
        print("checkAndLoadTopAgain called")
        guard let image = loadImageFromDiskWith(fileName: filename) else {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self = self else {return}
                print("image was nil when attempting to load from disk, retrying..")
                self.checkAndLoadTopAgain(filename)
            }
            
            return
        }
        
        print("LIVE CHECKING THIS LINE Compare 1")
        self.topIndicator.stopAnimating()
        self.topImageView.image = image
    }
    
    
    func startBottomImageLoading(_ thisCompare: Question){
        downloadOrLoadFirebaseImage(
            ofName: getFilenameFrom(qName: thisCompare.question_name, type: thisCompare.type,secondPhoto: true),
            forPath: thisCompare.imageURL_2) { [weak self]  image, error in
                
                guard let self = self else {return}
                
                if let error = error{
                    print("Error: \(error.localizedDescription)")
                    self.checkAndLoadBottomAgain(getFilenameFrom(qName: thisCompare.question_name, type: thisCompare.type, secondPhoto: true))
                    
                    return
                }
                
                print("RCVC Image Downloaded for \(thisCompare.question_name)")
                // hide the indicator as we have the image now
                self.bottomIndicator.stopAnimating()
                self.bottomImageView.image = image
            }
        
    }
    
    // checks if we've been able to download the top image already, if not try again
    func checkAndLoadBottomAgain(_ filename: String){
        guard let image = loadImageFromDiskWith(fileName: filename) else {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self = self else {return}
                self.checkAndLoadBottomAgain(filename)
            }
            
            return
        }
        
        print("LIVE CHECKING THIS LINE Compare 2")
        self.bottomIndicator.stopAnimating()
        self.bottomImageView.image = image
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// tells system that the glassView was tapped
        let tapGlassViewGesture = UITapGestureRecognizer(target: self, action: #selector(ReviewAskViewController.glassViewTapped(_:) ))
        glassView.addGestureRecognizer(tapGlassViewGesture)
        
        makeCircle(view: self.topLeftBackgroundView, alpha: self.backgroundCirclesAlphaValue)
        makeCircle(view: self.topCenterBackgroundView, alpha: self.backgroundCirclesAlphaValue)
        makeCircle(view: self.topRightBackgroundView, alpha: self.backgroundCirclesAlphaValue)
        makeCircle(view: self.bottomRightBackgroundView, alpha: self.backgroundCirclesAlphaValue)
        makeCircle(view: self.bottomCenterBackgroundView, alpha: self.backgroundCirclesAlphaValue)
        makeCircle(view: self.bottomLeftBackgroundView, alpha: self.backgroundCirclesAlphaValue)
        makeCircle(view: self.helpBackgroundView, alpha: self.backgroundCirclesAlphaValue)
        
        // we may or may not need this for ReviewCompareVC
        self.strongOriginalSize = self.strongImageView.frame.size.height
        
        // setTextViewYPosition()
        
        // Hides keyboard when user taps outside of text view
        self.hideKeyboardOnOutsideTouch()
        // This implicitly includes tapping the coverView, even though the only time we actually explicitly refer to tapping the coverView is when
        //  we run out of questions.
        
        
        // setup the indicator
        setupIndicator()
        
        
        self.topScrollView.delegate = self
        self.bottomScrollView.delegate = self
        
        //                    // Gesture Recognizers for swiping up and down
        //                    let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(ReviewAskViewController.userSwiped))
        //                    swipeUp.direction = UISwipeGestureRecognizer.Direction.up
        //                    self.view.addGestureRecognizer(swipeUp)
        //
        //                    let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(ReviewAskViewController.userSwiped))
        //                    swipeDown.direction = UISwipeGestureRecognizer.Direction.down
        //                    self.view.addGestureRecognizer(swipeDown)
        
        // For tapping the images to select them:
        let tapTopImageGesture = UITapGestureRecognizer(target: self, action: #selector(ReviewCompareViewController.userTappedTop(_:) ))
        self.topImageView.addGestureRecognizer(tapTopImageGesture)
        
        let tapBottomImageGesture = UITapGestureRecognizer(target: self, action: #selector(ReviewCompareViewController.userTappedBottom(_:) ))
        self.bottomImageView.addGestureRecognizer(tapBottomImageGesture)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        configureView()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { // `0.7` is the desired number of seconds.
            self.showTutorialAlertViewAsRequired()
        }
        
        reportButton.removeAttentionRectangle()
        menuButton.removeAttentionRectangle()
        
    }
    
    override func viewDidLayoutSubviews() {
        print("view did layout subviews called in RCVC")
        super.viewDidLayoutSubviews()
        configureView()
    }
    
    func showTutorialAlertViewAsRequired() {
        
        let skipCompareTutorial = UserDefaults.standard.bool(forKey: Constants.UD_SKIP_REVIEW_COMPARE_TUTORIAL_Bool)
        
        if !skipCompareTutorial {
            let alertVC_1 = UIAlertController(title: "Help this person decide WHICH ONE to wear", message: "\nTap the photo you think they should go with. \n\nThey won't see your identity, but your vote will affect the results they see.", preferredStyle: .alert)
            
            let alertVC_2 = UIAlertController(title: "Navigation Tips", message: "Review as many photos as you feel like, then tap the menu button (lower left) to return to home. \n\nTo report offensive content, tap the (!) on the bottom right of the screen.", preferredStyle: .alert)
            alertVC_2.addAction(UIAlertAction.init(title: "Got It!", style: .cancel, handler: { (action) in
            }))
            
            alertVC_1.addAction(UIAlertAction.init(title: "Got It!", style: .cancel, handler: { (action) in
                // Once the user has seen this, don't show it again
                self.ud.set(true, forKey: Constants.UD_SKIP_REVIEW_COMPARE_TUTORIAL_Bool)
                
                let alreadySawAskTutorial = UserDefaults.standard.bool(forKey: Constants.UD_SKIP_REVIEW_ASK_TUTORIAL_Bool)
                
                // Don't show the second alertView if they already saw it on an Ask. The second alertView is identical for both Question types
                if !alreadySawAskTutorial {
                    
                    self.present(alertVC_2, animated: true, completion: nil)
                    // wait a little time for the new member to read the tutorial alertView, then show them the menu button to go back. The clock starts once the user taps the first "got it"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in // `0.7` is the desired number of seconds.
                        // add attention rectangle around menu button and report button
                        
                        //MARK: For some reason this report button attention rectangle isn't visible. The menu one works fine. Maybe there is something in front of it or blocking the edges. Not a show stopper for the time being.
                        self.reportButton.addAttentionRectangle()
//                        self.reportButton.alpha = 1.0
                        self.menuButton.addAttentionRectangle()
                        print("inside dispatch queue")
                    }
                }
            }))
            
            present(alertVC_1, animated: true, completion: nil)
            

            
            
            

        }
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
    
    
    @IBAction func commentButtonTapped(_ sender: Any) {
        displayTextView()
        // This makes the keyboard pop up right away
    }
    
    // KEYBOARD METHODS:
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Comment (Optional)"
            textView.textColor = UIColor.lightGray
        }
    }
    
    
    
    // Displays the text View so that the reviewer can enter a comment.
    func displayTextView() {
        print("Show comment box")
        
        if commentWritten == nil{
            commentWritten = ""
        }
        
        let alertController = UIAlertController(title: "Enter", message: "\n\n\n\n\n\n", preferredStyle: .alert)
        
        // create our textview
        let rect        = CGRect(x: 15, y: 50, width: 240, height: 100.0)
        let textView    = UITextView(frame: rect)
        
        textView.font               = UIFont(name: "Helvetica", size: 15)
        textView.textColor          = UIColor.lightGray // so later we can distinguish between hint and actual text
        textView.backgroundColor    = UIColor.white
        textView.layer.borderColor  = UIColor.lightGray.cgColor
        textView.layer.borderWidth  = 1.0
        textView.text               = commentWritten.isEmpty ? "Comment (Optional)" : commentWritten
        textView.delegate           = self
        
        alertController.view.addSubview(textView)
        
        
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: {action in
            textView.resignFirstResponder()
        })
        let action = UIAlertAction(title: "Set", style: .default, handler: { action in
            
            let msg = textView.text
            if let msg = msg{
                self.commentWritten = msg
                textView.resignFirstResponder()
            }
            
        })
        
        alertController.addAction(cancel)
        alertController.addAction(action)
        
        
        
        self.present(alertController, animated: true, completion: {
            textView.becomeFirstResponder()
            // move up the keyboard
            UIView.animate(withDuration: 0.5, animations: {
                alertController.view.frame.origin.y = 100
            })
            
            // handles the outside touch
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissAlertController))
            alertController.view.superview?.subviews[0].addGestureRecognizer(tapGesture)
            
            
        })
    } // end displayTextView
    
    
    
    @objc func dismissAlertController(){
        self.dismiss(animated: true, completion: nil)
    }
    
    // END KEYBOARD METHODS
    
    
    @objc func userTappedTop(_ pressImageGesture: UITapGestureRecognizer){
        print("user tapped top")
        self.showSelectionImage(selection: .top)
        
    }
    
    @objc func userTappedBottom(_ pressImageGesture: UITapGestureRecognizer){
        print("user tapped bottom")
        self.showSelectionImage(selection: .bottom)
        
    }
    
    /// Logs the local user's selection and creates a Review that is uploaded to the Question's ReviewCollection
    func createReview(selection: topOrBottom) {
        
        // unwrap the compare again to pull its containerID:
        if let thisCompare = question {
            
            // update the review count and that I reviewed
//            var reviewSet = Set<String>()
//            reviewSet.insert(myProfile.username)
//            
//            for reviewer in thisCompare.q_reviewed{
//                reviewSet.insert(reviewer)
//            }
            
//           qReviewList = Array(reviewSet)
            
            var unrSet = Set<String>()
            
            for item in thisCompare.usersNotReviewedBy{
                    
                    if item != myProfile.username{
                        unrSet.insert(item)
                    }
                    
            }
            
            usersNotReviewedList = Array(unrSet)
            
            // update the list of q sent to
            var rList = Set<String>()
            
           
            for item in thisCompare.recipients{
                        
                        if item != myProfile.username{
                            rList.insert(item)
                        }
                        
            }
            
            recipientList = Array(rList)
            
            
            if commentWritten == nil{
                commentWritten = ""
            }
            let createdReview: CompareReview = CompareReview(selection: selection, strongYes: strongFlag, strongNo: false, comments: commentWritten, questionName: thisCompare.question_name)
            
            // do local
            updateCountOnReviewQues()
            // send to firebase
            
            save(compareReview: createdReview)
            
        }
        
        //someUser.containerCollection[containerNumber].reviewCollection.reviews.append(createdReview)
        print("new review created.")
        if let bvc = blueVC{
            //enables compare to drop off the bottom of the screen after being reviewed
            let transition = CATransition()
            transition.duration = 0.5
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
            
            transition.type = CATransitionType.reveal
            transition.subtype = CATransitionSubtype.fromBottom
            self.view.window!.layer.add(transition, forKey: nil)
            
            
            
            bvc.showNextQues()
        }
        
    } // end of createReview
    
    /// Toggles the 'strong' flag to denote whether the user feels strongly about his or her review selection. Recall that user does not swipe to create a selection for a compare. He or she taps.
    func userSwiped(gesture: UIGestureRecognizer) {

        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if swipeGesture.direction == UISwipeGestureRecognizer.Direction.up {
                // show the strong arm and set a strong flag to true
                switch strongFlag {
                case true: return
                case false:
                    strongFlag = true
                    showStrongImage()
                }
                return // this avoids reloading the form or a segue since it was just an up-swipe
            } else if swipeGesture.direction == UISwipeGestureRecognizer.Direction.down {
                strongFlag = false
                hideStrongImage()
                return // this avoids reloading the form or a segue since it was just an down-swipe
            } else {
                print("no selection made from the swipe")
                return
            }
        }
    } //end of userSwiped
    
    /// When user swipes up, a 'strong' image displays.
    func showStrongImage() {
        ////
        // Here we will manipulate the strong center background image instead of the imageView
        ////
        
        // We may just want to fade it in instead of changing the size
        self.topCenterBackgroundView.isHidden = false
        self.strongImageView.isHidden = false
        
        //self.strongImageView.isHidden = false
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIView.AnimationOptions.beginFromCurrentState, animations: {
            self.strongImageView.frame.size.height = self.strongOriginalSize * 2.0
            self.strongImageView.frame.size.width = self.strongOriginalSize * 2.0
            self.topCenterBackgroundView.alpha = 1.0
            // I could also try to animate a change in the alpha instead to let it fade in
            // I'm pretty sure that will work.
        }, completion: {
            finished in
            
        })
        self.strongImageView.frame.size.height = self.strongOriginalSize
        self.strongImageView.frame.size.width = self.strongOriginalSize
    } // end of showStrongImage
    
    /// Hides the strong image.
    func hideStrongImage() {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIView.AnimationOptions.beginFromCurrentState, animations: {
            self.strongImageView.frame.size.height = self.strongOriginalSize * 0.0001
            self.strongImageView.frame.size.width = self.strongOriginalSize * 0.0001
            self.topCenterBackgroundView.alpha = 0.0
            //self.strongImageView.isHidden = true
            // I could also try to animate a change in the alpha instead to let it fade in
            // I'm pretty sure that will work.
        }, completion: {
            finished in
            //self.strongImageView.isHidden = true
            self.topCenterBackgroundView.isHidden = true
        })
    } // end of hideStrongImage()
    
    
    /// Create an CompareReview in Firestore
    func save(compareReview: CompareReview) {
        
        let newCompareReview: [String: Any] = [
            "questionName": compareReview.reviewID.questionName,
            "comments": compareReview.comments,
            "reviewerUserName": compareReview.reviewer.username,
            "reviewerDisplayName": compareReview.reviewer.display_name,
            "reviewerProfilePictureURL": compareReview.reviewer.profile_pic,
            "reviewerAge": getAgeFromBdaySeconds(compareReview.reviewer.birthday),
            "reviewerBirthday": compareReview.reviewer.birthday,
            "reviewerOrientation": compareReview.reviewer.orientation,
            "reviewerSignUpDate": compareReview.reviewer.created,
            "reviewerReviewsRated": compareReview.reviewer.reviews,
            "reviewerScore": compareReview.reviewer.rating,
            "selection": compareReview.selection.rawValue,
            "strongYes": compareReview.strongYes,
            "strongNo":compareReview.strongNo
        ]
        
        // PATH => REVIEWS > docID() -> The Review we created
        
        let docID = Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION).document(compareReview.reviewID.questionName).collection(Constants.QUES_REVIEWS).document().documentID
        
        /// Store the review document to the path we want and it creates the appropriate collection if needed, or adds to the existing one automatically.
        Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION).document(compareReview.reviewID.questionName).collection(Constants.QUES_REVIEWS).document(docID).setData(newCompareReview) { (error) in
            if let error = error {
                print("questionsRef.document().setData(newAsk):  **error in saving review document for \(compareReview.reviewID.questionName); \(error)**")
                
            } else {
                print("COMPARE: review done for question \(compareReview.reviewID.questionName)")
                // Updates the reviewed Question's usersSentTo list by adding the reviewerUserName to it.
                
                // See ReviewAskVC => line 465
                //                Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION).document(compareView.reviewID.questionName).updateData([Constants.QUES_RECEIP_KEY: FieldValue.arrayUnion([compareView.reviewer.username])])
                
                Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION).document(compareReview.reviewID.questionName).updateData(
                    [Constants.QUES_REVIEWS: FieldValue.increment(Int64(1)),
//                     Constants.QUES_RECEIP_KEY: self.recipientList,
//                     Constants.QUES_USERS_NOT_REVIEWED_BY_KEY: self.usersNotReviewedList
                     // the above calls were replacing the entire list in firestore. The below calls just delete the local user's username from the lists. Simpler and less errors.
                     Constants.QUES_RECEIP_KEY: FieldValue.arrayRemove([myProfile.username]),
                     Constants.QUES_USERS_NOT_REVIEWED_BY_KEY: FieldValue.arrayRemove([myProfile.username])
                    ]){_ in
                    
                    self.recipientList.removeAll()
                    self.usersNotReviewedList.removeAll()
                }
                
                
                
            }
        }
    }
    
    
    
    
    
    /// Displays symbol images momentarily over the Compare's images to show the user what he or she just selected.
    func showSelectionImage(selection: topOrBottom) {
        switch selection {
        case .top:
            self.topSelectionImageView.image = #imageLiteral(resourceName: "greencheck")
            self.topSelectionImageView.alpha = 1.0
            self.bottomSelectionImageView.image = #imageLiteral(resourceName: "redX")
            self.bottomSelectionImageView.alpha = 0.5
        case .bottom:
            self.topSelectionImageView.image = #imageLiteral(resourceName: "redX")
            self.topSelectionImageView.alpha = 0.5
            self.bottomSelectionImageView.image = #imageLiteral(resourceName: "greencheck")
            self.bottomSelectionImageView.alpha = 1.0
        }
        
        self.topSelectionImageView.isHidden = false
        self.bottomSelectionImageView.isHidden = false
        
        // delays specified number of seconds before executing code in the brackets:
        UIView.animate(withDuration: 0.5, delay: 0.3,
                       options: UIView.AnimationOptions.allowAnimatedContent,
                       animations: {
            self.topSelectionImageView.alpha = 0.0
            self.bottomSelectionImageView.alpha = 0.0
        },
                       completion: { finished in
            self.topSelectionImageView.isHidden = true
            self.bottomSelectionImageView.isHidden = true
            self.createReview(selection: selection)
        }
        )
        
    } // end showSelectionImage()
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Needs work
    /// Should display an action sheet with reasons for reporting the Compare as being inappropriate for Tangerine.
    @IBAction func reportButtonTapped(_ sender: Any) {
        //pop up a menu and find out what kind of report the user wants
        print("report content button tapped")
        // we pass the processReport function here so that the system will wait for the alert controller input before continuing on:
        showReportSheet()
        
    }
    
    
    //       Also- add a tap gesture recognizer to the VC'sso that the alert controller dismisses if the user taps off of it.
    /// Displays an alertController to allow the user to report an inappropriate Question while he or she is reviewing it.
    public func showReportSheet() {
        let alertController = UIAlertController(title: "PLEASE LIST REASON FOR REPORTING", message: nil, preferredStyle: .actionSheet)
        
        // this should iterate through all enum values and add them as possible selections in the alertView
        for rT in reportType.allCases/*this was just (reportType) without the .self - if we get an error, we will need to add arguments per the Swift4 conversion - it had 2 options and we chose the easy one - .self*/ {
            let action = UIAlertAction(title: rT.rawValue, style: .default) {
                UIAlertAction in
                
                if rT.rawValue == reportType.cancel.rawValue{
                    print("report cancel")
                    alertController.dismiss(animated: true, completion: nil)
                }else{
                    // send the report
                    if let question = self.question{
                        let report: Report = Report(type: rT, questionName: question.question_name)
                        self.sendReport(report)
                    }
                    
                }
            }
            alertController.addAction(action)
            
        }
        
        
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    
    /// Reports are objects created in a Question's reportCollection when reviewing Users flag the Question for negative content.
    public func sendReport(_ report: Report) {
        //animation?
        processReport()
        // MARK: Implement if necessary
        // fetch my username
        let username = RealmManager.sharedInstance.getProfile().username
        
        print("compareVC sendReport called")
        
        do {
            try Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION).document(report.questionName).collection(Constants.QUES_REPORTS).addDocument(from: report,completion: { error in
                if let error = error {
                    self.presentDismissAlertOnMainThread(title: "Error", message: error.localizedDescription)
                    return
                } else {
                    print("User reported for question \(report.questionName)")
                    // see ReviewAskVC line 465
                    // don't want to see again
                    //                    Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION).document(report.questionName).updateData([Constants.QUES_RECEIP_KEY: FieldValue.arrayUnion([username])])
                    
                    
                    Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION).document(report.questionName).updateData(
                        [Constants.QUES_REPORTS: FieldValue.increment(Int64(1)),
                         // the arrayRemove calls ensure the user doesn't see the reported Question again
                         Constants.QUES_RECEIP_KEY: FieldValue.arrayRemove([username]),
                         Constants.QUES_USERS_NOT_REVIEWED_BY_KEY: FieldValue.arrayRemove([username])
                        ])
    
                    if let bvc = self.blueVC{
                        bvc.showNextQues()
                    }
                }
            })
        } catch let error {
            print("Error writing city to Firestore: \(error)")
            self.presentDismissAlertOnMainThread(title: "Server Error", message: error.localizedDescription)
        }
 
    }
    
    
    func processReport() {
        self.topSelectionImageView.image = #imageLiteral(resourceName: "redexclamation")
        self.topSelectionImageView.alpha = 0.9
        self.topSelectionImageView.isHidden = false
        
        self.bottomSelectionImageView.image = #imageLiteral(resourceName: "redexclamation")
        self.bottomSelectionImageView.alpha = 0.9
        self.bottomSelectionImageView.isHidden = false
        
        // delays specified number of seconds before executing code in the brackets:
        UIView.animate(withDuration: 0.5, delay: 0.3, options: UIView.AnimationOptions.allowAnimatedContent, animations: {self.topSelectionImageView.alpha = 0.0}, completion: { finished in
            self.topSelectionImageView.isHidden = true
            // load next is controlled from BlueVC
        })
        
        // delays specified number of seconds before executing code in the brackets:
        UIView.animate(withDuration: 0.5, delay: 0.3, options: UIView.AnimationOptions.allowAnimatedContent, animations: {self.bottomSelectionImageView.alpha = 0.0}, completion: { finished in
            self.bottomSelectionImageView.isHidden = true
            // load next is controlled from BlueVC
        })
    }
    
    //    @IBOutlet weak var helpReviewOptimizationLabel: UILabel!
    //    @IBOutlet weak var helpTapToReviewLabel: UILabel!
    //    @IBOutlet weak var helpLockedQuestionsLabel: UILabel!
    //    @IBOutlet weak var helpReviewsRemainingLabel: UILabel!
    //    @IBOutlet weak var helpReturnToMainMenuLabel: UILabel!
    //    @IBOutlet weak var helpReportLabel: UILabel!
    
    @IBAction func helpButtonTapped(_ sender: Any) {
        toggleHelpDisplay()
    }
    
    func toggleHelpDisplay() {
        let hidden = helpReviewOptimizationLabel.isHidden || helpTapToReviewLabel.isHidden || helpLockedQuestionsLabel.isHidden || helpReviewsRemainingLabel.isHidden || helpReturnToMainMenuLabel.isHidden || helpReportLabel.isHidden
        
        if hidden {
            
            glassView.isHidden = false
            self.view.bringSubviewToFront(glassView)
            self.view.bringSubviewToFront(helpReviewOptimizationLabel)
            self.view.bringSubviewToFront(helpTapToReviewLabel)
            self.view.bringSubviewToFront(helpLockedQuestionsLabel)
            self.view.bringSubviewToFront(helpReviewsRemainingLabel)
            self.view.bringSubviewToFront(helpReturnToMainMenuLabel)
            self.view.bringSubviewToFront(helpReportLabel)
    
            
            if let image = UIImage(named: "question circle green") {
                helpButton.setImage(image, for: .normal)
            }
            
            self.helpReviewOptimizationLabel.fadeInAfter(seconds: 0.0)
            self.helpTapToReviewLabel.fadeInAfter(seconds: 0.0)
            self.helpLockedQuestionsLabel.fadeInAfter(seconds: 0.0)
            self.helpReviewsRemainingLabel.fadeInAfter(seconds: 0.0)
            self.helpReturnToMainMenuLabel.fadeInAfter(seconds: 0.0)
            self.helpReportLabel.fadeInAfter(seconds: 0.0)
            
        } else {
            glassView.isHidden = true
            self.view.sendSubviewToBack(glassView)
            if let image = UIImage(named: "question circle blue") {
                helpButton.setImage(image, for: .normal)
            }
            
            self.helpReviewOptimizationLabel.fadeOutAfter(seconds: 0.0)
            self.helpTapToReviewLabel.fadeOutAfter(seconds: 0.0)
            self.helpLockedQuestionsLabel.fadeOutAfter(seconds: 0.0)
            self.helpReviewsRemainingLabel.fadeOutAfter(seconds: 0.0)
            self.helpReturnToMainMenuLabel.fadeOutAfter(seconds: 0.0)
            self.helpReportLabel.fadeOutAfter(seconds: 0.0)
            
        }
        
    }
    
    @objc func glassViewTapped(_ sender: UITapGestureRecognizer? = nil) {
        toggleHelpDisplay()
    }
    
    
    @IBAction func menuButtonTapped(_ sender: Any) {
        // This may need to be adjusted depending on how we segue between asks and compares
        returnToMainMenu()
    }
    
    /// Enables user to acknowldge message on coverview and return to main view.
    //    @objc func userTappedCoverView(_ pressImageGesture: UITapGestureRecognizer){
    //        print("user tapped coverView")
    //        commentsTextView.resignFirstResponder()
    //        // otherwise, do nothing
    //    }
    
    func returnToMainMenu() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // to show the loading
    func setupIndicator() {
        topIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        topIndicator.color = .white
        bottomIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        bottomIndicator.color = .white
        
        topIndicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        bottomIndicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        
        topIndicator.center = CGPoint(x: view.center.x, y: topView.center.y)
        bottomIndicator.center = CGPoint(x: view.center.x, y: bottomView.center.y)
        
        view.addSubview(topIndicator)
        view.addSubview(bottomIndicator)
        
        topIndicator.bringSubviewToFront(view)
        bottomIndicator.bringSubviewToFront(view)
    }
}



