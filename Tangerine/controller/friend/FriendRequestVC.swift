//
//  FriendRequestVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-27.
//

import UIKit
import RealmSwift
import FirebaseFirestore

class FriendRequestVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - Delegates
     - View Controller methods
     */
    /******************************************************************************************************************************/
    // listener
    var listener : ListenerRegistration!
    // holds the value of connection_list in firebase
    var requestList = [PersonList]()

    @IBOutlet weak var friendRequestList: UITableView!
    
    
    /******************************************************************************************************************************/
    @IBAction func onBackPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /******************************************************************************************************************************/
    
    func blockUser(){
        print("Blocked")
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
                        let alertVC = UIAlertController(title: "Not Found!", message: "Seems like you don't have any friend requests pending.", preferredStyle: .alert)
                        alertVC.addAction(UIAlertAction.init(title: "Dismiss", style: .cancel, handler: { (action) in
                            self.dismiss(animated: true, completion: nil)
                        }))
                    
                        self.present(alertVC, animated: true)
                    }

                    
                    
                }
                

                
                
        }
    }
    
    
    /******************************************************************************************************************************/
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of request we have known as PENDING
        return requestList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("Setting Table")
        let cell = Bundle.main.loadNibNamed("FriendCell", owner: self, options: nil)?.first as! FriendCell // we already know it is on our project list
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
            
            
            // just show a dialog
            let alertVC = UIAlertController(title: "Accepted!", message: "You are now friends with \(person.username!)", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction.init(title: "Dismiss", style: .cancel, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
                // delete the row
                self.requestList.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                
            }))
        
            self.present(alertVC, animated: true)

            
          
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
      
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "frienddetails_vc") as! FriendDetailsVC
            vc.modalPresentationStyle = .fullScreen
            vc.username = username
            vc.parentVC = PARENTVC.REQUEST
            vc.status = .PENDING
            self.present(vc, animated: true, completion: nil)
        

    }
    
    /******************************************************************************************************************************/
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
        

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // anytime, specially when return from detail view
        self.requestList.removeAll()
        self.friendRequestList.reloadData()
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
    

}
