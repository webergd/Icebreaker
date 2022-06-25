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

class OrientationVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: UI Items
    var specialtyPicker: UIPickerView! // MARK: We should rename these from specialty to orientation
    var specialtyTF: UITextField!
    var finishButton: UIButton!
    var topLabel: UILabel!
    var descL: UILabel!
    
    let options = Constants.ORIENTATIONS
    
    // MARK: Actions
    
    
    @objc func onFinishClicked(_ sender: UIButton) {
        print("finish")
        //already checked the specialty
        saveSpecialtyToFirestore()
    }
    
    // MARK: We should rename these from specialty to orientation
    func saveSpecialtyToFirestore(){
        // this username is still valid, although we can take from Auth.auth().user.displayname
        
        let db = Firestore.firestore()
        view.showActivityIndicator()
        
        if let spe = specialtyTF.text{
            
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
                            self.view.hideActivityIndicator()
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
                            self.view.hideActivityIndicator()
                            return
                        }
                        // move to next seague
                             self.view.hideActivityIndicator()
                        // all done, move to welcome
                        
                       
                        // save that signup done
                        UserDefaults.standard.setValue(true, forKey: Constants.UD_SIGNUP_DONE_Bool)
                        
                        Database.database().reference().child("usernames").child(Constants.username).setValue(Constants.username)
                             
                             
                        // clear the temp username
                        Constants.username = ""
                        
                        let vc = WelcomeVC()
                        vc.modalPresentationStyle = .fullScreen
                        
                        self.present(vc, animated: true, completion: nil)
                        
                        
                    }// end of saving specialty
                        
                        
                        
                        
                    } // end of saving in sub collection
            

        }// end of if let spe
        
    } // end of saveSpecialtyToFirebase
    
    // MARK: Delegates
    
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
        specialtyTF.text = options[row]
        finishButton.enable()
    }
    
    // MARK: VC Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Orientation"
        
        configureTopLabel()
        configureDescLabel()
        configureSpecialtyTF()
        configureSpecialtyPicker()
        configureContinueButton()
        configurePageControl()
        
        finishButton.disable()
        
        // set specialty delegate and datasource
        specialtyPicker.delegate = self
        specialtyPicker.dataSource = self
        
        // set a placeholder
        specialtyTF.text = "Select One"
        
    }
    
    // MARK: PROGRAMMATIC UI
    
    func configureTopLabel(){
        topLabel = UILabel()
        topLabel.text = "My Orientation"
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
        descL.text = "Helps the Tangerine Community send you the right questions"
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
    

    func configureSpecialtyTF(){
        specialtyTF = UITextField()
        specialtyTF.textColor = .label
        specialtyTF.font = UIFont.systemFont(ofSize: 14)
        specialtyTF.borderStyle = .roundedRect
        specialtyTF.textAlignment = .center
        
        
        specialtyTF.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(specialtyTF)
        
        NSLayoutConstraint.activate([
            specialtyTF.topAnchor.constraint(equalTo: descL.bottomAnchor, constant: 20),
            specialtyTF.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            specialtyTF.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
        ])
    }
    
    
    func configureSpecialtyPicker(){
        specialtyPicker = UIPickerView()
        
        specialtyPicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(specialtyPicker)
        
        NSLayoutConstraint.activate([
            specialtyPicker.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            specialtyPicker.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            specialtyPicker.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
        ])
    }
    
    func configureContinueButton(){
        finishButton = ContinueButton(title: "Finish!")
        
        view.addSubview(finishButton)
        
        finishButton.addTarget(self, action: #selector(onFinishClicked), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            finishButton.bottomAnchor.constraint(equalTo: specialtyPicker.topAnchor, constant: -40)
            ])
        
    }// end conf continue button
    
    func configurePageControl(){
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 6
        pageControl.currentPage = 5
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
