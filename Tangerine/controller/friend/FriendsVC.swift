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
    
    
    // MARK: UI Items
    
    var backBtn: UIButton!
    var friendReqBtn: UIButton!
    var addFriendBtn: UIButton!
    
    var friendReqWidth: NSLayoutConstraint!
    
    private var pullControl = UIRefreshControl()
    
    
    var searchbar: UISearchBar!
    var friendList: UITableView!
    
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
    var searchLimit = 10
    
    /// badge
    var hub : BadgeHub!
    
    
    
    // MARK: Actions
    @objc func backBtnPressed() {
        //update locally stored list of friend userName Strings in case localUser is now friends with different people
        fetchMyFriendNamesFromFirestore()
        // return to MainVC
        dismiss(animated: true, completion: nil)
    }
    
    
    @objc func addFriendPressed() {
        let vc = AddFriendVC()
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func friendReqPressed() {
        
        let vc = FriendRequestVC()
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    // Actions
    @objc private func refreshListData(_ sender: Any) {
        self.pullControl.beginRefreshing()
        // refresh list
        print("Refreshing list")
        // remove the items when view load from any other place
        syncFriendList()
    }
    
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
            
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(myProfile.username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(self.displayedFriends[indexPath.section].username)
                .delete { (error) in
                    if let error = error{
                        self.presentDismissAlertOnMainThread(title: "Error", message: error.localizedDescription)
                        return
                    }
                    
                    // From THIS PERSON'S FIREBASE
                    
                    Firestore.firestore().collection(Constants.USERS_COLLECTION).document(self.displayedFriends[indexPath.section].username).collection(Constants.USERS_LIST_SUB_COLLECTION).document(myProfile.username)
                        .delete { (error) in
                            if let error = error{
                                self.presentDismissAlertOnMainThread(title: "Error", message: error.localizedDescription)
                                return
                            }
                            
                            self.presentDismissAlertOnMainThread(title: "Friendship Removed", message: "💔 You are no longer friends with \(self.displayedFriends[indexPath.section].username!)")
                            
                            // delete the row
                            self.displayedFriends.remove(at: indexPath.section)
                            tableView.deleteRows(at: [indexPath], with: .automatic)
                        }
                }
            
            
        }
        // to manage dark and normal color
        blockAction.backgroundColor = .brown
        
        return UISwipeActionsConfiguration(actions: [blockAction])
        
    }
    
    
    // MARK: Delegates
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        return  UILocalizedIndexedCollation.current().sectionTitles
    }
    
    //handles the side click
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        print("You clicked on index \(title) with index \(index)")
        // find the first type that starts with the letter title:(A-Z)
        for item in displayedFriends{
            if item.displayName.uppercased().starts(with: title.uppercased()) {
                guard let sectionPosition = displayedFriends.firstIndex(of: item) else {continue}
                return sectionPosition
            }
        }
        
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1//displayedFriends.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return displayedFriends.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("loading cell with section \(indexPath.section)")
        let cell = Bundle.main.loadNibNamed("QFriendCell", owner: self, options: nil)?.first as! QFriendCell // we already know it is on our project list
        var friend : Friend!
        
        if displayedFriends.count > 0{
            friend = displayedFriends[indexPath.section]
            
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
    
    
    // for using side indexes with this version we switched rows with section
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print("section selected at \(indexPath.section)")
        
        var username = ""
        // only allow contact those are registered
        
        let person = displayedFriends[indexPath.section]
        username = person.username
        
        let vc = FriendDetailsVC()
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
    
    
    
    // MARK: VC Methods
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        // proUI
        
        configureBackButton()
        
        configureFriendReqButton()
        configureAddFriendButton()
        
        
        configureSearchBar()
        configureFriendsTableView()
        
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
        
        // enables swipe navigation
        
        view.attachDismissToRightSwipe()
  
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Did appear")
        
        
        // fetch the friend list
        syncFriendList()
        
        self.friendReqWidth.constant = 0
        
        print("Chunked name = \(chunkedNames.count)")
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
        
        backBtn.addTarget(self, action: #selector(backBtnPressed), for: .touchUpInside)
    }
    
    
    
    func configureFriendReqButton(){
        friendReqBtn = UIButton()
        friendReqBtn.setImage(UIImage(systemName: "person.2"), for: .normal)
        
        friendReqBtn.addTarget(self, action: #selector(friendReqPressed), for: .touchUpInside)
        
        friendReqBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(friendReqBtn)
        
        friendReqWidth = NSLayoutConstraint()
        friendReqWidth = friendReqBtn.widthAnchor.constraint(equalToConstant: 0)
        friendReqWidth.isActive = true
        
        
        NSLayoutConstraint.activate([
            friendReqBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 10),
            friendReqBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,constant: -10),
            friendReqBtn.heightAnchor.constraint(equalToConstant: 40),
        ])
        
    }
    
    func configureAddFriendButton(){
        addFriendBtn = UIButton()
        addFriendBtn.setImage(UIImage(systemName: "person.badge.plus"), for: .normal)
        
        addFriendBtn.addTarget(self, action: #selector(addFriendPressed), for: .touchUpInside)
        
        addFriendBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addFriendBtn)
        
        
        
        NSLayoutConstraint.activate([
            addFriendBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 10),
            addFriendBtn.trailingAnchor.constraint(equalTo: friendReqBtn.leadingAnchor,constant: -20),
            addFriendBtn.heightAnchor.constraint(equalToConstant: 40),
        ])
    }
    
    func configureSearchBar(){
        searchbar = UISearchBar()
        
        searchbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchbar)
        
        NSLayoutConstraint.activate([
            searchbar.topAnchor.constraint(equalTo: backBtn.bottomAnchor, constant: 10),
            searchbar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            searchbar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
            
        ])
    }
    
    func configureFriendsTableView(){
        friendList = UITableView()
        
        friendList.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(friendList)
        
        NSLayoutConstraint.activate([
            friendList.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            friendList.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            friendList.topAnchor.constraint(equalTo: searchbar.bottomAnchor,constant: 20),
            friendList.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
}
