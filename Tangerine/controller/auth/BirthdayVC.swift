//
//  BirthdayVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-18.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class BirthdayVC: UIViewController {
    
    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - Delegates
     - View Controller methods
     */
    /******************************************************************************************************************************/
    // outlets, we don't let user edit the bday field manually
    @IBOutlet weak var birthdayTF: UITextField!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    // the loading
    var indicator: UIActivityIndicatorView!
    // to store the bday for query
    var birthdayTimestamp: Double!
    
    /******************************************************************************************************************************/
    
    @IBAction func onContinueClicked(_ sender: UIButton) {
        // save the bday and move to next page
        saveBirthdayToFirestore()
    }
    
    
    @IBAction func onDateChanged(_ sender: UIDatePicker) {
        // set the date to TF
        setDateString(sender)
        // enable the continue button
        continueBtn.enable()
    }
    
    /******************************************************************************************************************************/
    
    func setupUI(){
        // let's customize our only button
        continueBtn.layer.borderWidth = 2.0
        continueBtn.layer.cornerRadius = 6.0
        continueBtn.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        continueBtn.disable()
        // set the indicator
        setupIndicator()
        
        // set the date 18 years before
        let cal = Calendar.current
        let past = cal.date(byAdding: .year, value: -18, to: Date())
        
        if let date = past{
            // past date set
            datePicker.maximumDate = date
            datePicker.setDate(date, animated: true)
            // set the TF as well, so at start we can see the date
            setDateString(datePicker)
        }
      
        
    }


    // this function sets the date to textfield
    func setDateString(_ sender: UIDatePicker){
        let formatter = DateFormatter()
        
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        birthdayTF.text = formatter.string(from: sender.date)
        birthdayTimestamp = sender.date.timeIntervalSince1970
        
    }
    
    // to show the loading
    func setupIndicator() {
        indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        indicator.center = view.center
        view.addSubview(indicator)
        indicator.bringSubviewToFront(view)
        
    }
    
    // this saves the bday to firestore now
    func saveBirthdayToFirestore(){
        
        
        // this username is still valid, although we can take from Auth.auth().user.displayname
        indicator.startAnimating()
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
                self.indicator.stopAnimating()
                self.performSegue(withIdentifier: "specialty_vc", sender: self)
                
            }
        }else{
            presentDismissAlertOnMainThread(title: "Birthday Error", message: "Birthday not set, select again")
        }
        
    }
    
    /******************************************************************************************************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Birthday"
        // Do any additional setup after loading the view.
        setupUI()
    }
    


}
