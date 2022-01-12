//
//  SettingsVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-11.
//

import UIKit

class SettingsVC: UIViewController {

    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - View Controller methods
     */
    /******************************************************************************************************************************/
    
    // user default
    var userDefault : UserDefaults!
    
    
    @IBOutlet weak var stayLoggedInSw: UISwitch!
    
    // the notification section switches
    @IBOutlet weak var notifyRecAnsSw: UISwitch!
    @IBOutlet weak var notifyFriendReqSw: UISwitch!
    @IBOutlet weak var notifyFriendQSw: UISwitch!
    
    /******************************************************************************************************************************/
    // when stay logged in is changed
    @IBAction func stayLoggedInSwitched(_ sender: UISwitch) {
        print("stay logged in? \(stayLoggedInSw.isOn)")
        
        userDefault.setValue(stayLoggedInSw.isOn, forKey: Constants.UD_SHOULD_PERSIST_LOGIN_Bool)
    }
    
    // when switches in notification section changed
    // can be used to set values to database
    @IBAction func notificationSwitched(_ sender: UISwitch) {
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
    
    
    // when the top back button pressed, to dismiss the vc
    @IBAction func backBtnPressed(_ sender: UIButton) {
        self.tabBarController?.dismiss(animated: true, completion: nil)
    }
    
    /******************************************************************************************************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // init the UD
        userDefault = UserDefaults.standard
        
        //check if user choses to keep him logged in
        let shouldKeepLoggedIn = userDefault.bool(forKey: Constants.UD_SHOULD_PERSIST_LOGIN_Bool)
        stayLoggedInSw.setOn(shouldKeepLoggedIn, animated: false)
        
        
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
    


}
