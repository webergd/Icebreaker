//
//  PasswordResetViewController.swift
//  Tangerine
//
//  Created by Mahmudul Hasan on 2022-02-20.
//

import UIKit
import FirebaseAuth
import MaterialComponents.MDCOutlinedTextField

class PasswordResetViewController: UIViewController, UITextFieldDelegate {

    // MARK: UI Items
    var user: User!
    // this will determine if we show password
    // default false
    
    var showPassword = true
    
    var topLabel: UILabel!
    var newPassTF: MDCOutlinedTextField!
    
    // create two types of eye icon
    var eye : UIImage!
    var eyeSlash : UIImage!
    // init the eye icon view
    var eyeIconView : UIImageView!
    
    var resetButton: ContinueButton!
    
    
    // MARK: Actions
    
    @objc func onResetClick(_ sender: UIButton) {
        print("Reset Clicked")
        if let newPassword = newPassTF.text, newPassword.count >= 6{
            view.showActivityIndicator()
            user.updatePassword(to: newPassword) { error in
                
                defer{
                    self.view.hideActivityIndicator()
                }
                
                if let error = error{
                    self.presentDismissAlertOnMainThread(title: "Auth Error", message: error.localizedDescription)
                    return
                }
                
                self.presentDismissAlertOnMainThread(title: "Success!", message: "Please login with your username and new password now"){
                    // move to login
                    self.navigationController?.dismissToLeft()
                }
                
            }
        }

    }
    
    // the toggle icon method
    @objc func toggleIcon(_ sender: UITapGestureRecognizer){
        
        // toggle the flag
        showPassword = !showPassword
        // toggle the secure mode
        newPassTF.isSecureTextEntry = !showPassword
        
        // when password is showing,
        // the eye is open, else not
        if(showPassword){
            eyeIconView.image = eye
        }else{
            eyeIconView.image = eyeSlash
        }
    } // toggleIcon
    
    // Additional Setup on the UI
    func setupUI(){

        // images for passwordTF
        eye = UIImage(systemName: "eye")
        eyeSlash = UIImage(systemName: "eye.slash")
        
        eyeIconView = UIImageView(image: eye)
        
        
        
        //add the icon to passwordTF
        newPassTF.trailingView = eyeIconView
        // set the eye icon to visible always
        newPassTF.trailingViewMode = .always
        
        //add a tap gesture to it
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.toggleIcon(_:)))
    
        // add the gesture to the iconview and also enable user interaction
        // as this is a subclass of UIView not UIControl
        eyeIconView.addGestureRecognizer(tap)
        eyeIconView.isUserInteractionEnabled = true
        
        
        // let's customize our only button
        resetButton.disable()
        
        
        //dismiss keyboard, call the extension
        hideKeyboardOnOutsideTouch()
        
        newPassTF.delegate = self
    } // end setupUI
    
    func showError(){
        print("show error")
        //set and hide the error text at the beggining
        newPassTF.leadingAssistiveLabel.text = "Password must contain\n* 6 or more characters"
        newPassTF.setLeadingAssistiveLabelColor(.systemRed, for: .normal)
        newPassTF.setLeadingAssistiveLabelColor(.systemRed, for: .editing)
        // also if there is error, username won't be valid, nor should the button be active
       
        resetButton.disable()
    }// end of show error
    
    func hideError(){
        print("hide error")
        //set and hide the error text at the beggining
        // isHidden not working
        newPassTF.leadingAssistiveLabel.text = ""
        resetButton.enable()
        
        
    }// end of hide error
    
    
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
        
        if let newPassword = newPassTF.text{
            // fire the reset button only if the length is valid
            if newPassword.count >= 6 {
                onResetClick(resetButton)
            }else{
                newPassTF.resignFirstResponder()
            }
            
        }
        
        return true
    }

    
    // MARK: VC Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // name will suggest what they do
        view.backgroundColor = .systemBackground
        title = "Reset Password"
        
        configureTopLabel()
        
        configurePassTF()
        
        configureResetButton()
        
        setupUI()
        
    }
    
    // MARK: PROGRAMMATIC UI
    
    // MARK: TopLabel
    func configureTopLabel(){
        topLabel = UILabel()
        topLabel.text = "Enter New Password"
        // to make it dark/light friendly
        topLabel.textColor = .label
        topLabel.textAlignment = .center
        topLabel.font = UIFont.systemFont(ofSize: 17,weight: .semibold)
        view.addSubview(topLabel)
        
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topLabel.heightAnchor.constraint(equalToConstant: 50),
            topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            topLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            topLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
        ])
    } // end conf topLabel
    

    // MARK: PASS TF
    func configurePassTF(){
        
        newPassTF = MDCOutlinedTextField()
        newPassTF.textColor = .label
        newPassTF.font = UIFont.systemFont(ofSize: 14)
        newPassTF.placeholder = "New Password"
        newPassTF.returnKeyType = .go
        
        view.addSubview(newPassTF)
        newPassTF.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            newPassTF.heightAnchor.constraint(equalToConstant: 100),
            newPassTF.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 50),
            newPassTF.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            newPassTF.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50)
        ])
    } // end pass tf
    
    
    // MARK: ContinueButton
    func configureResetButton(){
        resetButton = ContinueButton(title: "Reset Password")
        
        view.addSubview(resetButton)
        
        resetButton.addTarget(self, action: #selector(onResetClick), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100)
        ])
        
    }// end conf continue button


}
