//
//  FriendsVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-22.
//

import UIKit
import FirebaseFirestore
import BadgeHub


class FriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    
    @IBOutlet weak var friendReqWidth: NSLayoutConstraint!
    
    
    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - Delegates
     - View Controller methods
     */
    /******************************************************************************************************************************/
    
    private var pullControl = UIRefreshControl()
    
    
    @IBOutlet weak var searchbar: UISearchBar!
    @IBOutlet weak var friendList: UITableView!
    
    @IBOutlet weak var friendReqBtn: UIButton!
    /// a list of string for our friend names
    public var friendNames = [String]()
    /// a chunked version of above list
    var chunkedNames = [[String]]()
    /// a counter for chunk iteration
    var currentChunk = -1
    /// actual friend list fetched
    var allFriends = [Friend]()
    /// actual list showing
    var displayedFriends = [Friend]()
    ///flag that tells if we are fetching data
    var loadingFromFirestore = false
    /// the loading
    var indicator: UIActivityIndicatorView!
    // limit of search from firestore, can't be more than 10
    var searchLimit = 5
    
    /// badge
    var hub : BadgeHub!
    
    /******************************************************************************************************************************/
    
    @IBAction func backBtnPressed(_ sender: UIButton) {
        //update locally stored list of friend userName Strings in case localUser is now friends with different people
        fetchMyFriendNamesFromFirestore()
        // return to MainVC
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addFriendPressed(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "addfriend_vc") as! AddFriendVC
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func friendReqPressed(_ sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "friendrequest_vc") as! FriendRequestVC
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    /******************************************************************************************************************************/
    
    
    // Actions
    @objc private func refreshListData(_ sender: Any) {
        self.pullControl.beginRefreshing()
        // refresh list
        print("Refreshing list")
        // remove the items when view load from any other place
        syncFriendList()
        
        
    }
    
    
    /******************************************************************************************************************************/
    
    
    // indicator while loading
    
    func setupIndicator() {
        indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        indicator.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.maxY - 20)
        view.addSubview(indicator)
        indicator.bringSubviewToFront(view)
    }
    
    func syncFriendList(){
        
        hub.setCount(0)
        // reset the data first
        friendNames.removeAll()
        chunkedNames.removeAll()
        allFriends.removeAll()
        displayedFriends.removeAll()
        currentChunk = -1
        
        // remove the items when view load from any other place
        friendList.reloadData()
        
        // for invited to work, change the array on "in" field
        // We are requesting for
        // FRIEND => so we can show the friends now
        // PENDING => he already sent a request to me, no point of showing him here, but we can update the badge above
        
        print("Syncing Friendlist")
        // reset the db
        Firestore.firestore()
            .collection(Constants.USERS_COLLECTION)
            .document(myProfile.username)
            .collection(Constants.USERS_LIST_SUB_COLLECTION)
            .whereField(Constants.USER_STATUS_KEY, in: [Status.FRIEND.description,Status.PENDING.description])
            .getDocuments { (querySnaps, error) in
                // no need to show alert here
                
                self.pullControl.endRefreshing()
                if error != nil {
                    print("Sync error \(String(describing: error?.localizedDescription))")
                    return
                }
                
                // fetch the personsList
                if let docs = querySnaps?.documents{
                    if docs.count > 0 {
                        
                        for item in docs{
                            // save the friend names
                            let status = getStatusFromString(item.data()[Constants.USER_STATUS_KEY] as! String)
                            if status == .FRIEND{
                                self.friendNames.append(item.documentID)
                            }else if status == .PENDING{
                                self.friendReqWidth.constant = 40
                                self.hub.increment()
                                
                            }
                            
                        }
                        print("Sync done")
                        
                        if self.friendNames.count > 0 {
                            // chunk the results
                            self.chunkedNames = self.friendNames.chunked(by: self.searchLimit)
                            // now fetch 10 by 10
                            self.fetch10Friends()
                            
                        }
                        
                    }
                }// end if let
                
            }// end of firebase
    } // end of sync
    
    
    
    
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
                            self.allFriends.append(friend)
                            self.displayedFriends.append(friend)
                            
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
    
    
    
    
    /******************************************************************************************************************************/
    
    //    func numberOfSections(in tableView: UITableView) -> Int {
    //        return UILocalizedIndexedCollation.current().sectionTitles.count
    //    }
    
    //    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    //        return UILocalizedIndexedCollation.current().sectionTitles[section]
    //    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let blockAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, _ ) in
            print("Friend Delete tapped")
            
            // From MY FIREBASE
            
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(myProfile.username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(self.displayedFriends[indexPath.row].username)
                .delete { (error) in
                    if let error = error{
                        self.presentDismissAlertOnMainThread(title: "Error", message: error.localizedDescription)
                        return
                    }
                    
                    // From THIS PERSON'S FIREBASE
                    
                    Firestore.firestore().collection(Constants.USERS_COLLECTION).document(self.displayedFriends[indexPath.row].username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(myProfile.username)
                        .delete { (error) in
                            if let error = error{
                                self.presentDismissAlertOnMainThread(title: "Error", message: error.localizedDescription)
                                return
                            }
                            
                            self.presentDismissAlertOnMainThread(title: "Success", message: "You are no longer friend with \(self.displayedFriends[indexPath.row].username!)")
                            
                            // delete the row
                            self.displayedFriends.remove(at: indexPath.row)
                            tableView.deleteRows(at: [indexPath], with: .automatic)
                        }
                }
            
            
        }
        // to manage dark and normal color
        blockAction.backgroundColor = .brown
        
        return UISwipeActionsConfiguration(actions: [blockAction])
        
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        return  UILocalizedIndexedCollation.current().sectionTitles
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return UILocalizedIndexedCollation.current().section(forSectionIndexTitle: index)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedFriends.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("loading cell")
        let cell = Bundle.main.loadNibNamed("QFriendCell", owner: self, options: nil)?.first as! QFriendCell // we already know it is on our project list
        var friend : Friend!
        
        if displayedFriends.count > 0{
            friend = displayedFriends[indexPath.row]
            
            // DISPLAY THE CELL DATA
            let today = Date()
            let bday = Date(timeIntervalSince1970: friend.dobMills)
            let dc =  Calendar.current.dateComponents([.year], from: bday, to: today)
            
            cell.display_name.text = friend.displayName
            cell.user_name.text = friend.username
            
            downloadOrLoadFirebaseImage(
                ofName: getFilenameFrom(qName: friend.username, type: .ASK),
                forPath: friend.imageString) { image, error in
                    if let error = error{
                        print("Error: \(error.localizedDescription)")
                        return
                    }
                    
                    print("FVC Image Downloaded for \(String(describing: friend.username))")
//                    cell.profileImage.image = image!
                    // added soft unwrapping for robustness
                    if let imageToDisplay = image {
                        cell.profileImage.image = imageToDisplay
                    } else {
                        cell.profileImage.image = self.convertBase64StringToImage(imageBase64String: friend.imageString)
                    }
                }
            
            
            // get the age from date component dc
            if let age = dc.year{
                if friend.dobMills == 0{
                    // do nothing maybe?
                    cell.age.text = ""
                }else{
                    cell.age.text = "\(age)"
                }
                
            }
            
            cell.rating.text = "(\(friend.rating))"
            
        }
        
        cell.isCQCell = false
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("row selected at \(indexPath.row)")
        
        var username = ""
        // only allow contact those are registered
        
        let person = displayedFriends[indexPath.row]
        username = person.username
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "frienddetails_vc") as! FriendDetailsVC
        vc.modalPresentationStyle = .fullScreen
        vc.username = username
        vc.parentVC = PARENTVC.FRIENDS
        self.present(vc, animated: true, completion: nil)
        
        
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("Searchbar did change")
        // only fires when user presses the clear button
        if searchbar.text == ""{
            print("clear")
            // set the whole data
            self.displayedFriends = self.allFriends
            self.friendList.reloadData()
        }else{
            // clear current data
            self.displayedFriends.removeAll()
            // filter whole data and put to display
            for friend in allFriends{
                if friend.username.lowercased().contains(searchbar.text?.lowercased() ?? ""){
                    self.displayedFriends.append(friend)
                }
            }// end for
            
            self.friendList.reloadData()
        }
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
        
        // Do any additional setup after loading the view.
        hideKeyboardOnOutsideTouch()
        
        friendList.delegate = self
        friendList.dataSource = self
        
        searchbar.delegate = self
        
        // The Pull to Refresh
        pullControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        pullControl.addTarget(self, action: #selector(refreshListData(_:)), for: .valueChanged)
        friendList.refreshControl = pullControl
        
        
        
        hub = BadgeHub(view: friendReqBtn)
        hub.scaleCircleSize(by: 0.75)
        hub.moveCircleBy(x: 40.0, y: 0)
        // set the indicator
        setupIndicator()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Did appear")
        
        
        // fetch the friend list
        syncFriendList()
        
        self.friendReqWidth.constant = 0
        
        print("Chunked name = \(chunkedNames.count)")
    }
    
}
