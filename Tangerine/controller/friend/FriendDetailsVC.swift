//
//  FriendDetailsVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-30.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import RealmSwift

enum PARENTVC {
    case ADD // from add friend
    case REQUEST // from request
    case FRIENDS // from friends
}

class FriendDetailsVC: UIViewController {
    
    // just some default
    var username = ""
    var parentVC = PARENTVC.FRIENDS
    var status = Status.NONE
    var addedList = [String]()
    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - Delegates
     - View Controller methods
     */
    /******************************************************************************************************************************/
    
    
    @IBOutlet weak var addBtn: UIButton!
    
    @IBOutlet weak var defaultText: UILabel!
    @IBOutlet weak var defaultSw: UISwitch!
    
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var blockBtn: UIButton!
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var nameL: UILabel!
    @IBOutlet weak var ageL: UILabel!
    
    @IBOutlet weak var reviewerText: UILabel!
    @IBOutlet weak var reviewerScoreL: UILabel!
    @IBOutlet weak var totalReviewText: UILabel!
    @IBOutlet weak var reviewsL: UILabel!
    
    // the loading
    var indicator: UIActivityIndicatorView!
    
    var friend : Friend!
    /******************************************************************************************************************************/
    
    @IBAction func onBackPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func onAddPressed(_ sender: UIButton) {
        print("Added to friend")
        
        
        
        // so when from friendReq VC
        if status == .PENDING {
            // In MY FIREBASE
            
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(myProfile.username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(self.username)
                .setData([Constants.USER_STATUS_KEY:Status.FRIEND.description], merge: true)
            
            // In THIS PERSON'S FIREBASE
            
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(self.username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(myProfile.username)
                .setData([Constants.USER_STATUS_KEY:Status.FRIEND.description], merge: true)
            
            
            // add to default
            if defaultSw.isOn{
                RealmManager.sharedInstance.addOrUpdateFriend(object: friend, sendStatus: SendStatus.DEFAULT)
            }
            
            // just show a dialog
            let alertVC = UIAlertController(title: "Accepted!", message: "You are now friends with \(self.username)", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction.init(title: "Dismiss", style: .cancel, handler: { (action) in
                
                if self.defaultSw.isOn {
                    
                    RealmManager.sharedInstance.addOrUpdateFriend(object: self.friend,sendStatus: .DEFAULT)
                }else{
                    RealmManager.sharedInstance.addOrUpdateFriend(object: self.friend,sendStatus: .NONE)
                }
                
                self.dismiss(animated: true, completion: nil)
                
            }))
            
            self.present(alertVC, animated: true)
            
        }else if status != .REQUESTED {
            
            let person = Person()
            person.displayName = friend.displayName
            person.imageString = friend.imageString
            person.phoneNumberField = friend.phoneNumberField
            person.username = friend.username
            
            // add to local
            do {
                let database = try Realm()
                database.beginWrite()
                person.status = .REQUESTED
                database.add(person, update: .modified)
                self.presentDismissAlertOnMainThread(title: "Sent!", message: "Friend request sent to \(person.displayName)")
                try database.commitWrite()
                
                
            } catch {
                print("Error occured while updating realm")
            }
            
            
            // save to firebase
            
            // TO MY FIREBASE
            
            let personDoc : [String: String] = [Constants.USER_STATUS_KEY: person.status.description,
                                                Constants.USER_DNAME_KEY:person.displayName,
                                                Constants.USER_IMAGE_KEY:person.imageString]
            
            
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(myProfile.username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(person.username)
                .setData(personDoc, merge: true)
            
            // TO THIS PERSON'S FIREBASE
            
            let myDoc : [String: String] = [Constants.USER_STATUS_KEY: Status.PENDING.description,
                                            Constants.USER_DNAME_KEY:myProfile.display_name,
                                            Constants.USER_IMAGE_KEY:myProfile.profile_pic]
            
            
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(person.username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(myProfile.username)
                .setData(myDoc, merge: true)
            
            
            addBtn.setTitle("Requested", for: .normal)
            addBtn.backgroundColor = UIColor.systemOrange
            // set the status
            status = .REQUESTED
        } // end of check status
        
        
        
        
    }
    
    
    @IBAction func defaultSwitched(_ sender: UISwitch) {
        
        if self.defaultSw.isOn {
            RealmManager.sharedInstance.addOrUpdateFriend(object: self.friend,sendStatus: .DEFAULT)
        }else{
            RealmManager.sharedInstance.addOrUpdateFriend(object: self.friend,sendStatus: .NONE)
        }
        
    }
    
    
    @IBAction func onDeletePressed(_ sender: UIButton) {
        // In MY FIREBASE
        if let user = Auth.auth().currentUser, let name = user.displayName{
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(name).collection(Constants.USERS_LIST_SUB_COLLECTION).document(self.username)
                .delete()
            
            // In THIS PERSON'S FIREBASE
            
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(self.username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(name)
                .delete()
            
            let msg = status == .FRIEND ? "friend" : "request"
            print("\(status.description)")
            // just show a dialog
            
            let alertVC = UIAlertController(title: "Deleted!", message: "This \(msg) has been deleted.", preferredStyle: .alert)
            
            alertVC.addAction(UIAlertAction.init(title: "Dismiss", style: .cancel, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
                
            }))
            
            self.present(alertVC, animated: true)
        } // if let
    }
    
    
    @IBAction func onBlockPressed(_ sender: UIButton) {
        // In MY FIREBASE
        if let user = Auth.auth().currentUser, let name = user.displayName{
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(name).collection(Constants.USERS_LIST_SUB_COLLECTION).document(self.username)
                .setData([Constants.USER_STATUS_KEY:Status.BLOCKED.description], merge: true)
            
            // In THIS PERSON'S FIREBASE
            
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(self.username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(name)
                .setData([Constants.USER_STATUS_KEY:Status.GOT_BLOCKED.description], merge: true)
            
            
            // just show a dialog
            let alertVC = UIAlertController(title: "Blocked!", message: "You have blocked \(self.username)", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction.init(title: "Dismiss", style: .cancel, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
                
            }))
            
            self.present(alertVC, animated: true)
        } // if let
    }
    
    
    /******************************************************************************************************************************/
    
    func getUserDetail(){
        
        Firestore.firestore().collection(Constants.USERS_COLLECTION).document(username).getDocument{
            (snap, error) in
            // stop the loader
            
            // handle the error
            if let error = error{
                self.indicator.stopAnimating()
                
                print("An error occured")
                self.presentDismissAlertOnMainThread(title: "Error", message: error.localizedDescription)
                return
            }
            
            let doc = snap?.data();
            
            if let doc = doc{
                
                
                
                let phone_number = doc[Constants.USER_NUMBER_KEY] as? String ?? "0"
                
                
                
                let birthday = doc[Constants.USER_BIRTHDAY_KEY] as? Double ?? 0
                let display_name = doc[Constants.USER_DNAME_KEY] as? String ?? self.username
                
                let rating = doc[Constants.USER_RATING_KEY] as? Int ?? 0
                let review = doc[Constants.USER_REVIEW_KEY] as? Int ?? 0
                
                let profile_pic = doc[Constants.USER_IMAGE_KEY] as? String ?? DEFAULT_USER_IMAGE_URL
  
                
                self.nameL.text = display_name
                
                // DISPLAY THE CELL DATA
                let today = Date()
                let bday = Date(timeIntervalSince1970: birthday)
                let dc =  Calendar.current.dateComponents([.year], from: bday, to: today)
                
                // get the age from date component dc
                if let age = dc.year{
                    if birthday == 0{
                        // do nothing maybe?
                        self.ageL.text = ""
                    }else{
                        self.ageL.text = "\(age)"
                    }
                    
                }
                self.reviewerScoreL.text = "\(rating)"
                self.reviewsL.text = "\(review)"
                
                
                
                self.indicator.stopAnimating()
                self.showViews()
                
                
                
                self.friend = Friend()
                self.friend.dobMills = birthday
                self.friend.displayName = display_name
                self.friend.phoneNumberField = phone_number
                self.friend.rating = rating
                self.friend.review = review
                self.friend.username = self.username
                self.friend.imageString = profile_pic
                
                
                
                // set the values
                
                downloadOrLoadFirebaseImage(
                    ofName: getFilenameFrom(qName: self.username, type: .ASK),
                    forPath: profile_pic) { image, error in
                        if let error = error{
                            print("Error: \(error.localizedDescription)")
                            return
                        }
                        
                        print("FDVC Image Downloaded for \(self.username)")
                        self.profileImage.image = image!
                    }
            }
            
            
            
        } // end of firebase call
    }
    
    
    
    func setDefaultSW(){
        let savedFriend = RealmManager.sharedInstance.getFriend(username)
        defaultSw.setOn(savedFriend?.sendStatus == .DEFAULT, animated: true)
    }
    
    // indicator while loading
    
    func setupIndicator() {
        indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        indicator.center = view.center
        view.addSubview(indicator)
        indicator.bringSubviewToFront(view)
    }
    
    func showViews() {
        // basic views
        profileImage.isHidden = false
        nameL.isHidden = false
        ageL.isHidden = false
        
        // views on condition, as per the document
        if parentVC == .ADD || parentVC == .REQUEST {
            addBtn.isHidden = false
            
            // This doesn't work, it still shows "Add" even when user has been requested
            if status == .REQUESTED {
                addBtn.setTitle("Requested", for: .normal)
                addBtn.backgroundColor = UIColor.systemOrange
                addBtn.setTitleColor(UIColor.white, for: .normal)
                addBtn.layer.borderWidth = 1.0
                addBtn.layer.cornerRadius = 6.0
                addBtn.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            }
            
            if myFriendNames.contains(self.username) {
                addBtn.setTitle("Friends", for: .normal)
                addBtn.backgroundColor = UIColor.systemGreen
                addBtn.setTitleColor(UIColor.white, for: .normal)
                addBtn.layer.borderWidth = 1.0
                addBtn.layer.cornerRadius = 6.0
                addBtn.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
                addBtn.isEnabled = false
            }
            
        }
        // show/hide views based on who was parent
        
        if parentVC == .FRIENDS || parentVC == .REQUEST {
            defaultSw.isHidden = false
            defaultText.isHidden = false
        }
        
        if parentVC == .FRIENDS {
            deleteBtn.isHidden = false
            blockBtn.isHidden = false
        }
        
        totalReviewText.isHidden = false
        reviewerText.isHidden = false
        
        reviewerScoreL.isHidden = false
        reviewsL.isHidden = false
        
    }
    /******************************************************************************************************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // do some makeup with our button
        addBtn.layer.borderWidth = 2.0
        addBtn.layer.cornerRadius = 6.0
        addBtn.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        addBtn.backgroundColor = .systemGreen
        addBtn.tintColor = .white
        
        
        
        setupIndicator()
        // Do any additional setup after loading the view.
        indicator.startAnimating()
        // fetch detail
        getUserDetail()
        
        // set the default switch
        setDefaultSW()
    }
    
}
