//
//  UserNameVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-18.
//

import UIKit
import MaterialComponents
import FirebaseFirestore
import FirebaseAuth
import Combine

// this enum will make life easier while showing the
// availibility of username
enum UserNameStatus {
    case available
    case notAvailable
    case checking
}


class UserNameVC: UIViewController, UITextFieldDelegate,UITextViewDelegate {
    
    
    // MARK: UI Items
    var cancelButton: UIBarButtonItem!

    // Firestore
    var firestore : Firestore!
    
    // Outlets, name defines who they are
    var topLabel: UILabel! // actually the title
    var usernameTF: MDCOutlinedTextField!
    var checkAvailabilityLabel: UILabel!
    
    // suggestion labels
    var suggestionOneL: UILabel!
    var suggestionTwoL: UILabel!
    
    // the signup button
    var signupBtn: UIButton!
    // the TOS view
    var tosTV: UITextView!
    let tosUrl =  URL(string: Constants.TOS_URL)
    var pageControl: UIPageControl!
    
    // for the usernameTF
    var progressView: UIActivityIndicatorView!
    var availableTick: UIImage!
    var notAvailableCross:UIImage!
    var trailingImage:UIImageView!
    
    // var for this page
    var isUserAvailable = false
    // the selected username
    var user_name = ""
    @Published var usernameEntered = ""
    
    // MARK: Actions

    // triggers on "Check Availability" Label Click
    @objc func checkAvailabilityTapped() {
        // call the function
        checkAvailability()
    }
    
    
    // triggers on suggestionOne label click
    @objc func suggestionOneTapped() {
        print("Suggestion One")
        // set the text
        if let text = suggestionOneL.text, text.count >= 3{
            //set the suggestion text to input textfield
            usernameTF.text = text
            // check the availability of selected suggestion
            checkAvailability()
        }
    } // end of suggestion One Tapped
    
    // triggers on suggestionTwo label click
    @objc func suggestionTwoTapped() {
        print("Suggestion Two")
        // set the text
        if let text = suggestionTwoL.text, text.count >= 3{
            //set the suggestion text to input textfield
            usernameTF.text = text
            // check the availability of selected suggestion
            checkAvailability()
        }
        
    }// end of suggestion Two Tapped
    
    // triggers on signup button click
    @objc func signupTapped() {
        // we already validated username, so create it
        createUsernameInFirestore(user_name)
    }// end of func
    
    @objc func cancelTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // this function will set the trailing view of usernameTF
    func setTrailingView(for mode: UserNameStatus){
        // by default hidden, from the first call it will always have a result
        usernameTF.trailingViewMode = .always
        // check the modes
        switch mode {
        case .available:
            // do the available
            progressView.stopAnimating()
            trailingImage = UIImageView(image: availableTick)
            trailingImage.tintColor = UIColor.systemGreen
            usernameTF.trailingView = trailingImage
        case .notAvailable:
            // do the not available
            progressView.stopAnimating()
            trailingImage = UIImageView(image: notAvailableCross)
            trailingImage.tintColor = UIColor.systemRed
            usernameTF.trailingView = trailingImage
        case .checking:
            // do the checking
            usernameTF.trailingView = progressView
            progressView.startAnimating()
        }
        
    } // end of setTrailingView
    
    func showError(){
        print("show error")
        //set and hide the error text at the beggining
        usernameTF.leadingAssistiveLabel.text = "Username must contain\n* 3-10 characters\n* No spaces\n* * No invalid name"
        usernameTF.setLeadingAssistiveLabelColor(.systemRed, for: .normal)
        usernameTF.setLeadingAssistiveLabelColor(.systemRed, for: .editing)
        // also if there is error, username won't be valid, nor should the button be active
        isUserAvailable = false
        signupBtn.disable()
        
    }// end of show error
    
    func hideError(){
        print("hide error")
        //set and hide the error text at the beggining
        // isHidden not working
        usernameTF.leadingAssistiveLabel.text = ""
        
        
    }// end of hide error
    
