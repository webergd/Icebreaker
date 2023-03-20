//
//  ReviewAskViewController.swift
//  
//
//  Created by Wyatt Weber on 6/28/17.
//  Copyright © 2017 Insightful Inc. All rights reserved.
//
//  Displays an Ask that has been created by other users, so that it can be reviewed by local user.
//  Essentially this is "Blue View"


import UIKit
import FirebaseFirestore
import FirebaseAnalytics

class ReviewAskViewController: UIViewController, UIScrollViewDelegate, UITextViewDelegate {
    
    // for calling methods of BLUEVC
    weak var blueVC: ReviewOthersVC?
    
    @IBOutlet var mainView: UIView!
    
    
    @IBOutlet weak var helperView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var askCaptionTextField: UITextField!
    @IBOutlet weak var askCaptionTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var selectionImageView: UIImageView!
    @IBOutlet weak var strongImageView: UIImageView!
    @IBOutlet weak var textViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentsTextView: UITextView!
    
    // Background views. These are outlets so they can be cropped into circles.
    @IBOutlet weak var topLeftBackgroundView: UIView!
    @IBOutlet weak var topCenterBackgroundView: UIView!
    @IBOutlet weak var topRightBackgroundView: UIView!
    @IBOutlet weak var bottomRightBackgroundView: UIView!
    @IBOutlet weak var bottomLeftBackgroundView: UIView!
    @IBOutlet weak var helpBackgroundView: UIView!
    
    
    @IBOutlet weak var centralDisplayLabel: UILabel!
    
    @IBOutlet weak var lockedContainersLabel: UILabel!
    @IBOutlet weak var obligatoryReviewsRemainingLabel: UILabel!
    
    
    // Help Display Outlets
    @IBOutlet weak var helpReviewOptimizationLabel: UILabel!
    @IBOutlet weak var helpSwipeLeftNoLabel: UILabel!
    @IBOutlet weak var helpSwipeLeftNoUIImage: UIImageView!
    @IBOutlet weak var helpSwipeRightYesLabel: UILabel!
    @IBOutlet weak var helpSwipeRightYesUIImage: UIImageView!
    @IBOutlet weak var helpLockedQuestionsLabel: UILabel!
    @IBOutlet weak var helpReviewsRemainingLabel: UILabel!
    @IBOutlet weak var helpReturnToMainMenuLabel: UILabel!
    @IBOutlet weak var helpReportLabel: UILabel!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var glassView: UIView!
    
    // Yes and No Buttons
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var yesButton: UIButton!
    
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    
    // MARK: UI Items
    var skipButton: UIButton!
    var skipLabel: UILabel!
    
    let largeImageConfiguration = UIImage.SymbolConfiguration(scale: .large)
    
    // the loading
    var indicator: UIActivityIndicatorView!
    
    // for swipe card
    var centerPoint : CGPoint!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    var question: Question?
    
    var strongFlag: Bool = false
    
    let enterCommentConstant: String = "Enter optional comments here."
    let backgroundCirclesAlphaValue: CGFloat = 0.75
    var strongOriginalSize: CGFloat = 70.0 // this is a placeholder value, updated in viewDidLoad()
    
    
    var recipientList = [String]()
    var usersNotReviewedList = [String]()
    
    var ud = UserDefaults.standard
    
    // MARK: Actions
    @objc func skipButtonTapped(_ sender: UIButton) {
        
        // Displays the skip image for a short duration, then executes the rest of what it means to "skip" a Question
        self.selectionImageView.image = UIImage(systemName: "forward.fill", withConfiguration: largeImageConfiguration)
        // delays specified number of seconds before executing code in the brackets:
        UIView.animate(withDuration: 0.5, delay: 0.3,
                       options: UIView.AnimationOptions.allowAnimatedContent,
                       animations: {
            
            self.selectionImageView.alpha = 0.0
            self.selectionImageView.isHidden = false
        },
                       completion: {
            finished in
            self.selectionImageView.isHidden = true
            // this call executes the remaining skip functionality:
            self.skipReview()
        })
    }
    
