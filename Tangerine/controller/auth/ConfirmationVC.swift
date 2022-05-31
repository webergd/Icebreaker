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
    
    // MARK: UI Items
    var pageControl: UIPageControl!
    
    var editingBackButton: UIButton!
    
    var topLabel: UILabel!
    var descL: UILabel!
    
    var otpTF: UITextField!
    var errorLabel: UILabel!
    
    var continueButton: ContinueButton!
    
    // our final var for OTP
    var oneTimePass = ""
    
    // otp time count
    var otpTimer: Timer?
    // didn't find firebase default, so being safe
    var timeoutSeconds = 60
    
    // MARK: Actions
    
    @objc func editingBackTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func continueBtnClicked(_ sender: Any) {
        
        // check if resend or not
        if continueButton.titleLabel?.text == "Resend"{
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
        
        continueButton.disable()
        
        // set the delegate to check and move focus
        otpTF.delegate = self
        // make it first responder
        otpTF.becomeFirstResponder()
        
        
        // set the number to label as per doc format
        
            //\(number[5..<8])-\(number[8..<number.count])
            descL.text = "Enter the code we sent to (\(ConfirmationVC.usernumber.subString(from: 2, to: 5))) \(ConfirmationVC.usernumber.subString(from: 5, to: 8))-\(ConfirmationVC.usernumber.subString(from: 8, to: ConfirmationVC.usernumber.count))"
        
        
        //dismiss keyboard, call the extension
        hideKeyboardOnOutsideTouch()
        
        
        // WHEN EDITING PROFILE
        // hide the page control and show the editing backbutton
        
        if ConfirmationVC.isEditingProfile {
            editingBackButton.isHidden = false
            pageControl.isHidden = true
        }else{
            editingBackButton.isHidden = true
            pageControl.isHidden = false
        }
        
        // start the countdown
        startCountdown()
        
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
        view.showActivityIndicator()
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
                        self.view.hideActivityIndicator()
                        // reset and restart countdown
                        self.timeoutSeconds = 60
                        self.startCountdown()
                        return
                    }
                    
                    self.view.hideActivityIndicator()
                    
                    // dismiss this view and present previous view
                    // set the value of firestore and local before that
                    
                    // when editing the displayname will never be null
                    // also we just added the phone and checked for error, it won't be null either
                    Firestore.firestore().collection(Constants.USERS_COLLECTION).document(user.displayName!).setData([Constants.USER_NUMBER_KEY:user.phoneNumber!], merge: true){ (error) in
                        
                        if let error = error{
                            self.presentDismissAlertOnMainThread(title: "Update Failed", message: error.localizedDescription)
                            // reset and restart countdown
                            self.timeoutSeconds = 60
                            self.startCountdown()
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
                        // TODO: Implement go back to editProfileVc
                    } // end of firebase call
                    
                    
                }
                
            }else{
                // new signup
                
                user.link(with: credential) { (result, error) in
                    
                    // show the error if any
                    if let err = error{
                        self.presentDismissAlertOnMainThread(title: "Verification Failed", message: err.localizedDescription)
                        print(err.localizedDescription)
                        self.view.hideActivityIndicator()
                        // reset and restart countdown
                        self.timeoutSeconds = 60
                        self.startCountdown()
                        return
                    }
                    
                    self.view.hideActivityIndicator()
                    // move to next screen
                    let vc = BirthdayVC()
                    vc.modalPresentationStyle = .fullScreen
                    //self.present(vc, animated: true, completion: nil)
                    self.navigationController?.pushViewController(vc, animated: true)
                    
                }// end of user link
            } // end of else of if isEditingProfile

         
            
        } // end of if let
    }
    
    func resendOTP(){
        // show the loader
        view.showActivityIndicator()
        print("Resending \(ConfirmationVC.usernumber)")
        // start verifying, send sms here
        PhoneAuthProvider.provider().verifyPhoneNumber(ConfirmationVC.usernumber, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                self.presentDismissAlertOnMainThread(title: "Auth Error", message: error.localizedDescription)
                self.view.hideActivityIndicator()
                return
              }
            
            // save the verification ID as we are moving from here
            // save the phone so we can show it next screen
            UserDefaults.standard.setValue(verificationID, forKey: Constants.VERIFICATION_ID)
            
            // stop the loading indicator
            self.view.hideActivityIndicator()
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
                    self?.continueButton.enable()
                    self?.continueButton.setTitle("Resend", for: .normal)
                    timer.invalidate()
                    
                    self?.navigationItem.hidesBackButton = false
                    
                } else if let seconds = self?.timeoutSeconds {
                    // disable and show counter
                    self?.continueButton.disable()
                    // codes needed for prevent flashing
                    UIView.setAnimationsEnabled(false)
                    self?.continueButton.layoutIfNeeded()
                    self?.continueButton.setTitle("Resend (\(seconds))", for: .disabled)
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
    
    // MARK: Delegates
    
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        print("did change verify")
        
        // this one fires when otp is filled automatically
        // the code that is set is 6 digit
        if let code = textField.text{
            
            // if it is 6 then auto, if not, manual
            // spilit the code
            
            if code.count==6{
                // set digits to field
                otpTF.text = code
                // it was the first responder here
                otpTF.resignFirstResponder()
            }else{
                // this code must be one digit
                // keep showing error label
                errorLabel.isHidden = false
                  
                }// end of code count not 6
                
            
            if let otpCode = otpTF.text{
                // check if all good
                let valid = otpCode.count == 6
                
                // hide or show error?
                // depends on valid
                errorLabel.isHidden = valid
                
                if valid{
                    continueButton.enable()
                    // save the one time pass
                    oneTimePass = otpCode
                    // stop the timer
                    otpTimer?.invalidate()
                    // change the text to continue
                    continueButton.setTitle("Continue", for: .normal)
                    
                    
                }else{
                    continueButton.disable()
                    otpTimer?.invalidate()
                    startCountdown()
                }
                
            }
            
        } // end of if let code
        // this block fires when we delete all text field, it immediately disables the continue button
        else{
            // if any of those TF has no number, disable continue
            continueButton.disable()
            otpTimer?.invalidate()
            startCountdown()
        }
        
    }
    
    // MARK: VC Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // name will suggest what they do
        view.backgroundColor = .systemBackground
        title = "Confirmation"
        
        configureBackButton()
        
        configureTopLabel()
        configureDescLabel()
        
        configureOtpTF()
        
        configureErrorLabel()
        
        configureContinueButton()
        
        configurePageControl()
        
        setupUI()
        

    }
    
    // MARK: PROGRAMMATIC UI
    
    func configureBackButton(){
        
        editingBackButton = UIButton()
        editingBackButton.setTitle("Back", for: .normal)
        editingBackButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        editingBackButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        
        editingBackButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(editingBackButton)
        
        NSLayoutConstraint.activate([
            editingBackButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editingBackButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        editingBackButton.addTarget(self, action: #selector(editingBackTapped), for: .touchUpInside)
        
    }
    
    func configureTopLabel(){
        topLabel = UILabel()
        topLabel.text = "Enter Confirmation Code"
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
    
    func configureDescLabel(){
        descL = UILabel()
        descL.text = ""
        descL.numberOfLines = 3
        // to make it dark/light friendly
        descL.textColor = .label
        descL.textAlignment = .center
        descL.font = UIFont.systemFont(ofSize: 17)
        view.addSubview(descL)
        
        descL.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            descL.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 10),
            descL.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            descL.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
        ])
        
    } // end conf descLabel
    
    func configureOtpTF(){
        
        otpTF = UITextField()
        otpTF.textColor = .label
        otpTF.font = UIFont.systemFont(ofSize: 16)
        otpTF.textAlignment = .center
        otpTF.placeholder = "xxxxxx"
        otpTF.borderStyle = .roundedRect
        otpTF.textContentType = .oneTimeCode
        otpTF.keyboardType = .numberPad
        otpTF.autocapitalizationType = .none
        
        view.addSubview(otpTF)
        otpTF.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            otpTF.heightAnchor.constraint(equalToConstant: 50),
            otpTF.topAnchor.constraint(equalTo: descL.bottomAnchor, constant: 50),
            otpTF.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            otpTF.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50)
        ])
    } // end otp tf
    
    func configureErrorLabel(){
        errorLabel = UILabel()
        errorLabel.text = "That's not the right code!"
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 2
        errorLabel.textAlignment = .center
        errorLabel.font = UIFont.systemFont(ofSize: 17)
        view.addSubview(errorLabel)
        
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            errorLabel.heightAnchor.constraint(equalToConstant: 30),
            errorLabel.topAnchor.constraint(equalTo: otpTF.bottomAnchor, constant: 20),
            errorLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
    } // end conf errorLabel
    
    func configureContinueButton(){
        continueButton = ContinueButton(title: "Continue")
        
        view.addSubview(continueButton)
        
        continueButton.addTarget(self, action: #selector(continueBtnClicked), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100)
        ])
        
    }// end conf continue button

    
    func configurePageControl(){
        pageControl = UIPageControl()
        pageControl.numberOfPages = 6
        pageControl.currentPage = 3
        pageControl.pageIndicatorTintColor = .systemGray
        pageControl.currentPageIndicatorTintColor = .systemOrange
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)
        
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            pageControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            
        ])
    }
}
