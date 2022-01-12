//
//  MainVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-28.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import RealmSwift


class MainVC: UIViewController {
    
    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - View Controller methods
     */
    /******************************************************************************************************************************/
    
    var minimumAge:Int = 18
    var maximumAge:Int = 99
    
    var prefs: UserDefaults!
    
    
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
        let vc = storyboard.instantiateViewController(withIdentifier: "ask_tvc") as! AskTableViewController
        
        vc.modalPresentationStyle = .fullScreen
        self.presentFromRight(vc)
        
        //        self.present(vc, animated: true, completion: nil)
    }
    
    
    // answer question tapped
    
    
    @IBAction func onAQTapped(_ sender: Any) {
        print("AnsQ/Rev other")
        // maybe create a list of questions then decide which view to show?
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "blue_vc") as! BlueVC
        
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
        
    }
    
    // friends tapped
    
    @IBAction func onFriendsTapped(_ sender: Any) {
        print("Friends")
        performSegue(withIdentifier: "friends_vc", sender: self)
    }
    
    
    // when the profile and settings tapped
    @IBAction func onProfileTapped(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "settings_vc") as! ProfileSettingsTabBarController
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    
    // sign out the current user and take him to login screen
    @IBAction func onLogoutTapped(_ sender: UITapGestureRecognizer) {
        
        
        do {
            try Auth.auth().signOut()
            // clear the realm db
            // update the local db
            
            resetLocalAndRealmDB()
            
            resetQuestionRelatedThings() // detailed on declaration of this func => Cmd+Click (Jump to Definition)
            // Move to login
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "login_vc") as! LoginVC
            vc.modalPresentationStyle = .fullScreen
            
            self.present(vc, animated: true, completion: nil)

            
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
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

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("MainVC Appeared")
        

            // checks if we have enough questions, if not fetches some
            checkForQuestionsToFetch(){
                print("Completed fetching Questions from MainVC")
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
        
        //unloadAllVCs()
        
    }
//
//    func unloadAllVCs(){
//        // Remove all the view controllers we have till now
//        guard let navigationController = self.navigationController else { return }
//        var navigationArray = navigationController.viewControllers // To get all UIViewController stack as Array
//        print("MainVC Count: \(navigationArray.count)")
//        let temp = navigationArray.last
//        navigationArray.removeAll()
//        navigationArray.append(temp!) //To remove all previous UIViewController except the last one
//        self.navigationController?.viewControllers = navigationArray
//    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("MainVC Disappeared")
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
    }
    
    @objc func glassViewTapped(_ sender: UITapGestureRecognizer? = nil) {
        toggleHelpDisplay()
    }
    
    
    
}