    func configureView() {
        strongFlag = false
        strongImageView.isHidden = true
        topCenterBackgroundView.isHidden = true
        
        //flip left swipe image horizontally because it starts out looking like a right swipe image
        if let image = UIImage(named: "swipe_right") {
            let flippedImage = image.withHorizontallyFlippedOrientation()
            helpSwipeLeftNoUIImage.image = flippedImage
            //            setImage(image: flippedImage)
            //            setImage(flippedImage, for: .normal)
        }
        
        
        // unwraps the Ask that was sent over:
        if let thisAsk = question {
            
            print("setting values")
            
            // if saved image is found, load it.
            // else download it
            
            indicator.startAnimating()
            
            
            
            print(thisAsk.captionText_1.isEmpty)
            askCaptionTextField.isHidden = thisAsk.captionText_1.isEmpty // if true hide, else show
            askCaptionTextField.text = thisAsk.captionText_1
            askCaptionTopConstraint.constant = imageView.frame.height * CGFloat(thisAsk.yLoc_1)
            
            lockedContainersLabel.text = "🗝" + String(describing: lockedQuestionsCount)
            
            if obligatoryQuestionsToReviewCount == 0 {
                obligatoryReviewsRemainingLabel.text = String(describing: myProfile.reviewCredits) + "🐿️"
                helpReviewsRemainingLabel.text = reviewCreditsHelpText(on: true)
            }else {
                obligatoryReviewsRemainingLabel.text = String(describing: obligatoryQuestionsToReviewCount) + "📋"
                helpReviewsRemainingLabel.text = reviewCreditsHelpText(on: false)
            }
            
            
            resetTextView(textView: commentsTextView, blankText: enterCommentConstant)
            
            
            startImageLoading(thisAsk)
        }
        
    }
    
    func startImageLoading(_ thisAsk: Question){
        
        
        downloadOrLoadFirebaseImage(
            ofName: getFilenameFrom(qName: thisAsk.question_name, type: thisAsk.type),
            forPath: thisAsk.imageURL_1) { [weak self] image, error in
                
                guard let self = self else {return}
                
                if let error = error{
                    print("Error: \(error.localizedDescription)")
                    self.checkAndLoadAgain(getFilenameFrom(qName: thisAsk.question_name, type: thisAsk.type))
                    return
                }
                
                print("RAVC Image Downloaded for \(thisAsk.question_name)")
                // hide the indicator as we have the image now
                self.indicator.stopAnimating()
                self.imageView.image = image
            }
        
        
    }
    
    // checks if we've been able to download the image already, if not try again
    func checkAndLoadAgain(_ filename: String){
        guard let image = loadImageFromDiskWith(fileName: filename) else {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self = self else {return}
                self.checkAndLoadAgain(filename)
            }
            
            return
        }
        