    // this function creates and styles the Terms of Service related text
    func setTosLabel(){
        // set the tos text and attributes of tos and pp text
        let tosString = "Terms of Service"
        let ppString = "Privacy Policy"
        
        let mainString = NSMutableAttributedString(string: "By tapping Sign up & Accept, you acknowledge that you have read the \(ppString) and agree to the \(tosString).")

        let tosRange = mainString.mutableString.range(of: tosString)
        let ppRange = mainString.mutableString.range(of: ppString)

        // dummy links
        let tosURL = URL(string: "http://toslink.com")!
        let ppURL = URL(string: "http://pplink.com")!

        // we need to color those two words
        mainString.addAttribute(NSAttributedString.Key.link, value: tosURL, range: tosRange)
        mainString.addAttribute(.link, value: ppURL, range: ppRange)

        tosTV.delegate = self
        // so no cursor blinking
        mainString.endEditing()
        tosTV.attributedText = mainString
        tosTV.textColor = .label
        
    }
    

    // this function performs steps to check username
    func checkAvailability(){
        
        // check this regex, as per firebase doc
        let regex = try! NSRegularExpression(pattern: "__.*__")
        
        // other validations
      if let name = usernameTF.text, name.count >= 3, name.count <= 10, !name.contains(" "), !name.contains("/"), !name.starts(with: "."){
            let range = NSRange(location: 0, length: name.utf16.count)
            // so far good
            
            // regex first match not nil, so there is match, it's an error
            if  regex.firstMatch(in: name, options: [], range: range) != nil{
                // invalid username
                showError()
                
            }else{
                // regex is good as well
                // hide the error
                hideError()
                // hide the keyboard
                usernameTF.resignFirstResponder()
                // set the trailing icon
                setTrailingView(for: .checking)
                isUserAvailable = isUsernameAvailable(name)
            }
            
        }else{
            // not good at all
            showError()
        } // if let name end
        
    } // end of checkAvailability
    
    
    // this function check if the entered username is available on the database
    // is also sets the usernameTF's trailing view based on that
    func isUsernameAvailable(_ username: String) -> Bool {
        
        firestore.collection(FirebaseManager.shared.getUsersCollection()).document(username.lowercased()).getDocument { (docSnap, err) in
            
            if let document = docSnap, document.exists{
                print("username is already exist")
                self.isUserAvailable = false
                self.signupBtn.disable()
                self.setTrailingView(for: .notAvailable)
                
                // suggest username
                self.suggestionOneL.text = self.generateRandomWord()
                self.suggestionTwoL.text = self.generateRandomWord()
                
                // make them visible
                self.suggestionTwoL.isHidden = false
                self.suggestionOneL.isHidden = false
                
            }else{
                // document doesn't exist so move with creating it
                print("username doesn't exist")
                self.isUserAvailable = true
                self.signupBtn.enable()
                self.setTrailingView(for: .available)
                
                // make them visible
                self.suggestionTwoL.isHidden = true
                self.suggestionOneL.isHidden = true
                
                // set to local var
                self.user_name = username
            }
            
            
        } // end of firestore
        return false
    } // end of isUsernameAvailable
    
    
    // can be improved in future
    // for username suggestion
    func generateRandomWord()->String{
        // all english letter and number
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        // if user entered something, we'll suggest based on that
        if let userEntered = usernameTF.text{
            return userEntered+String((0...3).map{ _ in letters.randomElement()! })
        }
        // else, we'll suggest completely random
        // currently, it doesn't get triggered, cause we force user to type
        // at least 3 char
        
        return String((0...5).map{ _ in letters.randomElement()! })
    } // end of generateRandomWord
    
    
    // create the placeholder document for user when they click the signup button
    func createUsernameInFirestore(_ username:String){
        // we can now safely set the username
        
        // show the loading
        view.showActivityIndicator()
        
        // save the username to local variable for now
        Constants.username = username.lowercased()
    
        // create a placeholder document
        firestore.collection(FirebaseManager.shared.getUsersCollection()).document(username.lowercased()).setData([Constants.USER_CREATED_KEY: FieldValue.serverTimestamp()]) { (error) in
            
            if let err = error{
                self.presentDismissAlertOnMainThread(title: "Server Error", message: err.localizedDescription)
                return
            }else{
                // hide the indicator
                self.view.hideActivityIndicator()
                // to indicate new signup
                UserDefaults.standard.setValue(false, forKey: Constants.UD_SIGNUP_DONE_Bool)
                print("Doing signup seague")
                
                let vc = PasswordVC()
                vc.modalPresentationStyle = .fullScreen
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
            
        } // end of firestore
        
        
    }// end of createUsernameInFirestore
    
    
    // MARK: Delegates
    
    // when the text changes validate it again
    func textFieldDidChangeSelection(_ textField: UITextField) {
        print("did change")
        if let text = textField.text,text.count >= 3, !text.contains(" "){
            hideError()
        }else{
            showError()
        }
      self.usernameEntered = textField.text ?? ""
    }
    
    // when tos/pp clicked
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        // show the TOS view
      // opens safari the url provides inside the app

      if let tosUrl = tosUrl {
        openSafariVC(with: tosUrl)
      }

        return false
    }
    
