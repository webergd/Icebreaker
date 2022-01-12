//
//  PasswordVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-18.
//

import UIKit
import MaterialComponents
import FirebaseAuth

class PasswordVC: UIViewController, UITextFieldDelegate {
    
    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - Delegates
     - View Controller methods
     */
    /******************************************************************************************************************************/

    @IBOutlet weak var passwordTF: MDCOutlinedTextField!
    
    @IBOutlet weak var continueBtn: UIButton!
    
    // this will determine if we show password
    // default false
    
    var showPassword = true
    // to stop blocking the UI when user presses back from phoneview
    var isRegistered = false
    
    
    // create two types of eye icon
    var eye : UIImage!
    var eyeSlash : UIImage!
    // init the eye icon view
    var eyeIconView : UIImageView!
    // the loading
    var indicator: UIActivityIndicatorView!
    
    /******************************************************** ************************************************/
    
    @IBAction func onContinueClick(_ sender: UIButton) {
        print("Continue Clicked")
        
        if let password = passwordTF.text{
            createUserAccount(password)
        }
        
    }
    
    
    
    
    /******************************************************** ************************************************/
    
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
    
    // Additional Setup on the UI
    func setupUI(){
        // set the labels
        passwordTF.label.text = "Password"
        
        // images for passwordTF
        eye = UIImage(systemName: "eye")
        eyeSlash = UIImage(systemName: "eye.slash")
        
        eyeIconView = UIImageView(image: eye)
        
        
        
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
        
        
        // let's customize our only button
        continueBtn.layer.borderWidth = 2.0
        continueBtn.layer.cornerRadius = 6.0
        continueBtn.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        continueBtn.disable()
        
        
        // indicator
        setupIndicator()
        
        //dismiss keyboard, call the extension
        hideKeyboardOnOutsideTouch()
        
        passwordTF.delegate = self
    }
    
    
    func showError(){
        print("show error")
        //set and hide the error text at the beggining
        passwordTF.leadingAssistiveLabel.text = "Password must contain\n* 6 or more characters"
        passwordTF.setLeadingAssistiveLabelColor(.systemRed, for: .normal)
        passwordTF.setLeadingAssistiveLabelColor(.systemRed, for: .editing)
        // also if there is error, username won't be valid, nor should the button be active
       
        continueBtn.disable()
    }// end of show error
    
    func hideError(){
        print("hide error")
        //set and hide the error text at the beggining
        // isHidden not working
        passwordTF.leadingAssistiveLabel.text = ""
        continueBtn.enable()
        
        
    }// end of hide error
    
    
    // to show the loading
    func setupIndicator() {
        indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        indicator.center = view.center
        view.addSubview(indicator)
        indicator.bringSubviewToFront(view)
    }
    
    // called to create account using username ie: email and password
    func createUserAccount(_ password: String) {
        // start the loading
        indicator.startAnimating()
        // Create a user in firebase auth system with username and our custom domain
        // later we'll link the phone number with it
        
        // check if already registered
        
        if self.isRegistered {
            
            if let user = Auth.auth().currentUser{
                user.updatePassword(to: password) { (error) in
                    if let error = error{
                        self.indicator.stopAnimating()
                        self.presentDismissAlertOnMainThread(title: "Update Failed", message: error.localizedDescription)
                        return
                    }
                    
                    self.indicator.stopAnimating()
                    self.performSegue(withIdentifier: "phonenumber_vc", sender: self)
                    
                } // end of update password
            } // end if let

        }else{
            Auth.auth().createUser(withEmail: Constants.username+Constants.CUSTOM_EMAIL_DOMAIN, password: password) { (result, error) in
                if let err = error{
                    // there is some error, handle it, show some dialog
                    // TODO: show error message
                    self.indicator.stopAnimating()
                    self.presentDismissAlertOnMainThread(title: "Auth Error", message: err.localizedDescription)
                    
                }else{
                    // no error, let's move
                    if let result = result{
                        // save the username as display name in device
                        UserDefaults.standard.setValue(Constants.username, forKey: Constants.UD_USER_DISPLAY_NAME)
                        // set the username with the user
                        let request = result.user.createProfileChangeRequest()
                        request.displayName = Constants.username
                        request.commitChanges { (error) in
                            if error == nil{
                                print("Username set")
                                self.isRegistered = true
                                // move to next page
                                self.indicator.stopAnimating()
                                // this indicates that a temp account is created again
                                UserDefaults.standard.setValue(false, forKey: Constants.UD_SIGNUP_DONE_Bool)
                                self.performSegue(withIdentifier: "phonenumber_vc", sender: self)
                            }
                        }
                    }
                }
            } // end of create User
        }// end of else

        
        
        
        

        
         
    }// end of createUserAccount
    
    /******************************************************** ************************************************/
    
    // when the text changes validate it again
    func textFieldDidChangeSelection(_ textField: UITextField) {
        print("did change")
        if let text = textField.text, text.count < 6{
            showError()
        }else{
            
            hideError()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("Continue Clicked")
        
        if let password = passwordTF.text{
            createUserAccount(password)
        }
        
        return true
    }
    
    /******************************************************** ************************************************/
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        title = "Password"
        // Do any additional setup after loading the view.
        
        setupUI()
      
    }
    

    

}
