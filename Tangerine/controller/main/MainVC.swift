//
//  MainVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-28.
//  com.tangerineinsight.tangerineMM

import UIKit
import FirebaseAuth
import FirebaseFirestore
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
    @IBOutlet weak var spacerView1: UIView!
    
    //Button outlets
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var reviewOthersButton: UIButton!
    //this one is redundant with reviewOthersBtn
    @IBOutlet weak var viewResultsButton: UIButton!
    
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
  
    /******************************************************************************************************************************/
    
    /******************************************************************************************************************************/
    
    /// to toggle all switches based on noPrefSw
    func fetchTD(){
        
        // access the auth object, we saved the username as displayname
        if let user = Auth.auth().currentUser, let username = user.displayName{
            // save to target demo
            Firestore.firestore()
                .collection(Constants.USERS_COLLECTION)
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

      // for notification
      addObservers()
         
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
            self.showTutorial()
//            self.showTutorialInviteAsRequired()
        }
    }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    print("VWA")
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
            .collection(Constants.USERS_COLLECTION)
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

    /// centers the buttons in the view equally between the top of the view and the logout button by making the bottom constraint value equal to the top constraint value.
    func centerMainIconsVertically() {
//        cameraButtonTopConstraint.constant = 10.0
        let topDistance: CGFloat = cameraButtonTopConstraint.constant
        let bottomDistance: CGFloat = spacerView1.frame.height

        let combinedDistance = topDistance + bottomDistance
        let halfDistance = combinedDistance / 2.0
        
        
        print("cameraButtonTopConstraint before reset is \(cameraButtonTopConstraint.constant)")
        print("bottomConstraint before reset is \(spacerView1.frame.height)")
        cameraButtonTopConstraint.constant = halfDistance
//        spacerView1.frame.height = halfDistance
        
        print("cameraButtonTopConstraint AFTER reset is \(cameraButtonTopConstraint.constant)")
        print("bottomConstraint AFTER reset is \(spacerView1.frame.height)")
        
    }
    
    /// Sets all of the tutorial user default skip modes to true or all to false as desired
    func setTutorialMode(on: Bool) {
        let skipAllTutorialsBool: Bool = !on
        let tutorialSkipSettingsArray: [String] = [Constants.UD_SKIP_REVIEW_ASK_TUTORIAL_Bool, Constants.UD_SKIP_REVIEW_COMPARE_TUTORIAL_Bool, Constants.UD_SKIP_AVCAM_TUTORIAL_Bool, Constants.UD_SKIP_EDIT_QUESTION_TUTORIAL_Bool, Constants.UD_SKIP_SEND_TO_FRIENDS_TUTORIAL_Bool, Constants.UD_SKIP_FRIENDSVC_TUTORIAL_Bool, Constants.UD_SKIP_ADD_FRIENDS_TUTORIAL_Bool, Constants.UD_SKIP_ACTIVE_Q_TUTORIAL_Bool,  Constants.UD_SKIP_MY_ASK_TUTORIAL_Bool, Constants.UD_SKIP_MY_COMPARE_TUTORIAL_Bool]
        
        for thisSkipSetting in tutorialSkipSettingsArray {
            self.ud.set(skipAllTutorialsBool, forKey: thisSkipSetting)
            print("skip tutorial setting for \(thisSkipSetting) now set to \(skipAllTutorialsBool)")
        }
    }
    
    /// Displays an alertView which asks the member if he or she wants to get tutorial help
    func showTutorialInviteAsRequired() {
        
        let skipStartOrDismissTutorial = UserDefaults.standard.bool(forKey: Constants.UD_SKIP_MAINVC_TUTORIAL_Bool)
        
        if !skipStartOrDismissTutorial {
            print("TangerineScore tapped")
            let alertVC = UIAlertController(title: "Welcome to the Community!", message: "Would you like some help using the app for the first time? \nYou can adjust this later in settings.", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Sure!", style: .default, handler: { (action: UIAlertAction!) in
                print("Will continue with tutorial")
                // Enable all tutuorial elements
                self.setTutorialMode(on: true)
                // Once the member has seen this alertView once, we don't want to show it again, even if they do want to go through the tutorial
                self.ud.set(true, forKey: Constants.UD_SKIP_MAINVC_TUTORIAL_Bool)
                TutorialTracker().setTutorial(phase: .step1_ReviewOthers)
                self.showTutorial()
            }))
            
            alertVC.addAction(UIAlertAction(title: "No Thanks", style: .cancel, handler: { (action: UIAlertAction!) in
                print("Will CANCEL tutorial")
                // Skip all tutorial elements
                self.ud.set(true, forKey: Constants.UD_SKIP_MAINVC_TUTORIAL_Bool)
                self.setTutorialMode(on: false)
                // Once the member has seen this alertView once, we don't want to show it again, even if they do want to go through the tutorial
                self.ud.set(true, forKey: Constants.UD_SKIP_MAINVC_TUTORIAL_Bool)
            }))
                
            present(alertVC, animated: true, completion: nil)
            
            
        }
    }
    
    /// Highlights the appropriate icon as the next part of the tutorial
    func showTutorial() {
        let phase = TutorialTracker().getTutorialPhase()
        // we also need something where if they user taps somewhere else, it just shows them this next time or maybe even cancels the tutorial
        
        // Clear out all residual attention rectangles etc
        
        
        
        switch phase {
        case .step0_Intro:
            showTutorialInviteAsRequired()
        case .step1_ReviewOthers:
            reviewOthersButton.addAttentionRectangle()
            // ADD THE SHOW HELP LABEL HERE
        case .step2_PostQuestion:
            cameraButton.addAttentionRectangle()
        case .step3_AddFriends:
            friendsBtn.addAttentionRectangle()
        case .step4_ViewResults:
            viewResultsButton.addAttentionRectangle()
        case .step5_Complete:
            print("close something out here")
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
    
    
    
}
