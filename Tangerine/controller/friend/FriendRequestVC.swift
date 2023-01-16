//
//  FriendRequestVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-27.
//

import UIKit
import RealmSwift
import FirebaseFirestore
import FirebaseAnalytics

class FriendRequestVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: UI Items
    var backBtn: UIButton!
    // listener
    var listener : ListenerRegistration!
    // holds the value of connection_list in firebase
    var requestList = [PersonList]()

    var friendRequestList: UITableView!
    
    
    
    // MARK: Actions
    @IBAction func onBackPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    func blockUser(){
        print("Not Blocked, implement it")
    }
    
    func setupUI(){
        friendRequestList.delegate = self
        friendRequestList.dataSource = self
    }

    
    // add personlist object
    func addOrUpdatePersonList(_ object : PersonList)   {
        print("PersonList saved in realm")
        // add to local
        do {
            let database = try Realm()
            database.beginWrite()
            database.add(object, update: .modified)
            try database.commitWrite()
            
            self.friendRequestList.reloadData()
            
        } catch {
            print("Error occured while updating realm")
        }
    } // end of add
    

    // start a listener with the firebase persons list for change
    
    func listen2ConnectionChange(){
       
        // only listen for status == pending ie he added me
        listener = Firestore.firestore().collection(Constants.USERS_COLLECTION)
            .document(myProfile.username)
            .collection(Constants.USERS_LIST_SUB_COLLECTION).whereField(Constants.USER_STATUS_KEY, isEqualTo: Status.PENDING.description)
            .addSnapshotListener { (snapshot, error) in
            // handle error
            if let error = error{
                self.presentDismissAlertOnMainThread(title: "Server Error", message: error.localizedDescription)
                return
            }
            // proceed
            
                
            print("A listener is fired")
                
                let docs = snapshot?.documents
                
                if let docs = docs{
                    print("We got \(docs.count) docs for pending")
                    
                    if docs.count > 0{
                        // iterate over the result
                        for item in docs{
                            // make a personList Item
                            let personListItem = PersonList()
                            personListItem.username = item.documentID
                            personListItem.display_name = item.data()[Constants.USER_DNAME_KEY] as? String
                            personListItem.profile_pic = item.data()[Constants.USER_IMAGE_KEY] as? String
                            personListItem.status = getStatusFromString(item.data()[Constants.USER_STATUS_KEY] as! String)
                            
                            // add to local
                            self.addOrUpdatePersonList(personListItem)
                            
                            // add to our list
                            self.requestList.append(personListItem)
                            
                            
                        }// end for
                        print("Local list is now \(self.requestList.count)")
                        
                        self.friendRequestList.reloadData()

                        
                    }else{
                        // just show a dialog
                        let alertVC = UIAlertController(title: "No Additional Friend Requests", message: "You're up to date on all your pending friend request responses.", preferredStyle: .alert)
                        alertVC.addAction(UIAlertAction.init(title: "Got It", style: .cancel, handler: { (action) in
                            self.dismiss(animated: true, completion: nil)
                        }))
                    
                        self.present(alertVC, animated: true)
                    }

                }
        }
    }
    
    
    
    // MARK: Delegates
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of request we have known as PENDING
        return requestList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("Setting Table")
        let cell = Bundle.main.loadNibNamed("FriendCell", owner: self, options: nil)?.first as! AddFriendCell // we already know it is on our project list
        // show the delete button
        cell.delete_width.constant = 70
        
        let person = requestList[indexPath.row]
        
        cell.title.text = person.display_name
        cell.subtitle.text = person.username
       
        downloadOrLoadFirebaseImage(
            ofName: getFilenameFrom(qName: person.username, type: .ASK),
            forPath: person.profile_pic) { image, error in
            if let error = error{
                print("Error: \(error.localizedDescription)")
                return
            }
            
            print("FRVC Image Downloaded for \(person.username)")
            cell.profileImageView.image = image!
        }
        
        // style delete button
        cell.deleteButton.layer.borderWidth = 1.0
        cell.deleteButton.layer.cornerRadius = 6.0
        cell.deleteButton.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        // style for add button
        cell.button.setTitle("Add", for: .normal)
        cell.button.backgroundColor = UIColor.systemGreen
        cell.button.setTitleColor(UIColor.white, for: .normal)
        cell.button.layer.borderWidth = 1.0
        cell.button.layer.cornerRadius = 6.0
        cell.button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        cell.handleClick = {
            print("Added to friend")
            // In MY FIREBASE
            
            
            
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(myProfile.username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(person.username)
                .setData([Constants.USER_STATUS_KEY:Status.FRIEND.description], merge: true)

            // In THIS PERSON'S FIREBASE

            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(person.username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(myProfile.username)
                .setData([Constants.USER_STATUS_KEY:Status.FRIEND.description], merge: true)
            
            // in case user decides to exit app without returning to mainVC
            // we're updating the badge right from here to handle the correct badge number
            // just so user doesn't think he has more action to perform than he actually does
            
            // Update the fr count on firebase
            decreaseFRCountOf(username: myProfile.username)
            // we should have one less fr count locally
            friendReqCount -= 1
            // so update the badge now
            updateBadgeCount()
            
            
            // just show a dialog
            let alertVC = UIAlertController(title: "Accepted!", message: "You are now friends with \(person.username!)", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction.init(title: "Got It", style: .cancel, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
                // delete the row
                self.requestList.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                
            }))
        
            self.present(alertVC, animated: true)
            
            // Log Analytics Event
            Analytics.logEvent(Constants.FRIEND_REQUEST_ACCEPTED, parameters: nil)

        }
        
        cell.handleDelete = {
            print("Deleted the request")
            
            // deleting from firestore will fire the listener
            // no need to delete from table or else where
            
            // From MY FIREBASE
            
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(myProfile.username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(person.username)
                .delete { (error) in
                    if let error = error{
                        self.presentDismissAlertOnMainThread(title: "Error", message: error.localizedDescription)
                        return
                    }

                    // From THIS PERSON'S FIREBASE

                    Firestore.firestore().collection(Constants.USERS_COLLECTION).document(person.username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(myProfile.username)
                        .delete { (error) in
                            if let error = error{
                                self.presentDismissAlertOnMainThread(title: "Error", message: error.localizedDescription)
                                return
                            }
                        }
                }
            
            
            // ADDED BY WYATT on 30Sep2022 to decrement the receiving user's fr_count if he deletes the friend request. This was being done for accepting the FR but not for deleting (rejecting) it.
            
            // Update the fr count on firebase
            decreaseFRCountOf(username: myProfile.username)
            // we should have one less fr count locally
            friendReqCount -= 1
            // so update the badge now
            updateBadgeCount()

        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let blockAction = UIContextualAction(style: .destructive, title: "Block") { (_, _, _ ) in
            print("Block tapped")
            
            // In MY FIREBASE
            
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(myProfile.username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(self.requestList[indexPath.row].username)
                .setData([Constants.USER_STATUS_KEY:Status.BLOCKED.description], merge: true)

            // In THIS PERSON'S FIREBASE

            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(self.requestList[indexPath.row].username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(myProfile.username)
                .setData([Constants.USER_STATUS_KEY:Status.GOT_BLOCKED.description], merge: true)
            
            
            // show a dialog?
            
            self.presentDismissAlertOnMainThread(title: "Blocked!", message: "\(self.requestList[indexPath.row].username!) has been blocked.")
            
            // delete the row again
            self.requestList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)


            
        }
        // to manage dark and normal color
        blockAction.backgroundColor = .label
        
   
        
        return UISwipeActionsConfiguration(actions: [blockAction])
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("row selected at \(indexPath.row)")
        
        var username = ""
        // only allow contact those are registered
       
        let person = requestList[indexPath.row]
        username = person.username
      
            let vc = FriendDetailsVC()
        
            vc.modalPresentationStyle = .fullScreen
            vc.username = username
            vc.parentVC = PARENTVC.REQUEST
            vc.status = .PENDING
            self.present(vc, animated: true, completion: nil)
        

    }
    
    
    // MARK: VC Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // proUI
        
        configureBackButton()
        
        configureFriendsTableView()

        // Do any additional setup after loading the view.
        setupUI()
        

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // anytime, specially when return from detail view
        self.requestList.removeAll()
        self.friendRequestList.reloadData()
        
        view.attachDismissToRightSwipe()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // start the listener
        listen2ConnectionChange()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        listener.remove()
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
    
    
    func configureFriendsTableView(){
        friendRequestList = UITableView()
        
        friendRequestList.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(friendRequestList)
        
        NSLayoutConstraint.activate([
            friendRequestList.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            friendRequestList.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            friendRequestList.topAnchor.constraint(equalTo: backBtn.bottomAnchor,constant: 20),
            friendRequestList.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

}
