//
//  SpecialtyVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-18.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase

class SpecialtyVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    
    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - Delegates
     - View Controller methods
     */
    /******************************************************************************************************************************/

    
    @IBOutlet weak var specialtyPicker: UIPickerView!
    @IBOutlet weak var specialtyL: UITextField!
    @IBOutlet weak var finishBtn: UIButton!
    
    // the loading
    var indicator: UIActivityIndicatorView!
    
    let options = Constants.ORIENTATIONS
    /******************************************************************************************************************************/
    
    @IBAction func onFinishClicked(_ sender: UIButton) {
        print("finish")
        //already checked the specialty
        saveSpecialtyToFirestore()
    }
    

    
    /******************************************************************************************************************************/
    
    func saveSpecialtyToFirestore(){
        // this username is still valid, although we can take from Auth.auth().user.displayname
        
        let db = Firestore.firestore()
        indicator.startAnimating()
        if let spe = specialtyL.text{
            
            // the default target demo for firestore
            let target_demo = [
                Constants.UD_ST_WOMAN_Bool : false,
                Constants.UD_ST_MAN_Bool : false,
                Constants.UD_GWOMAN_Bool : false,
                Constants.UD_GMAN_Bool : false,
                Constants.UD_OTHER_Bool : false,
                Constants.UD_MIN_AGE_INT : 18,
                Constants.UD_MAX_AGE_INT : 99
            ] as [String : Any]
            
            
                // save default target demo
                db
                .collection(Constants.USERS_COLLECTION)
                .document(Constants.username)
                .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
                    .document(Constants.USERS_PRIVATE_INFO_DOC).setData([Constants.USER_TD_KEY: target_demo],merge: true){ err in
                        if let err = err{
                            self.presentDismissAlertOnMainThread(title: "Server Error", message: err.localizedDescription)
                            self.indicator.stopAnimating() 
                            return
                        }
                        // save the specialty now
                        db
                        .collection(Constants.USERS_COLLECTION)
                        .document(Constants.username).setData(
                        [Constants.USER_ORIENTATION_KEY: spe,
                         Constants.USER_RATING_KEY: 0,
                         Constants.USER_REVIEW_KEY: 0], merge: true) { (error) in
                        if let err = error{
                            self.presentDismissAlertOnMainThread(title: "Server Error", message: err.localizedDescription)
                            self.indicator.stopAnimating()
                            return
                        }
                        // move to next seague
                        self.indicator.stopAnimating()
                        // all done, move to welcome
                        
                       
                        // save that signup done
                        UserDefaults.standard.setValue(true, forKey: Constants.UD_SIGNUP_DONE_Bool)
                        
                        Database.database().reference().child("usernames").child(Constants.username).setValue(Constants.username)
                             
                             
                        // clear the temp username
                        Constants.username = ""
                        
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "welcome_vc") as! WelcomeVC
                        vc.modalPresentationStyle = .fullScreen
                        
                        self.present(vc, animated: true, completion: nil)
                        
                        
                    }// end of saving specialty
                        
                        
                        
                        
                    } // end of saving in sub collection
            

        }// end of if let spe
        
    } // end of saveSpecialtyToFirebase
    
    // to show the loading
    func setupIndicator() {
        indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        indicator.center = view.center
        view.addSubview(indicator)
        indicator.bringSubviewToFront(view)
    }
    /******************************************************************************************************************************/
    
    // number of "wheels" actually, how many values there will be
    // we have only name
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // how many items will there be in one wheel
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
    
    // this sets title for each row of each wheel
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return options[row]
    }
    
    // which row is selected from which component
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("\(row) \(component)")
        specialtyL.text = options[row]
        finishBtn.enable()
    }
    
    /******************************************************************************************************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Orientation"
        
        // style the finish button
        finishBtn.layer.borderWidth = 2.0
        finishBtn.layer.cornerRadius = 6.0
        finishBtn.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        finishBtn.disable()
        
        
        // set specialty delegate and datasource
        specialtyPicker.delegate = self
        specialtyPicker.dataSource = self
        
        // set a placeholder
        specialtyL.text = "Select One"
        
        setupIndicator()
        
    }
    


}
