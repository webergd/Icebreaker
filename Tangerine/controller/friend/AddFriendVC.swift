//
//  AddFriendVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-04.
//

import UIKit
import Contacts
import FirebaseFirestoreSwift
import FirebaseFirestore
import RealmSwift
import MessageUI
import grpc

class AddFriendVC: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate {

    // MARK: UI Items
    
    // this var saves all contact from device
    // we'll take 10 each time and run query
    var contacts = [Person]()
    // all number from phone
    var allNumbers = [String]()
    // shows the current displayed Persons
    var displayedContacts = [String:Person]()
    // shows the current displayed Person's Dictionary keys for iteration
    var displayedKeys = [String]()
    // this will store the chunked contact either from all/filtered
    var chunkedContacts = [[Person]]()
    // this variable will keep track of our chunk of contacts
    var currentChunk = -1
    //flag that tells if we are fetching data
    var loadingFromFirestore = false
    // the loading
    var indicator: UIActivityIndicatorView!
    // for cloud search section
    var isCloudSearch = false
    // will hold the current displaying contacts fetched from firestore
    var displayedCloudContacts = [String:Person]()
    // will hold phone number of these contacts
    var displayedCloudKeys = [String]()
    // to save last doc of each call, so we can fetch next 10
    // searching only
    var lastSnapForDocID : QueryDocumentSnapshot!
    var lastSnapForDname : QueryDocumentSnapshot!
    // the text that has been searched
    var searchedText : String!
    // limit of search from firestore
    var searchLimit = 10
    // Persons I added already
    var addedList = [String]()
    // person I won't show on list => block/got blocked by those
    var blockList = [String]()
    
    
    // the search bar and segment
    var searchbar: UISearchBar!
    var searchSegment: UISegmentedControl!
    // cancel and back buttons with width + the table view
    var cancelBtn: UIButton!
    var buttonWidth: NSLayoutConstraint!
    var friendTableView: UITableView!
    var backBtn: UIButton!
    var backButtonWidth: NSLayoutConstraint!
    
    // MARK: Actions
    
    // when back and cancel is clicked, searchbar is between them in view
    @objc func onCancelTapped() {
        hideCancelButton()
    }
    
    @objc func onBackClicked() {
        dismiss(animated: true, completion: nil)
    }
    // when we change local/cloud, reload the table
    @objc func onSegmentChanged(_ sender: UISegmentedControl) {
        isCloudSearch = sender.selectedSegmentIndex == 1
        print("Searching cloud? \(isCloudSearch)")
        
        friendTableView.reloadData()
    }
    

    
    // do initial setup on view load
    func setupUI(){
        // remove search border
        searchbar.backgroundImage = UIImage()
        
        //fetch the contacts
        fetchContacts()
        
        friendTableView.delegate = self
        friendTableView.dataSource = self
        
        // hide the button
        hideCancelButton()

    }
    
    // this makes the cancel button gone when search ends
    func hideCancelButton() {
        // when cancel is gone, back should be visible
        backButtonWidth.constant = 30
        backBtn.isHidden = false
        backBtn.layoutIfNeeded()
        backBtn.setNeedsUpdateConstraints()
        
        // the rest is for cancel button
        buttonWidth.constant = 0
        cancelBtn.isHidden = true
        cancelBtn.layoutIfNeeded()
        cancelBtn.setNeedsUpdateConstraints()
        view.endEditing(true)
    }
    
