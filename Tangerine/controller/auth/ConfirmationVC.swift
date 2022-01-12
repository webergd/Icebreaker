//
//  ConfirmationVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-18.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import RealmSwift

class ConfirmationVC: UIViewController, UITextFieldDelegate {
    
    // to determine if this view has been called for EditProfile
    
    static var isEditingProfile = false
    static var usernumber = ""
    
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var editingBack: UIButton!
    
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

    // all 6 input for OTP
    @IBOutlet weak var otpTF: UITextField!
    @IBOutlet weak var otp2TF: UITextField!
    @IBOutlet weak var otp3TF: UITextField!
    @IBOutlet weak var otp4TF: UITextField!
    @IBOutlet weak var otp5TF: UITextField!
    @IBOutlet weak var otp6TF: UITextField!
    
    // our final var for OTP
    var oneTimePass = ""
    
    // the outlets
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var errorL: UILabel!
    @IBOutlet weak var enterDescL: UILabel!
    
    
    // the loading
    var indicator: UIActivityIndicatorView!
    
    // otp time count
    var otpTimer: Timer?
    // didn't find firebase default, so being safe
    var timeoutSeconds = 60
    
    /******************************************************** ************************************************/
    
    @IBAction func continueBtnClicked(_ sender: Any) {
        
        // check if resend or not
        if continueBtn.titleLabel?.text == "Resend"{
            resendOTP()
        }else{
            // verify again if it is 6 digit
            if oneTimePass.count==6{
                verifyNumber(oneTimePass)
            }
        }

    }
    
    /******************************************************** ************************************************/
    
    // as always, make UI nice looking
    func setupUI(){
        // let's customize our only button
        continueBtn.layer.borderWidth = 2.0
        continueBtn.layer.cornerRadius = 6.0
        continueBtn.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        continueBtn.disable()
        // set the indicator
        setupIndicator()
        
        // set the delegate to check and move focus
        otpTF.delegate = self
        otp2TF.delegate = self
        otp3TF.delegate = self
        
        otp4TF.delegate = self
        otp5TF.delegate = self
        otp6TF.delegate = self
        // make it first responder
        otpTF.becomeFirstResponder()
        
        
        // set the number to label as per doc format
        
            //\(number[5..<8])-\(number[8..<number.count])
            enterDescL.text = "Enter the code we sent to (\(ConfirmationVC.usernumber.subString(from: 2, to: 5))) \(ConfirmationVC.usernumber.subString(from: 5, to: 8))-\(ConfirmationVC.usernumber.subString(from: 8, to: ConfirmationVC.usernumber.count))"
        
        
        //dismiss keyboard, call the extension
        hideKeyboardOnOutsideTouch()
        
        
        // WHEN EDITING PROFILE
        // hide the page control and show the editing backbutton
        
        if ConfirmationVC.isEditingProfile {
            editingBack.isHidden = false
            pageControl.isHidden = true
        }else{
            editingBack.isHidden = true
            pageControl.isHidden = false
        }
        
        // start the countdown
        startCountdown()
        
    }
    
    // to show the loading
    func setupIndicator() {
        indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        indicator.center = view.center
        view.addSubview(indicator)
        indicator.bringSubviewToFront(view)
    }
    
    // verify the phone number
    
    func verifyNumber(_ verificationCode: String) {
        
        // get the verification ID from UD
        let savedVerID = UserDefaults.standard.string(forKey: Constants.VERIFICATION_ID)
        // check for null
        guard let verificationID = savedVerID else {
            presentDismissAlertOnMainThread(title: "Verification Error", message: "Couldn't find valid verification id, try again")
            return
        }
        // show the progress
        indicator.startAnimating()
        // create a credential
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        
        
        // let's link this credential (if valid) with our already signed in user
        //
        if let user = Auth.auth().currentUser{
            
            // HERE LET"S CHECK IF IT IS EDITING OR NEW SIGNUP
            
            print("is editing profile \(ConfirmationVC.isEditingProfile)")
            
            // if we are editing
            if ConfirmationVC.isEditingProfile{
                // updating phone
                print("Editing Profile Verify")
                
                user.updatePhoneNumber(credential) { (error) in
                    // show the error if any
                    if let err = error{
                        self.presentDismissAlertOnMainThread(title: "Update Failed", message: err.localizedDescription)
                        print(err.localizedDescription)
                        self.indicator.stopAnimating()
                        return
                    }
                    
                    self.indicator.stopAnimating()
                    
                    // dismiss this view and present previous view
                    // set the value of firestore and local before that
                    
                    // when editing the displayname will never be null
                    // also we just added the phone and checked for error, it won't be null either
                    Firestore.firestore().collection(Constants.USERS_COLLECTION).document(user.displayName!).setData([Constants.USER_NUMBER_KEY:user.phoneNumber!], merge: true){ (error) in
                        
                        if let error = error{
                            self.presentDismissAlertOnMainThread(title: "Update Failed", message: error.localizedDescription)
                            return
                        }
                        
                        // update the local db
                        
                        do {
                            let database = try Realm()
                            database.beginWrite()
                            
                            let profile = RealmManager.sharedInstance.getProfile()
                            // phone isn't null, details above
                            profile.phone_number = user.phoneNumber!
                            try database.commitWrite()
                            
                            
                        } catch {
                            print("Error occured while updating realm")
                        }
                        
                        // go back to our parent
                                 
                                 let story = UIStoryboard.init(name: "Main", bundle: nil)
                                 let vc = story.instantiateViewController(identifier: "editprofile_vc") as! EditProfileVC
                                 
                                 vc.modalPresentationStyle = .fullScreen
                                 
                                 self.dismiss(animated: true, completion: nil)
                    } // end of firebase call
                    
                    
                }
                
            }else{
                // new signup
                
                user.link(with: credential) { (result, error) in
                    
                    // show the error if any
                    if let err = error{
                        self.presentDismissAlertOnMainThread(title: "Verification Failed", message: err.localizedDescription)
                        print(err.localizedDescription)
                        self.indicator.stopAnimating()
                        return
                    }
                    
                    self.indicator.stopAnimating()
                    // move to next screen
                    self.performSegue(withIdentifier: "birthday_vc", sender: self)
                    
                }// end of user link
            } // end of else of if isEditingProfile

         
            
        } // end of if let
    }
    
