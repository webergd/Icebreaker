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
    
    // for my future reference
    // dance = stW, music=gay, lifestyle=stM, sports=les
    
    
    // MARK: UI Items
    var topLabel: UILabel!
    var descLabel: UILabel!
    var prefReviewerLabel: UILabel!
    var prefReviewerAgeLabel: UILabel!
    
    var ageStack: UIStackView!
    
    // to determine if from isEditing
    var isEditingProfile = false
    
    // storyboard outlets
    var allDemoSw: UISwitch!
    var stWomenSw: UISwitch!     // st woman
    var stMenSw: UISwitch!   // st man
    var gaySw: UISwitch!      // gay woman
    var lesbianSw: UISwitch!       // gay man
    var otherSw: UISwitch!
    
    var ageRangeLabel: UILabel!
    var ageRangePicker: UIPickerView!
    
    var backBtn: UIButton!
    
    /// formerly tickBtn
    var saveBtn: UIButton!
    
    var minimumAge:Int = 18
    var maximumAge:Int = 99
    
    var prefs: UserDefaults!
    
    
    // MARK: Actions
    // the 5 switches
    
    @objc func allDemoSwitched() {
        // if on then change to default
        
        setDefaultState(allDemoSw.isOn)
        // a change made, so set the saveBtn visible
        saveBtn.isHidden = false
        
        // display a blue rectanlge around save button momentarily to draw the member's attention to it
        self.saveBtn.addAttentionRectangle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // `0.4` is the desired number of seconds.
            self.saveBtn.removeAttentionRectangle()
        }
        
    }
    
    @objc func stWomenSwitched(_ sender: UISwitch) {
        // set the state of no pref
        setStateOfNoPref(sender.isOn)
    }
    
    @objc func stMenSwitched(_ sender: UISwitch) {
        // set the state of no pref
        setStateOfNoPref(sender.isOn)
        
    }
    
    @objc func lesbianSwitched(_ sender: UISwitch) {
        // set the state of no pref
        setStateOfNoPref(sender.isOn)
        
    }
    
    @objc func gaySwitched(_ sender: UISwitch) {
        // set the state of no pref
        setStateOfNoPref(sender.isOn)
    }
    
    @objc func otherSwitched(_ sender: UISwitch) {
        // set the state of no pref
        setStateOfNoPref(sender.isOn)
        
    }
    
    // the bottom two buttons
    
    @objc func onBackPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func onSaveTapped() {
        saveValues()
        print("Save done!")
        
        // the default target demo for firestore
        let target_demo = [
            Constants.UD_ST_WOMAN_Bool : stWomenSw.isOn,
            Constants.UD_ST_MAN_Bool : stMenSw.isOn,
            Constants.UD_GWOMAN_Bool : lesbianSw.isOn,
            Constants.UD_GMAN_Bool : gaySw.isOn,
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
    
    // to toggle all sw based on noPrefSw
    func setDefaultState(_ isOn: Bool){
        
        if(isOn){
            // means all pref, so turn on all sw
            stWomenSw.setOn(isOn, animated: true)
            stMenSw.setOn(isOn, animated: true)
            gaySw.setOn(isOn, animated: true)
            lesbianSw.setOn(isOn, animated: true)
            otherSw.setOn(isOn, animated: true)
            
            
            minimumAge = 18
            maximumAge = 99
            
            // set the label to default
            setAgeLabel(minimumAge, maximumAge)
            
            
            // set the picker value to default
            ageRangePicker.selectRow(0, inComponent: 0, animated: true)
            ageRangePicker.selectRow(81, inComponent: 1, animated: true)
            
        }
        
        else{

            print("pull the settings from firebase")

            minimumAge = prefs.integer(forKey: Constants.UD_MIN_AGE_INT)
            maximumAge = prefs.integer(forKey: Constants.UD_MAX_AGE_INT)


            // with default value
            var isNoPrefEnabled = prefs.bool(forKey: Constants.UD_NO_PREF_Bool)
            var isStWomenEnabled = prefs.bool(forKey: Constants.UD_ST_WOMAN_Bool)
            var isGayEnabled = prefs.bool(forKey: Constants.UD_GMAN_Bool)
            var isStMenEnabled = prefs.bool(forKey: Constants.UD_ST_MAN_Bool)
            var isLesbianEnabled = prefs.bool(forKey: Constants.UD_GWOMAN_Bool)
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

                            isStWomenEnabled = data[Constants.UD_ST_WOMAN_Bool] as? Bool ?? false
                            isGayEnabled = data[Constants.UD_GMAN_Bool] as? Bool ?? false
                            isStMenEnabled = data[Constants.UD_ST_MAN_Bool] as? Bool ?? false
                            isLesbianEnabled = data[Constants.UD_GWOMAN_Bool] as? Bool ?? false
                            isOtherEnabled = data[Constants.UD_OTHER_Bool] as? Bool ?? false
                            self.minimumAge = data[Constants.UD_MIN_AGE_INT] as? Int ?? 18
                            self.maximumAge = data[Constants.UD_MAX_AGE_INT] as? Int ?? 99

                            if isStWomenEnabled && isGayEnabled && isStMenEnabled && isLesbianEnabled && isOtherEnabled{
                                isNoPrefEnabled = true
                            }else{
                                isNoPrefEnabled = false
                            }


                            self.allDemoSw.setOn(isNoPrefEnabled, animated: true)
                            self.stWomenSw.setOn(isStWomenEnabled, animated: true)
                            self.stMenSw.setOn(isStMenEnabled, animated: true)
                            self.lesbianSw.setOn(isLesbianEnabled, animated: true)
                            self.gaySw.setOn(isGayEnabled, animated: true)
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
            ageRangeLabel.text = "\(min) to \(max)+"
        }else{
            ageRangeLabel.text = "\(min) to \(max)"
        }
        
    }
    
    func setStateOfNoPref(_ isOn: Bool) {
        saveBtn.isHidden = false
        
        // display a blue rectanlge around save button momentarily to draw the member's attention to it
        self.saveBtn.addAttentionRectangle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // `0.4` is the desired number of seconds.
            self.saveBtn.removeAttentionRectangle()
        }
        
        // only apply when any sw is off
        if(!isOn){
            allDemoSw.setOn(false, animated: true)
        }
        
        // also check all sw
        if(stWomenSw.isOn && stMenSw.isOn && lesbianSw.isOn && gaySw.isOn && otherSw.isOn){
            allDemoSw.setOn(true, animated: true)
        }
        
    }
    
    func saveValues(){
        
        // set the no pref value to UD
        prefs.setValue(allDemoSw.isOn, forKey: Constants.UD_NO_PREF_Bool)
        // set the dancing value to UD
        prefs.setValue(stWomenSw.isOn, forKey: Constants.UD_ST_WOMAN_Bool)
        // set the lifestyle value to UD
        prefs.setValue(stMenSw.isOn, forKey: Constants.UD_ST_MAN_Bool)
        // set the sports value to UD
        prefs.setValue(lesbianSw.isOn, forKey: Constants.UD_GWOMAN_Bool)
        // set the music value to UD
        prefs.setValue(gaySw.isOn, forKey: Constants.UD_GMAN_Bool)
        // set the other value to UD
        prefs.setValue(otherSw.isOn, forKey: Constants.UD_OTHER_Bool)
        
        
        // save the min age to UD
        prefs.setValue(minimumAge, forKey: Constants.UD_MIN_AGE_INT)
        // save the max age to UD
        prefs.setValue(maximumAge, forKey: Constants.UD_MAX_AGE_INT)
    }
    
    // MARK: Delegates
    
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
    
    
    
    // MARK: VC Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        // init the pref/userdefault
        prefs = UserDefaults.standard
        
        // proUI
        
        configureBackButton()
        configureTopLabel()
        configureDescLabel()
        
        configureAllDemoSw()
        configurePreferredReviewerLabel()
        
        configureStWomenSw()
        configureStMenSw()
        configureLesSw()
        configureGaySw()
        configureOtherSw()
        
        configurePreferredReviewerAgeLabel()
        configureAgeStack()
        configureAgeRangePicker()
        
        configureSaveButton()
        
        
        
        
        // set the delegate to the picker
        ageRangePicker.delegate = self
        ageRangePicker.dataSource = self
        
        // set the no pref to true and reset the view for now
        let isNoPrefEnabled = prefs.bool(forKey: Constants.UD_NO_PREF_Bool)
        setDefaultState(isNoPrefEnabled)
        
        saveBtn.isHidden = true
        
        
    }
    
    
    // MARK: PROGRAMMATIC UI
    
    func configureBackButton(){
        backBtn = UIButton()
        backBtn.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)
        
        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 10),
            backBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,constant: 10)
        ])
        
        backBtn.addTarget(self, action: #selector(onBackPressed), for: .touchUpInside)
    }
    
    func configureTopLabel(){
        topLabel = UILabel()
        topLabel.text = "My Target Demographic"
        topLabel.textColor = .label
        topLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        
        topLabel.textAlignment = .center
        
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topLabel)
        
        NSLayoutConstraint.activate([
            topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            topLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            topLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
        ])
    }
    
    func configureDescLabel(){
        descLabel = UILabel()
        descLabel.text = "Who do you prefer opinions from?"
        descLabel.textColor = .label
        descLabel.font = UIFont.systemFont(ofSize: 17)
        descLabel.textAlignment = .center
        
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descLabel)
        
        NSLayoutConstraint.activate([
            descLabel.topAnchor.constraint(equalTo: topLabel.bottomAnchor),
            descLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            descLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
        ])
    }
    
    func configureAllDemoSw(){
        allDemoSw = UISwitch()
        
        let allDemoLabel = UILabel()
        allDemoLabel.text = "No Preference"
        allDemoLabel.textColor = .label
        allDemoLabel.font = UIFont.systemFont(ofSize: 17)
        
        allDemoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(allDemoLabel)
        
        allDemoSw.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(allDemoSw)
        
        NSLayoutConstraint.activate([
            allDemoSw.topAnchor.constraint(equalTo: descLabel.bottomAnchor,constant: 20),
            allDemoSw.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            allDemoLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            allDemoLabel.centerYAnchor.constraint(equalTo: allDemoSw.centerYAnchor)
        ])
        
        allDemoSw.addTarget(self, action: #selector(allDemoSwitched), for: .valueChanged)
    }
    
    func configurePreferredReviewerLabel(){
        prefReviewerLabel = UILabel()
        prefReviewerLabel.text = "Preferred Reviewer Orientation"
        prefReviewerLabel.textColor = .label
        prefReviewerLabel.font = UIFont.systemFont(ofSize: 17)
        prefReviewerLabel.textAlignment = .center
        
        prefReviewerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(prefReviewerLabel)
        
        NSLayoutConstraint.activate([
            prefReviewerLabel.topAnchor.constraint(equalTo: allDemoSw.bottomAnchor,constant: 35),
            prefReviewerLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            prefReviewerLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
        ])
    }
    
    func configureStWomenSw(){
        stWomenSw = UISwitch()
        
        stWomenSw.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stWomenSw)
        
        let stWomenLabel = UILabel()
        stWomenLabel.text = "Straight Women"
        stWomenLabel.textColor = .label
        stWomenLabel.font = UIFont.systemFont(ofSize: 17)
        
        stWomenLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stWomenLabel)
        
        NSLayoutConstraint.activate([
            stWomenSw.topAnchor.constraint(equalTo: prefReviewerLabel.bottomAnchor,constant: 20),
            stWomenSw.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            stWomenLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            stWomenLabel.centerYAnchor.constraint(equalTo: stWomenSw.centerYAnchor)
        ])
        
        stWomenSw.addTarget(self, action: #selector(stWomenSwitched), for: .valueChanged)
    }
    func configureStMenSw(){
        stMenSw = UISwitch()
        
        stMenSw.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stMenSw)
        
        let stMenLabel = UILabel()
        stMenLabel.text = "Straight Men"
        stMenLabel.textColor = .label
        stMenLabel.font = UIFont.systemFont(ofSize: 17)
        
        stMenLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stMenLabel)
        
        NSLayoutConstraint.activate([
            stMenSw.topAnchor.constraint(equalTo: stWomenSw.bottomAnchor,constant: 20),
            stMenSw.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            stMenLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            stMenLabel.centerYAnchor.constraint(equalTo: stMenSw.centerYAnchor)
        ])
        
        stMenSw.addTarget(self, action: #selector(stMenSwitched), for: .valueChanged)
    }
    func configureLesSw(){
        lesbianSw = UISwitch()
        
        lesbianSw.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lesbianSw)
        
        let lesbianLabel = UILabel()
        lesbianLabel.text = "Lesbians"
        lesbianLabel.textColor = .label
        lesbianLabel.font = UIFont.systemFont(ofSize: 17)
        
        lesbianLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lesbianLabel)
        
        NSLayoutConstraint.activate([
            lesbianSw.topAnchor.constraint(equalTo: stMenSw.bottomAnchor,constant: 20),
            lesbianSw.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            lesbianLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            lesbianLabel.centerYAnchor.constraint(equalTo: lesbianSw.centerYAnchor)
        ])
        
        lesbianSw.addTarget(self, action: #selector(lesbianSwitched), for: .valueChanged)
    }
    func configureGaySw(){
        gaySw = UISwitch()
        
        gaySw.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gaySw)
        
        let gayLabel = UILabel()
        gayLabel.text = "Gay Men"
        gayLabel.textColor = .label
        gayLabel.font = UIFont.systemFont(ofSize: 17)
        
        gayLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gayLabel)
        
        NSLayoutConstraint.activate([
            gaySw.topAnchor.constraint(equalTo: lesbianSw.bottomAnchor,constant: 20),
            gaySw.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            gayLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            gayLabel.centerYAnchor.constraint(equalTo: gaySw.centerYAnchor)
        ])
        
        gaySw.addTarget(self, action: #selector(gaySwitched), for: .valueChanged)
    }
    
    func configureOtherSw(){
        otherSw = UISwitch()
        
        otherSw.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(otherSw)
        
        let otherLabel = UILabel()
        otherLabel.text = "Other Orientations"
        otherLabel.textColor = .label
        otherLabel.font = UIFont.systemFont(ofSize: 17)
        
        otherLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(otherLabel)
        
        NSLayoutConstraint.activate([
            otherSw.topAnchor.constraint(equalTo: gaySw.bottomAnchor,constant: 20),
            otherSw.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            otherLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            otherLabel.centerYAnchor.constraint(equalTo: otherSw.centerYAnchor)
        ])
        
        otherSw.addTarget(self, action: #selector(otherSwitched), for: .valueChanged)
    }
    
    func configurePreferredReviewerAgeLabel(){
        prefReviewerAgeLabel = UILabel()
        prefReviewerAgeLabel.text = "Preferred Reviewer Age Range"
        prefReviewerAgeLabel.textColor = .label
        prefReviewerAgeLabel.font = UIFont.systemFont(ofSize: 17)
        
        prefReviewerAgeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(prefReviewerAgeLabel)
        
        NSLayoutConstraint.activate([
            prefReviewerAgeLabel.topAnchor.constraint(equalTo: otherSw.bottomAnchor,constant: 20),
            prefReviewerAgeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    
    func configureAgeStack(){
        // the stack that holds the boxes
        ageStack = UIStackView()
        ageStack.axis = .horizontal
        ageStack.alignment = .center
        ageStack.distribution = .equalSpacing
        ageStack.spacing = 0
        ageStack.contentMode = .scaleToFill
        
        ageStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ageStack)
        
        let minLabel = UILabel()
        minLabel.textColor = .label
        minLabel.font = UIFont.systemFont(ofSize: 14)
        minLabel.text = "Minimum"
        
        let maxLabel = UILabel()
        maxLabel.textColor = .label
        maxLabel.font = UIFont.systemFont(ofSize: 14)
        maxLabel.text = "Maximum"
        
        ageRangeLabel = UILabel()
        ageRangeLabel.textColor = .label
        ageRangeLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        ageRangeLabel.textAlignment = .center
        ageRangeLabel.text = "18 to 99+"
        
        ageStack.addArrangedSubview(minLabel)
        ageStack.addArrangedSubview(ageRangeLabel)
        ageStack.addArrangedSubview(maxLabel)
        
        NSLayoutConstraint.activate([
            ageStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            ageStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            ageStack.topAnchor.constraint(equalTo: prefReviewerAgeLabel.bottomAnchor, constant: 10)
        ])
    }
    
    func configureAgeRangePicker(){
        ageRangePicker = UIPickerView()
        ageRangePicker.contentMode = .center
        
        ageRangePicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ageRangePicker)
        
        NSLayoutConstraint.activate([
            ageRangePicker.heightAnchor.constraint(equalToConstant: 90),
            ageRangePicker.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            ageRangePicker.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            ageRangePicker.topAnchor.constraint(equalTo: ageStack.bottomAnchor)
        ])
        
    }
    
    func configureSaveButton(){
        
        
        saveBtn = UIButton()
        saveBtn.setTitle("Save", for: .normal)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        saveBtn.setTitleColor(.link, for: .normal)
        
        saveBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveBtn)
        
        
        
        
//        saveBtn = UIButton()
//        saveBtn.setImage(UIImage(systemName: "checkmark"), for: .normal)
//        saveBtn.tintColor = .systemGreen
//        
//        saveBtn.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(saveBtn)
        
        
        NSLayoutConstraint.activate([
//            saveBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,constant: -10),
//            saveBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,constant: -30),
//            saveBtn.heightAnchor.constraint(equalToConstant: 40),
//            saveBtn.widthAnchor.constraint(equalToConstant: 40)
            
            saveBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 10),
            saveBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,constant: -10)
            
        ])
        
        saveBtn.addTarget(self, action: #selector(onSaveTapped), for: .touchUpInside)
    }
}
