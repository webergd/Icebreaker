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
    
    // MARK: UI Items
    var topLabel: UILabel! // actually the title
    var passwordTF: MDCOutlinedTextField!
    
    var continueBtn: UIButton!
    
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
    
    
    // MARK: Actions
    
    @objc func onContinueClick(_ sender: UIButton) {
        print("Continue Clicked")
        
        if let password = passwordTF.text{
            createUserAccount(password)
        }
        
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
    
    
    
    // called to create account using username ie: email and password
    func createUserAccount(_ password: String) {
        // start the loading
        view.showActivityIndicator()
        // Create a user in firebase auth system with username and our custom domain
        // later we'll link the phone number with it
        
        // check if already registered
        // occurs when user presses back from next VC
        // no matter if user writes same or different password, it'll be updated
        // without it, it'll show, user already exists.
        // this prevents that
        if self.isRegistered {
            
            if let user = Auth.auth().currentUser{
                user.updatePassword(to: password) { (error) in
                    if let error = error{
                        self.view.hideActivityIndicator()
                        self.presentDismissAlertOnMainThread(title: "Update Failed", message: error.localizedDescription)
                        return
                    }
                    
                    self.view.hideActivityIndicator()
                    let vc = PhoneNumberVC()
                    vc.modalPresentationStyle = .fullScreen
                    self.navigationController?.pushViewController(vc, animated: true)
                    
                } // end of update password
            } // end if let

        }else{
            Auth.auth().createUser(withEmail: Constants.username+Constants.CUSTOM_EMAIL_DOMAIN, password: password) { (result, error) in
                if let err = error{
                    // there is some error, handle it, show some dialog
                    // TODO: show error message
                    self.view.hideActivityIndicator()
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
                                self.view.hideActivityIndicator()
                                // this indicates that a temp account is created again
                                UserDefaults.standard.setValue(false, forKey: Constants.UD_SIGNUP_DONE_Bool)
                                
                                // move
                                let vc = PhoneNumberVC()
                                vc.modalPresentationStyle = .fullScreen
                                self.navigationController?.pushViewController(vc, animated: true)
                            }
                        }
                    }
                }
            } // end of create User
        }// end of else

        
        
        
        

        
         
    }// end of createUserAccount
    
    
    // MARK: Delegates
    
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
    
    // MARK: VC Methods
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Password"
        // Do any additional setup after loading the view.
        // proUI
        configureTopLabel()
        configurePassTF()
        configureContinueButton()
        configurePageControl()
        
        setupUI()
      
    }
    

    
    // MARK: PROGRAMMATIC UI
    func configureTopLabel(){
        topLabel = UILabel()
        topLabel.text = "Create a password"
        topLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        topLabel.textColor = .label
        
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topLabel)
        
        NSLayoutConstraint.activate([
            topLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
        ])
        
        
    }
    
    func configurePassTF(){
        
        passwordTF = MDCOutlinedTextField()
        passwordTF.textColor = .label
        passwordTF.font = UIFont.systemFont(ofSize: 14)
        passwordTF.placeholder = "Password"
        passwordTF.returnKeyType = .done
        
        view.addSubview(passwordTF)
        passwordTF.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            passwordTF.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 20),
            passwordTF.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            passwordTF.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50)
        ])
    } // end pass tf
    
    func configureContinueButton(){
        continueBtn = ContinueButton(title: "Continue")
        
        view.addSubview(continueBtn)
        
        continueBtn.addTarget(self, action: #selector(onContinueClick), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            continueBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
    }// end conf continue button
    
    func configurePageControl(){
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 6
        pageControl.currentPage = 1
        pageControl.pageIndicatorTintColor = .systemGray
        pageControl.currentPageIndicatorTintColor = .systemOrange
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)
        
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            pageControl.topAnchor.constraint(equalTo: continueBtn.bottomAnchor, constant: 50),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

}
