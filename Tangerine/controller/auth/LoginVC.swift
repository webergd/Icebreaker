//
//  LoginVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-15.
//

import UIKit
import MaterialComponents
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics
import RealmSwift


class LoginVC: UIViewController, UITextFieldDelegate {
    
    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - Delegates
     - View Controller methods
     */
    /******************************************************************************************************************************/
    // to resize the view when keyboard pops
    @IBOutlet weak var usernameTFTopConstraint: NSLayoutConstraint!
    
    // TextField outlets
    
    @IBOutlet weak var usernameTF: MDCOutlinedTextField!
    @IBOutlet weak var passwordTF: MDCOutlinedTextField!
    
    // If user should logged in? Default : True
    
    @IBOutlet weak var stayLoggedInSW: UISwitch!
    
    // the login button
    @IBOutlet weak var loginBtn: UIButton!
    
    // this will determine if we show password
    // default false
    
    var showPassword = false
    
    // create two types of eye icons
    var eye : UIImage!
    var eyeSlash : UIImage!
    // init the eye icon view
    var eyeIconView : UIImageView!
    
    
    // the loading
    var indicator: UIActivityIndicatorView!
    
    // user default
    let ud = UserDefaults.standard
    
    let TEXTFIELDTOPCONSTRAINTDEFAULTVALUE: CGFloat = 40.0

    /******************************************************** ************************************************/
    // fires when loginButton is tapped
    
    @IBAction func onLoginTapped(_ sender: UIButton) {
        print("login tapped")
        
        doLogin()
        
    }
    
    // when the stayLoggedInSW is changed
    // ie: clicked/tapped by user
    
    @IBAction func stayLoginSwitched(_ sender: Any) {
        ud.set(stayLoggedInSW.isOn, forKey: Constants.UD_SHOULD_PERSIST_LOGIN_Bool)
        let shouldKeepLoggedIn = ud.bool(forKey: Constants.UD_SHOULD_PERSIST_LOGIN_Bool)
        print("Saved stayLoginSW \(shouldKeepLoggedIn)")
    }
    
    // when the forgot pasword label is tapped
    
    @IBAction func forgotPasswordTapped(_ sender: UITapGestureRecognizer) {
        print("forgot my pass")
    }
    
