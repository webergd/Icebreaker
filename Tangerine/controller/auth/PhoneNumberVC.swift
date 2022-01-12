//
//  PhoneNumberVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-18.
//

import UIKit
import FirebaseAuth

class PhoneNumberVC: UIViewController, UITextFieldDelegate {
    
    // to determine if this view has been called from EditProfile
    
    var isEditingProfile = false
    // to detect if it is auto filled
    var isAutoFilled = false
    // to hide or show based on calling from where
    @IBOutlet weak var pageControll: UIPageControl!
    
    @IBOutlet weak var editingBackButton: UIButton!
    
    
    
    @IBAction func editingBackTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - Delegates
     - View Controller methods
     */
    /******************************************************************************************************************************/

    
    @IBOutlet weak var phoneBoxOneTF: UITextField!
    @IBOutlet weak var phoneBoxTwoTF: UITextField!
    @IBOutlet weak var phoneBoxThreeTF: UITextField!
    
    @IBOutlet weak var errorL: UILabel!
    @IBOutlet weak var continueBtn: UIButton!
    
    // the loading
    var indicator: UIActivityIndicatorView!
    
    var phoneNumber = ""
    
    /******************************************************** ************************************************/
    
    
    @IBAction func onInfoClicked(_ sender: Any) {
        presentDismissAlertOnMainThread(title: "Info", message: "We will never sell or distribute any of your contact information")
    }
    
    
    @IBAction func onContinueClick(_ sender: UIButton) {
        // sendVerification
        print(phoneNumber.count)
        if phoneNumber.count == 12{
            print("Continue Clicked")
            sendVerificationCode(phoneNumber)
        }
        
    }
    
    /******************************************************** ************************************************/
    
    // Additional Setup on the UI
    func setupUI(){
        
        // let's customize our only button
        continueBtn.layer.borderWidth = 2.0
        continueBtn.layer.cornerRadius = 6.0
        continueBtn.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        showError()
        
        
        // indicator
        setupIndicator()
        
        //dismiss keyboard, call the extension
        hideKeyboardOnOutsideTouch()
        
        // set the delegate to change keyboard focus
        phoneBoxOneTF.delegate = self
        phoneBoxTwoTF.delegate = self
        phoneBoxThreeTF.delegate = self
        
        phoneBoxOneTF.becomeFirstResponder()
        
        
        // WHEN EDITING PROFILE
        // hide the page control and show the editing backbutton
        
        if isEditingProfile {
            editingBackButton.isHidden = false
            pageControll.isHidden = true
        }else{
            editingBackButton.isHidden = true
            pageControll.isHidden = false
        }
        
        
        
    }
    // to show error
    func showError(){
        print("show error")
        errorL.isHidden = false
        continueBtn.disable()
    }// end of show error
    
    // to hide error
    func hideError(){
        print("hide error")
        errorL.isHidden = true
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
    
    // send user verification code
    func sendVerificationCode(_ number: String){
        // show the loader
        indicator.startAnimating()
        // start verifying, send sms here
        PhoneAuthProvider.provider().verifyPhoneNumber(number, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                self.presentDismissAlertOnMainThread(title: "Auth Error", message: error.localizedDescription)
                print("error occured when attempting to sendVerificationCode in PhoneNumberVC. Error: \(error).")
                self.indicator.stopAnimating()
                return
              }
            
            // save the verification ID as we are moving from here
            // save the phone so we can show it next screen
            UserDefaults.standard.setValue(verificationID, forKey: Constants.VERIFICATION_ID)
            // stop the loading indicator
            self.indicator.stopAnimating()
            
            // pass the number
            ConfirmationVC.usernumber = number
            // if we are editing number, prepare these data
            
            if self.isEditingProfile {
                
                ConfirmationVC.isEditingProfile = true
                
                
                
                let story = UIStoryboard.init(name: "Main", bundle: nil)
                let vc = story.instantiateViewController(identifier: "confirmation_vc") as! ConfirmationVC
                
                vc.modalPresentationStyle = .fullScreen
                
                // We want to dismiss this and go to next  vc
                let parentvc = self.presentingViewController
               
                self.dismiss(animated: false, completion: {
                    parentvc!.present(vc, animated: true, completion: nil)
                })
                
                
                
            }else{
                self.performSegue(withIdentifier: "confirmation_vc", sender: self)
            }
            
            
            
            
        }
    }// end of send verification code
    
    /******************************************************** ************************************************/
    
    // when the text changes validate it again
    func textFieldDidChangeSelection(_ textField: UITextField) {
        print("did change")
        
        // check who the responder and count their digits
        // check if text is not null and if their count matches with doc
        // if yes, then move focus
        
        if isAutoFilled {
            // auto filled
            print("Auto fill")
            
            // format and fill 
            if let number = textField.text, number.count >= 10{
               
                // format and set
                let formattedNumber = formatNumberWOCC(number)

                phoneBoxOneTF.text = formattedNumber.subString(from: 0, to: 3)
                phoneBoxTwoTF.text = formattedNumber.subString(from: 3, to: 6)
                phoneBoxThreeTF.text = formattedNumber.subString(from: 6, to: 10)
                textField.resignFirstResponder()
                isAutoFilled = false
            }
            
            
            
        }else{
            
            // we're also making some checks if user types more than they allowed to
            // if they do, we discard it
            
            // user manually typed
            if phoneBoxOneTF.isFirstResponder {
                if let text = textField.text{
                    
                    if text.count == 3{
                        phoneBoxTwoTF.becomeFirstResponder()
                    }else if text.count > 3{
                        phoneBoxOneTF.text = text.subString(from: 0, to: 3)
                        phoneBoxTwoTF.becomeFirstResponder()
                    }
                }
            }
            
            else if phoneBoxTwoTF.isFirstResponder {
                if let text = textField.text{
                    if text.count == 3{
                        phoneBoxThreeTF.becomeFirstResponder()
                    }else if text.count > 3{
                        phoneBoxTwoTF.text = text.subString(from: 0, to: 3)
                        phoneBoxThreeTF.becomeFirstResponder()
                    }else if text.count == 0{
                        // when second box is empty move to first box
                        phoneBoxOneTF.becomeFirstResponder()
                    }
                }
            }
            
            else{
                if let text = textField.text{
                    
                    if text.count == 4{
                        phoneBoxThreeTF.resignFirstResponder()
                    }else if text.count > 4 {
                        phoneBoxThreeTF.text = text.subString(from: 0, to: 4)
                        phoneBoxThreeTF.resignFirstResponder()
                    }else if text.count == 0{
                        // when third box is empty, move to second box
                        phoneBoxTwoTF.becomeFirstResponder()
                    }
                    
                    
                }
            }
            
        } //end of else
       
        
        
        // at any given moment of text change, check the length of phone
        if let phone1Digits = phoneBoxOneTF.text, let phone2Digits = phoneBoxTwoTF.text, let phone3Digits = phoneBoxThreeTF.text{
            // check if all good
            let valid = phone1Digits.count + phone2Digits.count + phone3Digits.count == 10
            // everything is fine or not?
            if valid{
                hideError()
                phoneNumber = "+1\(phone1Digits)\(phone2Digits)\(phone3Digits)"
            }else{
                showError()
            }
        } // end if let
        
        
    } // end did change
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
      if string.count > 1 {
        // user tapped the quicktype bar'
        isAutoFilled = true
        print("Auto fill detected")
        
      }
      return true
    }
    
    
    
    /******************************************************** ************************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Phone number"
        // Do any additional setup after loading the view.
        setupUI()
    }
    


}