    // when key from keyboard pressed : Done
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // call the function
        checkAvailability()
        return true
    }
    // MARK: VC Methods

  // to store our cancellables
  private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Username"
        view.backgroundColor = .systemBackground
        // call the proUI first
        
        configureNavItem()
        configureTopLabel()
        configureUsernameTF()
        configureCheckAvailabilityLabel()
        configureSuggestionLabels()
        configureTOSView()
        configureSignupButton()
        configurePageControl()
        
        // init the firestore
        firestore = Firestore.firestore();
        
        // set the images
        availableTick = UIImage(systemName: "checkmark.circle")
        notAvailableCross = UIImage(systemName: "xmark.circle")
        // progress view
        progressView = UIActivityIndicatorView(style: .medium)
        // to controll the helper text on this text field
        usernameTF.delegate = self
    
        // set the TOS label
        setTosLabel()
        
        // let's customize our only button
        signupBtn.layer.borderWidth = 2.0
        signupBtn.layer.cornerRadius = 6.0
        signupBtn.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        // disable, cause we haven't done the username validation yet
        signupBtn.disable()
        
        
        //dismiss keyboard, call the extension
        hideKeyboardOnOutsideTouch()


      // Combine
      $usernameEntered
        .debounce(for: .milliseconds(600), scheduler: RunLoop.main)
        .filter {
          print($0)
          return $0.count >= 3
        }
        .sink { _ in
          self.checkAvailability()
        }.store(in: &cancellables)
    }
    
    
    // overriding this function so we show the nav bar on this screen
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        print("View will appear")
        
        
        // check if user is authenticated already, if so unauth him
        // and delete the account
        // Constant.username will only be set during signup process
        
        let status = UserDefaults.standard.bool(forKey: Constants.UD_SIGNUP_DONE_Bool)
        
        
        if !status && !Constants.username.isEmpty{
        // a user is found, let's kill him
        print("Deleting temp account")
            firestore.collection(FirebaseManager.shared.getUsersCollection()).document(Constants.username).delete { (error) in
            // handle the error here
            if let error = error{
                print("Error deleting data \(error.localizedDescription)")
                
            }
            // account and storage will be deleted from function
            
        }// end of firestore call
        }
      
    } // end of view will appear
    
    
    
    // MARK: PROGRAMMATIC UI
    func configureNavItem(){
        cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        self.navigationItem.leftBarButtonItem = cancelButton
    }
    
    func configureTopLabel(){
        topLabel = UILabel()
        topLabel.text = "Pick a username"
        topLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        topLabel.textColor = .label
        
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topLabel)
        
        NSLayoutConstraint.activate([
            topLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
        ])
        
        
    }
    
    func configureUsernameTF(){
        usernameTF = MDCOutlinedTextField()
        usernameTF.textColor = .label
        usernameTF.font = UIFont.systemFont(ofSize: 14)
        usernameTF.containerRadius = 6
        usernameTF.autocapitalizationType = .none
        usernameTF.returnKeyType = .search
        usernameTF.autocorrectionType = .no
        usernameTF.textContentType = .username
        usernameTF.spellCheckingType = .no
        usernameTF.enablesReturnKeyAutomatically = true
        
        
        usernameTF.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(usernameTF)
        
        NSLayoutConstraint.activate([
            usernameTF.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 20),
            usernameTF.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 100),
            usernameTF.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -100),
        ])
    }
    
    func configureCheckAvailabilityLabel(){
        checkAvailabilityLabel = UILabel()
        checkAvailabilityLabel.text = "Check Availability"
        checkAvailabilityLabel.font = UIFont.systemFont(ofSize: 15)
        checkAvailabilityLabel.textColor = .link
        checkAvailabilityLabel.isUserInteractionEnabled = true
        checkAvailabilityLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(checkAvailabilityLabel)
        
        NSLayoutConstraint.activate([
            checkAvailabilityLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            checkAvailabilityLabel.topAnchor.constraint(equalTo: usernameTF.bottomAnchor, constant: 10),
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(checkAvailabilityTapped))
        checkAvailabilityLabel.addGestureRecognizer(tapGesture)
        
    }
    
    func configureSuggestionLabels(){
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = 20
        stackView.contentMode = .scaleToFill
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // first suggestion
        suggestionOneL = UILabel()
        suggestionOneL.font = UIFont.systemFont(ofSize: 17)
        suggestionOneL.textColor = .systemTeal
        suggestionOneL.isUserInteractionEnabled = true
        
        suggestionTwoL = UILabel()
        suggestionTwoL.font = UIFont.systemFont(ofSize: 17)
        suggestionTwoL.textColor = .systemTeal
        suggestionTwoL.isUserInteractionEnabled = true
        
        stackView.addArrangedSubview(suggestionOneL)
        stackView.addArrangedSubview(suggestionTwoL)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            stackView.topAnchor.constraint(equalTo: checkAvailabilityLabel.bottomAnchor, constant: 0)
        ])
        
        let tap1Gesture = UITapGestureRecognizer(target: self, action: #selector(suggestionOneTapped))
        suggestionOneL.addGestureRecognizer(tap1Gesture)
        let tap2Gesture = UITapGestureRecognizer(target: self, action: #selector(suggestionTwoTapped))
        suggestionTwoL.addGestureRecognizer(tap2Gesture)
        
    }
    
    func configureTOSView(){
        tosTV = UITextView()
        tosTV.textColor = .label
        tosTV.font = UIFont.systemFont(ofSize: 14)
        tosTV.dataDetectorTypes = .link
        tosTV.autocapitalizationType = .sentences
        
        tosTV.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tosTV)
        
        NSLayoutConstraint.activate([
            tosTV.heightAnchor.constraint(equalToConstant: 100),
            tosTV.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            tosTV.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50)
        ])
        
    }
    
    func configureSignupButton(){
        signupBtn = ContinueButton(title: "Sign Up & Accept")
        
        view.addSubview(signupBtn)
        signupBtn.addTarget(self, action: #selector(signupTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            signupBtn.topAnchor.constraint(equalTo: tosTV.bottomAnchor, constant: 50),
            signupBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0)
        ])
    }
    
    func configurePageControl(){
        pageControl = UIPageControl()
        pageControl.numberOfPages = 6
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .systemGray
        pageControl.currentPageIndicatorTintColor = .systemOrange
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)
        
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            pageControl.topAnchor.constraint(equalTo: signupBtn.bottomAnchor, constant: 50),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}
