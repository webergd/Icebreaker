//
//  CQViewController.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-15.
//

import UIKit
import Firebase
import Contacts

/// This is the view that displays after a user has created a Question, and is deciding whether to send it to any of their friends.
class SendToFriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    
    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - Delegates
     - View Controller methods
     */
    /******************************************************************************************************************************/
    @IBOutlet weak var saveDefaultSw: UISwitch!
    @IBOutlet weak var friendList: UITableView!
    
    
    var defaultSendNames = [Friend]()
    var recentSendNames = [Friend]()
    
    
    var friends = [Friend]()
    var friendNames = [String]()
    // a chunked version of above list
    var chunkedNames = [[String]]()
    
    // a counter for chunk iteration
    var currentChunk = -1
    
    var contacts = [Friend]()
    
    var displayedList = [Friend]()
    var displayedNames = [String]()
    
    
    //flag that tells if we are fetching data
    var loadingFromFirestore = false
    // the loading
    var indicator: UIActivityIndicatorView!
    // limit of search from firestore
    var searchLimit = 10
    // to save last doc of each call, so we can fetch next 10
    var lastSnap: QueryDocumentSnapshot!
    var newlyCreatedDocID: String = ""
    
    
    
    /******************************************************************************************************************************/
    
    
    @IBAction func saveSelectedSwitched(_ sender: UISwitch) {
        
    }
    
    @IBAction func skipTapped(_ sender: UITapGestureRecognizer) {
        // move to main
        // added on 29Sept Fix: MM
        clearOutCurrentCompare()
        
        
        dismissAllViewControllers()
    }
    
    @IBAction func onSendPressed(_ sender: UIButton) {
        // save the selected items
        saveSelectedItems()
        
    }
    /******************************************************************************************************************************/
    // saves the selected items in default items
    func saveSelectedItems(){
        
        
        let paths = friendList.indexPathsForSelectedRows
        var selectedItems = [Friend]()
        var receipientNames = [String]()
        
        var defaultItemsToRemove = [Friend]()
        var recentItemsToRemove = [Friend]()
        
        
        // unwrap optional
        if let items = paths{
            for item in items{
                // save the item
                // get selected value
                let friend = displayedList[item.row]
                selectedItems.append(friend)
                receipientNames.append(friend.username)
                // if sw is on it is default, also recent
                
                if saveDefaultSw.isOn{
                    print("saving default")
                    // checks if this friend is already in default list, if not add
                    if !defaultSendNames.contains(friend){
                        RealmManager.sharedInstance.addOrUpdateFriend(object: friend, sendStatus: SendStatus.DEFAULT)
                    }
                    
                }else{
                    // recent
                    // save it
                    print("saving recent")
                    // checks if this friend is already in recent list, if not add
                    if !recentSendNames.contains(friend){
                        RealmManager.sharedInstance.addOrUpdateFriend(object: friend, sendStatus: SendStatus.RECENT)
                    }
                    
                } // end of else
                
            }// end for loop
        }
        
        // check if sw on
        // delete old items if on
        
        print("removing old defaults")
        
        for item in defaultSendNames{
            
            
            if !selectedItems.contains(item){
                if saveDefaultSw.isOn{
                    defaultItemsToRemove.append(item)
                } // end is On
                
                // selected item doesn't contain this default name, so we should send here as well
                // cause this is a default name by default !
                
                receipientNames.append(item.username)
            }
            
            
            
            
        } // end for
        
        
        
        // this removes the old recent items from realm
        for item in recentSendNames {
            if !selectedItems.contains(item){
                recentItemsToRemove.append(item)
            }
        }
        
        
        RealmManager.sharedInstance.removeAllDefault(defaultItemsToRemove)
        
        // we'll remove the recent items as well
        RealmManager.sharedInstance.removeAllRecent(recentItemsToRemove)
        
        updateQuestion(newlyCreatedDocID, receipientNames)
        
        
        
        let alertVC = UIAlertController(title: "Sent!", message: "Question Sent to selected friends", preferredStyle: .alert)
        // On DISMISS
        alertVC.addAction(UIAlertAction.init(title: "Dismiss", style: .cancel, handler: { (action) in
            
            // Now move to main

            self.dismissAllViewControllers()
            
        }))
        
        self.present(alertVC, animated: true)
        
        
        
    }
    
    
    // fetch the default names from realm
    func getDefaultSendNames(){
        defaultSendNames = RealmManager.sharedInstance.getDefaultItems()
        // assing to our list and reload
        if defaultSendNames.count > 0{
            print("We got \(defaultSendNames.count) default contacts")
            displayedList.append(contentsOf: defaultSendNames)
            
            friendList.reloadData()
        }else{
            print("No default friend")
        }
    }// end of fetch default send names
    
    // fetch the recent names from realm
    func getRecentSendNames(){
        recentSendNames = RealmManager.sharedInstance.getRecentItems()
        
        recentSendNames = Array(Set(recentSendNames).subtracting(defaultSendNames))
        // assing to our list and reload
        if recentSendNames.count > 0{
            print("We got \(recentSendNames.count) recent contacts")
            
            // before appending remove duplicated that matches with default
            displayedList.append(contentsOf: recentSendNames)
            friendList.reloadData()
        }else{
            print("No recent friend")
        }
        
    }// end of fetch recent names
    
    
    // uploadImageToFirebasestorage
    // which image refers to 1 or 2 ie: top or bottom
    func updateQuestion(_ docID: String, _ receipients: [String]){
        Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION).document(docID).updateData([Constants.QUES_RECEIP_KEY:receipients])
    }// end of createQuestion
    
    
    // fetch friends from firestore
    func getFriendsFromFirestore(){
        
        Firestore.firestore()
            .collection(Constants.USERS_COLLECTION)
            .document(myProfile.username)
            .collection(Constants.USERS_LIST_SUB_COLLECTION)
            .whereField(Constants.USER_STATUS_KEY, in: [Status.FRIEND.description])
            .getDocuments { (querySnaps, error) in
                
                
                // fetch the personsList
                if let docs = querySnaps?.documents{
                    if docs.count > 0 {
                        
                        for item in docs{
                            // we'll need these to fetch details
                            // we don't want to fetch names already in recent/default list
                            if !self.displayedNames.contains(item.documentID){
                                self.friendNames.append(item.documentID)
                            }
                        }
                        
                        if self.friendNames.count > 0 {
                            // chunk the results
                            self.chunkedNames = self.friendNames.chunked(by: 10)
                            // now fetch 10 by 10
                            self.fetch10Friends()
                            
                        }
                    }
                }// end if let
                
            }// end of firebase
        
    }
    
    func fetch10Friends(){
        // set the flags
        self.loadingFromFirestore = true
        self.indicator.startAnimating()
        
        currentChunk += 1
        
        
        Firestore.firestore()
            .collection(Constants.USERS_COLLECTION)
            .whereField(.documentID(), in: chunkedNames[currentChunk]).limit(to: searchLimit).getDocuments { (snapshots, error) in
                print("Firestore call done for friend fetch")
                // set these flags
                self.loadingFromFirestore = false
                self.indicator.stopAnimating()
                
                if let error = error{
                    print(error.localizedDescription)
                    return
                }
                
                // the usual code
                if let docs = snapshots?.documents{
                    if docs.count > 0 {
                        
                        self.lastSnap = docs.last
                        
                        for item in docs{
                            
                            let doc = item.data()
                            //make a friend out of it
                            
                            let birthday = doc[Constants.USER_BIRTHDAY_KEY] as? Double ?? 0
                            let display_name = doc[Constants.USER_DNAME_KEY] as? String ?? item.documentID
                            
                            let phone_number = doc[Constants.USER_NUMBER_KEY] as? String ?? "0"
                            let rating = doc[Constants.USER_RATING_KEY] as? Int ?? 0
                            let review = doc[Constants.USER_REVIEW_KEY] as? Int ?? 0
                            let profile_pic = doc[Constants.USER_IMAGE_KEY] as? String ?? DEFAULT_USER_IMAGE_URL
                            
                            // create the profile
                            
                            let friend = Friend()
                            friend.dobMills = birthday
                            friend.displayName = display_name
                            friend.phoneNumberField = phone_number
                            friend.rating = rating
                            friend.review = review
                            friend.username = item.documentID
                            friend.imageString = profile_pic
                            
                            // add to realm and the list here
                            self.friends.append(friend)
                            self.displayedList.append(friend)
                            
                            let savedFriend = RealmManager.sharedInstance.getFriend(item.documentID)
                            
                            if let saved = savedFriend {
                                RealmManager.sharedInstance.addOrUpdateFriend(object: friend,sendStatus: saved.sendStatus)
                            }else{
                                RealmManager.sharedInstance.addOrUpdateFriend(object: friend,sendStatus: .NONE)
                            }
                            
                            print("Friend Added")
                        }
                        
                        
                        // reload the table
                        
                        self.friendList.reloadData()
                    }
                }
                
            } // end firestore call
    }// end fetch 10 friend
    
    
    
    
    // fetch contacts from iPhone
    func getContacts(){
        print("Starting contact fetch")
        //   UIImage(systemName: "person.crop.circle")
        let store = CNContactStore()
        // request permission
        store.requestAccess(for: .contacts) { [self] (granted, error) in
            if let error = error {
                print("failed to request access", error)
                return
            }
            if granted {
                // we will be requesting for these fields
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactThumbnailImageDataKey, CNContactImageDataAvailableKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                request.sortOrder = CNContactSortOrder.givenName
                do {
                    
                    //This method can fetch all contacts without keeping all of them at once in memory, which is expensive.
                    try store.enumerateContacts(with: request, usingBlock: { (contact, stopPointer) in
                        // if this contact has no phone number, we won't count him
                        // as per the doc
                        if let phoneNumber = contact.phoneNumbers.first?.value.stringValue, phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined().count >= 10{
                            
                            let number = formatNumber(phoneNumber)
                            // fill the all contact Array to reuse later
                            
                            
                            
                            let friend = Friend()
                            friend.imageString = self.getProfileImageString(contact)
                            friend.displayName = "\(contact.givenName) \(contact.familyName)"
                            friend.username = "iPhone Contact" // no username for iPhone contact
                            friend.rating = 0
                            friend.phoneNumberField = number
                            friend.dobMills = 0
                            friend.sendStatus = .NONE
                            
                            self.contacts.append(friend)
                            
                        }
                        
                        
                    }) // end of iteration
                    
                    // set these in displayed
                    self.displayedList.append(contentsOf: self.contacts)
                    // reload must be called from main thread
                    DispatchQueue.main.async {
                        // reload the tableview with newly added data
                        friendList.reloadData()
                    }
                    
                } catch let error {
                    print("Failed to enumerate contact", error)
                }
            } else {
                print("access denied")
            }
        }// end of req access
        
        
    }// end of fetch contact
    
    
    
    // indicator while loading
    
    func setupIndicator() {
        indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        indicator.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.maxY - 20)
        view.addSubview(indicator)
        indicator.bringSubviewToFront(view)
    }
    
    
    /******************************************************************************************************************************/
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of rows = count of these list
        print("\(displayedList.count)")
        return displayedList.count
    }
    
    
    // FOR DEBUG PURPOSE TO SEE HOW RECENTS AND DEFAULTS BEHAVE
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let friend = displayedList[indexPath.row]
        
        if friend.sendStatus == .DEFAULT {
            print("coloring the default cell")
            //cell.contentView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.5)
            
            friendList.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            
        }
