//
//  WelcomeVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-28.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import RealmSwift

class WelcomeVC: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    // MARK: UI Items
    
    var topLabel: UILabel!
    var jumpBtn: UIButton!
    var descLabel: UITextView!
    
    var settingsImage: UIImageView!
    
    var updateDisplayNameLabel: UILabel! // to update it
    // the one that show's currently displays as
    var displayUsernameL: UILabel!
    
    var updateTDLabel: UILabel! // to update
    
    var targetDemoDescLabel: UILabel! // to show the message
    
    var addFriendsLabel: UILabel! // to add friend
    
    var displayFriendsCountL: UILabel! // the one that shows friends count
    
    // the image view that shows PP
    var profileImageView: UIImageView!
    var profileImageDescLabel: UILabel! // to show below PP frame
    
    var displayNameIndicator: UIActivityIndicatorView!
    var profileImageIndicator: UIActivityIndicatorView!

    // this is where we'll save the profile image or any other image
    var profileRef: StorageReference!
    
    // we'll use this variable to show friends count if this vc is used multiple times in future
    static var friendsCount = 0
    
    
    
    // MARK: Actions
    
    @objc func onJumpClicked() {
        print("Jump")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let vc = storyboard.instantiateViewController(withIdentifier: "main_vc") as! MainVC
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: false, completion: nil)
    }
    
    @objc func updateDisplayNameClicked() {
        print("Display name")
        
        let dname = UserDefaults.standard.string(forKey: Constants.UD_USER_DISPLAY_NAME) ?? ""
        
        // fetch the username from Auth
        if let user = Auth.auth().currentUser, let username = user.displayName{
            
            let alert = UIAlertController(title: "Update Display Name", message: nil, preferredStyle: .alert)

            // Add the text field. You can configure it however you need.
            
            alert.addTextField { (textField) in
                textField.text = dname.isEmpty ? username : dname
            }

            // Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak alert] (_) in
                // Force unwrapping because we know it exists.
                // we added this textfield in the above line
                // show the update indicator, as it takes few seconds to update
                self.displayNameIndicator.isHidden = false
                
                
                let textField = alert?.textFields![0]
                if let text = textField?.text{
                    // update the display name here
                    
                        
                        Firestore.firestore().collection(Constants.USERS_COLLECTION).document(username).setData([Constants.USER_DNAME_KEY: text], merge: true) { (error) in
                            if let err = error{
                                self.presentDismissAlertOnMainThread(title: "Server Error", message: err.localizedDescription)
                                return
                            }
                            UserDefaults.standard.setValue(text, forKey: Constants.UD_USER_DISPLAY_NAME)
                            self.displayNameIndicator.isHidden = true
                            
                            self.displayUsernameL.text = "Currently appearing as \(text)"
        
                            // save to local
                            
                            let profileToUpdate = RealmManager.sharedInstance.getProfile()
                            
                            do {
                                let database = try Realm()
                                database.beginWrite()
                                profileToUpdate.display_name = text
                                database.add(profileToUpdate, update: .modified)
                                
                                try database.commitWrite()
                                
                                
                            } catch {
                                print("Error occured while updating realm")
                            }
                            
                        } // end of firestore call
                        
                        
                    
                    
              
                }
            }))
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))

            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
            
        }
        
        
      
        
    }
    
    @objc func updateTargetDemoClicked() {
        print("Update Target Demo")
        let vc = TargetDemoVC()
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func addFriendClicked() {
        print("Add Friend")
        let vc = AddFriendVC()
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func profilePictureClicked() {
        
        // let user choose which way he would like to go
        // camera or photo
        // declare the alert
        let alert = UIAlertController(title: "Select your picture from", message: nil, preferredStyle: .actionSheet)
            
        // add two actions
            alert.addAction(UIAlertAction(title: "Camera", style: .default , handler:{ (UIAlertAction)in
                print("User click Camera button")
                self.selectImageFrom(.camera)
            }))
            
            alert.addAction(UIAlertAction(title: "Photo Library", style: .default , handler:{ (UIAlertAction)in
                print("User click Photo button")
                self.selectImageFrom(.photoLibrary)
            }))
            
        // add the dismiss button
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction)in
                print("User click Dismiss button")
            }))
        
        // for iPad
        
            alert.popoverPresentationController?.sourceView = self.view


        // present it to user
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
    }
    
     
    func selectImageFrom(_ sourceType: UIImagePickerController.SourceType){
        // set the camera
        let cameraVc = UIImagePickerController()
        // the source
        cameraVc.sourceType = sourceType
        // to let us know when picking is done
        cameraVc.delegate = self
        // so we can edit ie: crop
        
        cameraVc.allowsEditing = true
        self.present(cameraVc, animated: true, completion: nil)
        
    }
    
    
    func setupUI(){
        
        jumpBtn.enable()
        
        // set the name and pic ref
        
        setNameAndRef()
        displayFriendsCountL.text = "You currently have \(WelcomeVC.friendsCount) friends"
        
    }
    
    func setNameAndRef(){
        let storageRef = Storage.storage().reference();
        // fetch the username from Auth
        
        
        if let user = Auth.auth().currentUser, let name = user.displayName{
            // if nil then it isn't updated on firestore, so displayname it is
            
            displayUsernameL.text = "Currently appearing as \(name)"
            
            
            profileRef = storageRef.child(Constants.PROFILES_FOLDER).child(name).child(getFilenameFrom(qName: name, type: .ASK))
            
            
                // get the download url
                profileRef.downloadURL { (url, error) in
                    // check for null
                    guard let imageURL = url, error == nil else{
                            //handle error here if returned url is bad or there is error
                            return
                          }
                    
                    
                    // Run on Background Thread
                    var data = Data()
                    DispatchQueue.background {
                        guard let imageData = NSData(contentsOf: imageURL) else {
                          //same thing here, handle failed data download
                          return
                        }
                        data = imageData as Data
                    } completion: {
                       
                            self.profileImageView.image = UIImage(data: data)
                    }

            }
            
        }else{
            presentDismissAlertOnMainThread(title: "Auth Error", message: "You aren't signed in!")
        }
    }// end of setName and Ref
    
    
    // fetch user object
    
    func fetchUserData(){
        if let user = Auth.auth().currentUser, let name = user.displayName{
            // get the documents from firestore
            
            Firestore.firestore().collection(Constants.USERS_COLLECTION).whereField(FieldPath.documentID(), isEqualTo: name).getDocuments {
                (snap, error) in
                // handle the error
                if let error = error{
                    
                    print("An error occured")
                    self.presentDismissAlertOnMainThread(title: "Error", message: error.localizedDescription)
                    return
                }
                // check the document of this user
                if let doc = snap?.documents.first?.data(){
                    let isSpecialtyPresent = doc[Constants.USER_ORIENTATION_KEY] as? String ?? ""
                    // if it is present, then user done signup
                    
                    if isSpecialtyPresent.count > 0{
                        // user validated
                        
                        // save to realm profile
                        
                        // get the values of this user and provide default if there is chance of being nil
                        let birthday = doc[Constants.USER_BIRTHDAY_KEY] as? Double ?? 0
                        let created = doc[Constants.USER_CREATED_KEY] as! Timestamp
                        let display_name = doc[Constants.USER_DNAME_KEY] as? String ?? name
                        
                        let phone_number = doc[Constants.USER_NUMBER_KEY] as? String ?? "0"
                        let rating = doc[Constants.USER_RATING_KEY] as? Double ?? 0
                        let review = doc[Constants.USER_REVIEW_KEY] as? Int ?? 0
                        
                        let profile_pic = doc[Constants.USER_IMAGE_KEY] as? String ?? DEFAULT_USER_IMAGE_URL
                        let specialty = doc[Constants.USER_ORIENTATION_KEY] as? String ?? "Other"
                        
                        // create the profile
                        
                        let profile = Profile()
                        profile.birthday = birthday
                        profile.created = created.seconds
                        profile.display_name = display_name
                        profile.phone_number = phone_number
                        profile.rating = rating
                        profile.reviews = review
                        profile.username = name
                        profile.profile_pic = profile_pic
                        profile.orientation = specialty
                        
                        
                        
                        // Save to realm database
                        RealmManager.sharedInstance.addOrUpdateProfile(profile)
                        
                        
                        print("User updated with username \(name)")
                        

                    }
                    
                } // end of if
                
            } // end of firebase call
            
        }// end of Auth user check
    }
    
    
    // MARK: Delegates
    
    // this delegate is called when image selecting is done
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // dismiss the picker
        picker.dismiss(animated: true, completion: nil)
        
        // a guard to ensure that we got the picture
        guard let image = info[.editedImage] as? UIImage else{
            presentDismissAlertOnMainThread(title: "Camera Error", message: "Image picking failed. Try again!")
            return
        }
        
        profileImageView.image = image
        // save it to our user's profile
        // data from jpeg
        let imageData = image.jpegData(compressionQuality: 80)
        
        // put guard for optional
        guard let data = imageData else {
            presentDismissAlertOnMainThread(title: "Image Error", message: "Corrupted Image")
            return
        }
        
        // upload the file to profileRef
        let uploadTask = profileRef.putData(data, metadata: nil){ (metadata,error) in
            // check the meta for error check
            guard metadata != nil else{
                //error
                self.presentDismissAlertOnMainThread(title: "Upload Error", message: "An error occured. Try again!")
                return
            }
            
            // access download url for later use
            self.profileRef.downloadURL { (url, error) in
                guard let downloadUrl = url else{
                    self.presentDismissAlertOnMainThread(title: "Upload Error", message: "Couldn't upload. Try again!")
                    return
                }
                
                // access the download url here
                // write it to firebase firestore
                
                if let user = Auth.auth().currentUser, let username = user.displayName{
                    
                    Firestore.firestore().collection(Constants.USERS_COLLECTION).document(username).setData([Constants.USER_IMAGE_KEY: downloadUrl.absoluteString], merge: true) { (error) in
                        if let err = error{
                            self.presentDismissAlertOnMainThread(title: "Server Error", message: err.localizedDescription)
                            return
                        }
                        
                        
                        // save to local
                        
                        let profileToUpdate = RealmManager.sharedInstance.getProfile()
                        
                        do {
                            let database = try Realm()
                            database.beginWrite()
                            profileToUpdate.profile_pic = downloadUrl.absoluteString
                            database.add(profileToUpdate, update: .modified)
                            
                            try database.commitWrite()
                            
                            
                        } catch {
                            print("Error occured while updating realm")
                        }
                        
                        
                    }// end of firestore call
                    
                    
                }// end of user
                
                
            }
            
            
            
            
        } // end of upload task
        
        // start the upload
        uploadTask.resume()
        
        
        // Add a progress observer to an upload task
        // observe the progress here
        let _ = uploadTask.observe(.progress) { snapshot in
          // A progress event occured
            let _ = 100.0 * Double(snapshot.progress!.completedUnitCount)
                / Double(snapshot.progress!.totalUnitCount)
            self.profileImageIndicator.isHidden = false
            
        } // end of progress observer
        
        
        uploadTask.observe(.success) { (snapshot) in
            // success ? hide the progress
            self.profileImageIndicator.isHidden = true
        }
        
        // observe the failure here
        uploadTask.observe(.failure) { snapshot in
            // failed? hide the progress
            self.profileImageIndicator.isHidden = true
            
            if let error = snapshot.error as NSError? {
            switch (StorageErrorCode(rawValue: error.code)!) {
            case .objectNotFound:
                self.presentDismissAlertOnMainThread(title: "Upload Error", message: "Object not found. Try again!")
              break
            case .unauthorized:
                self.presentDismissAlertOnMainThread(title: "Upload Error", message: "You aren't authorised. Try again!")
              break
            case .cancelled:
              // User canceled the upload
                print("User cancelled the upload")
              break

            /* ... */

            case .unknown:
              // Unknown error occurred, inspect the server response
                self.presentDismissAlertOnMainThread(title: "Upload Error", message: "Unknown error occured. Try again!")
              break
            default:
              // A separate error occurred. This is a good place to retry the upload.
                self.presentDismissAlertOnMainThread(title: "Upload Error", message: "Couldn't upload. Try again!")
              break
            } // end of switch
          } // end of if let error = snapshot
    } // end of failure observe
}
    
    
    
    // MARK: VC Methods
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        
        // proUI
        configureTopLabel()
        configureJumpButton()
        configureDescLabel()
        
        configureSettingsImage()
        
        configureUpdateDisplayNameLabel()
        configureDisplayName()
        
        configureUpdateTDLabel()
        configureTDMessage()
        
        configureAddFriendsLabel()
        configureFriendsCount()
        
        configurePP()
        configurePPLabel()
        
        configureIndicatorView()
        
        
        fetchUserData()
        // Do any additional setup after loading the view.
        setupUI()
        // Remove all the view controllers we have till now
        guard let navigationController = self.navigationController else { return }
        var navigationArray = navigationController.viewControllers // To get all UIViewController stack as Array
        
        let temp = navigationArray.last
        navigationArray.removeAll()
        navigationArray.append(temp!) //To remove all previous UIViewController except the last one
        self.navigationController?.viewControllers = navigationArray
        // when this view runs for the first time, we need to have these data saved
        
    }
    

    // MARK: PROGRAMMATIC UI
    
    func configureTopLabel(){
        topLabel = UILabel()
        topLabel.text = "Welcome to the Tangerine Community!"
        topLabel.textColor = .label
        topLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        topLabel.numberOfLines = 2
        
        topLabel.textAlignment = .center
        
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topLabel)
        
        NSLayoutConstraint.activate([
            topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            topLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            topLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            topLabel.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func configureJumpButton(){
        jumpBtn = ContinueButton(title: "Start Tangerining")
        
        jumpBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(jumpBtn)
        
        NSLayoutConstraint.activate([
            jumpBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            jumpBtn.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 20),
            jumpBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        jumpBtn.addTarget(self, action: #selector(onJumpClicked), for: .touchUpInside)
        
        
    }
    
    func configureDescLabel(){
        descLabel = UITextView()
        descLabel.text = "Feel free to use the links below to customize your experience. You can always adjust these later in settings"
        descLabel.textColor = .label
        descLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        descLabel.textAlignment = .center
        
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descLabel)
        
        NSLayoutConstraint.activate([
            descLabel.topAnchor.constraint(equalTo: jumpBtn.bottomAnchor, constant: 20),
            descLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            descLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            descLabel.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    
    func configureSettingsImage(){
        settingsImage = UIImageView()
        settingsImage.image = UIImage(systemName: "gearshape")
        settingsImage.tintColor = .label
        
        settingsImage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingsImage)
        
        NSLayoutConstraint.activate([
            settingsImage.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 0),
            settingsImage.heightAnchor.constraint(equalToConstant: 20),
            settingsImage.widthAnchor.constraint(equalToConstant: 20),
            settingsImage.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0)
        ])
    }
    
    
    func configureUpdateDisplayNameLabel(){
        updateDisplayNameLabel = UILabel()
        updateDisplayNameLabel.text = "Update Display Name"
        
        updateDisplayNameLabel.textColor = .link
        updateDisplayNameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        updateDisplayNameLabel.textAlignment = .center
        
        updateDisplayNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(updateDisplayNameLabel)
        
        updateDisplayNameLabel.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(updateDisplayNameClicked))
        updateDisplayNameLabel.addGestureRecognizer(gesture)
        
        NSLayoutConstraint.activate([
            updateDisplayNameLabel.topAnchor.constraint(equalTo: settingsImage.bottomAnchor, constant: 30),
            updateDisplayNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
        ])
        
    }
    
    func configureDisplayName(){
        displayUsernameL = UILabel()
        
        displayUsernameL.textColor = .label
        displayUsernameL.font = UIFont.systemFont(ofSize: 17)
        displayUsernameL.textAlignment = .center
        
        displayUsernameL.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(displayUsernameL)
        
        
        
        NSLayoutConstraint.activate([
            displayUsernameL.topAnchor.constraint(equalTo: updateDisplayNameLabel.bottomAnchor, constant: 0),
            displayUsernameL.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0)
        ])
    }
    
    
    func configureUpdateTDLabel(){
        updateTDLabel = UILabel()
        updateTDLabel.text = "Update Target Demo"
        
        updateTDLabel.textColor = .link
        updateTDLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        updateTDLabel.textAlignment = .center
        
        updateTDLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(updateTDLabel)
        
        updateTDLabel.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(updateTargetDemoClicked))
        updateTDLabel.addGestureRecognizer(gesture)
        
        NSLayoutConstraint.activate([
            updateTDLabel.topAnchor.constraint(equalTo: displayUsernameL.bottomAnchor, constant: 25),
            updateTDLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0)
        ])
    }
    
    func configureTDMessage(){
        targetDemoDescLabel = UILabel()
        targetDemoDescLabel.text = "Customize the age range and orientation of users you’d like feedback from."
        targetDemoDescLabel.textColor = .label
        targetDemoDescLabel.font = UIFont.systemFont(ofSize: 17)
        targetDemoDescLabel.numberOfLines = 3
        targetDemoDescLabel.textAlignment = .center
        
        targetDemoDescLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(targetDemoDescLabel)
        
        
        
        NSLayoutConstraint.activate([
            targetDemoDescLabel.topAnchor.constraint(equalTo: updateTDLabel.bottomAnchor, constant: 0),
            targetDemoDescLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            targetDemoDescLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            targetDemoDescLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
    }
    
    
    func configureAddFriendsLabel(){
        addFriendsLabel = UILabel()
        addFriendsLabel.text = "Add Friends"
        
        addFriendsLabel.textColor = .link
        addFriendsLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        addFriendsLabel.textAlignment = .center
        
        addFriendsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addFriendsLabel)
        
        addFriendsLabel.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(addFriendClicked))
        addFriendsLabel.addGestureRecognizer(gesture)
        
        NSLayoutConstraint.activate([
            addFriendsLabel.topAnchor.constraint(equalTo: targetDemoDescLabel.bottomAnchor, constant: 25),
            addFriendsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0)
        ])
    }
    
    func configureFriendsCount(){
        displayFriendsCountL = UILabel()
        displayFriendsCountL.textColor = .label
        displayFriendsCountL.font = UIFont.systemFont(ofSize: 17)
        displayFriendsCountL.textAlignment = .center
        
        displayFriendsCountL.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(displayFriendsCountL)
        
        
        
        NSLayoutConstraint.activate([
            displayFriendsCountL.topAnchor.constraint(equalTo: addFriendsLabel.bottomAnchor, constant: 0),
            displayFriendsCountL.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0)
        ])
    }
    
    
    func configurePP(){
        profileImageView = UIImageView()
        profileImageView.image = UIImage(systemName: "person.badge.plus")
        profileImageView.tintColor = .link
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileImageView)
        
        profileImageView.isUserInteractionEnabled = true
        
        NSLayoutConstraint.activate([
            profileImageView.heightAnchor.constraint(equalToConstant: 50),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(profilePictureClicked))
        profileImageView.addGestureRecognizer(gesture)
        
    }
    
    func configurePPLabel(){
        profileImageDescLabel = UILabel()
        profileImageDescLabel.text = "Profile Picture"
        
        profileImageDescLabel.textColor = .label
        profileImageDescLabel.font = UIFont.systemFont(ofSize: 17)
        
        profileImageDescLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileImageDescLabel)
        
        profileImageDescLabel.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(profilePictureClicked))
        profileImageDescLabel.addGestureRecognizer(gesture)
        
        NSLayoutConstraint.activate([
            profileImageDescLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 5),
            profileImageDescLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            profileImageDescLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    func configureIndicatorView(){
        displayNameIndicator = UIActivityIndicatorView()
        profileImageIndicator = UIActivityIndicatorView()
        
        displayNameIndicator.startAnimating()
        profileImageIndicator.startAnimating()
        
        displayNameIndicator.isHidden = true
        profileImageIndicator.isHidden = true
        
        displayNameIndicator.translatesAutoresizingMaskIntoConstraints = false
        profileImageIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(displayNameIndicator)
        view.addSubview(profileImageIndicator)
        
        
        NSLayoutConstraint.activate([
            displayNameIndicator.leadingAnchor.constraint(equalTo: updateDisplayNameLabel.trailingAnchor, constant: 10),
            displayNameIndicator.centerYAnchor.constraint(equalTo: updateDisplayNameLabel.centerYAnchor),
            
            profileImageIndicator.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 10),
            profileImageIndicator.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            
        ])
    }
    
}