    // this makes the cancel button visible when search starts
    func showCancelButton(){
        
        // when cancel is visible, back should be gone
        
        backButtonWidth.constant = 0
        backBtn.isHidden = true
        backBtn.layoutIfNeeded()
        backBtn.setNeedsUpdateConstraints()
        
        // the rest is for cancel button
        buttonWidth.constant = 48
        cancelBtn.isHidden = false
        cancelBtn.layoutIfNeeded()
        cancelBtn.setNeedsUpdateConstraints()
        
    }
    
    
    // this will fetch data from firestore without search, the first segment
    func fetchDataFromFirestore(){
        
        print("fetching data from firestore \(chunkedContacts.count)")
        //take 10 contacts and query for them
        currentChunk+=1
        if currentChunk != chunkedContacts.count {
            
            
            indicator.startAnimating()
            
            let newChunk = chunkedContacts[currentChunk]
            // get the phone number in a list
            var numbers = [String]()
            var newDict = [String:Person]()
            
            for item in newChunk {
                let number =  item.phoneNumberField
                // making the number formated to our specification
                
                if myProfile.phone_number != number {
                    numbers.append(number)
                    // also feeding the list
                    newDict[number] = item
                    // and we will need the keys for later
                    displayedKeys.append(number)
                }
            }
            
            // query in firestore against these contacts
            Firestore.firestore().collection(Constants.USERS_COLLECTION).whereField(Constants.USER_NUMBER_KEY, in: numbers).getDocuments { (snapshots, error) in
                
                print("Firestore call done")
                if let error = error{
                    print(error.localizedDescription)
                    return
                }
                
                if let docs = snapshots?.documents {
                    if docs.count > 0 {
                        // itereate over the collection
                        for item in docs{
                            print("From general search we got \(docs.count) person")
                            // check if blocked user or not
                            
                            if !self.blockList.contains(item.documentID){
                                // get the dictionary from the item/one document
                                // it is easier to turn it into dict in swift
                                let dict = item.data()
                                // find the number associated with this user
                                let phone = dict[Constants.USER_NUMBER_KEY] as! String
                                
                                newDict[phone] = self.getPersonFromDict(dict, item.documentID, phone)[phone]
                            }
                            
                            
                        }
                    } // end of for each
                }// end if let
                
                // as we done loading before reloading data
                // set the flag to opposite
                self.loadingFromFirestore = false
                // merge the fetch + edited data
                self.displayedContacts.merge(newDict){(_,new) in new}
                print("DC size in fetch contact \(self.displayedContacts.count)")
                // hide the indicator
                self.indicator.stopAnimating()
                // load the table with new data
                self.friendTableView.reloadData()
                
            }// end of firebase call
            
        }
    }// end of fetch data from firestore
    
    
    func searchDataOnFirestore(_ searchTerm: String){
        
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        
        
        
        print("we are searching for \(searchTerm)")
        self.loadingFromFirestore = true
        self.indicator.startAnimating()
        // to seach for username aka document id
        // starts with
        
        var query1 : Query!
        
        // if last snap present get the next 10
        if self.lastSnapForDocID != nil{
            query1 = Firestore.firestore()
                .collection(Constants.USERS_COLLECTION)
                .whereField(.documentID(), isGreaterThanOrEqualTo: searchTerm)
                .whereField(.documentID(), isLessThanOrEqualTo: "\(searchTerm)\u{F7FF}")
                .limit(to: searchLimit)
                .start(afterDocument: self.lastSnapForDocID)
        }else{
            query1 = Firestore.firestore()
                .collection(Constants.USERS_COLLECTION)
                .whereField(.documentID(), isGreaterThanOrEqualTo: searchTerm)
                .whereField(.documentID(), isLessThanOrEqualTo: "\(searchTerm)\u{F7FF}")
                .limit(to: searchLimit)
        }
        
        group.enter()
        query1.getDocuments { (snapshots, error) in
            print("Firestore call done for key search")
            
            if let error = error{
                print(error.localizedDescription)
                group.leave()
                return
            }
            // to be filled later
            var newDict = [String:Person]()
            // force unwraping casue we know what the data type would be
            // official way
            if let docs = snapshots?.documents{
                if docs.count > 0 {
                    print("we've got \(docs.count) results")
                    // set the last doc here as well
                    self.lastSnapForDocID = docs.last
                    for item in docs{
                        // check the blocklist and check if it's not me
                        if !self.blockList.contains(item.documentID) && myProfile.username != item.documentID{
                            // get the dictionary from the item/one document
                            // it is easier to turn it into dict in swift
                            let dict = item.data()
                            // only take the user if the orientation is present, which is the last step of signup
                            // if it presents then the user has done signing, simple trick
                            if let _ = dict[Constants.USER_ORIENTATION_KEY] as? String{
                                // find the number associated with this user
                                let phone = dict[Constants.USER_NUMBER_KEY] as! String
                                newDict = self.getPersonFromDict(dict, item.documentID, phone)
                                
                                if !self.displayedCloudKeys.contains(phone){
                                    self.displayedCloudKeys.append(phone)
                                    self.displayedCloudContacts.merge(newDict){(_,new) in new}
                                }
                            }
                        }
                        
                    }
                } // end of for
                
                // as we done loading before reloading data
                // set the flag to opposite
                self.loadingFromFirestore = false
                
                // leave the group
                group.leave()
                self.indicator.stopAnimating()
                // load the table with new data
                self.friendTableView.reloadData()
                
            }// end of if let
            
        }// end of searching by docID ie: username
        
        
        // begins with is not available and is tricky
        // contains not available, endsWith Not possible at all
        // so doing the trick that works for begins with
        
        // the begins with query
        
        var query2 : Query!
        
        // if last snap present get the next 10
        if self.lastSnapForDname != nil{
            query2 = Firestore.firestore()
                .collection(Constants.USERS_COLLECTION)
                .whereField(Constants.USER_DNAME_KEY, isGreaterThanOrEqualTo: searchTerm)
                .whereField(Constants.USER_DNAME_KEY, isLessThanOrEqualTo: "\(searchTerm)\u{F7FF}")
                .limit(to: searchLimit)
                .start(afterDocument: self.lastSnapForDname)
        }else{
            query2 = Firestore.firestore()
                .collection(Constants.USERS_COLLECTION)
                .whereField(Constants.USER_DNAME_KEY, isGreaterThanOrEqualTo: searchTerm)
                .whereField(Constants.USER_DNAME_KEY, isLessThanOrEqualTo: "\(searchTerm)\u{F7FF}")
                .limit(to: searchLimit)
        }
        
        
        group.enter()
        query2.getDocuments { (snaps, error) in
            print("Firestore call done for key search")
            if let error = error{
                print(error.localizedDescription)
                group.leave()
                return
            }
            // fill later
            var newDict = [String:Person]()
            // force unwraping casue we know what the data type would be
            // official way
            if let docs2 = snaps?.documents{
                if docs2.count > 0 {
                    
                    self.lastSnapForDname = docs2.last
                    for item in docs2{
                        
                        // check the blocklist and check if it's not me
                        if !self.blockList.contains(item.documentID) && myProfile.username != item.documentID{
                            let dict = item.data()
                            
                            if let _ = dict[Constants.USER_ORIENTATION_KEY] as? String{
                                
                                // find the number associated with this user
                                let phone = dict[Constants.USER_NUMBER_KEY] as! String
                                newDict = self.getPersonFromDict(dict, item.documentID, phone)
                                
                                if !self.displayedCloudKeys.contains(phone){
                                    self.displayedCloudKeys.append(phone)
                                    self.displayedCloudContacts.merge(newDict){(_,new) in new}
                                }
                            }
                        }
                    }
                }// end of for
                
                
                // as we done loading before reloading data
                // set the flag to opposite
                self.loadingFromFirestore = false
                
                //
                group.leave()
                self.indicator.stopAnimating()
                // load the table with new data
                self.friendTableView.reloadData()
                
            }// end of if name
            
            
            
        }// end of firebase call
        
        
        group.notify(queue: queue){
            if self.displayedCloudKeys.count > 0 {
                print("We got something")
            }else{
                self.presentDismissAlertOnMainThread(title: "No Result", message: "Searching for \(searchTerm) returned no result, Try fewer characters.")
            }
        }
    }
    