        print("LIVE CHECKING THIS LINE")
        self.indicator.stopAnimating()
        self.imageView.image = image
    }
    
    // handles the user taps NO button image or words
    @IBAction func noButtonTapped(_ sender: Any) {
        noTapped()
    }
    @IBAction func no2ButtonTapped(_ sender: Any) {
        noTapped()
    }
    func noTapped(){
        displayNoImage()
        //        showSwipeImage(selection: .no)
        finalizeSelection(selection: .no, xCoord: -1.0)
    }
    
    
    // handles the user taps YES button image or words
    @IBAction func yesButtonTapped(_ sender: Any) {
        yesTapped()
    }
    @IBAction func yes2ButtonTapped(_ sender: Any) {
        yesTapped()
    }
    func yesTapped() {
        displayYesImage()
        //        showSwipeImage(selection: .yes)
        
        //        // delays specified number of seconds before executing code in the brackets:
        //        UIView.animate(withDuration: 0.5, delay: 0.3,
        //                       options: UIView.AnimationOptions.allowAnimatedContent,
        //                       animations: {
        //
        //            self.selectionImageView.alpha = 0.0
        //            self.selectionImageView.isHidden = false
        //        },
        //                       completion: {
        //            finished in
        ////            self.selectionImageView.isHidden = true
        //
        //        })
        
        //        self.selectionImageView.alpha = 1.0
        //        self.selectionImageView.isHidden = false
        self.finalizeSelection(selection: .yes, xCoord: 1.0)
        
    }
    
    
    func displayNoImage() {
        self.selectionImageView.image = #imageLiteral(resourceName: "redX")
    }
    
    func displayYesImage() {
        self.selectionImageView.image = #imageLiteral(resourceName: "greencheck")
    }
        
    
    @IBAction func onViewSwiped(_ sender: UIPanGestureRecognizer) {
        
        // view that reacts to pan
        let cardView = sender.view!
        
        // the updated point of this view
        let point = sender.translation(in: cardView)
        
        // move the view accordingly
        
        cardView.center = CGPoint(x:  centerPoint.x + point.x, y:  centerPoint.y - 20)
        
        
        
        switch sender.state {
        case .changed:
            print("changed")
            
            switch sender.direction{
            case .rightToLeft:
                //display no image on screen
                // to ensure we don't show before passing center
                if point.x < 0 {
                    self.displayNoImage()
                    //                    self.selectionImageView.image = #imageLiteral(resourceName: "redX")
                }
                
            case .leftToRight:
                //display yes image on screen
                // to ensure we don't show before passing center
                if point.x > 0{
                    self.displayYesImage()
                    //                    self.selectionImageView.image = #imageLiteral(resourceName: "greencheck")
                }
                
                // display yes image on screen
            default:
                print("default")
            }
            
            self.selectionImageView.alpha = (abs(point.x) * 1.5)/centerPoint.x
            self.selectionImageView.isHidden = false
            
            
            
            
        case .ended:
            print("ended")
            var currentSelection: yesOrNo!
            
            // have no idea why it moved about 20pt from the top
            UIView.animate(withDuration: 0.4) {
                cardView.center = CGPoint(x:self.centerPoint.x, y: self.centerPoint.y - 20)
                self.selectionImageView.alpha = 0
                self.selectionImageView.isHidden = true
            }
            
            switch sender.direction{
            case .rightToLeft:
                currentSelection = .no
                
            case .leftToRight:
                currentSelection = .yes
                
            case .topToBottom:
                
                strongFlag = false
                print("Strong Flag set to: \(strongFlag)")
                hideStrongImage()
                print("Strong Image alpha = \(strongImageView.alpha)")
                
                return
            case .bottomToTop:
                
                // 'Strong' functionality to be uncommented later to see if this is something the users want
                //                strongFlag = true
                //                print("Strong Flag set to: \(strongFlag)")
                //                showStrongImage()
                //                print("Strong Image alpha = \(strongImageView.alpha)")
                
                return // this avoids reloading the form or a segue since it was just an up-swipe
            default:
                print("default")
            }
            
            // only allow create review when the this vc's center is 50% far from center
            
            if abs(point.x)/centerPoint.x > 0.5{
                // do our thing
                if currentSelection != nil{
                    
                    finalizeSelection(selection: currentSelection, xCoord: point.x)
                    //                    self.showSwipeImage(selection: currentSelection)
                    //                    let transition = CATransition()
                    //                    transition.duration = 0.5
                    //                    transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
                    //
                    //                    transition.type = CATransitionType.push //was .reveal, .push is about the smoothest option for this config
                    //                    transition.subtype = point.x > 0 ? CATransitionSubtype.fromLeft : CATransitionSubtype.fromRight
                    //                    self.view.window!.layer.add(transition, forKey: nil)
                }
            }
            
            
        default: break
        }
    }
    
    func finalizeSelection(selection: yesOrNo, xCoord: CGFloat) {
        self.showSwipeImage(selection: selection)
        let transition = CATransition()
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
        
        transition.type = CATransitionType.push //was .reveal, .push is about the smoothest option for this config
        transition.subtype = xCoord > 0 ? CATransitionSubtype.fromLeft : CATransitionSubtype.fromRight
        self.view.window!.layer.add(transition, forKey: nil)
        self.imageView.image = #imageLiteral(resourceName: "loading_large_black.png")
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ReviewAskVC viewDidLoad() called")
        
        centerPoint = mainView.center
        // setup the indicator
        setupIndicator()
        
        //centerPoint = mainView.center
        // This allows user to tap coverView to segue to main menu (if we run out of quetions):
        //        let tapCoverViewGesture = UITapGestureRecognizer(target: self, action: #selector(ReviewAskViewController.userTappedCoverView(_:) ))
        //        coverView.addGestureRecognizer(tapCoverViewGesture)
        //
        //
        
        
        // make sure the coverView wasn't still displayed from a previous showing of this view:
        //hide(coverView: self.coverView, mainView: self.mainView)
        
        /// tells system that the glassView was tapped
        let tapGlassViewGesture = UITapGestureRecognizer(target: self, action: #selector(ReviewAskViewController.glassViewTapped(_:) ))
        glassView.addGestureRecognizer(tapGlassViewGesture)
        
        // Configure UI Elements
        configureSkipButton()
        configureSkipLabel()
        
        // Set up the Yes and No buttons' appearance:
        makeCircle(button: noButton)
        makeCircle(button: yesButton)
        noButton.backgroundColor = .systemRed
        yesButton.backgroundColor = .systemGreen
        noButton.titleLabel?.font = .systemFont(ofSize: 50, weight: .medium)
        noButton.setTitleColor(.white, for: .normal)
        yesButton.titleLabel?.font = .systemFont(ofSize: 50, weight: .medium)
        noButton.titleLabel?.adjustsFontSizeToFitWidth = true
        yesButton.titleLabel?.adjustsFontSizeToFitWidth = true
        noButton.imageEdgeInsets = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
        yesButton.imageEdgeInsets = UIEdgeInsets(top: 25.0, left: 25.0, bottom: 25.0, right: 25.0)
        
        // Crop the background views behind the displays and buttons into circles
        makeCircle(view: self.topLeftBackgroundView, alpha: self.backgroundCirclesAlphaValue)
        makeCircle(view: self.topCenterBackgroundView, alpha: self.backgroundCirclesAlphaValue)
        makeCircle(view: self.topRightBackgroundView, alpha: self.backgroundCirclesAlphaValue)
        makeCircleInverse(view: self.bottomRightBackgroundView, alpha: self.backgroundCirclesAlphaValue)
        makeCircleInverse(view: self.bottomLeftBackgroundView, alpha: self.backgroundCirclesAlphaValue)
        makeCircleInverse(view: self.helpBackgroundView, alpha: 0.0) // this one currently looks dumb with a gray background
        
        self.strongOriginalSize = self.strongImageView.frame.size.height
        self.commentsTextView.translatesAutoresizingMaskIntoConstraints = false
        
        
        // This makes the text view have rounded corners:
        self.commentsTextView.clipsToBounds = true
        self.commentsTextView.layer.cornerRadius = 10.0
        self.commentsTextView.layer.borderColor = UIColor.systemBackground.cgColor
        self.commentsTextView.delegate = self
        self.setTextViewYPosition()
        
        // Hides keyboard when user taps outside of text view
        self.hideKeyboardOnOutsideTouch()
        
        // This will move the caption text box out of the way when the keyboard pops up:
        NotificationCenter.default.addObserver(self, selector: #selector(ReviewAskViewController.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        // This will move the caption text box back down when the keyboard goes away:
        NotificationCenter.default.addObserver(self, selector: #selector(ReviewAskViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
        self.scrollView.delegate = self
        
        // Gesture Recognizers for swiping left and right
        //                    let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(ReviewAskViewController.userSwiped))
        //                    swipeUp.direction = UISwipeGestureRecognizer.Direction.up
        //                    self.view.addGestureRecognizer(swipeUp)
        //
        //                    let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(ReviewAskViewController.userSwiped))
        //                    swipeDown.direction = UISwipeGestureRecognizer.Direction.down
        //                    self.view.addGestureRecognizer(swipeDown)
        //
        //                    let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(ReviewAskViewController.userSwiped))
        //                    swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        //                    self.view.addGestureRecognizer(swipeRight)
        //
        //                    let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(ReviewAskViewController.userSwiped))
        //                    swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        //                    self.view.addGestureRecognizer(swipeLeft)
        
        
        
    } // end of viewDidLoad method
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Calling configureView() any earlier this here messes up the caption location, presumably because the imageView that the top constraint is relative to has not reached its final size yet.
        //        configureView()
        reportButton.removeAttentionRectangle()
        menuButton.removeAttentionRectangle()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { // `0.7` is the desired number of seconds.
            self.showTutorialAlertViewAsRequired()
        }
        
        
    }
    
    override func viewDidLayoutSubviews() {
        print("viewDidLayoutSubviews called")
        super.viewDidLayoutSubviews()
        // Calling configureView() any earlier this here messes up the caption location, presumably because the imageView that the top constraint is relative to has not reached its final size yet.
        configureView()
    }
    
    func showTutorialAlertViewAsRequired() {
        
        let skipAskTutorial = UserDefaults.standard.bool(forKey: Constants.UD_SKIP_REVIEW_ASK_TUTORIAL_Bool)
        
        
        if !skipAskTutorial {
            let alertVC_1 = UIAlertController(title: "Help this person decide WHETHER TO wear this", message: "\nSwipe right or tap the green button if you think they should wear it, if not swipe left or tap the red button. \n\nThey won't see your identity, but your vote will affect the results they see.", preferredStyle: .alert)
            
            let alertVC_2 = UIAlertController(title: "Navigation Tips", message: "Review as many photos as you feel like, then tap the menu button (lower left) to return to home. \n\nTo report offensive content, tap the (!) on the bottom right of the screen.", preferredStyle: .alert)
            alertVC_2.addAction(UIAlertAction.init(title: "Got It!", style: .cancel, handler: { (action) in
            }))
            
            alertVC_1.addAction(UIAlertAction.init(title: "Got It!", style: .cancel, handler: { (action) in
                // Once the user has seen this, don't show it again
                self.ud.set(true, forKey: Constants.UD_SKIP_REVIEW_ASK_TUTORIAL_Bool)
                
                let alreadySawCompareTutorial = UserDefaults.standard.bool(forKey: Constants.UD_SKIP_REVIEW_COMPARE_TUTORIAL_Bool)
                
                // Don't show the second alertView if they already saw it on a Compare. The second alertView is identical for both Question types
                if !alreadySawCompareTutorial {
                    self.present(alertVC_2, animated: true, completion: nil)
                    // wait a little time for the new member to read the tutorial alertView, then show them the menu button to go back. The clock starts once the user taps the first "got it"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in // `0.7` is the desired number of seconds.
                        // add attention rectangle around menu button and report button
                        self.reportButton.addAttentionRectangle()
                        self.menuButton.addAttentionRectangle()
                    }
                }
            }))
            
            present(alertVC_1, animated: true, completion: nil)
            
            
            
            
            
            
            
            
            
        }
        
    }
    
    
    
    
    // KEYBOARD METHODS:
    
    // There is a decent amount of this in viewDidLoad() also
    @objc func keyboardWillShow(_ notification: Notification) {
        // this would look better if we animated a fade in of the coverView (and a fade out lower down)
        mainView.bringSubviewToFront(commentsTextView)
        
        // Basically all this is for moving the textView out of the way of the keyboard while we're editing it:
        self.commentsTextView.textColor = UIColor.black
        
        if self.commentsTextView.text == enterCommentConstant {
            self.commentsTextView.text = ""
        }
        
        //get the height of the keyboard that will show and then shift the text field up by that amount
        if let userInfoDict = notification.userInfo,
           let keyboardFrameValue = userInfoDict [UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            
            let keyboardFrame = keyboardFrameValue.cgRectValue
            
            //this makes the text box movement animated so it looks smoother:
            UIView.animate(withDuration: 0.8, animations: {
                
                self.textViewTopConstraint.constant = UIScreen.main.bounds.height - keyboardFrame.size.height - self.topLayoutGuide.length - self.commentsTextView.frame.size.height
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        //this makes the text box movement animated so it looks smoother:
        UIView.animate(withDuration: 1.0, animations: {
            //moves the textView back to its original location:
            self.setTextViewYPosition()
            
        })
        // If the user has entered no text in the titleTextField, reset it to how it was originally:
        if self.commentsTextView.text == "" {
            resetTextView(textView: commentsTextView, blankText: enterCommentConstant)
        }
        self.view.layoutIfNeeded()
    }
    
    // This dismisses the keyboard when the user clicks the DONE button on the keyboard
    func textViewShouldReturn(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    // END KEYBOARD METHODS
    
    /// This positions the textView correctly so that it's not covering up the image (or too low)
    func setTextViewYPosition() {
        textViewTopConstraint.constant = helperView.frame.size.height * 1.1
    }
    
    func createReview(selection: yesOrNo) {
        
        var strong: yesOrNo? = nil
        if strongFlag == true { strong = selection }
        
        // unwrap the ask again to pull its questionName:
        
        if let question = question{
            // send docID
            let createdReview: AskReview = AskReview(selection: selection, strong: strong, comments: commentsTextView.text, questionName: question.question_name)
            
            print("List updating for review Before R: \(self.recipientList.count) U: \(self.usersNotReviewedList.count)")
            print("List updating for review QQQ R: \(question.recipients.count) U: \(question.usersNotReviewedBy.count)")
            // update the list
            
            var unrSet = Set<String>()
            
            for item in question.usersNotReviewedBy{
                
                if item != myProfile.username{
                    unrSet.insert(item)
                }
                
            }
            
            usersNotReviewedList = Array(unrSet)
            
            
            // update the list of q sent to
            var rList = Set<String>()
            
            
            // this rebuilds the entire recipients list making sure that all instances of my username are gone
            // Shouldn't be necessary anymore
            for item in question.recipients{
                
                if item != myProfile.username{
                    rList.insert(item)
                }
            }
            
            recipientList = Array(rList)
            
            
            // do local updates
            updateCountOnReviewQues()
            // send review to firebase
            save(askReview: createdReview)
            
            // Log Analytics Event
            Analytics.logEvent(Constants.REVIEW_QUESTION, parameters: nil)
            
        }
        
        print("new review created.")
        if let bvc = blueVC{
            bvc.showNextQues()
        }
        
    } // end of createReview
    
    
    /* When skipping a Question:
     All the same things happen that do when the user has reviewed a Question EXCEPT:
     -no review is created
     -no review credit increment / review required decrement
     -display some kind of skipped icon instead of the heart or X
     -app still cycles to the next Q
     -reviewing user’s username is still removed from usersNotSentTo
     */
    func skipReview() {
        // need an animation where the card just drops down (similar to Compares) instead of swiping left or right
        
        // unwrap the ask again to pull its questionName:
        if let question = question {
            // send docID
            
            print("List updating for review Before R: \(self.recipientList.count) U: \(self.usersNotReviewedList.count)")
            print("List updating for review QQQ R: \(question.recipients.count) U: \(question.usersNotReviewedBy.count)")
            // update the list
            
            // unr stands for "users not reviewed"
            var unrSet = Set<String>()
            
            // this is building a new usersNotReviewedBy list that does not include my username
            for item in question.usersNotReviewedBy{
                if item != myProfile.username{
                    unrSet.insert(item)
                }
            }
            
            let myUserProfile = RealmManager.sharedInstance.getProfile()
            
            usersNotReviewedList = Array(unrSet)
            
            // update the list of q sent to
            var rList = Set<String>()
            
            // this rebuilds the entire recipients list making sure that all instances of my username are gone
            // Shouldn't be necessary anymore
            for item in question.recipients{
                
                if item != myProfile.username{
                    rList.insert(item)
                }
            }
            
            recipientList = Array(rList)
            
            // Removes the localUser's name from a Question's usersNotSentTo list (or recipient list if sent to him from a friend) in firestore
            Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(question.question_name).updateData(
                [//The below calls just delete the local user's username from the lists. Simpler and less errors.
                    Constants.QUES_RECEIP_KEY: FieldValue.arrayRemove([myProfile.username]),
                    Constants.QUES_USERS_NOT_REVIEWED_BY_KEY: FieldValue.arrayRemove([myProfile.username])
                ]){_ in
                    
                    //why are we removing all the names from this? Didn't we just update it?
                    // or is this just clearing it out for the next Question?
                    self.recipientList.removeAll()
                    self.usersNotReviewedList.removeAll()
                }
            
            // Log Analytics Event
            Analytics.logEvent(Constants.SKIP_QUESTION, parameters: nil)
            
        }
        
        self.imageView.image = #imageLiteral(resourceName: "loading_large_black.png")
        
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
    } // end of skipReview
    
    
    /// When user swipes up, a 'strong' image displays.
    func showStrongImage() {
        ////
        // Here we will manipulate the strong center background image instead of the imageView
        ////
        
        // We may just want to fade it in instead of changing the size
        self.topCenterBackgroundView.isHidden = false
        self.strongImageView.isHidden = false
        self.centralDisplayLabel.isHidden = true
        
        
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
    
    // Hides the strong image.
    func hideStrongImage() {
        //uncomment upon restoring strong like functionality
        //        self.centralDisplayLabel.isHidden = false
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIView.AnimationOptions.beginFromCurrentState, animations: {
            self.strongImageView.frame.size.height = self.strongOriginalSize * 0.0001
            self.strongImageView.frame.size.width = self.strongOriginalSize * 0.0001
            self.topCenterBackgroundView.alpha = 0.0
            
            // We could also try to animate a change in the alpha instead to let it fade in
        }, completion: {
            finished in
            self.topCenterBackgroundView.isHidden = true
        })
    } // end of hideStrongImage()
    
    
    /// Create an AskReview in Firestore
    func save(askReview: AskReview) {
        var strongValue: String
        if let strong = askReview.strong {
            switch strong {
            case .yes: strongValue = "yes"
            case .no: strongValue = "no"
            }
        } else {
            strongValue = "nil"
        }
        
        let newAskReview: [String: Any] = [ "questionName": askReview.reviewID.questionName,
                                            "comments": askReview.comments,
                                            "reviewerUserName": askReview.reviewer.username,
                                            "reviewerDisplayName": askReview.reviewer.display_name,
                                            "reviewerProfilePictureURL": askReview.reviewer.profile_pic,
                                            "reviewerAge": getAgeFromBdaySeconds(askReview.reviewer.birthday),
                                            "reviewerBirthday": askReview.reviewer.birthday,
                                            "reviewerOrientation": askReview.reviewer.orientation,
                                            "reviewerSignUpDate": askReview.reviewer.created,
                                            "reviewerReviewsRated": askReview.reviewer.reviews,
                                            "reviewerScore": askReview.reviewer.rating,
                                            "selection": askReview.selection.rawValue,
                                            "strong": strongValue // this is different because strong is an optional yesOrNo enum.
        ]
        
        /// Store the review document to the path we want and it creates the appropriate collection if needed, or adds to the existing one automatically.
        
        let docID = Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(askReview.reviewID.questionName).collection(Constants.QUES_REVIEWS).document().documentID
        
        Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(askReview.reviewID.questionName).collection(Constants.QUES_REVIEWS).document(docID).setData(newAskReview){ (error) in
            if let error = error {
                print("questionsRef.document().setData(newAsk):  **error in saving review document for \(askReview.reviewID.questionName); \(error)**")
                
            } else {
                print("ASK: review done for question \(askReview.reviewID.questionName)")
                // Updates the reviewed Question's usersSentTo list by adding the reviewerUserName to it.
                // EDIT MM 2: Do we need the following line anymore? we aren't getting any question twice anyway
                //                Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(askReview.reviewID.questionName).updateData([Constants.QUES_RECEIP_KEY: FieldValue.arrayUnion([askReview.reviewer.username])])
                print("List updating for review R: \(self.recipientList.count) U: \(self.usersNotReviewedList.count)")
                
                Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(askReview.reviewID.questionName).updateData(
                    [Constants.QUES_REVIEWS: FieldValue.increment(Int64(1)), // Increment the number of reviews for the Question that just got reviewed.
                     //                     Constants.QUES_RECEIP_KEY: self.recipientList,
                     //                     Constants.QUES_USERS_NOT_REVIEWED_BY_KEY: self.usersNotReviewedList,
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
    
    
    
    
    
    
    
    /*
     func showStrongImage() {
     self.strongImageView.isHidden = false
     UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.beginFromCurrentState, animations: {
     self.strongImageView.frame.size.height = self.strongOriginalSize * 2.0
     self.strongImageView.frame.size.width = self.strongOriginalSize * 2.0
     // I could also try to animate a change in the alpha instead to let it fade in
     // I'm pretty sure that will work.
     }, completion: {
     finished in
     
     })
     self.strongImageView.frame.size.height = self.strongOriginalSize
     self.strongImageView.frame.size.width = self.strongOriginalSize
     } // end of showStrongImage
     
     
     func hideStrongImage() {
     UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.beginFromCurrentState, animations: {
     self.strongImageView.frame.size.height = self.strongOriginalSize * 0.0001
     self.strongImageView.frame.size.width = self.strongOriginalSize * 0.0001
     //self.strongImageView.isHidden = true
     // I could also try to animate a change in the alpha instead to let it fade in
     // I'm pretty sure that will work.
     }, completion: {
     finished in
     self.strongImageView.isHidden = true
     })
     
     
     
     } // end of hideStrongImage()
     */
    /// Shows swipe image AND calls functionality to create a review
    func showSwipeImage(selection: yesOrNo) {
        
        switch selection {
        case .yes:
            displayYesImage()
        case .no:
            displayNoImage()
        }
        
        
        // delays specified number of seconds before executing code in the brackets:
        UIView.animate(withDuration: 0.5, delay: 0.3,
                       options: UIView.AnimationOptions.allowAnimatedContent,
                       animations: {
            
            self.selectionImageView.alpha = 0.0
            self.selectionImageView.isHidden = false
        },
                       completion: {
            finished in
            self.selectionImageView.isHidden = true
            // finally create review
            self.createReview(selection: selection)
        })
        
    }
    
    //    func segueToReviewCompareViewController() {
    //        // pop this VC off the stack
    //        //self.navigationController?.popViewController(animated: false)
    //
    //        ////////////
    //        // ok this works when the above line is commented out but is there a way to push the next VC and then pop the next one below that in the background without the user seeing?
    //
    //
    //        ///////        /////////
    //        // Untested thus far: //
    //        ///////         ////////
    //        if let navController = self.navigationController {
    //            let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "reviewCompareViewController") as! ReviewCompareViewController
    //            //let newVC = DestinationViewController(nibName: "DestinationViewController", bundle: nil)
    //
    //            var stack = navController.viewControllers
    //            stack.remove(at: stack.count - 1)       // remove current VC
    //            stack.insert(nextVC, at: stack.count) // add the new one
    //            navController.setViewControllers(stack, animated: false) // boom!
    //        }
    //
    //
    //    }
    
    
    // Allows the user to zoom within the scrollView that the user is manipulating at the time.
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollView.setZoomScale(1.0, animated: true)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    @IBAction func reportButtonTapped(_ sender: Any) {
        
        //pop up a menu and find out what kind of report the user wants
        print("report content button tapped")
        
        // we pass the processReport function here so that the system will wait for the alert controller input before continuing on:
        showReportSheet()
        
    }
    
    // MARK: This needs to be fixed. Currently does not display any of the reportType enum cases.
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
        // show animation?
        processReport()
        // MARK: Implement if necessary
        // fetch my username
        let username = RealmManager.sharedInstance.getProfile().username
        
        do {
            try Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(report.questionName).collection(Constants.QUES_REPORTS).addDocument(from: report,completion: { error in
                if let error = error {
                    self.presentDismissAlertOnMainThread(title: "Error", message: error.localizedDescription)
                    return
                } else {
                    print("User reported for question \(report.questionName)")
                    // don't want to see again
                    // Line 465 => EDIT MM 2: Do we need the following line anymore? we aren't getting any question twice anyway
                    
                    //                    Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(report.questionName).updateData([Constants.QUES_RECEIP_KEY: FieldValue.arrayUnion([username])])
                    
                    Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(report.questionName).updateData(
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
        self.selectionImageView.image = #imageLiteral(resourceName: "redexclamation")
        self.selectionImageView.alpha = 0.9
        self.selectionImageView.isHidden = false
        // delays specified number of seconds before executing code in the brackets:
        UIView.animate(withDuration: 0.5, delay: 0.3, options: UIView.AnimationOptions.allowAnimatedContent, animations: {self.selectionImageView.alpha = 0.0}, completion: { finished in
            self.selectionImageView.isHidden = true
            // load next is controlled from BlueVC
        })
    }
    
    
    @IBAction func helpButtonTapped(_ sender: Any) {
        toggleHelpDisplay()
    }
    
    /// shows or hides all the help labels and glassView depending on whether they are hidden at the time it's called
    func toggleHelpDisplay() {
        
        let hidden = helpReviewOptimizationLabel.isHidden ||
        helpSwipeLeftNoLabel.isHidden ||
        helpSwipeLeftNoUIImage.isHidden ||
        helpSwipeRightYesLabel.isHidden ||
        helpSwipeRightYesUIImage.isHidden ||
        helpLockedQuestionsLabel.isHidden ||
        helpReviewsRemainingLabel.isHidden ||
        helpReturnToMainMenuLabel.isHidden ||
        helpReportLabel.isHidden
        
        if hidden {
            glassView.isHidden = false
            self.view.bringSubviewToFront(glassView)
            self.view.bringSubviewToFront(helpReviewOptimizationLabel)
            self.view.bringSubviewToFront(helpSwipeLeftNoLabel)
            self.view.bringSubviewToFront(helpSwipeLeftNoUIImage)
            self.view.bringSubviewToFront(helpSwipeRightYesLabel)
            self.view.bringSubviewToFront(helpSwipeRightYesUIImage)
            self.view.bringSubviewToFront(helpLockedQuestionsLabel)
            self.view.bringSubviewToFront(helpReviewsRemainingLabel)
            self.view.bringSubviewToFront(helpReturnToMainMenuLabel)
            self.view.bringSubviewToFront(helpReportLabel)
            
            if let image = UIImage(named: "question circle green") {
                helpButton.setImage(image, for: .normal)
            }
            
            self.helpReviewOptimizationLabel.fadeInAfter(seconds: 0.0)
            helpSwipeLeftNoLabel.fadeInAfter(seconds: 0.0)
            helpSwipeLeftNoUIImage.alpha = 1.0
            helpSwipeRightYesLabel.fadeInAfter(seconds: 0.0)
            helpSwipeRightYesUIImage.alpha = 1.0
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
            helpSwipeLeftNoLabel.fadeOutAfter(seconds: 0.0)
            helpSwipeLeftNoUIImage.alpha = 0.0
            helpSwipeRightYesLabel.fadeOutAfter(seconds: 0.0)
            helpSwipeRightYesUIImage.alpha = 0.0
            self.helpLockedQuestionsLabel.fadeOutAfter(seconds: 0.0)
            self.helpReviewsRemainingLabel.fadeOutAfter(seconds: 0.0)
            self.helpReturnToMainMenuLabel.fadeOutAfter(seconds: 0.0)
            self.helpReportLabel.fadeOutAfter(seconds: 0.0)
            
        }
        // if the glassView is visible, user interaction should be enabled, otherwise, it should be disabled.
        glassView.isUserInteractionEnabled = !glassView.isHidden
    }
    
    @objc func glassViewTapped(_ sender: UITapGestureRecognizer? = nil) {
        toggleHelpDisplay()
    }
    
    
    
    @IBAction func menuButtonTapped(_ sender: Any) {
        print("Menu button tapped")
        // This may need to be adjusted depending on how we segue between asks and compares
        returnToMainMenu()
    }
    
    //    @objc func userTappedCoverView(_ pressImageGesture: UITapGestureRecognizer){
    //        print("user tapped coverView")
    //        if tapCoverViewToSegue == true {
    //            returnToMainMenu()
    //        } else {
    //            commentsTextView.resignFirstResponder()
    //        }
    //    }
    
    func returnToMainMenu() {
        if let blueVC = blueVC{
            blueVC.returnToMenu()
        }
        
    }
    // I need a way to switch between the two Review Controllers without
    //  stacking up multiple instances of them on top of each other.
    
    // to show the loading
    func setupIndicator() {
        indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        indicator.color = .white
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        indicator.center = CGPoint(x: view.center.x, y: selectionImageView.center.y)
        view.addSubview(indicator)
        indicator.bringSubviewToFront(view)
        
    }
    
    // MARK: PROGRAMMATIC UI
    func configureSkipButton(){
        skipButton = UIButton()
        
        skipButton.setImage(UIImage(systemName: "forward.fill", withConfiguration: largeImageConfiguration), for: .normal)
        
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skipButton)
        
        NSLayoutConstraint.activate([
            skipButton.centerYAnchor.constraint(equalTo: yesButton.centerYAnchor),
            skipButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            // I don't think these h/w constraints are doing anything:
            skipButton.heightAnchor.constraint(equalToConstant: 20),
            skipButton.widthAnchor.constraint(equalToConstant: 30)
            
        ])
        
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
    }
    
    func configureSkipLabel(){
        skipLabel = UILabel()
        //        let largeConfiguration = UIImage.SymbolConfiguration(scale: .large)
        
        
        //        skipButton.setImage(UIImage(systemName: "forward.fill", withConfiguration: largeConfiguration), for: .normal)
        
        skipLabel.text = "Skip"
        skipLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        skipLabel.textColor = .label
        skipLabel.textAlignment = .center
        
        skipLabel.textColor = .systemBlue
        
        skipLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skipLabel)
        
        NSLayoutConstraint.activate([
            skipLabel.topAnchor.constraint(equalTo: skipButton.bottomAnchor, constant: 0),
            skipLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
        ])
    }
}



