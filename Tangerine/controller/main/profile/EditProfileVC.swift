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
    
    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - Delegates
     - View Controller methods
     */
    /******************************************************************************************************************************/
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var uploadIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var displayNameL: UILabel!
    @IBOutlet weak var updateDnameIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var mytargetDemoL: UILabel!
    @IBOutlet weak var mytargetAge: UILabel!
    
    @IBOutlet weak var specialtyPicker: UIPickerView!
    
    @IBOutlet weak var usernameL: UILabel!
    
    @IBOutlet weak var phoneNumberL: UILabel!
    @IBOutlet weak var passwordIndicator: UIActivityIndicatorView!
    
    
    // the loading
    var indicator: UIActivityIndicatorView!
    
    // this is where we'll save the profile image or any other image
    var profileRef: StorageReference!
    
    // user default
    var userDefault : UserDefaults!
    
    
    // options for specialty
    let options = Constants.ORIENTATIONS
    var speText = ""
    
    /******************************************************************************************************************************/
    
    @IBAction func onBackPressed(_ sender: UIButton) {
        print("Back")
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDonePressed(_ sender: UIButton) {
        print("Done")
        // save to firestore and local
        saveToFirestore()
        
    }
    
    
    @IBAction func profileImageTapped(_ sender: UITapGestureRecognizer) {
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
    
    
    @IBAction func displayNameTapped(_ sender: UITapGestureRecognizer) {
        
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
    
    
    @IBAction func editTargetDemoTapped(_ sender: UIButton) {
        let story = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = story.instantiateViewController(identifier: "targetdemo_vc") as! TargetDemoVC
        vc.isEditingProfile = true
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    
    @IBAction func changePasswordTapped(_ sender: UITapGestureRecognizer) {
        changePassword()
    }
    
    @IBAction func changePhoneTapped(_ sender: UITapGestureRecognizer) {
        
        let story = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = story.instantiateViewController(identifier: "phonenumber_vc") as! PhoneNumberVC
        
        vc.isEditingProfile = true
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    
    @IBAction func deleteAccountTapped(_ sender: UIButton) {
        
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
    
    
    
    /******************************************************************************************************************************/
    
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
        
        
        // setup the indicator
        
        setupIndicator()
        
        // put some border on profile picture
        profileImage.layer.borderWidth = 1.0
        profileImage.layer.borderColor = UIColor.systemBlue.cgColor
        profileImage.layer.cornerRadius = 4.0
        
        fetchPastValues()
    }
    
    
    func saveToFirestore(){
        // this username is still valid, although we can take from Auth.auth().user.displayname
        
        let db = Firestore.firestore()
        
        
        // save the specialty now
        db
            .collection(Constants.USERS_COLLECTION)
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
        indicator.startAnimating()
        // delete the user doc
        
        Firestore.firestore().collection(Constants.USERS_COLLECTION)
            .document(myProfile.username).delete { (error) in
                if let error = error{
                    self.presentDismissAlertOnMainThread(title: "Server Error", message: error.localizedDescription)
                }
                
                
                // delete the private docs
                
                Firestore.firestore().collection(Constants.USERS_COLLECTION).document(myProfile.username).collection(Constants.USERS_PRIVATE_SUB_COLLECTION).document(Constants.USERS_PRIVATE_INFO_DOC).delete { (error) in
                    
                    if let error = error{
                        self.presentDismissAlertOnMainThread(title: "Server Error", message: error.localizedDescription)
                    }
                    
                    
                    // remove db values
                    
                    resetLocalAndRealmDB()
                    
                    
                    // move to login
                    
                    self.indicator.stopAnimating()
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "login_vc") as! LoginVC
                    vc.modalPresentationStyle = .fullScreen
                    
                    self.present(vc, animated: true, completion: nil)
                    
                    // account and storage will be deleted from functions
                    
                    
                }
                
            }// end of doc delete
        
        
        
        
        
    }// end of delete user
    
    
    
    // to show the loading
    func setupIndicator() {
        indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        indicator.center = view.center
        view.addSubview(indicator)
        indicator.bringSubviewToFront(view)
    }
    
    /******************************************************************************************************************************/
    
    // this delegate is called when image selecting is done
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // dismiss the picker
        picker.dismiss(animated: true, completion: nil)
        
        // a guard to ensure that we got the picture
        guard let image = info[.editedImage] as? UIImage else{
            presentDismissAlertOnMainThread(title: "Camera Error", message: "Image picking failed. Try again!")
            return
        }
        
        profileImage.image = image
        
        // save to local
        saveImageToDiskWith(imageName: getFilenameFrom(qName: myProfile.username, type: .ASK), image: image)
        
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
    
    
    
    
    
    /******************************************************************************************************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        downloadOrLoadFirebaseImage(
            ofName: getFilenameFrom(qName: myProfile.username, type: .ASK),
            forPath: myProfile.profile_pic) { image, error in
                if let error = error{
                    print("Error: \(error.localizedDescription)")
                    return
                }
                
                print("Profile Image Downloaded for MYSELF")
                self.profileImage.image = image
            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // if we return from target demo, we'll need to update the values
        fetchPastValues()
    }
    
}
