//
//  Formerly "CQViewController.swift"
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-15.
//

import UIKit
import Firebase //importing this includes the Analytics package so no need for separate import of that
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
    @IBOutlet weak var friendListTableView: UITableView!
	
	// user default
	var userDefault : UserDefaults!
    
    /// This hold friend objects, not just names
    var defaultSendNames = [Friend]()
	/// This hold friend objects, not just names
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
	
	
	/// This is a list of all friends whose row should be selected orange. We use it to set the row to selected or de-selected.
	var selectedFriendNames = [String]()
    
    
    //flag that tells if we are fetching data
    var loadingFromFirestore = false
    // the loading
    var indicator: UIActivityIndicatorView!
    // limit of search from firestore
    var searchLimit = 10
    // to save last doc of each call, so we can fetch next 10
    var lastSnap: QueryDocumentSnapshot!
    var newlyCreatedDocID: String = ""
    
	var ud = UserDefaults.standard
    
    
    /******************************************************************************************************************************/
    
    
    @IBAction func saveSelectedSwitched(_ sender: UISwitch) {
		
		print("Default to these friends? \(saveDefaultSw.isOn)")
		
		userDefault.setValue(saveDefaultSw.isOn, forKey: Constants.UD_DEFAULT_TO_THESE_FRIENDS_SWITCH_SETTING)
        
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
        
        
        let paths = friendListTableView.indexPathsForSelectedRows
        var selectedItems = [Friend]()
        var recipientNames = [String]()
        
        var defaultItemsToRemove = [Friend]()
        var recentItemsToRemove = [Friend]()
		
		var numFriendsSentTo: Int = 0
        
        
        // unwrap optional
        if let items = paths{
            for item in items{
                // save the item
                // get selected value
                let friend = displayedList[item.row]
                selectedItems.append(friend)
                recipientNames.append(friend.username)
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
                
                recipientNames.append(item.username)
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
        
		// Updates the Question in Firestore
        updateQuestion(newlyCreatedDocID, recipientNames)
		
		// determine the number of names on the list for the Question to be sent to so we can include that in the event report
		numFriendsSentTo = recipientNames.count
        
		// Log Analytics Event
		Analytics.logEvent(Constants.SENT_QUESTION_TO_FRIEND, parameters: ["num_friends_sent_to": numFriendsSentTo])
        
        
        let alertVC = UIAlertController(title: "Sent!", message: "Question Sent to selected friends", preferredStyle: .alert)
        // On DISMISS
        alertVC.addAction(UIAlertAction.init(title: "Got It", style: .cancel, handler: { (action) in
            
            // Now move to main

            self.dismissAllViewControllers()
            
        }))
        
        self.present(alertVC, animated: true)
        
        
        
    }
    
    
    /// fetch the default names from realm
    func getDefaultSendNames(){
        defaultSendNames = RealmManager.sharedInstance.getDefaultItems()
		
		// here we baseline the selected friend names list once using the defaults we just retrieved above:
		selectedFriendNames = getNameArrayFrom(friendArray: defaultSendNames)
		
        // adding to our list and reload
        if defaultSendNames.count > 0{
            print("We got \(defaultSendNames.count) default contacts")
            displayedList.append(contentsOf: defaultSendNames)
            
            friendListTableView.reloadData()
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
            friendListTableView.reloadData()
        }else{
            print("No recent friend")
        }
        
    }// end of fetch recent names
    
    
    /// uploads Image To Firebase storage
    func updateQuestion(_ docID: String, _ recipients: [String]){
		// which image refers to 1 or 2 ie: top or bottom

        Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(docID).updateData([Constants.QUES_RECEIP_KEY:recipients])

        
        // to increment the QFF Count
        for username in recipients {
            increaseQFFCountOf(username: username)
        }
        
        
    }// end of createQuestion
    
    
    
    
    // fetch friends from firestore
    func getFriendsFromFirestore(){
        
        Firestore.firestore()
            .collection(FirebaseManager.shared.getUsersCollection())
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
		print("getFriendsFromFirestore() completed")
        
    }
    
    func fetch10Friends(){
        // set the flags
        self.loadingFromFirestore = true
        self.indicator.startAnimating()
        
        currentChunk += 1
        
        
        Firestore.firestore()
            .collection(FirebaseManager.shared.getUsersCollection())
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
                        
                        self.friendListTableView.reloadData()
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
                        friendListTableView.reloadData()
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
	
	func getNameArrayFrom(friendArray: [Friend]) -> [String] {
		var namesToReturn: [String] = []
		for friend in friendArray {
			namesToReturn.append(friend.username)
		}
		return namesToReturn
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
    
	/// here we add that a cell should be selected next time it displays
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let nameOfFriendRowSelected: String = displayedList[indexPath.row].username
		
		if selectedFriendNames.contains(nameOfFriendRowSelected) {
			// it's already supposed to be selected, don't add a duplicate
			return
		} else {
			selectedFriendNames.append(nameOfFriendRowSelected)
		}
	}
	
	// here we specify that a cell should be DEselected next time it displays
	func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		let nameOfFriendRowSelected: String = displayedList[indexPath.row].username
		
		// remove the string from the array if it's in there, if not this will just return the array as it was
		selectedFriendNames = removeIf(element: nameOfFriendRowSelected, memberOf: selectedFriendNames)
	}
	

	// This happens when a cell is about to display from off the screen to now ON the screen
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		
//		let friend = displayedList[indexPath.row]
		guard let friendName = displayedList[indexPath.row].username else {
			return // don't select the row if we can't find a username for this friend
		}
		
		
		//        if friend.sendStatus == .DEFAULT {
		
		
		// We check here to determine whether the cell corresponds to a friend name that the user has either selected in this instance of the view controller, or was a default friend to send to and was not yet modified in this instance of the SendToFriendsVC
		if selectedFriendNames.contains(friendName) {
			
			print("selecting and coloring the cell")
			//cell.contentView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.5)
			
			friendListTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			
		} else {
			
			friendListTableView.deselectRow(at: indexPath, animated: false)
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
            // was dc, never used, so commented out
            //_ =  Calendar.current.dateComponents([.year], from: bday, to: today)
            
            cell.display_name.text = friend.displayName
            cell.user_name.text = friend.username
            cell.age.text = "" //sets "Age" label to blank
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
        friendListTableView.delegate = self
        friendListTableView.dataSource = self
		
		
		// init the UD (so we can save the toggle switch position)
		userDefault = UserDefaults.standard
		
		// set the "default to these friends in the future" toggle switch to the right position
		let defaultToTheseFriends = userDefault.bool(forKey: Constants.UD_DEFAULT_TO_THESE_FRIENDS_SWITCH_SETTING)
		saveDefaultSw.setOn(defaultToTheseFriends, animated: false)

        
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { // `0.7` is the desired number of seconds.
			self.showTutorialAlertViewAsRequired()
		}
		
	}
	
	func showTutorialAlertViewAsRequired() {
		
		let skipCompareTutorial = UserDefaults.standard.bool(forKey: Constants.UD_SKIP_SEND_TO_FRIENDS_TUTORIAL_Bool)
		
		if !skipCompareTutorial {
			let alertVC = UIAlertController(title: "Congrats on publishing your first photo!", message: "Seeing this page means your photo is now live and being reviewed by everyone who has Tangerine. \nIf this was an accident, don't worry, you can unpost it at any time. \n\nNext we’ll show you how to request friends. Once you have friends, you’ll see their names here so you can tag them to make sure they review your photo first.", preferredStyle: .alert)
			alertVC.addAction(UIAlertAction.init(title: "Got It!", style: .cancel, handler: { (action) in
				// Once the user has seen this, don't show it again
				self.ud.set(true, forKey: Constants.UD_SKIP_SEND_TO_FRIENDS_TUTORIAL_Bool)
			}))
			
			present(alertVC, animated: true, completion: nil)
		}
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
