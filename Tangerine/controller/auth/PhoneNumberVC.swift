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
    
    // MARK: UI Items
    var isEditingProfile = false
    // to detect if it is auto filled
    var isAutoFilled = false
    
    // to hide or show based on calling from where
    var pageControl: UIPageControl!
    var editingBackButton: UIButton! // when editing mode is active
    
    
    var topLabel: UILabel!
    var numberStack: UIStackView!
    var firstThreeDigitTF: UITextField!
    var secondThreeDigitTF: UITextField!
    var lastFourDigitTF: UITextField!
    
    
    
    var errorLabel: UILabel!
    
    var continueButton: ContinueButton!
    
    var phoneNumber = ""
    
    // MARK: Actions
    
    @objc func editingBackTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func onInfoClicked() {
        presentDismissAlertOnMainThread(title: "Info", message: "We will never sell or distribute any of your contact information")
    }
    
    
    @objc func onContinueClick() {
        // sendVerification
        print(phoneNumber.count)
        if phoneNumber.count == 12{
            print("Continue Clicked")
            sendVerificationCode(phoneNumber)
        }
        
    }
    
    
    // Additional Setup on the UI
    func setupUI(){

        showError()
        
        
        //dismiss keyboard, call the extension
        hideKeyboardOnOutsideTouch()
        
        // set the delegate to change keyboard focus
        firstThreeDigitTF.delegate = self
        secondThreeDigitTF.delegate = self
        lastFourDigitTF.delegate = self
        
        firstThreeDigitTF.becomeFirstResponder()
        
        
        // WHEN EDITING PROFILE
        // hide the page control and show the editing backbutton
        
        if isEditingProfile {
            editingBackButton.isHidden = false
            pageControl.isHidden = true
        }else{
            editingBackButton.isHidden = true
            pageControl.isHidden = false
        }
        
        
    }
    // to show error
    func showError(){
        print("show error")
        errorLabel.isHidden = false
        continueButton.disable()
    }// end of show error
    
    // to hide error
    func hideError(){
        print("hide error")
        errorLabel.isHidden = true
        continueButton.enable()
        
    }// end of hide error
    
    
    // send user verification code
    func sendVerificationCode(_ number: String){
        // show the loader
        view.showActivityIndicator()
        // start verifying, send sms here
        PhoneAuthProvider.provider().verifyPhoneNumber(number, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                self.presentDismissAlertOnMainThread(title: "Auth Error", message: error.localizedDescription)
                print("error occured when attempting to sendVerificationCode in PhoneNumberVC. Error: \(error).")
                self.view.hideActivityIndicator()
                return
              }
            
            // save the verification ID as we are moving from here
            // save the phone so we can show it next screen
            UserDefaults.standard.setValue(verificationID, forKey: Constants.VERIFICATION_ID)
            // stop the loading indicator
            self.view.hideActivityIndicator()
            
            // pass the number
            ConfirmationVC.usernumber = number
            // if we are editing number, prepare these data
            
            if self.isEditingProfile {
                
                ConfirmationVC.isEditingProfile = true
                
                
                
                // move to OTP
                let vc = ConfirmationVC()
                vc.modalPresentationStyle = .fullScreen
                
                // We want to dismiss this and go to next  vc
                let parentvc = self.presentingViewController
               
                self.dismiss(animated: false, completion: {
                    parentvc!.present(vc, animated: true, completion: nil)
                })
                
                
                
                
                
            }else{
                // move to OTP
                let vc = ConfirmationVC()
                vc.modalPresentationStyle = .fullScreen
                //self.present(vc, animated: true, completion: nil)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
            
            
            
        }
    }// end of send verification code
    
    // MARK: Delegates
    
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

                firstThreeDigitTF.text = formattedNumber.subString(from: 0, to: 3)
                secondThreeDigitTF.text = formattedNumber.subString(from: 3, to: 6)
                lastFourDigitTF.text = formattedNumber.subString(from: 6, to: 10)
                textField.resignFirstResponder()
                isAutoFilled = false
            }
            
            
            
        }else{
            
            // we're also making some checks if user types more than they allowed to
            // if they do, we discard it
            
            // user manually typed
            if firstThreeDigitTF.isFirstResponder {
                if let text = textField.text{
                    
                    if text.count == 3{
                        secondThreeDigitTF.becomeFirstResponder()
                    }else if text.count > 3{
                        firstThreeDigitTF.text = text.subString(from: 0, to: 3)
                        secondThreeDigitTF.becomeFirstResponder()
                    }
                }
            }
            
            else if secondThreeDigitTF.isFirstResponder {
                if let text = textField.text{
                    if text.count == 3{
                        lastFourDigitTF.becomeFirstResponder()
                    }else if text.count > 3{
                        secondThreeDigitTF.text = text.subString(from: 0, to: 3)
                        lastFourDigitTF.becomeFirstResponder()
                    }else if text.count == 0{
                        // when second box is empty move to first box
                        firstThreeDigitTF.becomeFirstResponder()
                    }
                }
            }
            
            else{
                
                if let text = textField.text{
                    
                    if text.count == 4{
                        lastFourDigitTF.resignFirstResponder()
                    }else if text.count > 4 {
                        lastFourDigitTF.text = text.subString(from: 0, to: 4)
                        lastFourDigitTF.resignFirstResponder()
                    }else if text.count == 0{
                        // when third box is empty, move to second box
                        secondThreeDigitTF.becomeFirstResponder()
                    }
                    
                    
                }
            }
            
        } //end of else
       
        
        
        // at any given moment of text change, check the length of phone
        if let phone1Digits = firstThreeDigitTF.text, let phone2Digits = secondThreeDigitTF.text, let phone3Digits = lastFourDigitTF.text{
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
    
    
    
    // MARK: VC Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // name will suggest what they do
        view.backgroundColor = .systemBackground
        title = "Phone Number"
        
        
        // one by one, create the UI
        
        configureBackButton()
        
        configureTopLabel()
    
        configureStackForNumbers()
        
        configureErrorLabel()
        
        configureContinueButton()
        
        configurePageControl()
        
        // setup the UI
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
        topLabel.text = "Enter Phone Number"
        // to make it dark/light friendly
        topLabel.textColor = .label
        topLabel.numberOfLines = 2
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
    
    // for the next function, returns a UILabel with a dash on it
    public func makeADash()-> UILabel{
        let dash = UILabel()
        dash.text = "-"
        dash.textColor = .label
        dash.font = UIFont.systemFont(ofSize: 17)
        return dash
    }
    
   
    func configureStackForNumbers(){
        // the stack that holds the boxes
        numberStack = UIStackView()
        numberStack.axis = .horizontal
        numberStack.alignment = .fill
        numberStack.distribution = .fillProportionally
        numberStack.spacing = 5
        numberStack.contentMode = .scaleToFill
        
        view.addSubview(numberStack)
        
        
        // one static label
        let plusOneLabel = UILabel()
        plusOneLabel.text = "+1"
        plusOneLabel.textColor = .label
        plusOneLabel.font = UIFont.systemFont(ofSize: 17)
        
        // add the dash via method call
        
        // first three digit
        firstThreeDigitTF = UITextField()
        firstThreeDigitTF.textColor = .label
        firstThreeDigitTF.font = UIFont.systemFont(ofSize: 14)
        firstThreeDigitTF.textAlignment = .center
        firstThreeDigitTF.placeholder = "xxx"
        firstThreeDigitTF.borderStyle = .roundedRect
        firstThreeDigitTF.textContentType = .telephoneNumber
        firstThreeDigitTF.keyboardType = .phonePad
        firstThreeDigitTF.autocapitalizationType = .none
        
        // second three digit
        secondThreeDigitTF = UITextField()
        secondThreeDigitTF.textColor = .label
        secondThreeDigitTF.font = UIFont.systemFont(ofSize: 14)
        secondThreeDigitTF.textAlignment = .center
        secondThreeDigitTF.placeholder = "xxx"
        secondThreeDigitTF.borderStyle = .roundedRect
        secondThreeDigitTF.textContentType = .telephoneNumber
        secondThreeDigitTF.keyboardType = .phonePad
        secondThreeDigitTF.autocapitalizationType = .none
        
        // last four digit
        lastFourDigitTF = UITextField()
        lastFourDigitTF.textColor = .label
        lastFourDigitTF.font = UIFont.systemFont(ofSize: 14)
        lastFourDigitTF.textAlignment = .center
        lastFourDigitTF.placeholder = "xxxx"
        lastFourDigitTF.borderStyle = .roundedRect
        lastFourDigitTF.textContentType = .telephoneNumber
        lastFourDigitTF.keyboardType = .phonePad
        lastFourDigitTF.autocapitalizationType = .none
        
        // the info button
        let infoButton = UIButton(type: .custom)
        infoButton.tintColor = .systemBlue
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.backgroundColor = .systemBackground
        
        infoButton.addTarget(self, action: #selector(onInfoClicked), for: .touchUpInside)
        
        numberStack.addArrangedSubview(plusOneLabel)
        numberStack.addArrangedSubview(makeADash())
        numberStack.addArrangedSubview(firstThreeDigitTF)
        numberStack.addArrangedSubview(makeADash())
        numberStack.addArrangedSubview(secondThreeDigitTF)
        numberStack.addArrangedSubview(makeADash())
        numberStack.addArrangedSubview(lastFourDigitTF)
        numberStack.addArrangedSubview(infoButton)
        
        
        numberStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            numberStack.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 20),
            numberStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            numberStack.heightAnchor.constraint(equalToConstant: 50),
            firstThreeDigitTF.heightAnchor.constraint(equalToConstant: 50),
            secondThreeDigitTF.heightAnchor.constraint(equalToConstant: 50),
            lastFourDigitTF.heightAnchor.constraint(equalToConstant: 50),
        ])
    }// end conf stack
    
    
    func configureErrorLabel(){
        errorLabel = UILabel()
        errorLabel.text = "Enter a valid US mobile phone number"
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 2
        errorLabel.textAlignment = .center
        errorLabel.font = UIFont.systemFont(ofSize: 17)
        view.addSubview(errorLabel)
        
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            errorLabel.heightAnchor.constraint(equalToConstant: 30),
            errorLabel.topAnchor.constraint(equalTo: numberStack.bottomAnchor, constant: 25),
            errorLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
    } // end conf errorLabel
    
    
    func configureContinueButton(){
        continueButton = ContinueButton(title: "Continue")
        
        view.addSubview(continueButton)
        
        continueButton.addTarget(self, action: #selector(onContinueClick), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100)
        ])
        
    }// end conf continue button
    
    func configurePageControl(){
        pageControl = UIPageControl()
        pageControl.numberOfPages = 6
        pageControl.currentPage = 2
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
