//
//  ReAuthConfirmationVC.swift
//  Tangerine
//
//  Created by Mahmudul Hasan on 2022-02-19.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import RealmSwift

class ReAuthConfirmationVC: UIViewController, UITextFieldDelegate {

    
    // MARK: UI Items
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
    static var usernumber = ""
    // MARK: Actions
    
    @objc func continueBtnClicked(_ sender: Any) {
        
        // check if resend or not
        if continueButton.titleLabel?.text == "Resend"{
            resendOTP()
        }else{
            // verify again if it is 6 digit
            if oneTimePass.count==6{
                verifyNumber(oneTimePass)
            }
        }

    } // end continueClicked
    
    func setupUI(){
        // let's customize our only button
        continueButton.disable()
        
        // set the delegate to check and move focus
        otpTF.delegate = self
        // make it first responder
        otpTF.becomeFirstResponder()
        
        
        // set the number to label as per doc format
        
            //\(number[5..<8])-\(number[8..<number.count])
            descL.text = "Enter the code we sent to (\(ReAuthConfirmationVC.usernumber.subString(from: 2, to: 5))) \(ReAuthConfirmationVC.usernumber.subString(from: 5, to: 8))-\(ReAuthConfirmationVC.usernumber.subString(from: 8, to: ReAuthConfirmationVC.usernumber.count))"
        
        
        //dismiss keyboard, call the extension
        hideKeyboardOnOutsideTouch()
        
        
        // start the countdown
        startCountdown()
        
    } // end setup UI
    
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
        
        // sign in the user to see if it's valid
        Auth.auth().signIn(with: credential) { result, error in
            // hide the indicator not matter what
            defer{
                self.view.hideActivityIndicator()
            }
            
            if let error = error{
                self.presentDismissAlertOnMainThread(title: "Auth Error", message: error.localizedDescription)
                // reset and restart countdown
                self.timeoutSeconds = 60
                self.startCountdown()
                return
            }
            
            // we have a user
            if let result = result {
                let user = result.user
                
                let vc = PasswordResetViewController()
                vc.modalPresentationStyle = .fullScreen
                vc.user = user
                
                self.navigationController?.pushViewController(vc, animated: true)
                
            }
            
        }
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
                
            } // end of code count not 6
            
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
        
        configureTopLabel()
        configureDescLabel()
        
        configureOtpTF()
        
        configureErrorLabel()
        
        configureContinueButton()
        
        setupUI()
    }
    
    // MARK: PROGRAMMATIC UI
    
    // MARK: TopLabel
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

    
    // MARK: DescLabel
    
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

    // MARK: OTP TF
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
    
    // MARK: ErrorLabel
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
    
    // MARK: ContinueButton
    func configureContinueButton(){
        continueButton = ContinueButton(title: "Continue")
        
        view.addSubview(continueButton)
        
        continueButton.addTarget(self, action: #selector(continueBtnClicked), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100)
        ])
        
    }// end conf continue button
}