//        else if friend.sendStatus == .RECENT {
//            print("coloring the recent cell")
//            cell.contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
//        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("loading cell")
        let cell = Bundle.main.loadNibNamed("QFriendCell", owner: self, options: nil)?.first as! QFriendCell // we already know it is on our project list
        var friend : Friend!
        
        if displayedList.count > 0{
            friend = displayedList[indexPath.row]
            
            // DISPLAY THE CELL DATA
            let today = Date()
            let bday = Date(timeIntervalSince1970: friend.dobMills)
            let dc =  Calendar.current.dateComponents([.year], from: bday, to: today)
            
            cell.display_name.text = friend.displayName
            cell.user_name.text = friend.username
            self.displayedNames.append(friend.username)
            
            
            // display profile image of friend in cell
            //            cell.profileImage.image = convertBase64StringToImage(imageBase64String: friend.imageString)
            
            // MARK: If we have the images stored in Realm already, we should switch this to a Realm fetch instead of a Firestore fetch in order to save reads
            downloadOrLoadFirebaseImage(
                ofName: getFilenameFrom(qName: friend.username, type: .ASK),
                forPath: friend.imageString) { image, error in
                    if let error = error{
                        print("Error: \(error.localizedDescription)")
                        return
                    }
                    if let imageToDisplay = image {
                        cell.profileImage.image = imageToDisplay
                    } else {
                        cell.profileImage.image = self.convertBase64StringToImage(imageBase64String: friend.imageString)
                    }
                }
            
            
            
            
            
            // get the age from date component dc
//            if let age = dc.year{
//                if friend.dobMills == 0{
//                    // if age is set 0, for iPhone contacts
//                    // do nothing maybe?
//                    cell.age.text = ""
//                }else{
//                    cell.age.text = "\(age)"
//                }
//                
//            }
            
            cell.rating.text = "(\(friend.rating))"
            
            
            
            return cell
        }
        
        
        return UITableViewCell()
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let isReachingEnd = scrollView.contentOffset.y >= 0
        && scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)
        
        
        if isReachingEnd && !loadingFromFirestore{
            
            // but for normal way, fetch it
            loadingFromFirestore = true
            
            // end of list?
            if currentChunk != chunkedNames.count - 1 {
                // when we are searching fetch it in different way
                fetch10Friends()
            }
            
            
            
        }
        
    }
    /******************************************************************************************************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // pops all view controllers to clean up the memory
        
        
        setupIndicator()
        // Do any additional setup after loading the view.
        getDefaultSendNames()
        getRecentSendNames()
        getFriendsFromFirestore()
        //getContacts()
        
        // set the delegate and datasource of our table view of friends
        friendList.delegate = self
        friendList.dataSource = self

        
    }
    
    /// This pops all existing view controllers all the way down to login view to break the strong references that cause a memory leak otherwise. There is most likely a better solution involving a weak var declaration in AVCameraViewController. The issue seems to be eminating from that VC after the continue button is tapped.
    func dismissAllViewControllers() {
        // this comment added from copy_of_wyatt....
        print("dismissAllViewControllers() called from CQVC")
        
        
        
//        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        
//        let eqvcThatPresented = self.presentingViewController
        
//        self.presentingViewController?.dismiss(animated: false)
        
        print("presenting VC of CQVC is: \(String(describing: self.presentingViewController))")
        
//        self.presentingViewController?.presentingViewController?.presentingViewController?.dismiss(animated: false)
        
        self.view.window?.rootViewController?.dismiss(animated: true, completion: {
            print("inside completion hander of dimiss")
//
//            eqvcThatPresented?.dismiss(animated: true)
//
//            print("eqvcThatPresented is: \(String(describing: eqvcThatPresented))")

        })
        
        
       // self.dismiss(animated: true, completion: nil)

        
        
//        self.view.window?.rootViewController?.navigationController
    }
    
    
    // Experimenting with this. It doesn't work right now.
    func backThree() {
        print("backThree called")
        guard let navController = self.navigationController else {
            print("error executing backThree. Could not find the navigationController.")
            return
        }
        let viewControllers: [UIViewController] = navController.viewControllers as [UIViewController]
        self.navigationController!.popToViewController(viewControllers[viewControllers.count - 4], animated: true)
    }
    
    //This fails too
    func otherBackThree() {
        print("otherBackThree called")
        guard let navController = self.view.window?.rootViewController?.navigationController else {
            print("error executing otherBackThree. Could not find the navigationController.")
            return
        }
        let viewControllers: [UIViewController] = navController.viewControllers as [UIViewController]
        self.navigationController!.popToViewController(viewControllers[viewControllers.count - 4], animated: true)
    }
    
    
}
