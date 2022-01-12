//
//  TargetDemoVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-28.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class TargetDemoVC: UIViewController, UIDocumentPickerDelegate,UIPickerViewDataSource, UIPickerViewDelegate {

    // to determine if from isEditing
    var isEditingProfile = false
    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - Delegates
     - View Controller methods
     */
    /******************************************************************************************************************************/
    // storyboard outlets
    @IBOutlet weak var noPreferenceSw: UISwitch!
    @IBOutlet weak var dancingSw: UISwitch!     // st woman
    @IBOutlet weak var lifestyleSw: UISwitch!   // st man
    @IBOutlet weak var sportsSw: UISwitch!      // gay woman
    @IBOutlet weak var musicSw: UISwitch!       // gay man
    @IBOutlet weak var otherSw: UISwitch!
    
    @IBOutlet weak var ageRangeL: UILabel!
    @IBOutlet weak var ageRangePicker: UIPickerView!
    
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var tickBtn: UIButton!

    var minimumAge:Int = 18
    var maximumAge:Int = 99
    
    var prefs: UserDefaults!
    
    /******************************************************************************************************************************/
    // the 5 switches
    
    @IBAction func noPreferenceSwitched(_ sender: UISwitch) {
        // if on then change to default
        setDefaultState(sender.isOn)
        // a change made, so set the tickBtn visible
        tickBtn.isHidden = false
    }
    
    @IBAction func dancingSwitched(_ sender: UISwitch) {
        // set the state of no pref
        setStateOfNoPref(sender.isOn)
    }
    
    @IBAction func lifestyleSwitched(_ sender: UISwitch) {
        // set the state of no pref
        setStateOfNoPref(sender.isOn)
        
    }
    
    @IBAction func sportsSwitched(_ sender: UISwitch) {
        // set the state of no pref
        setStateOfNoPref(sender.isOn)

    }
    
    @IBAction func musicSwitched(_ sender: UISwitch) {
        // set the state of no pref
        setStateOfNoPref(sender.isOn)
    }
    
    @IBAction func otherSwitched(_ sender: UISwitch) {
        // set the state of no pref
        setStateOfNoPref(sender.isOn)

    }
    
    // the bottom two buttons
    
    @IBAction func onBackPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onTickPressed(_ sender: UIButton) {
        saveValues()
        print("Save done!")
        
        // the default target demo for firestore
        let target_demo = [
            Constants.UD_ST_WOMAN_Bool : dancingSw.isOn,
            Constants.UD_ST_MAN_Bool : lifestyleSw.isOn,
            Constants.UD_GWOMAN_Bool : sportsSw.isOn,
            Constants.UD_GMAN_Bool : musicSw.isOn,
            Constants.UD_OTHER_Bool : otherSw.isOn,
            Constants.UD_MIN_AGE_INT : minimumAge,
            Constants.UD_MAX_AGE_INT : maximumAge
        ] as [String : Any]
        
      
        // access the auth object, we saved the username as displayname
        if let user = Auth.auth().currentUser, let username = user.displayName{
            // save to target demo
            Firestore.firestore()
            .collection(Constants.USERS_COLLECTION)
            .document(username)
            .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
            .document(Constants.USERS_PRIVATE_INFO_DOC).setData([Constants.USER_TD_KEY: target_demo],merge: true){ err in
                    if let err = err{
                        self.presentDismissAlertOnMainThread(title: "Server Error", message: err.localizedDescription)
                        
                        return
                    }
                
                self.dismiss(animated: true, completion: nil)
            }
        }// end of user
        
    }
    /******************************************************************************************************************************/
    // to toggle all sw based on noPrefSw
    func setDefaultState(_ isOn: Bool){
        
        if(isOn){
            // means no pref, so turn off all sw
            dancingSw.setOn(!isOn, animated: true)
            lifestyleSw.setOn(!isOn, animated: true)
            sportsSw.setOn(!isOn, animated: true)
            musicSw.setOn(!isOn, animated: true)
            otherSw.setOn(!isOn, animated: true)

            minimumAge = 18
            maximumAge = 99

            // set the label to default
            setAgeLabel(minimumAge, maximumAge)


            // set the picker value to default
            ageRangePicker.selectRow(0, inComponent: 0, animated: true)
            ageRangePicker.selectRow(81, inComponent: 1, animated: true)

        }else{
            
            
            
            minimumAge = prefs.integer(forKey: Constants.UD_MIN_AGE_INT)
            maximumAge = prefs.integer(forKey: Constants.UD_MAX_AGE_INT)
            
            
            // with default value
            var isNoPrefEnabled = prefs.bool(forKey: Constants.UD_NO_PREF_Bool)
            var isDancingEnabled = prefs.bool(forKey: Constants.UD_ST_WOMAN_Bool)
            var isMusicEnabled = prefs.bool(forKey: Constants.UD_GMAN_Bool)
            var isLifestyleEnabled = prefs.bool(forKey: Constants.UD_ST_MAN_Bool)
            var isSportsEnabled = prefs.bool(forKey: Constants.UD_GWOMAN_Bool)
            var isOtherEnabled = prefs.bool(forKey: Constants.UD_OTHER_Bool)
            
            // access the auth object, we saved the username as displayname
            if let user = Auth.auth().currentUser, let username = user.displayName{
                // save to target demo
                Firestore.firestore()
                .collection(Constants.USERS_COLLECTION)
                .document(username)
                .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
                    .document(Constants.USERS_PRIVATE_INFO_DOC).getDocument(completion: {snapshot, err in
                        if let err = err{
                            self.presentDismissAlertOnMainThread(title: "Server Error", message: err.localizedDescription)
                            
                            return
                        }
                    
                        if let doc = snapshot?.data(){
                            // we know it exists, but firebase doesn't so it yells at us
                            let data = doc[Constants.USER_TD_KEY] as! [String : Any]
                            
                            isDancingEnabled = data[Constants.UD_ST_WOMAN_Bool] as? Bool ?? false
                            isMusicEnabled = data[Constants.UD_GMAN_Bool] as? Bool ?? false
                            isLifestyleEnabled = data[Constants.UD_ST_MAN_Bool] as? Bool ?? false
                            isSportsEnabled = data[Constants.UD_GWOMAN_Bool] as? Bool ?? false
                            isOtherEnabled = data[Constants.UD_OTHER_Bool] as? Bool ?? false
                            self.minimumAge = data[Constants.UD_MIN_AGE_INT] as? Int ?? 18
                            self.maximumAge = data[Constants.UD_MAX_AGE_INT] as? Int ?? 99
                            
                            if isDancingEnabled || isMusicEnabled || isLifestyleEnabled || isSportsEnabled || isOtherEnabled{
                                isNoPrefEnabled = false
                            }else{
                                isNoPrefEnabled = true
                            }
                            
                            
                            // MARK: These really need to be changed to the actual orientations, not the old ones
                            self.noPreferenceSw.setOn(isNoPrefEnabled, animated: true)
                            self.dancingSw.setOn(isDancingEnabled, animated: true)
                            self.lifestyleSw.setOn(isLifestyleEnabled, animated: true)
                            self.sportsSw.setOn(isSportsEnabled, animated: true)
                            self.musicSw.setOn(isMusicEnabled, animated: true)
                            self.otherSw.setOn(isOtherEnabled, animated: true)
                            
                            // set the label to default
                            self.setAgeLabel(self.minimumAge, self.maximumAge)
                            
                            if self.minimumAge == 0{
                                self.minimumAge = 18
                            }
                            
                            if self.maximumAge == 0{
                                self.maximumAge = 99
                            }

                            
                            // set the picker value to saved
                            // age starts from 18 instead of 0, so minus it to balance
                            self.ageRangePicker.selectRow(self.minimumAge-18, inComponent: 0, animated: true)
                            self.ageRangePicker.selectRow(self.maximumAge-18, inComponent: 1, animated: true)
                            // save the fetched values
                            self.saveValues()
                        }
                })
            }// end of user
            
     
        
        
        }


    }
    
    func setAgeLabel(_ min:Int, _ max : Int){
        if (max == 99){
            ageRangeL.text = "\(min) to \(max)+"
        }else{
            ageRangeL.text = "\(min) to \(max)"
        }
        
    }
    
    func setStateOfNoPref(_ isOn: Bool) {
        tickBtn.isHidden = false
        // only apply when any sw is on
        if(isOn){
            noPreferenceSw.setOn(!isOn, animated: true)
        }
        
    }
    
    func saveValues(){
    
        // set the no pref value to UD
        prefs.setValue(noPreferenceSw.isOn, forKey: Constants.UD_NO_PREF_Bool)
        // set the dancing value to UD
        prefs.setValue(dancingSw.isOn, forKey: Constants.UD_ST_WOMAN_Bool)
        // set the lifestyle value to UD
        prefs.setValue(lifestyleSw.isOn, forKey: Constants.UD_ST_MAN_Bool)
        // set the sports value to UD
        prefs.setValue(sportsSw.isOn, forKey: Constants.UD_GWOMAN_Bool)
        // set the music value to UD
        prefs.setValue(musicSw.isOn, forKey: Constants.UD_GMAN_Bool)
        // set the other value to UD
        prefs.setValue(otherSw.isOn, forKey: Constants.UD_OTHER_Bool)
        
        
        // save the min age to UD
        prefs.setValue(minimumAge, forKey: Constants.UD_MIN_AGE_INT)
        // save the max age to UD
        prefs.setValue(maximumAge, forKey: Constants.UD_MAX_AGE_INT)
    }
    /******************************************************************************************************************************/
    
    // number of "wheels" actually, how many values there will be
    // we have minimum and maximum age
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    // how many items will there be in one wheel
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // this needs some work
        return 82
    }
    
    // this sets title for each row of each wheel
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        
        let startingAge = 18
        let aAge = row+startingAge
        if aAge == 99 {
            return "\(aAge)+"
        }
        return "\(aAge)"
    }
    
    // which row is selected from which component
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        // true can be referred as did we change the ui by hand? true== yes we did, so set no pref to false
        setStateOfNoPref(true)
        
        //  check component
        if (component==0){
            // set the minimum
            minimumAge = row + 18
            // check collision
            if minimumAge >= maximumAge{
                minimumAge = maximumAge-1
                ageRangePicker.selectRow(minimumAge-18, inComponent: 0, animated: true)
            }

        }else{
            // set the maximum, add 18 cause that is the starting age
            maximumAge = row + 18
            // check collision
            if maximumAge <= minimumAge{
                maximumAge = minimumAge+1
                ageRangePicker.selectRow(maximumAge-18, inComponent: 1, animated: true)
            }
            

            
        }
        // set the age label
        setAgeLabel(minimumAge, maximumAge)
    }
    
    
    /******************************************************************************************************************************/

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // init the pref/userdefault
        prefs = UserDefaults.standard
        
        
        // set the delegate to the picker
        ageRangePicker.delegate = self
        ageRangePicker.dataSource = self
        
        // set the no pref to true and reset the view for now
        let isNoPrefEnabled = prefs.bool(forKey: Constants.UD_NO_PREF_Bool)
        setDefaultState(isNoPrefEnabled)
        
        tickBtn.isHidden = true
        
        
    }
    

}
