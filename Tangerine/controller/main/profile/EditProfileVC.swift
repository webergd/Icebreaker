//
//  EditProfileVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-24.
//

import UIKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import RealmSwift

class EditProfileVC: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: UI Items
    var backBtn: UIButton!
    var titleLabel: UILabel!
    var saveBtn: UIButton!
    
    var scrollView: UIScrollView!
    var contentView: UIView!
    
    
    var profileImageView: UIImageView!
    var uploadIndicatorView: UIActivityIndicatorView!
    
    var displayNameL: UILabel!
    var updateDnameIndicator: UIActivityIndicatorView!
    var updateDisplayNameBtn: UILabel!
    var topHorizontalLine: UIView!
    
    var mytargetDemoText: UILabel!
    var iPreferOpinionLabel: UILabel!
    
    var mytargetDemoL: UILabel!
    
    var agesText: UILabel!
    var mytargetAge: UILabel!
    
    var editTDBtn: UILabel!
    
    var bottomHorizontalLine: UIView!
    
    var myOrientationText: UILabel!
    var specialtyPicker: UIPickerView!
    
    var myUsernameText: UILabel!
    var usernameL: UILabel!
    
    var changePasswordBtn: UILabel!
    
    var phoneNumberText: UILabel!
    var phoneNumberL: UILabel!
    var changePhoneNumberBtn: UILabel!
    
    var deleteAccountBtn: UILabel!

    var passwordIndicator: UIActivityIndicatorView!
    
    
    
    // this is where we'll save the profile image or any other image
    var profileRef: StorageReference!
    
    // user default
    var userDefault : UserDefaults!
    
    
    // options for specialty
    let options = Constants.ORIENTATIONS
    var speText = ""
    
    
    // MARK: Actions
    
    @objc func onBackPressed(_ sender: UIButton) {
        print("Back")
        dismiss(animated: true, completion: nil)
    }
    
    @objc func onDonePressed(_ sender: UIButton) {
        print("Done")
        // save to firestore and local
        saveToFirestore()
        
        
    }
    
    
    @objc func profileImageTapped(_ sender: UITapGestureRecognizer) {
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
    
    
    @objc func displayNameTapped(_ sender: UITapGestureRecognizer) {
        
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
                self.updateDnameIndicator.isHidden = false
                
                let textField = alert?.textFields![0]
                if let text = textField?.text{
                    // update the display name here
                    
                    
                    Firestore.firestore().collection(Constants.USERS_COLLECTION).document(username).setData([Constants.USER_DNAME_KEY: text], merge: true) { [self] (error) in
                        if let err = error{
                            self.updateDnameIndicator.isHidden = true
                            self.presentDismissAlertOnMainThread(title: "Server Error", message: err.localizedDescription)
                            return
                        }
                        UserDefaults.standard.setValue(text, forKey: Constants.UD_USER_DISPLAY_NAME)
                        self.updateDnameIndicator.isHidden = true
                        
                        self.displayNameL.text = "Currently appearing as \(text)"
                        
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
                        
                    }
                    
                    
                    
                    
                    
                }
            }))
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
            
        }
        
        
        
    } // end of display name tapped
    
    
    @objc func editTargetDemoTapped(_ sender: UIButton) {
        let story = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = story.instantiateViewController(identifier: "targetdemo_vc") as! TargetDemoVC
        vc.isEditingProfile = true
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    
    @objc func changePasswordTapped(_ sender: UITapGestureRecognizer) {
        changePassword()
    }
    
    @objc func changePhoneTapped(_ sender: UITapGestureRecognizer) {
        
        let story = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = story.instantiateViewController(identifier: "phonenumber_vc") as! PhoneNumberVC
        
        vc.isEditingProfile = true
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    
    @objc func deleteAccountTapped(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Delete your account?", message: "This action is permanent and can't be undone.", preferredStyle: .alert)
        
        // add two actions
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive , handler:{ (UIAlertAction)in
            self.deleteUser()
        }))
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default , handler:{ (UIAlertAction)in
            
        }))
        
        // present it to user
        self.present(alert, animated: true, completion: nil)
        
        
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
    
    
    
    
    func fetchPastValues(){
        // init a new profile and populate with old data
        speText = myProfile.orientation
        
        // set a placeholder
        let id = options.firstIndex { (text) -> Bool in
            text == myProfile.orientation
        }
        // set the picker to default
        if let id = id{
            specialtyPicker.selectRow(id, inComponent: 0, animated: true)
        }
        
        // set display name and picture
        displayNameL.text = "Currently appearing as \(myProfile.display_name)"
        
        // set the mytarget demo vars
        
        let isStWEnabled = userDefault.bool(forKey: Constants.UD_ST_WOMAN_Bool)
        let isGMEnabled = userDefault.bool(forKey: Constants.UD_GMAN_Bool)
        let isStMEnabled = userDefault.bool(forKey: Constants.UD_ST_MAN_Bool)
        let isLBEnabled = userDefault.bool(forKey: Constants.UD_GWOMAN_Bool)
        let isOtherEnabled = userDefault.bool(forKey: Constants.UD_OTHER_Bool)
        
        // check bool and add text to the label
        mytargetDemoL.text = "\(isStWEnabled ? "Straight Women\n" : "")\(isGMEnabled ? "Gay Men\n" : "")\(isStMEnabled ? "Straight Men\n" : "")\(isLBEnabled ? "Lesbians\n" : "")\(isOtherEnabled ? "Others" : "")"
        
        
        // set the age label
        
        var minAge = userDefault.integer(forKey: Constants.UD_MIN_AGE_INT)
        var maxAge = userDefault.integer(forKey: Constants.UD_MAX_AGE_INT)
        
        if minAge == 0{
            minAge = 18
        }
        
        if maxAge == 0{
            maxAge = 99
        }
        
        mytargetAge.text = "\(minAge) to \(maxAge)"
        
        // set my username
        
        usernameL.text = myProfile.username
        
        // set the phone number label as well
        
        phoneNumberL.text = myProfile.phone_number
        // set the profile ref
        let storageRef = Storage.storage().reference();
        
        profileRef = storageRef.child(Constants.PROFILES_FOLDER).child(myProfile.username).child(getFilenameFrom(qName: myProfile.username, type: .ASK))
        
        
    } // end of fetch value
    
    
    func setupUI(){
        
        // init the pref
        userDefault = UserDefaults.standard
        
        // set specialty delegate and datasource
        specialtyPicker.delegate = self
        specialtyPicker.dataSource = self
        
        
        // put some border on profile picture
        profileImageView.layer.borderWidth = 1.0
        profileImageView.layer.borderColor = UIColor.systemBlue.cgColor
        profileImageView.layer.cornerRadius = 4.0
        
        fetchPastValues()
    }
    
    
    func saveToFirestore(){
        // this username is still valid, although we can take from Auth.auth().user.displayname
        
        let db = Firestore.firestore()
        
        
        // save the specialty now
        db.collection(Constants.USERS_COLLECTION)
            .document(myProfile.username).setData(
                [Constants.USER_ORIENTATION_KEY: self.speText], merge: true) { (error) in
                    if let err = error{
                        self.presentDismissAlertOnMainThread(title: "Server Error", message: err.localizedDescription)
                        
                        return
                    }
                    
                    // all done, dismiss
                    // save to local
                    
                    let profileToUpdate = RealmManager.sharedInstance.getProfile()
                    
                    do {
                        let database = try Realm()
                        database.beginWrite()
                        profileToUpdate.orientation = self.speText
                        database.add(profileToUpdate, update: .modified)
                        
                        try database.commitWrite()
                        
                        
                    } catch {
                        print("Error occured while updating realm")
                    }
                    
                    self.dismiss(animated: true, completion: nil)
                    
                }// end of saving specialty
        
        
        
        
    } // end of saveSpecialtyToFirebase
    
    
    
    // change the user password
    func changePassword(){
        // show a dialog first
        
        // fetch the username from Auth
        if let user = Auth.auth().currentUser{
            
            let alert = UIAlertController(title: "Update Password", message: nil, preferredStyle: .alert)
            
            // Add the text field. You can configure it however you need.
            
            alert.addTextField { (textField) in
                textField.text = ""
            }
            
            // Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak alert] (_) in
                // Force unwrapping because we know it exists.
                // we added this textfield in the above line
                self.passwordIndicator.isHidden = false
                
                let textField = alert?.textFields![0]
                if let text = textField?.text{
                    // update the password here
                    user.updatePassword(to: text) { (error) in
                        if let error = error{
                            self.passwordIndicator.isHidden = true
                            self.presentDismissAlertOnMainThread(title: "Update Failed", message: error.localizedDescription)
                            return
                        }
                        
                        self.passwordIndicator.isHidden = true
                        self.presentDismissAlertOnMainThread(title: "Success!", message: "Password changed successfully!")
                        
                    } // end of update password
                    
                    
                }
            }))
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }// end of change pass
    
    
    
    func deleteUser(){
        view.showActivityIndicator()
        // delete the user doc
        
        Firestore.firestore().collection(Constants.USERS_COLLECTION)
            .document(myProfile.username).delete { (error) in
                if let error = error{
                    self.presentDismissAlertOnMainThread(title: "Server Error", message: error.localizedDescription)
                }
                
                
                // remove db values
                
                resetLocalAndRealmDB()
                
                
                // move to login
                
                self.view.hideActivityIndicator()
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "login_vc") as! LoginVC
                vc.modalPresentationStyle = .fullScreen
                
                self.present(vc, animated: true, completion: nil)
                
                // private docs, connection_list, storage will be deleted from cloud function
                
             
                
            }// end of doc delete
        
        
        
        
        
    }// end of delete user
    
    
    
    
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
        
        // save to local, the new overwrite flag ensures that the method will erase old image and save new image
        // which isn't required for questions, as image in questions aren't changable.
        saveImageToDiskWith(imageName: getFilenameFrom(qName: myProfile.username, type: .ASK), image: image, overwrite: true)
        
        
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
            self.uploadIndicatorView.isHidden = false
            
        } // end of progress observer
        
        
        uploadTask.observe(.success) { (snapshot) in
            // success ? hide the progress
            self.uploadIndicatorView.isHidden = true
        }
        
        // observe the failure here
        uploadTask.observe(.failure) { snapshot in
            // failed? hide the progress
            self.uploadIndicatorView.isHidden = true
            
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
    
    
    
    // number of "wheels" actually, how many values there will be
    // we have only name
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // how many items will there be in one wheel
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
    
    // this sets title for each row of each wheel
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return options[row]
    }
    
    // which row is selected from which component
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("\(row) \(component)")
        speText = options[row]
        
    }
    
    
    
    
    
    
    // MARK: VC Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        
        // proUI
        configureTopBar()
        
        configureScrollView()
        
        configureProfileImageView()
        
        // thing related to DN
        configureDisplayNameThings()
        
        // things related to TD
        configureTargetDemoThings()
        
        // things related to age
        configureAgeThings()
        
        configureEditTDButton()
        
        configureSpecialtyThings()
        
        configureUNThings()
        
        configureChangePassBtn()
        
        configurePhoneNumberThings()
        
        configureDeleteAccountBtn()
        
        
        
        
        
        setupUI()
        
        downloadOrLoadFirebaseImage(
            ofName: getFilenameFrom(qName: myProfile.username, type: .ASK),
            forPath: myProfile.profile_pic) { image, error in
                if let error = error{
                    print("Error: \(error.localizedDescription)")
                    return
                }
                
                print("Profile Image Downloaded for MYSELF")
                self.profileImageView.image = image
            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // if we return from target demo, we'll need to update the values
        fetchPastValues()
    }
    
    
    
    // MARK: PROGRAMMATIC UI
    // back btn, title, saveBtn
    func configureTopBar(){
        backBtn = UIButton()
        backBtn.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        backBtn.setTitleColor(.label, for: .normal)
        
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)
        
        titleLabel = UILabel()
        titleLabel.text = "Edit Profile"
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textColor = .label
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        saveBtn = UIButton()
        saveBtn.setTitle("Save", for: .normal)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        saveBtn.setTitleColor(.link, for: .normal)
        
        saveBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveBtn)
        
        
        NSLayoutConstraint.activate([
            backBtn.widthAnchor.constraint(equalToConstant: 40),
            backBtn.heightAnchor.constraint(equalToConstant: 40),
            backBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            backBtn.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            
            saveBtn.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor),
            saveBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            saveBtn.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
            
        ])
        
        
        backBtn.addTarget(self, action: #selector(onBackPressed), for: .touchUpInside)
        
        saveBtn.addTarget(self, action: #selector(onDonePressed), for: .touchUpInside)
        
        
        
    }
    
   
    func configureScrollView(){
        scrollView = UIScrollView()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        
        
        contentView = UIView()
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 25),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor)
        ])
    }
    
    
    func configureProfileImageView(){
        profileImageView = UIImageView()
        profileImageView.image = UIImage(named: "generic_user")
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        uploadIndicatorView = UIActivityIndicatorView()
        uploadIndicatorView.startAnimating()
        
        uploadIndicatorView.isHidden = true
        
        uploadIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(uploadIndicatorView)
        
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            uploadIndicatorView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            uploadIndicatorView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor,constant: 10)
        ])
        
        profileImageView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(gesture)
    }
    
    
    // thing related to DN
    func configureDisplayNameThings(){
        displayNameL = UILabel()
        displayNameL.text = "appearing as dname"
        displayNameL.textColor = .label
        displayNameL.font = UIFont.systemFont(ofSize: 19, weight: .semibold)
        displayNameL.textAlignment = .center
        
        displayNameL.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(displayNameL)
        
        updateDnameIndicator = UIActivityIndicatorView()
        updateDnameIndicator.startAnimating()
        
        updateDnameIndicator.isHidden = true
        
        updateDnameIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(updateDnameIndicator)
        
        updateDisplayNameBtn = UILabel()
        updateDisplayNameBtn.text = "Update Display Name"
        updateDisplayNameBtn.font = UIFont.systemFont(ofSize: 17)
        
        updateDisplayNameBtn.isUserInteractionEnabled = true
        updateDisplayNameBtn.textColor = .link
        
        updateDisplayNameBtn.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(updateDisplayNameBtn)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(displayNameTapped))
        updateDisplayNameBtn.addGestureRecognizer(gesture)
        
        // the gray line below udn button
        topHorizontalLine = UIView()
        topHorizontalLine.backgroundColor = .lightGray
        
        topHorizontalLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(topHorizontalLine)
        
        
        NSLayoutConstraint.activate([
            displayNameL.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 20),
            displayNameL.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            updateDnameIndicator.centerYAnchor.constraint(equalTo: displayNameL.centerYAnchor),
            updateDnameIndicator.leadingAnchor.constraint(equalTo: displayNameL.trailingAnchor,constant: 10),
            
            updateDisplayNameBtn.topAnchor.constraint(equalTo: displayNameL.bottomAnchor, constant: 10),
            updateDisplayNameBtn.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            topHorizontalLine.topAnchor.constraint(equalTo: updateDisplayNameBtn.bottomAnchor, constant: 27),
            topHorizontalLine.heightAnchor.constraint(equalToConstant: 1.0),
            topHorizontalLine.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
            topHorizontalLine.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        
    }
    
    
    // things related to TD
    func configureTargetDemoThings(){
        mytargetDemoText = UILabel()
        mytargetDemoText.font = UIFont.systemFont(ofSize: 19, weight: .semibold)
        mytargetDemoText.textColor = .label
        mytargetDemoText.text = "My Target Demographic"
        mytargetDemoText.textAlignment = .center
        
        mytargetDemoText.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mytargetDemoText)
        
        
        iPreferOpinionLabel = UILabel()
        iPreferOpinionLabel.font = UIFont.systemFont(ofSize: 17)
        iPreferOpinionLabel.textColor = .label
        iPreferOpinionLabel.text = "I prefer opinions from:"
        iPreferOpinionLabel.textAlignment = .center
        
        iPreferOpinionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iPreferOpinionLabel)
        
        mytargetDemoL = UILabel()
        mytargetDemoL.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        mytargetDemoL.textColor = .label
        mytargetDemoL.text = "target dmeo list"
        mytargetDemoL.textAlignment = .center
        mytargetDemoL.numberOfLines = 6
        
        mytargetDemoL.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mytargetDemoL)
        
        
        NSLayoutConstraint.activate([
            mytargetDemoText.topAnchor.constraint(equalTo: topHorizontalLine.bottomAnchor, constant: 10),
            mytargetDemoText.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            iPreferOpinionLabel.topAnchor.constraint(equalTo: mytargetDemoText.bottomAnchor, constant: 8),
            iPreferOpinionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            mytargetDemoL.topAnchor.constraint(equalTo: iPreferOpinionLabel.bottomAnchor, constant: 4),
            mytargetDemoL.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            mytargetDemoL.heightAnchor.constraint(lessThanOrEqualToConstant: 140),
            
          
        ])
    }
    
    
    // things related to age
    func configureAgeThings(){
        agesText = UILabel()
        agesText.font = UIFont.systemFont(ofSize: 17)
        agesText.textColor = .label
        agesText.text = "Ages"
        
        agesText.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(agesText)
        
        mytargetAge = UILabel()
        mytargetAge.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        mytargetAge.textColor = .label
        mytargetAge.text = ""
        
        mytargetAge.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mytargetAge)
        
        NSLayoutConstraint.activate([
            agesText.topAnchor.constraint(equalTo: mytargetDemoL.bottomAnchor, constant: 8),
            agesText.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            mytargetAge.topAnchor.constraint(equalTo: agesText.bottomAnchor, constant: 4),
            mytargetAge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        
    }
    
    
    func configureEditTDButton(){
        editTDBtn = UILabel()
        editTDBtn.text = "Edit Target Demographic"
        editTDBtn.font = UIFont.systemFont(ofSize: 17)
        
        editTDBtn.isUserInteractionEnabled = true
        editTDBtn.textColor = .link
        
        editTDBtn.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(editTDBtn)
        
        NSLayoutConstraint.activate([
            editTDBtn.topAnchor.constraint(equalTo: mytargetAge.bottomAnchor, constant: 8),
            editTDBtn.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        
       
        let gesture = UITapGestureRecognizer(target: self, action: #selector(editTargetDemoTapped))
        editTDBtn.addGestureRecognizer(gesture)
    }
    
    
    func configureSpecialtyThings(){
        // the gray line below etd button
        bottomHorizontalLine = UIView()
        bottomHorizontalLine.backgroundColor = .lightGray
        
        bottomHorizontalLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomHorizontalLine)
        
        
        myOrientationText = UILabel()
        myOrientationText.textColor = .label
        myOrientationText.text = "My Orientation"
        myOrientationText.font = UIFont.systemFont(ofSize: 19, weight: .semibold)
        
        myOrientationText.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(myOrientationText)
        
        specialtyPicker = UIPickerView()
        specialtyPicker.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(specialtyPicker)
        
        
        
        NSLayoutConstraint.activate([
            bottomHorizontalLine.heightAnchor.constraint(equalToConstant: 1.0),
            bottomHorizontalLine.topAnchor.constraint(equalTo: editTDBtn.bottomAnchor, constant: 4),
            bottomHorizontalLine.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            bottomHorizontalLine.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
            bottomHorizontalLine.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor),
            
            myOrientationText.topAnchor.constraint(equalTo: bottomHorizontalLine.bottomAnchor, constant: 4),
            myOrientationText.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            specialtyPicker.topAnchor.constraint(equalTo: myOrientationText.bottomAnchor, constant: 0),
            specialtyPicker.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 75),
            specialtyPicker.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -75),
            specialtyPicker.heightAnchor.constraint(equalToConstant: 120)
            
        ])
    }
    
    
    func configureUNThings(){
        
        myUsernameText = UILabel()
        myUsernameText.text = "My Username:"
        myUsernameText.textColor = .label
        myUsernameText.font = UIFont.systemFont(ofSize: 19, weight: .semibold)
        
        myUsernameText.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(myUsernameText)
        
        usernameL = UILabel()
        usernameL.text = ""
        usernameL.textColor = .label
        usernameL.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        usernameL.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(usernameL)
        
        
        NSLayoutConstraint.activate([
            myUsernameText.topAnchor.constraint(equalTo: specialtyPicker.bottomAnchor, constant: 20),
            myUsernameText.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            usernameL.topAnchor.constraint(equalTo: myUsernameText.bottomAnchor),
            usernameL.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        
        
        
    }
    
    
    func configureChangePassBtn(){
        changePasswordBtn = UILabel()
        changePasswordBtn.text = "Change Password"
        changePasswordBtn.font = UIFont.systemFont(ofSize: 17)
        changePasswordBtn.isUserInteractionEnabled = true
        changePasswordBtn.textColor = .link
        
        changePasswordBtn.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(changePasswordBtn)
        
        passwordIndicator = UIActivityIndicatorView()
        
        passwordIndicator.startAnimating()
        passwordIndicator.isHidden = true
        
        passwordIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(passwordIndicator)
        
        NSLayoutConstraint.activate([
            changePasswordBtn.topAnchor.constraint(equalTo: usernameL.bottomAnchor, constant: 20),
            changePasswordBtn.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            passwordIndicator.centerYAnchor.constraint(equalTo: changePasswordBtn.centerYAnchor),
            passwordIndicator.leadingAnchor.constraint(equalTo: changePasswordBtn.trailingAnchor,constant: 20),
        ])
        
   
        let gesture = UITapGestureRecognizer(target: self, action: #selector(changePasswordTapped))
        changePasswordBtn.addGestureRecognizer(gesture)
    }
    
    
    func configurePhoneNumberThings(){
        phoneNumberText = UILabel()
        phoneNumberText.text = "Phone Number"
        phoneNumberText.textColor = .label
        phoneNumberText.font = UIFont.systemFont(ofSize: 17)
        
        phoneNumberText.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(phoneNumberText)
        
        phoneNumberL = UILabel()
        phoneNumberL.text = ""
        phoneNumberL.textColor = .label
        phoneNumberL.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        phoneNumberL.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(phoneNumberL)
        
        changePhoneNumberBtn = UILabel()
        changePhoneNumberBtn.text = "Change Phone Number"
        changePhoneNumberBtn.font = UIFont.systemFont(ofSize: 17)
        changePasswordBtn.textColor = .link
        
        changePhoneNumberBtn.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(changePhoneNumberBtn)
        
        
        NSLayoutConstraint.activate([
            phoneNumberText.topAnchor.constraint(equalTo: changePasswordBtn.bottomAnchor, constant: 30),
            phoneNumberText.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            phoneNumberL.topAnchor.constraint(equalTo: phoneNumberText.bottomAnchor, constant: 10),
            phoneNumberL.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            changePhoneNumberBtn.topAnchor.constraint(equalTo: phoneNumberL.bottomAnchor, constant: 20),
            changePhoneNumberBtn.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(changePhoneTapped))
        changePhoneNumberBtn.addGestureRecognizer(gesture)
        
    }
    
    
    func configureDeleteAccountBtn(){
        deleteAccountBtn = UILabel()
        deleteAccountBtn.text = "Delete Account"
        deleteAccountBtn.font = UIFont.systemFont(ofSize: 17)
        deleteAccountBtn.isUserInteractionEnabled = true
        deleteAccountBtn.textColor = .systemRed
        
        deleteAccountBtn.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deleteAccountBtn)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(deleteAccountTapped))
        deleteAccountBtn.addGestureRecognizer(gesture)
        
        
        NSLayoutConstraint.activate([
            deleteAccountBtn.topAnchor.constraint(equalTo: changePhoneNumberBtn.bottomAnchor, constant: 50),
            deleteAccountBtn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            deleteAccountBtn.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    
    
    
}