    func getPersonFromDict(_ dict: [String:Any], _ docID: String,_ phone: String) -> [String:Person]{
        print("getting person from dict")
        var newDict = [String:Person]()
        
        // the display name
        let dname = dict[Constants.USER_DNAME_KEY] as! String
        // profile image
        let profile_pic = dict[Constants.USER_IMAGE_KEY] as? String ?? DEFAULT_USER_IMAGE_URL // might be nil if user hasn't set yet
        
        // create a person instance
        
        let person = Person()
        person.imageString = profile_pic
        person.displayName = dname
        person.username = docID
        person.phoneNumberField = phone
        
        if addedList.contains(person.username) {
            print("Found in added list")
            person.status = .REQUESTED
        } else if myFriendNames.contains(person.username) {
            print("Found in friends list")
            person.status = .FRIEND
        }else{
            person.status = .REGISTERED
        }
        
        
        newDict[phone] = person
        
        return newDict
        
    }
    
    
    
    /******************************************************************************************************************************/
    /********************************************  FIRESTORE CALLS ENDED ABOVE *****************************************/
    /******************************************************************************************************************************/
    /******************************************************************************************************************************/
    
    
    func fetchContacts() {
        
        //   UIImage(systemName: "person.crop.circle")
        let store = CNContactStore()
        // request permission
        store.requestAccess(for: .contacts) { [self] (granted, error) in
            if let error = error {
                print("failed to request access", error)
                return
            }
            if granted {
                
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
                            
                            let person = Person()
                            person.imageString = self.getProfileImageString(contact)
                            person.displayName = "\(contact.givenName) \(contact.familyName)"
                            person.username = "Tap to invite me to Tangerine!"
                            person.phoneNumberField = number
                            person.status = .NONE
                            
                            self.contacts.append(person)
                            // save the numbers to be used as keys
                            self.allNumbers.append(number)
                            
                            
                            
                        }
                        
                        
                    })
                    