    // when signup button tapped
    @IBAction func onSignupTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "username_vc", sender: self)
    }
    
    
    
    /******************************************************** ************************************************/
    
    
    // to show the loading
    func setupIndicator() {
        indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        indicator.center = view.center
        view.addSubview(indicator)
        indicator.bringSubviewToFront(view)
    }
    
    func showError(_ errorTF: MDCOutlinedTextField){
        print("show error")
        //set and hide the error text at the beggining
        if errorTF==passwordTF{
            errorTF.leadingAssistiveLabel.text = "Password must contain\n* 6 or more characters"
        }else{
            errorTF.leadingAssistiveLabel.text = "Username must contain\n* 3 or more characters\n* No spaces\n* * No invalid name"
        }
        
        
        errorTF.setLeadingAssistiveLabelColor(.systemRed, for: .normal)
        errorTF.setLeadingAssistiveLabelColor(.systemRed, for: .editing)
        // also if there is error, username won't be valid, nor should the button be active
        
    }// end of show error
    
    func hideError(_ errorTF: MDCOutlinedTextField){
        
        print("hide error")
        //set and hide the error text at the beggining
        // isHidden not working
        errorTF.leadingAssistiveLabel.text = ""
        
    }// end of hide error
    
    
    
    func doLogin(){
        
        // check this regex, as per firebase doc
        //https://firebase.google.com/docs/firestore/quotas
        let regex = try! NSRegularExpression(pattern: "__.*__")
        
        
        
        
        // if there is space at the end, we remove it
        if let name = usernameTF.text, (name.hasSuffix(" ") || name.hasPrefix(" ")){
            print("found spaces in username") //MARK: Added by Wyatt, feel free to remove.
            usernameTF.text = name.replacingOccurrences(of: " ", with: "")
        }
        
        
        // other validations
        if let name = usernameTF.text, name.count >= 3, !name.contains(" "), !name.contains("/"), !name.starts(with: "."){
            let range = NSRange(location: 0, length: name.utf16.count)
            // good so far
            // regex first match not nil, so there is match, it's an error
            if  regex.firstMatch(in: name, options: [], range: range) != nil{
                // invalid username
                showError(usernameTF)
            }else{
                // we got valid name
                // hide error
                hideError(usernameTF)
                // check password now
                if let password = passwordTF.text, password.count >= 6{
                    // hide the password error if any
                    hideError(passwordTF)
                    
                        self.indicator.startAnimating()
                        Auth.auth().signIn(withEmail: name+Constants.CUSTOM_EMAIL_DOMAIN, password: password) { (result, error) in
                            // got an error, return
                            if let err = error{
                                self.indicator.stopAnimating()
                                self.presentDismissAlertOnMainThread(title: "Login Error", message: err.localizedDescription)
                                return
                            }
                            self.validateLoginUsingFirestore()
                        }
                }else{
                    // error on password tf
                    showError(passwordTF)
                }
            }
        }else{
            showError(usernameTF)
        }
    }
    
    // Additional Setup on the UI
    func setupUI(){
        // set the labels
        usernameTF.label.text = "Username"
        passwordTF.label.text = "Password"
        
        eye = UIImage(systemName: "eye")
        eyeSlash = UIImage(systemName: "eye.slash")
        
        eyeIconView = UIImageView(image: eyeSlash)

        //add the icon to passwordTF
        passwordTF.trailingView = eyeIconView
        // set the eye icon to visible always
        passwordTF.trailingViewMode = .always
        
        //add a tap gesture to it
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.toggleIcon(_:)))
    
        // add the gesture to the iconview and also enable user interaction
        // as this is a subclass of UIView not UIControl
        eyeIconView.addGestureRecognizer(tap)
        eyeIconView.isUserInteractionEnabled = true
        
        //dismiss keyboard, call the extension
        hideKeyboardOnOutsideTouch()
        
        // set the delegates for TF
        usernameTF.delegate = self
        passwordTF.delegate = self
        
        
        // set this switch based on value
        let shouldKeepLoggedIn = ud.bool(forKey: Constants.UD_SHOULD_PERSIST_LOGIN_Bool)
        stayLoggedInSW.setOn(shouldKeepLoggedIn, animated: false)
        
        
    }
    
    // the toggle icon method
    @objc func toggleIcon(_ sender: UITapGestureRecognizer){
        
        // toggle the flag
        showPassword = !showPassword
        // toggle the secure mode
        passwordTF.isSecureTextEntry = !showPassword
        
        // when password is showing,
        // the eye is open, else not
        if(showPassword){
            eyeIconView.image = eye
        }else{
            eyeIconView.image = eyeSlash
        }
    }
    
    func removeOldData(){
        print("REMOVING OLD USER DATA")
        // so if a different user logs in we can be sure that he is not getting value of other user
        do {
            let database = try Realm()
            database.beginWrite()
            database.deleteAll()
            try database.commitWrite()
            
            
        } catch {
            print("Error occured while updating realm")
        }
        
        
        // update the user defaults
        // same goes for userdefaults
        
            let defaults = UserDefaults.standard
            let dictionary = defaults.dictionaryRepresentation()
            dictionary.keys.forEach { key in
                defaults.removeObject(forKey: key)
            }
    } // end of delete old data
    

    func validateLoginUsingFirestore(){
        // we are going to check if the current user has finished signup completely
        // if not, we'll remove this account, this can happen if user force closes the app during signing up
        // we'll check if orientation is present in user's doc, as that was the last field to input in the signup process
        
        let saved = RealmManager.sharedInstance.getProfile()
        
        
        if let user = Auth.auth().currentUser, let name = user.displayName{
            // get the documents from firestore
            
            // if saved username is empty that means new login
            // if it's equal to auth name, then it's same user
            if saved.username == name || saved.username.isEmpty{
                // all good
                print("NOT REMOVING UD")
            }else{
                // remove data of old user
                self.removeOldData()
            }
            
            self.indicator.startAnimating()
            
            
            Firestore.firestore().collection(Constants.USERS_COLLECTION).whereField(FieldPath.documentID(), isEqualTo: name).getDocuments {
                (snap, error) in
                // stop the loader
                self.indicator.stopAnimating()
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
                        
                        // Annotate the user's login in Google Analytics
                        Analytics.logEvent(AnalyticsEventLogin, parameters: [
                            AnalyticsParameterMethod: self.method
                          ])
                        
                        
                        print("User validated with username \(name)")
                        // all good, move to main
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                       
                        // Debug purpose
                        //let vc = storyboard.instantiateViewController(withIdentifier: "welcome_vc") as! WelcomeVC
                        //let vc = storyboard.instantiateViewController(withIdentifier: "friends_vc") as! FriendsVC
                        

                        
                        let vc = storyboard.instantiateViewController(withIdentifier: "main_vc") as! MainVC
                        vc.modalPresentationStyle = .fullScreen
                        

                        
                        self.present(vc, animated: false, completion: nil)
                        
                        //presentVC?.dismiss(animated: false, completion: nil)

                    }else{
                        // not present
                        // delete the account and show error
                        
                        self.delete(user)
                    }
                    
                    
                }else{
                    // no user on firestore either
                    // not present
                    // delete the account and show error
                    self.delete(user)
                    
                } // end of last else
                
                
            } // end of firebase call
            
        }// end of Auth user check
        
        
    } // end of validate func
    
    
    // delete the temp user from auth profiles
    func delete(_ user : FirebaseAuth.User){
        // stop the loader
        self.indicator.stopAnimating()
        
        user.delete { (error) in
            print("Deleting temp user")
            if let error = error{
                print("An error occured")
                self.presentDismissAlertOnMainThread(title: "Error", message: error.localizedDescription)
                return
            }
            
            self.presentDismissAlertOnMainThread(title: "Not Found", message: "We couldn't find the account you are trying to login!")
        }
    }
    
    /******************************************************** ************************************************/
    
    // Delegate method
    // called when user presses return key on keyboard
    // for username, next : for password, go
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // check which textfield has called this function
        print("Return Login")
        
        if textField.returnKeyType == .next{
            // this is the username TF
            print("moving to next")
            usernameTF.resignFirstResponder()
            passwordTF.becomeFirstResponder()
        } else if passwordTF.returnKeyType == .go{
            // this is the username TF
            passwordTF.resignFirstResponder()
            // do login
            doLogin()
            // We'll add the login function here as well
        }
        return true
    }

    /******************************************************** ************************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // call this function first to give user
        // a nice UI
        setupUI()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Main Login Appeared:")
    }
    
    // overriding this function so we don't show the nav bar on login screen
    // which will look odd
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("LoginVC View will appear")
        setupIndicator()
        configureKeyboard()
        
        // we don't want to see navbar here
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        // but first check if user chooses to keep him logged in
        let shouldKeepLoggedIn = ud.bool(forKey: Constants.UD_SHOULD_PERSIST_LOGIN_Bool)
        print("Should keep logged in? \(shouldKeepLoggedIn)")
        // if user if present and signup done , move to main
        
        if let _ = Auth.auth().currentUser, shouldKeepLoggedIn{
            
            // if true, then move him
            if !shouldKeepLoggedIn{
                do {
                    try Auth.auth().signOut()
                    print("LOGGED OUT")
                } catch let signOutError as NSError {
                    print ("Error signing out: %@", signOutError)
                  }
                return
            }
            
            // Auto login on, so let him log in, but check first
            
            validateLoginUsingFirestore()

        }
        
    }
    
    
    
    
    
    // This portion copied from other project to push view above keyboard
    
    
    
    func configureKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(LoginVC.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginVC.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    // MARK: this executes twice for some reason when a text field is tapped
    @objc func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            print("KEYBOARD HEIGHT: \(keyboardSize.height)")
            print("TFTopConstraint value was: \(usernameTFTopConstraint!)")
            usernameTFTopConstraint.constant = TEXTFIELDTOPCONSTRAINTDEFAULTVALUE - 100
            print("TFTopConstraint value is now: \(usernameTFTopConstraint!)")
            
            UIView.animate(withDuration: 0.5){
                self.view.setNeedsUpdateConstraints()
                self.view.layoutIfNeeded()
            }
            
            
        }
    }
    
    
    @objc func keyboardWillHide(notification: NSNotification) {
        
        if let _ = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            usernameTFTopConstraint.constant = TEXTFIELDTOPCONSTRAINTDEFAULTVALUE
            UIView.animate(withDuration: 0.5){
                self.view.setNeedsUpdateConstraints()
                self.view.layoutIfNeeded()
            }
            
        }
        
    }
    
}
