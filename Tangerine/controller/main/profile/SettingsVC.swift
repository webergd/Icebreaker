//
//  SettingsVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-11.
//

import UIKit

class SettingsVC: UIViewController {

    // MARK: UI Items
    // user default
    var userDefault : UserDefaults!
    
    var backBtn: UIButton!
    var topLabel: UILabel!
    var notLabel: UILabel!
    
    var stayLoggedInSW: UISwitch!
    
    // the notification section switches
    var notifyRecAnsSw: UISwitch!
    var notifyFriendReqSw: UISwitch!
    var notifyFriendQSw: UISwitch!
    var tutorialModeToggleSw: UISwitch!
    
    
    // MARK: Actions
    // when stay logged in is changed
    @objc func stayLoggedInSwitched() {
        print("stay logged in? \(stayLoggedInSW.isOn)")
        
        userDefault.setValue(stayLoggedInSW.isOn, forKey: Constants.UD_SHOULD_PERSIST_LOGIN_Bool)
    }
    
    // when switches in notification section changed
    // can be used to set values to database
    @objc func notificationSwitched(_ sender: UISwitch) {
        // check which switch we pressed and save it to UD
        if sender == notifyRecAnsSw{
            print("Rec Ans")
            userDefault.setValue(notifyRecAnsSw.isOn, forKey: Constants.UD_NOTIFY_RECEIVE_ANSWER_Bool)
        }else if sender == notifyFriendReqSw{
            print("Friend Req")
            userDefault.setValue(notifyFriendReqSw.isOn, forKey: Constants.UD_NOTIFY_FRIEND_REQ_Bool)
        }else if sender == notifyFriendQSw{
            print("Friend Q")
            userDefault.setValue(notifyFriendQSw.isOn, forKey: Constants.UD_NOTIFY_FRIEND_QUES_Bool)
        }
    }
    
    @objc func tutorialModeSwitched() {
        print("system attempting to set tutorial mode ON: \(tutorialModeToggleSw.isOn)")
        TutorialTracker().setTutorialMode(on: tutorialModeToggleSw.isOn)
        
        // if we just switched the tutorial to off, we need to make sure MainVC cleans up the remnants as required
        needToClearOutMainVCTutorial = !tutorialModeToggleSw.isOn
    }
    
    
    
    // when the top back button pressed, to dismiss the vc
    @objc func backBtnPressed(_ sender: UIButton) {
        self.tabBarController?.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: Delegates
    // MARK: VC Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // proUI
        configureBackButton()
        configureTopLabel()

        configureStayLoginSw()
        
        configureNotLabel()
        configureNotRecAnsSw()
        configureNotFriReqSw()
        configureNotFriQuesSw()
        
        configureTutorialModeToggleSwitch()
        
        
        // init the UD
        userDefault = UserDefaults.standard
        
        //check if user choses to keep him logged in
        let shouldKeepLoggedIn = userDefault.bool(forKey: Constants.UD_SHOULD_PERSIST_LOGIN_Bool)
        stayLoggedInSW.setOn(shouldKeepLoggedIn, animated: false)
        
        // check if we have any tutorials remaining so we know whether to set the switch on or off
        let tutorialModeOn: Bool = TutorialTracker().getTutorialModeOnState()
        tutorialModeToggleSw.setOn(tutorialModeOn, animated: false)
        
        
        // setup the notification switches
        
        let receiveAnswer = userDefault.bool(forKey: Constants.UD_NOTIFY_RECEIVE_ANSWER_Bool)
        let friendReq = userDefault.bool(forKey: Constants.UD_NOTIFY_FRIEND_REQ_Bool)
        let friendQ = userDefault.bool(forKey: Constants.UD_NOTIFY_FRIEND_QUES_Bool)
        
        // set the switches based on value
        notifyRecAnsSw.setOn(receiveAnswer, animated: false)
        notifyFriendReqSw.setOn(friendReq, animated: false)
        notifyFriendQSw.setOn(friendQ, animated: false)
        
        
        // Do any additional setup after loading the view.
    }
    
    
    // MARK: PROGRAMMATIC UI