    func resendOTP(){
        // show the loader
        indicator.startAnimating()
        print("Resending \(ConfirmationVC.usernumber)")
        // start verifying, send sms here
        PhoneAuthProvider.provider().verifyPhoneNumber(ConfirmationVC.usernumber, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                self.presentDismissAlertOnMainThread(title: "Auth Error", message: error.localizedDescription)
                self.indicator.stopAnimating()
                return
              }
            
            // save the verification ID as we are moving from here
            // save the phone so we can show it next screen
            UserDefaults.standard.setValue(verificationID, forKey: Constants.VERIFICATION_ID)
            
            // stop the loading indicator
            self.indicator.stopAnimating()
            // to capture otp again
            self.otpTF.becomeFirstResponder()
            
            // reset and restart the timer
            self.timeoutSeconds = 60
            self.startCountdown()
       
            
        }
    }
    
    
    func startCountdown() {
            otpTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                self?.timeoutSeconds -= 1
                if self?.timeoutSeconds == 0 {
                    // time out, enable resend
                    self?.continueBtn.enable()
                    self?.continueBtn.setTitle("Resend", for: .normal)
                    timer.invalidate()
                    
                    self?.navigationItem.hidesBackButton = false
                    
                } else if let seconds = self?.timeoutSeconds {
                    // disable and show counter
                    self?.continueBtn.disable()
                    // codes needed for prevent flashing
                    UIView.setAnimationsEnabled(false)
                    self?.continueBtn.layoutIfNeeded()
                    self?.continueBtn.setTitle("Resend (\(seconds))", for: .disabled)
                    UIView.setAnimationsEnabled(false)
                    
                    // to block ui from moving
                    self?.navigationItem.hidesBackButton = true
                }
            }
        }

        deinit {
            // ViewController going away.  Kill the timer.
            otpTimer?.invalidate()
        }
    
    /******************************************************** ************************************************/
    
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        print("did change verify")
        
        // this one fires when otp is filled automatically
        // the code that is set is 6 digit
        if let code = textField.text{
            
            // if it is 6 then auto, if not, manual
            // spilit the code
            
            if code.count==6{
                let codes = code.map{
                    String($0)
                }
                
                // set one digit to each field
                otpTF.text = codes[0]
                otp2TF.text = codes[1]
                
                otp3TF.text = codes[2]
                otp4TF.text = codes[3]
                
                otp5TF.text = codes[4]
                otp6TF.text = codes[5]
                // it was the first responder here
                otpTF.resignFirstResponder()
            }else{
                // this code must be one digit
                // keep showing error label
                errorL.isHidden = false
                // check the responder and move the focus
                if otpTF.isFirstResponder{
                    if let singleCode = textField.text, singleCode.count == 1{
                        otp2TF.becomeFirstResponder()
                    }
                    
                }else if otp2TF.isFirstResponder{
                    if let singleCode = textField.text, singleCode.count == 1{
                        otp3TF.becomeFirstResponder()
                    }else{
                        otpTF.becomeFirstResponder()
                    }
                    
                }else if otp3TF.isFirstResponder{
                    
                    if let singleCode = textField.text, singleCode.count == 1{
                        otp4TF.becomeFirstResponder()
                    }else{
                        otp2TF.becomeFirstResponder()
                    }
                    
                }else if otp4TF.isFirstResponder{
                    if let singleCode = textField.text, singleCode.count == 1{
                        otp5TF.becomeFirstResponder()
                        
                    }else{
                        otp3TF.becomeFirstResponder()
                    }
                   
                    
                }else if otp5TF.isFirstResponder{
                    if let singleCode = textField.text, singleCode.count == 1{
                        otp6TF.becomeFirstResponder()
                    }else{
                        otp4TF.becomeFirstResponder()
                    }
                  
                }else {
                    if let singleCode = textField.text, singleCode.count == 1{
                            otp6TF.resignFirstResponder()
                        
                    }else{
                        otp5TF.becomeFirstResponder()
                    }
                }
                
                
                
                
            } // end of code count not 6
            
            if let code1 = otpTF.text, let code2 = otp2TF.text, let code3 = otp3TF.text, let code4 = otp4TF.text, let code5 = otp5TF.text, let code6 = otp6TF.text{
                // check if all good
                let valid = code1.count + code2.count + code3.count + code4.count + code5.count + code6.count == 6
                
                // hide or show error?
                // depends on valid
                errorL.isHidden = valid
                
                if valid{
                    continueBtn.enable()
                    // save the one time pass
                    oneTimePass = code1+code2+code3+code4+code5+code6;
                    // stop the timer
                    otpTimer?.invalidate()
                    // change the text to continue
                    continueBtn.setTitle("Continue", for: .normal)
                    
                    
                }else{
                    continueBtn.disable()
                    otpTimer?.invalidate()
                    startCountdown()
                }
                
            }
            
        } // end of if let code
        // this block fires when we delete all text field, it immediately disables the continue button
        else{
            // if any of those TF has no number, disable continue
            continueBtn.disable()
            otpTimer?.invalidate()
            startCountdown()
        }
        
    }
    
    /******************************************************** ************************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Confirmation"
        setupUI()
        

    }
    

}