                    if(self.contacts.count > 0){
                        // divide the contacts into chunks of 10 so that we can query on firestore
                        self.chunkedContacts = self.contacts.chunked(by: 10)
                        
                        DispatchQueue.main.async {
                            self.fetchDataFromFirestore()
                        }
                        
                    }
                    
                    
                } catch let error {
                    print("Failed to enumerate contact", error)
                }
            } else {
                print("access denied")
            }
        }// end of req access
    } // end of fetch
    
    
    // indicator while loading
    
    func setupIndicator() {
        indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        indicator.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.maxY - 20)
        view.addSubview(indicator)
        indicator.bringSubviewToFront(view)
    }
    
    
    func addPersonToFirestoreAndLocal(_ person: Person){
        print("Person saved in added list is \(addedList.count)")
        // add to local
        do {
            let database = try Realm()
            database.beginWrite()
            person.status = .REQUESTED
            database.add(person, update: .modified)
            self.presentDismissAlertOnMainThread(title: "Sent!", message: "Friend request sent to \(person.displayName)")
            try database.commitWrite()
            
            // add to local list
            addedList.append(person.username)
            self.friendTableView.reloadData()
            
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
        
    }
    
    
    
    // fetch device saved persons
    
    func getSaved(){
        
        let list = RealmManager.sharedInstance.getRequestedPersonList()
        
        let blockedList = RealmManager.sharedInstance.getBothBlockedPersonList()
        
        // add the usernames
        for item in list{
            addedList.append(item.username)
        }
        
        // add the block names
        for item in blockedList{
            blockList.append(item.username)
        }
        
        // setup the ui now
        setupUI()
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
            
            self.friendTableView.reloadData()
            
        } catch {
            print("Error occured while updating realm")
        }
    } // end of add
    
    func removePersonsList(){
        print("Reseting persons list")
        let currentList = RealmManager.sharedInstance.getPersonList()
        do {
            let database = try Realm()
            database.beginWrite()
            database.delete(currentList)
            try database.commitWrite()
            
            self.friendTableView.reloadData()
            
        } catch {
            print("Error occured while updating realm")
        }
    }// end of remove
    
    func syncPersonList(){
        // for invited to work, change the array on "in" field
        // We are requesting for
        // REQUESTED => so we can show the "Added" Label
        // BLOCK => so we hide these users
        // GOT_BLOCKED => they blocked us, can't see them
        // PENDING => he already sent a request to me, no point of showing him here
        
        print("Syncing")
        // reset the db
        self.removePersonsList()
        Firestore.firestore()
            .collection(Constants.USERS_COLLECTION)
            .document(myProfile.username)
            .collection(Constants.USERS_LIST_SUB_COLLECTION)
            .whereField(Constants.USER_STATUS_KEY, in: [
                Status.REQUESTED.description,
                Status.BLOCKED.description,
                Status.GOT_BLOCKED.description,
                Status.PENDING.description])
            .getDocuments { (querySnaps, error) in
                // no need to show alert here
                if error != nil {
                    print("Sync error \(String(describing: error?.localizedDescription))")
                    return
                }
                
                // fetch the personsList
                if let docs = querySnaps?.documents{
                    if docs.count > 0 {
                        
                        for item in docs{
                            
                            let personListItem = PersonList()
                            personListItem.username = item.documentID
                            personListItem.display_name = item.data()[Constants.USER_DNAME_KEY] as? String
                            personListItem.profile_pic = item.data()[Constants.USER_IMAGE_KEY] as? String
                            personListItem.status = getStatusFromString(item.data()[Constants.USER_STATUS_KEY] as! String)
                            
                            // add to local
                            self.addOrUpdatePersonList(personListItem)
                        }
                        print("Sync done")
                    }
                    // reload this
                    self.getSaved()
                }// end if let
                
            }// end of firebase
    } // end of sync
    
    
    
    
    
    // sending msg
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result.rawValue) {
        case MessageComposeResult.cancelled.rawValue:
            print("Message was cancelled")
            self.dismiss(animated: true, completion: nil)
        case MessageComposeResult.failed.rawValue:
            print("Message failed")
            self.dismiss(animated: true, completion: nil)
        case MessageComposeResult.sent.rawValue:
            print("Message was sent")
            self.dismiss(animated: true, completion: nil)
        default:
            break;
        }
    }
    
    // MARK: Delegates
    // when search on keyboard is clicked
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // handle search, when the search from keyboard is clicked
        
        if let searchedText = searchbar.text{
            print("Search Button \(searchedText)")
            if isCloudSearch{
                print("Searing on cloud")
                self.displayedCloudContacts.removeAll()
                self.displayedCloudKeys.removeAll()
                self.searchedText = searchedText
                searchDataOnFirestore(searchedText.lowercased())
            }else{
                // do search on local here
                // actually filter
                // displayedContact might have filtered result, so remove it first
                
                displayedContacts.removeAll()
                displayedKeys.removeAll()
                
                // clear the chunk to set again for filtered list
                chunkedContacts.removeAll()
                currentChunk = -1
                
                // temp var for chunking again
                var filteredContact = [Person]()
                
                for item in contacts{
                    // checks if this item matches with our search
                    if(item.displayName.lowercased().contains(searchedText.lowercased()) || item.username.lowercased().contains(searchedText.lowercased())){
                        // match found, add
                        displayedContacts[item.phoneNumberField] = item
                        displayedKeys.append(item.phoneNumberField)
                        
                        // add to chunk contacts as well
                        filteredContact.append(item)
                        
                    }
                }
                
                // fetch data from firestore to match against the filtered list
                if filteredContact.count > 0 {
                    chunkedContacts = filteredContact.chunked(by: 10)
                    fetchDataFromFirestore()
                }else{
                    // else reload to remove all item
                    friendTableView.reloadData()
                }
                
            }
            
        }
        
        // hide the button now
        hideCancelButton()
    }
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        showCancelButton()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("Searchbar did change")
        // only fires when user presses the clear button or removes all text
        if searchbar.text == ""{
            print("clear | isCloudSearch: \(isCloudSearch)")
            if isCloudSearch{
                // not sure what to do yet
                self.displayedCloudContacts.removeAll()
                self.displayedCloudKeys.removeAll()
                self.lastSnapForDname = nil
                self.lastSnapForDocID = nil
                
            }else{
                // remove all filters
                // displayedContact might have filtered result, so remove it first
                
                displayedContacts.removeAll()
                displayedKeys.removeAll()
                
                // clear the chunk to set again for filtered list
                chunkedContacts.removeAll()
                currentChunk = -1// displayedContact might have filtered result, so remove it first
                
                // reset the chunks again and fetch matches
                chunkedContacts = contacts.chunked(by: 10)
                fetchDataFromFirestore()
            }
            
        }
    }
    
    
    // return the number of rows in tableview
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isCloudSearch ? displayedCloudContacts.count : displayedContacts.count
    }
    
    // sets the data for the row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        print("add friend table invalidated")
        let cell = Bundle.main.loadNibNamed("FriendCell", owner: self, options: nil)?.first as! FriendCell // we already know it is on our project list
        var person : Person!
        
        // for checking if we are trying to fill will nil data
        var isDataAvailable = false
        if isCloudSearch {
            print(displayedCloudKeys.count)
            if displayedCloudKeys.count > 0 {
                person = displayedCloudContacts[displayedCloudKeys[indexPath.row]]!
                isDataAvailable = true
            }
        }else{
            if displayedKeys.count > 0{
                // with all the display key we can go over all the dictionary Persons
                person = displayedContacts[displayedKeys[indexPath.row]]!
                isDataAvailable = true
            }
        }
        
        if isDataAvailable{
            
            // Default data
            cell.title.text = person.displayName
            cell.subtitle.text = person.username
            
            if person.imageString.starts(with: "https"){
                // firebase
                downloadOrLoadFirebaseImage(
                    ofName: getFilenameFrom(qName: person.username, type: .ASK),
                    forPath: person.imageString) { image, error in
                        if let error = error{
                            print("Error: \(error.localizedDescription)")
                            return
                        }
                        
                        print("AFVC Image Downloaded for \(String(describing: person.username))")
                        cell.profileImageView.image = image
                    }
                
                
            }else{
                cell.profileImageView.image = convertBase64StringToImage(imageBase64String: person.imageString)
            }
            
            
            
            
            // DISPLAY THE CELL DATA
            if person.status == Status.REGISTERED {
                // set the button based on status
                // function names saying what are they for
                
                cell.button.setTitle("Add", for: .normal)
                cell.button.backgroundColor = UIColor.systemGreen
                cell.button.setTitleColor(UIColor.white, for: .normal)
                cell.button.layer.borderWidth = 1.0
                cell.button.layer.cornerRadius = 6.0
                cell.button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
                cell.button.isEnabled = true
                cell.handleClick={
                    self.addPersonToFirestoreAndLocal(person)
                    
                }
                
                // WYATT ADD 2/1/22
                // A good result looks like this:
                // Search for a person who is already a friend
                // Cell should have green "Friend" button that is disabled
            } else if person.status == Status.FRIEND {
                cell.button.setTitle("Friends", for: .normal)
                cell.button.backgroundColor = UIColor.systemGreen
                cell.button.setTitleColor(UIColor.white, for: .normal)
                cell.button.layer.borderWidth = 1.0
                cell.button.layer.cornerRadius = 6.0
                cell.button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
                cell.button.isEnabled = false
                
                
            }else if person.status == .REQUESTED{
                cell.button.setTitle("Requested", for: .normal)
                cell.button.backgroundColor = UIColor.systemOrange
                cell.button.setTitleColor(UIColor.white, for: .normal)
                cell.button.layer.borderWidth = 1.0
                cell.button.layer.cornerRadius = 6.0
                cell.button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
                cell.button.isEnabled = true
                cell.handleClick={
                    
                    // self.presentDismissAlertOnMainThread(title: "Hey!", message: "This person is already added")
                }
            }
            else{
                // this block never execute on local search
                
                cell.button.setTitle("Invite", for: .normal)
                cell.button.backgroundColor = UIColor.systemGreen.darker()
                cell.button.setTitleColor(UIColor.white, for: .normal)
                cell.button.layer.borderWidth = 1.0
                cell.button.layer.cornerRadius = 6.0
                cell.button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
                cell.button.isEnabled = true
                cell.handleClick={
                    print("Invited")
                    guard MFMessageComposeViewController.canSendText() else {
                        return
                    }
                    
                    let messageVC = MFMessageComposeViewController()
                    
                    messageVC.body = "Take off that doubtfit \(person.displayName)! Do you know about Tangerine yet? \(myProfile.display_name) is inviting you to be a member. Only available for iOS. http://www.letstangerine.com to learn more. 'Confident Comfort through Connection.'";
                    messageVC.recipients = ["\(person.phoneNumberField)"]
                    messageVC.messageComposeDelegate = self;
                    
                    self.present(messageVC, animated: false, completion: nil)
                } // end handle click
            }
            return cell
        }
        
        return UITableViewCell()
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("row selected at \(indexPath.row)")
        var username = ""
        var userstatus = Status.NONE
        // only allow contact those are registered
        var shouldShow = false
        if isCloudSearch {
            // cloud searched person's are always registered
            shouldShow = true
            if let name = displayedCloudContacts[displayedCloudKeys[indexPath.row]]?.username{
                username = name
            }
            
        }else{
            let person = displayedContacts[displayedKeys[indexPath.row]]
            // if registered or requested
            if let person = person, person.status == Status.REQUESTED || person.status == Status.REGISTERED {
                shouldShow = true
                username = person.username
                userstatus = person.status
            }
        } // else
        
        //
        if shouldShow {
            let vc = FriendDetailsVC()
            vc.modalPresentationStyle = .fullScreen
            vc.username = username
            vc.parentVC = PARENTVC.ADD
            vc.status = userstatus
            self.present(vc, animated: true, completion: nil)
        } // should show
        
    } // end of did select row
    
    
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let isReachingEnd = scrollView.contentOffset.y >= 0
        && scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)
        
        
        if isReachingEnd && !loadingFromFirestore{
            
            // but for normal way, fetch it
            loadingFromFirestore = true
            
            // when we are searching fetch it in different way
            
            if isCloudSearch {
                // fetch firestore
                if searchedText != nil && !searchedText.isEmpty{
                    searchDataOnFirestore(searchedText)
                }
                
            }else {
                // fetch the data
                fetchDataFromFirestore()
            }
            
            
        }
        
    }
    
    
    // MARK: VC Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // proUI
        
        configureBackButton()
        configureSearchBar()
        configureCancelButton()
        configureSegmentControl()
        configureAFTableView()
        
        
        setupIndicator()
        searchbar.delegate = self
        
        // fetch the firebase version and sync with personList
        syncPersonList()
        
        view.attachDismissToRightSwipe()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        
        // if we are searching on cloud
        // reload the list
        if isCloudSearch{
            print("Refreshing from cloud")
            self.displayedCloudContacts.removeAll()
            self.displayedCloudKeys.removeAll()
            searchDataOnFirestore(searchedText.lowercased())
        }
    }
    
    
    // MARK: PROGRAMMATIC UI
    func configureBackButton(){
        backBtn = UIButton()
        backBtn.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)
        
        backButtonWidth = NSLayoutConstraint()
        backButtonWidth = backBtn.widthAnchor.constraint(equalToConstant: 30)
        backButtonWidth.isActive = true
        
        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 10),
            backBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,constant: 8),
            backBtn.heightAnchor.constraint(equalToConstant: 30),
        ])
        
        backBtn.addTarget(self, action: #selector(onBackClicked), for: .touchUpInside)
    }
    
    func configureSearchBar(){
        searchbar = UISearchBar()
        searchbar.placeholder = "Search for a Friend to Add"
        
        searchbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchbar)
        
        NSLayoutConstraint.activate([
            searchbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchbar.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            searchbar.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor),
            
        ])
    }
    
    func configureCancelButton(){
        cancelBtn = UIButton()
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        cancelBtn.backgroundColor = .systemBackground
        cancelBtn.setTitleColor(UIColor.link, for: .normal)
        
        cancelBtn.addTarget(self, action: #selector(onCancelTapped), for: .touchUpInside)
        
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelBtn)
        
        buttonWidth = NSLayoutConstraint()
        buttonWidth = cancelBtn.widthAnchor.constraint(equalToConstant: 0)
        buttonWidth.isActive = true
        
        
        NSLayoutConstraint.activate([
            cancelBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 10),
            cancelBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,constant: -16),
            cancelBtn.leadingAnchor.constraint(equalTo: searchbar.trailingAnchor),
            cancelBtn.centerYAnchor.constraint(equalTo: searchbar.centerYAnchor)
        ])
        
    }
    
    func configureSegmentControl(){
        searchSegment = UISegmentedControl(items: ["My Contacts", "All Users"])
        searchSegment.selectedSegmentIndex = 0
        
        searchSegment.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchSegment)
        
        NSLayoutConstraint.activate([
            searchSegment.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,constant: 50),
            searchSegment.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            searchSegment.topAnchor.constraint(equalTo: searchbar.bottomAnchor, constant: 0)
        ])
        
        searchSegment.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)
        
    }
    
    func configureAFTableView(){
        friendTableView = UITableView()
        
        friendTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(friendTableView)
        
        NSLayoutConstraint.activate([
            friendTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            friendTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            friendTableView.topAnchor.constraint(equalTo: searchSegment.bottomAnchor,constant: 20),
            friendTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}
