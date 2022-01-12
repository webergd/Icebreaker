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

    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - Delegates
     - View Controller methods
     */
    /******************************************************************************************************************************/
    
    @IBOutlet weak var jumpBtn: UIButton!
    @IBOutlet weak var displayUsernameL: UILabel!
    @IBOutlet weak var displayFriendsCountL: UILabel!
    
    @IBOutlet weak var profileImageView: UIImageView!
   
    @IBOutlet weak var uploadIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var displayNameUpdatingIndicator: UIActivityIndicatorView!
    
    /******************************************************************************************************************************/

    // this is where we'll save the profile image or any other image
    var profileRef: StorageReference!
    
    // we'll use this variable to show friends count if this vc is used multiple times in future
    static var friendsCount = 0
    
    /******************************************************************************************************************************/
    
    @IBAction func onJumpClicked(_ sender: UIButton) {
        print("Jump")
        performSegue(withIdentifier: "main_vc", sender: self)
    }
    
    @IBAction func updateDisplayNameClicked(_ sender: UITapGestureRecognizer) {
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
                self.displayNameUpdatingIndicator.isHidden = false
                
                let textField = alert?.textFields![0]
                if let text = textField?.text{
                    // update the display name here
                    
                        
                        Firestore.firestore().collection(Constants.USERS_COLLECTION).document(username).setData([Constants.USER_DNAME_KEY: text], merge: true) { (error) in
                            if let err = error{
                                self.presentDismissAlertOnMainThread(title: "Server Error", message: err.localizedDescription)
                                return
                            }
                            UserDefaults.standard.setValue(text, forKey: Constants.UD_USER_DISPLAY_NAME)
                            self.displayNameUpdatingIndicator.isHidden = true
                            
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
    
    @IBAction func updateTargetDemoClicked(_ sender: UITapGestureRecognizer) {
        print("Update Target Demo")
        performSegue(withIdentifier: "targetdemo_vc", sender: self)
    }
    
    @IBAction func addFriendClicked(_ sender: UITapGestureRecognizer) {
        print("Add Friend")
        performSegue(withIdentifier: "addfriend_vc", sender: self)
    }
    
    @IBAction func profilePictureClicked(_ sender: UITapGestureRecognizer) {
        
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
    
    
    func setupUI(){
        // style the jump button
        jumpBtn.layer.borderWidth = 2.0
        jumpBtn.layer.cornerRadius = 6.0
        jumpBtn.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        jumpBtn.enable()
        
        // put some border on profile picture
        profileImageView.layer.borderWidth = 1.0
        profileImageView.layer.borderColor = UIColor.systemBlue.cgColor
        profileImageView.layer.cornerRadius = 4.0
        
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
            self.uploadIndicator.isHidden = false
            
        } // end of progress observer
        
        
        uploadTask.observe(.success) { (snapshot) in
            // success ? hide the progress
            self.uploadIndicator.isHidden = true
        }
        
        // observe the failure here
        uploadTask.observe(.failure) { snapshot in
            // failed? hide the progress
            self.uploadIndicator.isHidden = true
            
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
    
    /******************************************************************************************************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
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
    

}
