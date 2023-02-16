//
//  MainVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-28.
//  com.tangerineinsight.tangerineMM

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics
import FirebaseRemoteConfig
import RealmSwift
import BadgeHub



class MainVC: UIViewController {
    
    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - View Controller methods
     */
    /******************************************************************************************************************************/
    
    // view for friends
    @IBOutlet weak var friendsBtn: UIButton!
    @IBOutlet weak var reviewOthersBtn: UIButton!
    
    var minimumAge:Int = 18
    var maximumAge:Int = 99
    
    var ud = UserDefaults.standard
    
    var prefs: UserDefaults!
    /// badge
    var friendBadgeHub : BadgeHub!
    var qffBadgeHub : BadgeHub!
    
    // Help Display Outlets
    
    @IBOutlet weak var helpSharePhotoLabel: UILabel!
    @IBOutlet weak var helpViewResultsLabel: UILabel!
    @IBOutlet weak var helpReviewOthersLabel: UILabel!
    @IBOutlet weak var helpFriendsLabel: UILabel!
    @IBOutlet weak var helpProfileAndSettingsLabel: UILabel!
    @IBOutlet weak var helpHomepageLabel: UILabel!
    @IBOutlet weak var helpTutorialLabel: UILabel!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var glassView: UIView!
    @IBOutlet weak var cameraButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var reviewOthersButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewResultsButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var spacerView1: UIView!
    
    //Button outlets
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var reviewOthersButton: UIButton!
    //this one is redundant with reviewOthersBtn
    @IBOutlet weak var viewResultsButton: UIButton!
    
    
    //Label Outlets
    @IBOutlet weak var getOpinionsLabel: UILabel!
    @IBOutlet weak var giveOpinionsLabel: UILabel!
    @IBOutlet weak var viewResultsLabel: UILabel!
    
    // UI Items:
    var tutorialLabel: UILabel!
    var cancelTutorialButton: UIButton!
    
    // to track if both qff and frCount has finished updating locally
    var applicationBadgeNumber = 0
    
    /// Other ViewControllers can access this to take themselves back to this VC.
    /// Detailed instructions on an 'unwind' segue and its use here: https://www.andrewcbancroft.com/2015/12/18/working-with-unwind-segues-programmatically-in-swift/
    @IBAction func unwindToMainVC(segue: UIStoryboardSegue) {}
    
    
    // for share photo label
    @IBAction func onSharePhotoTapped(_ sender: UITapGestureRecognizer) {
        
        performSegue(withIdentifier: "camera_vc", sender: self)
    }
    
    
    
