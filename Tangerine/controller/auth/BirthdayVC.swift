//
//  BirthdayVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-18.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class BirthdayVC: UIViewController, UIPickerViewDelegate {
    
    // MARK: UI Items
    
    // outlets, we don't let user edit the bday field manually
    var birthdayTF: UITextField!
    var continueButton: UIButton!
    var datePicker: UIDatePicker!
    
    // to store the bday for query
    var birthdayTimestamp: Double!
    
    var topLabel: UILabel!
    var descL: UILabel!
    
    // MARK: Actions
    
    @objc func onContinueClicked() {
        
        // check the date
        let cal = Calendar.current
        let minimumBDay = cal.date(byAdding: .year, value: -18, to: Date())
        
        
        if let validMinimumDate = minimumBDay{
            let result: ComparisonResult = datePicker.date.compare(validMinimumDate)
            print(result.rawValue)
            if result == .orderedDescending || result == .orderedSame{
                print("Invalid")
                presentDismissAlertOnMainThread(title: "Invalid Birthday", message: "Tangerine is currently only available to adults 18 and older.")
                return
            }else{
                print("Valid")
                // save the bday and move to next page

                saveBirthdayToFirestore()
            }
        }
        
    }
    
    
    @objc func onDateChanged() {
        // set the date to TF
        setDateString(datePicker)
        // enable the continue button
        continueButton.enable()
    }
    
    
    func setupUI(){
        continueButton.disable()
        
        // hides the back button from this VC so that user cannot return to validation code entry
        self.navigationItem.setHidesBackButton(true, animated: true)

        datePicker.addTarget(self, action: #selector(onDateChanged), for: .valueChanged)
        
        
    }


    // this function sets the date to textfield
    func setDateString(_ sender: UIDatePicker){
        let formatter = DateFormatter()
        
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        birthdayTF.text = formatter.string(from: sender.date)
        birthdayTimestamp = sender.date.timeIntervalSince1970
        
    }
    
    // this saves the bday to firestore now
    func saveBirthdayToFirestore(){
        
        
        // this username is still valid, although we can take from Auth.auth().user.displayname
        view.showActivityIndicator()
        if let _ = birthdayTF.text{
            Firestore.firestore().collection(Constants.USERS_COLLECTION).document(Constants.username).setData(
                [Constants.USER_BIRTHDAY_KEY: birthdayTimestamp as Any,
                 Constants.USER_NUMBER_KEY: Auth.auth().currentUser?.phoneNumber ?? "0",// user is still authenticated, so it won't never be null
                 Constants.USER_DNAME_KEY: Auth.auth().currentUser?.displayName ?? "guest"
                ], merge: true) { (error) in
                if let err = error{
                    self.presentDismissAlertOnMainThread(title: "Server Error", message: err.localizedDescription)
                    return
                }
                // move to next seague
                    self.view.hideActivityIndicator()
                    // move to next screen
                    let vc = OrientationVC()
                    vc.modalPresentationStyle = .fullScreen
                    //self.present(vc, animated: true, completion: nil)
                    self.navigationController?.pushViewController(vc, animated: true)
                
            }
        }else{
            presentDismissAlertOnMainThread(title: "Birthday Error", message: "Birthday not set, select again")
        }
        
    }
    
    
    // MARK: Delegates
    
    
    // MARK: VC Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // proUI
        configurePageControl()
        configureTopLabel()
        configureDescLabel()
        configureBirthdayTF()
        configureDatePicker()
        configureContinueButton()
        
        // Do any additional setup after loading the view.
        setupUI()
    }
    

    
    // MARK: PROGRAMMATIC UI
    
    func configureTopLabel(){
        topLabel = UILabel()
        topLabel.text = "When's your birthday?"
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
        descL.text = "User must be 18 years of age to sign up"
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
    
    func configureBirthdayTF(){
        birthdayTF = UITextField()
        birthdayTF.textColor = .label
        birthdayTF.font = UIFont.systemFont(ofSize: 14)
        birthdayTF.borderStyle = .roundedRect
        birthdayTF.textAlignment = .center
        
        
        birthdayTF.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(birthdayTF)
        
        NSLayoutConstraint.activate([
            birthdayTF.topAnchor.constraint(equalTo: descL.bottomAnchor, constant: 20),
            birthdayTF.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            birthdayTF.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
        ])
    }
    
    func configureDatePicker(){
        datePicker = UIDatePicker()
        
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        } else {
            // Fallback on earlier versions
        }
        datePicker.datePickerMode = .date
        
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            datePicker.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            datePicker.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
        ])
    }
    
    func configureContinueButton(){
        continueButton = ContinueButton(title: "Continue")
        
        view.addSubview(continueButton)
        
        continueButton.addTarget(self, action: #selector(onContinueClicked), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.bottomAnchor.constraint(equalTo: datePicker.topAnchor, constant: -40)
            ])
        
    }// end conf continue button
    
    func configurePageControl(){
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 6
        pageControl.currentPage = 4
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
