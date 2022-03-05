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
    
    // MARK: UI Items
    // just some default
    var username = ""
    var parentVC = PARENTVC.FRIENDS
    var status = Status.NONE
    var addedList = [String]()
    
    var backBtn: UIButton!
    var addBtn: UIButton!
    
    var defaultText: UILabel!
    var defaultSw: UISwitch!
    
    var deleteBtn: UIButton!
    var blockBtn: UIButton!
    
    var profileImage: UIImageView!
    
    var nameL: UILabel!
    var ageL: UILabel!
    
    var reviewerText: UILabel!
    var reviewerScoreL: UILabel!
    var totalReviewText: UILabel!
    var reviewsL: UILabel!
    
    var friend : Friend!
    
    
    // MARK: Actions
    
    @objc func onBackPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @objc func onAddPressed() {
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
    
    
    @objc func defaultSwitched(_ sender: UISwitch) {
        
        if self.defaultSw.isOn {
            RealmManager.sharedInstance.addOrUpdateFriend(object: self.friend,sendStatus: .DEFAULT)
        }else{
            RealmManager.sharedInstance.addOrUpdateFriend(object: self.friend,sendStatus: .NONE)
        }
        
    }
    
    
    @objc func onDeletePressed(_ sender: UIButton) {
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
    
    
    @objc func onBlockPressed(_ sender: UIButton) {
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
    
    
    
    func getUserDetail(){
        
        Firestore.firestore().collection(Constants.USERS_COLLECTION).document(username).getDocument{
            (snap, error) in
            // stop the loader
            
            // handle the error
            if let error = error{
                self.view.hideActivityIndicator()
                
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
                
                
                
                self.view.hideActivityIndicator()
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
    
    // MARK: Delegates
    // MARK: VC Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // proUI
        
        configureProfileImageView()
        configureBackButton()
        
        configureNameLabel()
        configureAgeLabel()
        
        configureAddButton()
        configureDefaultSw()
        
        configureReviewerScore()
        configureTotalReviews()
        
        configureBlockButton()
        configureDeleteButton()
        
        
        
        // Do any additional setup after loading the view.
        view.showActivityIndicator()
        // fetch detail
        getUserDetail()
        
        // set the default switch
        setDefaultSW()
    }
    
    // MARK: PROGRAMMATIC UI
    
    func configureBackButton(){
        backBtn = UIButton()
        backBtn.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)
        
        
        
        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 10),
            backBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,constant: 8),
            backBtn.heightAnchor.constraint(equalToConstant: 40),
            backBtn.widthAnchor.constraint(equalToConstant: 40)
            
        ])
        
        backBtn.addTarget(self, action: #selector(onBackPressed), for: .touchUpInside)
    }
    
    func configureProfileImageView(){
        profileImage = UIImageView()
        profileImage.image = UIImage(named: "generic_user")
        
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileImage)
        
        NSLayoutConstraint.activate([
            profileImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            profileImage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            profileImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            profileImage.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4)
        ])
    }
    
    func configureNameLabel(){
        nameL = UILabel()
        nameL.text = ""
        nameL.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nameL.textColor = .label
        nameL.textAlignment = .center
        nameL.numberOfLines = 2
        
        nameL.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameL)
        
        NSLayoutConstraint.activate([
            nameL.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            nameL.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 10),
            nameL.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func configureAgeLabel(){
        ageL = UILabel()
        ageL.text = ""
        ageL.font = UIFont.systemFont(ofSize: 17)
        ageL.textColor = .label
        ageL.textAlignment = .center
        
        ageL.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ageL)
        
        NSLayoutConstraint.activate([
            ageL.leadingAnchor.constraint(equalTo: nameL.trailingAnchor, constant: 10),
            ageL.centerYAnchor.constraint(equalTo: nameL.centerYAnchor),
            ageL.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50)
        ])
        
    }
    
    func configureAddButton(){
        addBtn = UIButton()
        addBtn.setTitle("Add", for: .normal)
        
        addBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addBtn)
        
        NSLayoutConstraint.activate([
            addBtn.topAnchor.constraint(equalTo: ageL.bottomAnchor, constant: 25),
            addBtn.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            addBtn.widthAnchor.constraint(equalToConstant: 100),
            addBtn.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        addBtn.addTarget(self, action: #selector(onAddPressed), for: .touchUpInside)
        
    }
    
    func configureDefaultSw(){
        defaultText = UILabel()
        defaultText.text = "Default recipient of Questions"
        defaultText.font = UIFont.systemFont(ofSize: 17)
        defaultText.textColor = .label
        
        defaultText.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(defaultText)
        
        defaultSw = UISwitch()
        defaultSw.setOn(true, animated: false)
        
        defaultSw.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(defaultSw)
        
        
        NSLayoutConstraint.activate([
            defaultText.topAnchor.constraint(equalTo: addBtn.bottomAnchor, constant: 25),
            defaultText.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            defaultSw.leadingAnchor.constraint(equalTo: defaultText.trailingAnchor, constant: 10),
            defaultSw.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            defaultSw.centerYAnchor.constraint(equalTo: defaultText.centerYAnchor)
        ])
        
    }
    
    func configureReviewerScore(){
        
        reviewerText = UILabel()
        reviewerText.text = "Reviewer Score"
        reviewerText.font = UIFont.systemFont(ofSize: 17)
        
        reviewerScoreL = UILabel()
        reviewerScoreL.text = "0"
        reviewerScoreL.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        
        reviewerText.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reviewerText)
        
        reviewerScoreL.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reviewerScoreL)
        
        NSLayoutConstraint.activate([
            reviewerText.topAnchor.constraint(equalTo: defaultText.bottomAnchor, constant: 20),
            reviewerText.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            reviewerScoreL.widthAnchor.constraint(equalToConstant: 70),
            reviewerScoreL.leadingAnchor.constraint(equalTo: reviewerText.trailingAnchor, constant: 20),
            reviewerScoreL.centerYAnchor.constraint(equalTo: reviewerText.centerYAnchor),
            reviewerScoreL.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])
        
    }
    func configureTotalReviews(){
        totalReviewText = UILabel()
        totalReviewText.text = "Total Reviews"
        totalReviewText.font = UIFont.systemFont(ofSize: 17)
        
        reviewsL = UILabel()
        reviewsL.text = "0"
        reviewsL.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        
        totalReviewText.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(totalReviewText)
        
        reviewsL.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reviewsL)
        
        NSLayoutConstraint.activate([
            totalReviewText.topAnchor.constraint(equalTo: reviewerText.bottomAnchor, constant: 20),
            totalReviewText.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            reviewsL.widthAnchor.constraint(equalToConstant: 70),
            reviewsL.leadingAnchor.constraint(equalTo: totalReviewText.trailingAnchor, constant: 20),
            reviewsL.centerYAnchor.constraint(equalTo: totalReviewText.centerYAnchor),
            reviewsL.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])
    }
    
    func configureDeleteButton(){
        deleteBtn = UIButton()
        deleteBtn.setTitle("Delete", for: .normal)
        
        deleteBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deleteBtn)
        
        NSLayoutConstraint.activate([
            deleteBtn.bottomAnchor.constraint(equalTo: blockBtn.topAnchor, constant: 20),
            deleteBtn.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            deleteBtn.widthAnchor.constraint(equalToConstant: 100),
            deleteBtn.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        deleteBtn.addTarget(self, action: #selector(onDeletePressed), for: .touchUpInside)
    }
    
    func configureBlockButton(){
        blockBtn = UIButton()
        blockBtn.setTitle("Block", for: .normal)
        
        blockBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blockBtn)
        
        NSLayoutConstraint.activate([
            blockBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 20),
            blockBtn.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            blockBtn.widthAnchor.constraint(equalToConstant: 100),
            blockBtn.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        blockBtn.addTarget(self, action: #selector(onBlockPressed), for: .touchUpInside)
    }
}
