//
//  UNService.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-14.
//

import UIKit
import UserNotifications
import FirebaseAuth

class UNService: NSObject,UNUserNotificationCenterDelegate {
    // instance
    static let shared = UNService()
    // to request authorization
    let unCenter = UNUserNotificationCenter.current()
    
    
    // This function ask for authorization from user
    // if granted, we'll register for remote notification
    func authorize(){
        let options: UNAuthorizationOptions = [.alert,.sound,.badge]
        unCenter.requestAuthorization(options: options) { (granted, error) in
            print(error ?? "No un auth error")
            
            guard granted else {print("SOME ERROR"); return}
            
            DispatchQueue.main.async {
                self.unCenter.delegate = self
                let application = UIApplication.shared
                application.registerForRemoteNotifications()
            }
        }
    } //  end of authorize
    
    
    
    // Asks the delegate how to handle a notification that arrived while the app was running in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // will present
        print("Notification: will present")
        let options: UNNotificationPresentationOptions = [.alert,.sound,.badge]
        
      if notification.request.content.title.count > 0 {

        print("Notification: Not Silent")
        qFFCount += 1
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.QFF_NOTI_NAME), object: nil)

      }

      completionHandler(options)
    }
    
    // Asks the delegate to process the user's response to a delivered notification.
    // Use this method to process the user's response to a notification. If the user selected one of your app's custom
    //actions, the response parameter contains the identifier for that action. (The response can also indicate that
    //the user dismissed the notification interface, or launched your app, without selecting a custom action.) At
    //the end of your implementation, call the completionHandler block to let the system know that you are done
    //processing the user's response. If you do not implement this method, your app never responds to custom actions.
    // FROM OFFICIAL DOC, FOR FUTURE REFERENCE
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        //did receive
        print("Notification: did receive")
      qFFCount += 1
      NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.QFF_NOTI_NAME), object: nil)

        completionHandler()
    }
    
    
}