    func configureBackButton(){
        backBtn = UIButton()
        backBtn.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)
        
        
        
        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 10),
            backBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,constant: 8),
            backBtn.heightAnchor.constraint(equalToConstant: 40),
            backBtn.widthAnchor.constraint(equalToConstant: 40)
            
        ])
        
        backBtn.addTarget(self, action: #selector(backBtnPressed), for: .touchUpInside)
    }
    
    func configureTopLabel(){
        topLabel = UILabel()
        topLabel.text = "SETTINGS"
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
    
    func configureStayLoginSw(){
        stayLoggedInSW = UISwitch()
        
        stayLoggedInSW.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stayLoggedInSW)
        
        let swLabel = UILabel()
        swLabel.text = "Stay Logged in"
        swLabel.textColor = .label
        swLabel.font = UIFont.systemFont(ofSize: 17)
        
        swLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(swLabel)
        
        NSLayoutConstraint.activate([
            swLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            swLabel.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 20),
            swLabel.heightAnchor.constraint(equalTo: stayLoggedInSW.heightAnchor, multiplier: 1),
            stayLoggedInSW.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stayLoggedInSW.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 20)
        ])
        
        stayLoggedInSW.addTarget(self, action: #selector(stayLoggedInSwitched), for: .valueChanged)
    }
    
    func configureNotLabel(){
        notLabel = UILabel()
        notLabel.text = "Notifications"
        // to make it dark/light friendly
        notLabel.textColor = .label
        notLabel.textAlignment = .center
        notLabel.font = UIFont.systemFont(ofSize: 17,weight: .semibold)
        view.addSubview(notLabel)
        
        notLabel.translatesAutoresizingMaskIntoConstraints = false
        notLabel.isHidden = true
        
        NSLayoutConstraint.activate([
            notLabel.heightAnchor.constraint(equalToConstant: 50),
            notLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            notLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0),
            notLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            notLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
        ])
    } // end conf topLabel
    
    
    func configureNotRecAnsSw(){
        notifyRecAnsSw = UISwitch()
        
        notifyRecAnsSw.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(notifyRecAnsSw)
        
        let swLabel = UILabel()
        swLabel.text = "When I receive an answer"
        swLabel.textColor = .label
        swLabel.font = UIFont.systemFont(ofSize: 17)
        
        swLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(swLabel)
        
        notifyRecAnsSw.isHidden = true
        swLabel.isHidden = true
        
        NSLayoutConstraint.activate([
            swLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            swLabel.topAnchor.constraint(equalTo: notLabel.bottomAnchor, constant: 20),
            swLabel.heightAnchor.constraint(equalTo: notifyRecAnsSw.heightAnchor, multiplier: 1),
            notifyRecAnsSw.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            notifyRecAnsSw.topAnchor.constraint(equalTo: notLabel.bottomAnchor, constant: 20)
        ])
        
        notifyRecAnsSw.addTarget(self, action: #selector(notificationSwitched), for: .valueChanged)
    }
    
    func configureNotFriReqSw(){
        notifyFriendReqSw = UISwitch()
        
        notifyFriendReqSw.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(notifyFriendReqSw)
        
        let swLabel = UILabel()
        swLabel.text = "New friend requests"
        swLabel.textColor = .label
        swLabel.font = UIFont.systemFont(ofSize: 17)
        
        swLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(swLabel)
        
        notifyFriendReqSw.isHidden = true
        swLabel.isHidden = true
        
        NSLayoutConstraint.activate([
            swLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            swLabel.topAnchor.constraint(equalTo: notifyRecAnsSw.bottomAnchor, constant: 20),
            swLabel.heightAnchor.constraint(equalTo: notifyFriendReqSw.heightAnchor, multiplier: 1),
            notifyFriendReqSw.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            notifyFriendReqSw.topAnchor.constraint(equalTo: notifyRecAnsSw.bottomAnchor, constant: 20)
        ])
        
        notifyFriendReqSw.addTarget(self, action: #selector(notificationSwitched), for: .valueChanged)
    }
    
    func configureNotFriQuesSw(){
        notifyFriendQSw = UISwitch()
        
        notifyFriendQSw.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(notifyFriendQSw)
        
        let swLabel = UILabel()
        swLabel.text = "New friend requests"
        swLabel.textColor = .label
        swLabel.font = UIFont.systemFont(ofSize: 17)
        
        swLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(swLabel)
        
        notifyFriendQSw.isHidden = true
        swLabel.isHidden = true
        
        NSLayoutConstraint.activate([
            swLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            swLabel.topAnchor.constraint(equalTo: notifyFriendReqSw.bottomAnchor, constant: 20),
            swLabel.heightAnchor.constraint(equalTo: notifyFriendQSw.heightAnchor, multiplier: 1),
            notifyFriendQSw.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            notifyFriendQSw.topAnchor.constraint(equalTo: notifyFriendReqSw.bottomAnchor, constant: 20)
        ])
        
        notifyFriendQSw.addTarget(self, action: #selector(notificationSwitched), for: .valueChanged)
    }
    
    
    /// Sets up the tutorial mode toggle switch
    func configureTutorialModeToggleSwitch(){
        tutorialModeToggleSw = UISwitch()
        
        tutorialModeToggleSw.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tutorialModeToggleSw)
        
        let swLabel = UILabel()
        swLabel.text = "Tutorial Mode"
        swLabel.textColor = .label
        swLabel.font = UIFont.systemFont(ofSize: 17)
        
        swLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(swLabel)
        
        NSLayoutConstraint.activate([
            swLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            swLabel.topAnchor.constraint(equalTo: tutorialModeToggleSw.topAnchor, constant: 0),
            swLabel.heightAnchor.constraint(equalTo: tutorialModeToggleSw.heightAnchor, multiplier: 1),
            tutorialModeToggleSw.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            tutorialModeToggleSw.topAnchor.constraint(equalTo: notifyFriendQSw.bottomAnchor, constant: 20)
        ])
        
        tutorialModeToggleSw.addTarget(self, action: #selector(tutorialModeSwitched), for: .valueChanged)
    }
 
    
}