    @IBAction func onAPTapped(_ sender: Any) {
        print("ActvPht/view result")
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ask_tvc") as! ActiveQuestionsVC
        
        vc.modalPresentationStyle = .fullScreen
        self.presentFromRight(vc)
        
        //        self.present(vc, animated: true, completion: nil)
    }
    
    
    // answer question tapped
    
    
    @IBAction func onAQTapped(_ sender: Any) {
        print("AnsQ/Rev other")
        // maybe create a list of questions then decide which view to show?
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "blue_vc") as! ReviewOthersVC
        
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
        
    }
    
    // friends tapped
    
    @IBAction func onFriendsTapped(_ sender: Any) {
        print("Friends")
        let vc = FriendsVC()
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    
    // when the profile and settings tapped
    @IBAction func onProfileTapped(_ sender: Any) {
        
        
        let vc = ProfileSettingsTabBarController()
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func onCancelTutorialTapped() {
        // set all Bools to skip tutorial
        self.setTutorialMode(on: false)
    }
    
    /******************************************************************************************************************************/
    
    /******************************************************************************************************************************/
    
    /// to toggle all switches based on noPrefSw
    func fetchTD(){

        // access the auth object, we saved the username as displayname
        if let user = Auth.auth().currentUser, let username = user.displayName{
          print("Fetching TD: \(username), \(FirebaseManager.shared.getUsersCollection())")
            // save to target demo
            Firestore.firestore()
                .collection(FirebaseManager.shared.getUsersCollection())
                .document(username)
                .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
                .document(Constants.USERS_PRIVATE_INFO_DOC).getDocument(completion: {snapshot, err in
                    if let err = err{
                        self.presentDismissAlertOnMainThread(title: "Server Error", message: err.localizedDescription)
                        
                        return
                    }
                    
                    if let doc = snapshot?.data(){
                        print("Fetched TD, saving")
                        // we know it exists, but firebase doesn't so it yells at us
                        let data = doc[Constants.USER_TD_KEY] as! [String : Any]
                        
                        let stWoman = data[Constants.UD_ST_WOMAN_Bool] as? Bool ?? false
                        let gMan = data[Constants.UD_GMAN_Bool] as? Bool ?? false
                        let stMan = data[Constants.UD_ST_MAN_Bool] as? Bool ?? false
                        let gWoman = data[Constants.UD_GWOMAN_Bool] as? Bool ?? false
                        let other = data[Constants.UD_OTHER_Bool] as? Bool ?? false
                        
                        self.minimumAge = data[Constants.UD_MIN_AGE_INT] as? Int ?? 18
                        self.maximumAge = data[Constants.UD_MAX_AGE_INT] as? Int ?? 99
                        
                        let questionToReview = doc[Constants.UD_QUESTION_TO_REVIEW_KEY] as? Int ?? 0
                        let lockedQuestionCount = doc[Constants.UD_LOCKED_QUESTION_KEY] as? Int ?? 0
                        
                        // save these two in UD
                        print("QR: \(questionToReview) LQ: \(lockedQuestionCount)")
                        
                        if self.minimumAge == 0{
                            self.minimumAge = 18
                        }
                        
                        if self.maximumAge == 0{
                            self.maximumAge = 99
                        }
                        
                        
                        // save the fetched values
                        self.saveValues(stWoman,stMan,gWoman,gMan,other,questionToReview,lockedQuestionCount)
                    }
                })
        }// end of user
        
    }
    
    func saveValues(_ stWoman:Bool, _ stMan:Bool, _ gWoman: Bool, _ gMan: Bool, _ other: Bool, _ quesToReview: Int, _ lockedCount: Int){
        
        // set the dancing value to UD
        prefs.setValue(stWoman, forKey: Constants.UD_ST_WOMAN_Bool)
        // set the lifestyle value to UD
        prefs.setValue(stMan, forKey: Constants.UD_ST_MAN_Bool)
        // set the sports value to UD
        prefs.setValue(gWoman, forKey: Constants.UD_GWOMAN_Bool)
        // set the music value to UD
        prefs.setValue(gMan, forKey: Constants.UD_GMAN_Bool)
        // set the other value to UD
        prefs.setValue(other, forKey: Constants.UD_OTHER_Bool)
        
        
        // save the min age to UD
        prefs.setValue(minimumAge, forKey: Constants.UD_MIN_AGE_INT)
        // save the max age to UD
        prefs.setValue(maximumAge, forKey: Constants.UD_MAX_AGE_INT)
        
        // the counts
        prefs.set(quesToReview, forKey: Constants.UD_QUESTION_TO_REVIEW_KEY)
        prefs.set(lockedCount,forKey: Constants.UD_LOCKED_QUESTION_KEY)
        
        // set these first
        lockedQuestionsCount = lockedCount
        obligatoryQuestionsToReviewCount = quesToReview
        
        //        updateNumLockedQuestionsInFirestore()
    }
    
    
    
    
    
    
    /******************************************************************************************************************************/
    
    
    
    //    override func viewWillAppear(_ animated: Bool) {
    //        // dismiss all view controllers to keep the memory clean
    //        self.view.window?.rootViewController?.dismiss(animated: false, completion: nil)
    //    }
    
    
    override func viewDidLoad() {
        print("Main vc view did load x W z")
        super.viewDidLoad()
        
        prefs = UserDefaults.standard
        // update the TD
        fetchTD()
        
        // update myFriendNames list
        fetchMyFriendNamesFromFirestore()
        
        // Display label explaining to user how to use help button
        // This is in ViewDidLoad so that it doesn't appear as often.
        let inWaitTime: Double = 10.0
        let outWaitTime: Double = 7.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { // `0.4` is the desired number of seconds.
            self.helpTutorialLabel.fadeInAfter(seconds: inWaitTime)
            self.helpTutorialLabel.fadeOutAfter(seconds: outWaitTime)
            
        }
        
        configureTutorialLabel()
        configureCancelTutorialButton()
        
        // remote config split testing calls:
        setupRemoteConfigDefaults()
        fetchRemoteConfig()
        
        /// tells system that the glassView was tapped
        let tapGlassViewGesture = UITapGestureRecognizer(target: self, action: #selector(ReviewAskViewController.glassViewTapped(_:) ))
        glassView.addGestureRecognizer(tapGlassViewGesture)
        
        
        UIApplication.shared.windows.first?.rootViewController = self
        //UIApplication.shared.windows.first?.makeKeyAndVisible()
        
        // setup the review count
        qffBadgeHub = BadgeHub(view: reviewOthersBtn)
        
        qffBadgeHub.scaleCircleSize(by: 0.75)
        qffBadgeHub.moveCircleBy(x: 5.0, y: 0)
        
        //setup friend count hub
        friendBadgeHub = BadgeHub(view: friendsBtn)
        friendBadgeHub.setCount(0)
        
        friendBadgeHub.scaleCircleSize(by: 0.75)
        friendBadgeHub.moveCircleBy(x: 5.0, y: 0)

        // ensure user properties are up to date for firebase analytics purposes
        updateAnalyticsUserProperties()
        
        // Set Cohort ID from Constants.swift
        Analytics.setUserProperty(Constants.CURRENT_COHORT_ID, forName: "cohortID")
        
        // for notification
        addObservers()

      // for sandbox
      showSandboxBanner()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("MainVC Appeared")
        
        //setup qff count hub
        
        keyboardIsVisible = false // there is no keyboard option on main vc so let's reset this field to false
        
        centerMainIconsVertically()
        // checks if we have enough questions, if not fetches some
        checkForQuestionsToFetch(){
            print("Completed fetching Questions from MainVC")
            self.updateQFFCount()
            updateBadgeCount()
        }
        
        // fetch the active question or questions that I posted
        fetchActiveQuestions { questions, error in
            if error != nil{
                print("Fetch Active: \(error?.localizedDescription)")
                return
            }
            
            print("Success fetching my active Questions! Total Questions downloaded: \(myActiveQuestions.count)")
        } // end fetch active
        
        
        
        // wyatt knows
        clearOutCurrentCompare()
        
        
        
        
        // now fetch and update count
        updateFriendReqCount()
        updateQFFCount()
        
        // Just a quick hack to update the application badge number from local var
        applicationBadgeNumber = 0
        
        // if the glassView is visible, user interaction should be enabled, otherwise, it should be disabled.
        glassView.isUserInteractionEnabled = !glassView.isHidden
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { // `0.7` is the desired number of seconds.
            self.showTutorialAsRequired()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("VWA")
        
        // this was added to facilitate a smoother visual experience while resetting the vertical constraints of the main icons during the A-B test of cohort0. No need to keep doing this, just be sure to delete the hiding and re-showing of the icons in the centerMainIconsVertically() method.
        makeMainVCIcons(visible: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("MainVC Disappeared")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        
    }
    
    @IBAction func websiteButtonTapped(_ sender: Any) {
        print("website button tapped on main vc")
        
        if let url = URL(string: "https://letstangerine.com") {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func helpButtonTapped(_ sender: Any) {
        toggleHelpDisplay()
    }
    
    // display the number of pending friend request that I haven't accepted yet
    
    func updateFriendReqCount(){
        
        Firestore.firestore()
            .collection(FirebaseManager.shared.getUsersCollection())
            .document(myProfile.username)
            .collection(Constants.USERS_LIST_SUB_COLLECTION)
            .whereField(Constants.USER_STATUS_KEY, isEqualTo: Status.PENDING.description)
            .addSnapshotListener { snapshot, error in
                print("Friend Req Count")
                // to make sure we don't add the already added ones
                self.friendBadgeHub.setCount(0)
                friendReqCount = 0
                if error != nil {
                    print("Sync error \(String(describing: error?.localizedDescription))")
                    return
                }
                
                
                if let docs = snapshot?.documents{
                    if docs.count > 0 {
                        
                        
                        for item in docs{
                            // save the friend names
                            let status = getStatusFromString(item.data()[Constants.USER_STATUS_KEY] as! String)
                            if status == .PENDING{
                                self.friendBadgeHub.increment()
                                friendReqCount += 1
                            }
                            
                        }
                        print("Sync done")
                        self.friendBadgeHub.blink()
                        updateBadgeCount()
                        
                    }
                    
                }// end if let
                
            }
        // no need to show alert here
        
        
    }
    
    
    /// Updates the Questoins From Friends count to be displayed on the badge associated with the Review Others icon.
    @objc func updateQFFCount(){
        print("Setting QFF to \(qFFCount) \(filteredQuestionsToReview.count)")
        if qFFCount > 0 {
            qffBadgeHub.setCount(qFFCount)
        }else{
            qffBadgeHub.setCount(0)
        }
        
    }
    
    deinit {
        removeObservers()
    }
    
    func addObservers(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateQFFCount),
            name: NSNotification.Name(rawValue: Constants.QFF_NOTI_NAME) ,
            object: nil
        )
    }
    
    func removeObservers(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.QFF_NOTI_NAME), object: nil)
    }
    
    
    /// Hides or show the MainVC icons as requested
    func makeMainVCIcons(visible: Bool) {
        let hide = !visible
        
        cameraButton.isHidden = hide
        getOpinionsLabel.isHidden = hide
        reviewOthersBtn.isHidden = hide
        giveOpinionsLabel.isHidden = hide
        viewResultsButton.isHidden = hide
        viewResultsLabel.isHidden = hide
    }
    
    /// centers the buttons in the view equally between the top of the view and the logout button by making the bottom constraint value equal to the top constraint value.
    func centerMainIconsVertically() {

        
        makeMainVCIcons(visible: false) //hide the icons before we move them


        
        // these need to create the proper top constraint distance to even out but they also need to postion the icon in the right spot, which it is currently not doing
        // we have the size of all elements so we can compute from each other what the otehr one should be

        // Split test code that was here can be found at:
        // https://docs.google.com/document/d/1e8eo-wDztZUOkRP_9cptoR2paDTYKLTiXxlQ7rVxKGk/edit?usp=share_link
        
        // Original Setup with Camera on top as first icon
        let topDistance: CGFloat = cameraButtonTopConstraint.constant
        let bottomDistance: CGFloat = spacerView1.frame.height

        let combinedDistance = topDistance + bottomDistance
        let halfDistance = combinedDistance / 2.0


//            print("cameraButtonTopConstraint before reset is \(cameraButtonTopConstraint.constant)")
//            print("bottomConstraint before reset is \(spacerView1.frame.height)")
        cameraButtonTopConstraint.constant = halfDistance
        //        spacerView1.frame.height = halfDistance

//            print("cameraButtonTopConstraint AFTER reset is \(cameraButtonTopConstraint.constant)")
//            print("bottomConstraint AFTER reset is \(spacerView1.frame.height)")

        let heightOfIcon: CGFloat = 60
        let heightOfLabel: CGFloat = 21
        let verticalSpaceBetweenIcons: CGFloat = 50

        reviewOthersButtonTopConstraint.constant = cameraButtonTopConstraint.constant + heightOfIcon + heightOfLabel + verticalSpaceBetweenIcons
        
        // added after RO_ON_TOP split test completion:
        viewResultsButtonTopConstraint.constant = reviewOthersButtonTopConstraint.constant + heightOfIcon + heightOfLabel + verticalSpaceBetweenIcons
        
        
        
    makeMainVCIcons(visible: true) // show them once we're done moving them
        
        
    }
    
    /// Sets all of the tutorial user default skip modes to true or all to false as desired
    func setTutorialMode(on: Bool) {
        TutorialTracker().setTutorialMode(on: on)
        
        
        if !on {
            // set tutorial mode to complete if we're turning off the tutorial
            TutorialTracker().setTutorial(phase: .step5_Complete)
            
            // remove any labels and rectangles
            removeAllTutorialAttentionRectangles()
            
            // show tutorial one last time to clean everything up
            showTutorial()
        }
    }
    
    /// Checks to see if there are any tutorial steps left to complete on MainVC
    func showTutorialAsRequired() {
        let skipTutorial = UserDefaults.standard.bool(forKey: Constants.UD_SKIP_MAINVC_TUTORIAL_Bool)
        
        if !skipTutorial {
            showTutorial()
        }
        
        if needToClearOutMainVCTutorial {
            setTutorialMode(on: false)
            needToClearOutMainVCTutorial = false // then reset it to false since we are now going to clean up the view
        }
    }
    
    func removeAllTutorialAttentionRectangles() {
        // remove any labels and rectangles
        reviewOthersButton.removeAttentionRectangle()
        cameraButton.removeAttentionRectangle()
        friendsBtn.removeAttentionRectangle()
        viewResultsButton.removeAttentionRectangle()
        tutorialLabel.text = "Exiting Tutorial...👋 "
        tutorialLabel.fadeOutAfter(seconds: 0.7)
        cancelTutorialButton.isHidden = true
    }
    
    /// Highlights the appropriate icon as the next part of the tutorial
    func showTutorial() {
        let phase = TutorialTracker().getTutorialPhase()
        //show cancel button
        cancelTutorialButton.isHidden = false
        
        //MARK:  we also need something where if they user taps somewhere else, it just shows them this next time or maybe even cancels the tutorial
        
        
        // Based on what tutorial phase we're in, we decide what to show the new member
        switch phase {
        case .step0_Intro:
            removeAllTutorialAttentionRectangles()
            tutorialLabel.isHidden = true
            cancelTutorialButton.isHidden = true
            // Displays an alertView which asks the member if he or she wants to get tutorial help
            let alertVC = UIAlertController(title: "Welcome to the Community!", message: "Would you like some help using the app for the first time? \nYou can adjust this later in settings.", preferredStyle: .alert)
            
            //Actions if memeber decides to go through the tutorial
            alertVC.addAction(UIAlertAction(title: "Sure!", style: .default, handler: { (action: UIAlertAction!) in
                print("Will continue with tutorial")
                // Enable all tutuorial elements
                self.setTutorialMode(on: true)
                // Once the member has seen this alertView once, we don't want to show it again, even if they do want to go through the tutorial
                
                TutorialTracker().setTutorial(phase: .step1_ReviewOthers)
                self.showTutorial()
            }))
            
            //Actions if the member declines the tutorial
            alertVC.addAction(UIAlertAction(title: "No Thanks", style: .cancel, handler: { (action: UIAlertAction!) in
                print("Will CANCEL tutorial")
                // Skip all tutorial elements
                self.ud.set(true, forKey: Constants.UD_SKIP_MAINVC_TUTORIAL_Bool)
                self.setTutorialMode(on: false)
                // Once the member has seen this alertView once, we don't want to show it again, even if they do want to go through the tutorial
            }))
            
            present(alertVC, animated: true, completion: nil)
        case .step1_ReviewOthers:
            tutorialLabel.text = "First, tap GIVE OPINIONS to review some photos!"
            tutorialLabel.fadeInAfter(seconds: 0.0)
            reviewOthersButton.addAttentionRectangle()
            // ADD THE SHOW HELP LABEL HERE
        case .step2_PostQuestion:
            tutorialLabel.text = "Now let's upload your first photo for review"
            tutorialLabel.fadeInAfter(seconds: 0.0)
            reviewOthersButton.removeAttentionRectangle()
            cameraButton.addAttentionRectangle()
        case .step3_AddFriends:
            tutorialLabel.text = "Next, let's add some friends"
            tutorialLabel.fadeInAfter(seconds: 0.0)
            cameraButton.removeAttentionRectangle()
            friendsBtn.addAttentionRectangle()
        case .step4_ViewResults:
            tutorialLabel.text = "Now let's check for feedback on your uploaded photo"
            tutorialLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
            tutorialLabel.fadeInAfter(seconds: 0.0)
            friendsBtn.removeAttentionRectangle()
            viewResultsButton.addAttentionRectangle()
        case .step5_Complete:
            tutorialLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
            tutorialLabel.text = "Tutorial Complete. \nHappy Tangerining!"
            viewResultsButton.removeAttentionRectangle()
            tutorialLabel.fadeInAfter(seconds: 0.0)
            tutorialLabel.fadeOutAfter(seconds: 1.5)
            cancelTutorialButton.isHidden = true
            
            // finally after we've shown the last element of the MainVC tutorial, we set the mainVC skip to true:
            self.ud.set(true, forKey: Constants.UD_SKIP_MAINVC_TUTORIAL_Bool)
            
        }
        TutorialTracker().incrementTutorialFrom(currentPhase: phase)
    }
    
    
    /// shows or hides all the help labels and glassView depending on whether they are hidden at the time it's called
    func toggleHelpDisplay() {
        
        let hidden = helpSharePhotoLabel.isHidden ||
        helpViewResultsLabel.isHidden ||
        helpReviewOthersLabel.isHidden ||
        helpFriendsLabel.isHidden ||
        helpProfileAndSettingsLabel.isHidden ||
        helpHomepageLabel.isHidden
        
        if hidden {
            glassView.isHidden = false
            self.view.bringSubviewToFront(glassView)
            self.view.bringSubviewToFront(helpSharePhotoLabel)
            self.view.bringSubviewToFront(helpViewResultsLabel)
            self.view.bringSubviewToFront(helpReviewOthersLabel)
            self.view.bringSubviewToFront(helpFriendsLabel)
            self.view.bringSubviewToFront(helpProfileAndSettingsLabel)
            self.view.bringSubviewToFront(helpHomepageLabel)
            
            if let image = UIImage(named: "question circle green") {
                helpButton.setImage(image, for: .normal)
            }
            
            helpSharePhotoLabel.fadeInAfter(seconds: 0.0)
            helpViewResultsLabel.fadeInAfter(seconds: 0.0)
            helpReviewOthersLabel.fadeInAfter(seconds: 0.0)
            helpFriendsLabel.fadeInAfter(seconds: 0.0)
            helpProfileAndSettingsLabel.fadeInAfter(seconds: 0.0)
            helpHomepageLabel.fadeInAfter(seconds: 0.0)
            
            
        } else {
            glassView.isHidden = true
            self.view.sendSubviewToBack(glassView)
            if let image = UIImage(named: "question circle blue") {
                helpButton.setImage(image, for: .normal)
            }
            
            helpSharePhotoLabel.fadeOutAfter(seconds: 0.0)
            helpViewResultsLabel.fadeOutAfter(seconds: 0.0)
            helpReviewOthersLabel.fadeOutAfter(seconds: 0.0)
            helpFriendsLabel.fadeOutAfter(seconds: 0.0)
            helpProfileAndSettingsLabel.fadeOutAfter(seconds: 0.0)
            helpHomepageLabel.fadeOutAfter(seconds: 0.0)
            
        }
        // if the glassView is visible, user interaction should be enabled, otherwise, it should be disabled.
        glassView.isUserInteractionEnabled = !glassView.isHidden
    }
    
    @objc func glassViewTapped(_ sender: UITapGestureRecognizer? = nil) {
        toggleHelpDisplay()
    }
    
    // MARK: PROGRAMMATIC UI
    func configureTutorialLabel (){
        tutorialLabel = UILabel()
        tutorialLabel.text = ""
        tutorialLabel.textColor = .systemBlue
        tutorialLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        tutorialLabel.numberOfLines = 3
        tutorialLabel.isHidden = true
        
        tutorialLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        
        tutorialLabel.textAlignment = .center
        
        tutorialLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tutorialLabel)
        
        NSLayoutConstraint.activate([
            
            tutorialLabel.bottomAnchor.constraint(equalTo: cameraButton.topAnchor, constant: -30),
            tutorialLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            tutorialLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            tutorialLabel.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func configureCancelTutorialButton(){
        
        cancelTutorialButton = UIButton()
        cancelTutorialButton.setTitleColor(.systemGray, for: .normal)
        cancelTutorialButton.setTitle("✖️ \nCancel \nTutorial", for: .normal)
        cancelTutorialButton.backgroundColor = .systemBackground
        
        cancelTutorialButton.titleLabel?.lineBreakMode = .byWordWrapping
        cancelTutorialButton.titleLabel?.textAlignment = .center
        
        cancelTutorialButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelTutorialButton)
        
        NSLayoutConstraint.activate([
            cancelTutorialButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0),
            cancelTutorialButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            cancelTutorialButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        cancelTutorialButton.addTarget(self, action: #selector(onCancelTutorialTapped), for: .touchUpInside)
        
        //hide it until we need it
        cancelTutorialButton.isHidden = true
    }
    
    
    
}
