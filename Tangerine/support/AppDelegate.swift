//
//  AppDelegate.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-12.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import RealmSwift
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {


    var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 0);

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Configuring Firebase
        FirebaseApp.configure()
        // We would like to get the registration token, and control notification by ourselves
        Messaging.messaging().delegate = self
        // UserNotificaion Service Class, keeps this AppDelegate Class Clean
        // Huge potential, can be used for advanced features later
        UNService.shared.authorize()

        application.registerForRemoteNotifications()

      // for Keyboard
      IQKeyboardManager.shared.enable = true
        
        // to prevent Realm Crash
        let config = Realm.Configuration(
                  // Set the new schema version. This must be greater than the previously used
                  // version (if you've never set a schema version before, the version is 0).
          // changed to 3: adminReviewRequired added
                  schemaVersion: 3,

                  // Set the block which will be called automatically when opening a Realm with
                  // a schema version lower than the one set above
                  migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 1 {
                      
                    }
                  }
                )
                Realm.Configuration.defaultConfiguration = config
        
        return true
    }
    
    
    // We disabled Method Swizzling, so we are manually setting the device token to apn token
    // <key>FirebaseAppDelegateProxyEnabled</key><false/>
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        Messaging.messaging().apnsToken = deviceToken

        // set the device token to auth as per doc to handle silent push
      Auth.auth().setAPNSToken(deviceToken, type: .unknown)
        print("Notification: did register device \(deviceToken)")
    }
    
    // this comes in handy, if we'd like to send any USER a notification
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // we'll use it later
        // saving the token for later use
        if let token = fcmToken {
            
            if let user = Auth.auth().currentUser, let name = user.displayName{
                Firestore.firestore()
                .collection(FirebaseManager.shared.getUsersCollection())
                    .document(name)
                .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
                    .document(Constants.USERS_PRIVATE_INFO_DOC).setData(["fcm":token], merge: true)
            }
        }
    }
    
    
    // for firebase auth for verification, see the doc for more info
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Did receive notification")

        if let userBannedStatus = userInfo["isBanned"] as? String {

            if let isUserBanned = Bool(userBannedStatus), isUserBanned == true {

                do {
                    try Auth.auth().signOut()
                    // clear the realm db
                    // update the local db

                    resetLocalAndRealmDB()

                    resetQuestionRelatedThings() // detailed on declaration of this func => Cmd+Click (Jump to Definition)
                    // Move to login


                    let vc = LoginVC()
                    vc.modalPresentationStyle = .fullScreen

                    guard let window = UIApplication.shared.windows.first else {
                        return
                    }

                    window.rootViewController = vc
                    window.makeKeyAndVisible()


                } catch let signOutError as NSError {
                    print ("Error signing out: %@", signOutError)
                }
            } // if
        }

        if let userSuspendedStatus = userInfo["isSuspended"] as? String {

            if let userSuspended = Bool(userSuspendedStatus) {

                if let _ = Auth.auth().currentUser {

                    isUserSuspended = userSuspended
                    let sED = userInfo["suspensionEnds"] as? String ?? ""
                    userSuspensionEnds = Double(sED) ?? 0.0

                    print("User suspended? \(isUserSuspended) \(userSuspensionEnds)")
                    // Move to main

                    if userSuspended {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "main_vc") as! MainVC
                        vc.modalPresentationStyle = .fullScreen

                        guard let window = UIApplication.shared.windows.first else {
                            return
                        }

                        window.rootViewController = vc
                        window.makeKeyAndVisible()
                    }

                }

                // So if the user isn't logged in, I don't see the point of moving him to login
                // because as soon as he logs in we'll update the value

//                else {
//                    // Move to login
//                    let vc = LoginVC()
//                    vc.modalPresentationStyle = .fullScreen
//
//                    guard let window = UIApplication.shared.windows.first else {
//                        return
//                    }
//
//                    window.rootViewController = vc
//                    window.makeKeyAndVisible()
//                }


            }


        }

        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
    }
    
    // for firebase auth verification again
    func application(_ application: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
      if Auth.auth().canHandle(url) {
        return true
      }
      // URL not auth related
        return true
    }
    
    
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("Will Terminate")
        
        let status = UserDefaults.standard.bool(forKey: Constants.UD_SIGNUP_DONE_Bool)
        
        // Delete user name when force closed app
        if !status && !Constants.username.isEmpty{
        // a user is found, let's kill him
        print("Deleting temp account")
            
            
//            Passing zero for the value is useful for when two threads need to reconcile the completion of a particular event. Passing a value greater than zero is useful for managing a finite pool of resources, where the pool size is equal to the value.
//            Important
//            Calls to signal() must be balanced with calls to wait(). Attempting to dispose of a semaphore with a count lower than value causes an EXC_BAD_INSTRUCTION exception.
            
            let ds = DispatchSemaphore(value: 0)
            Firestore.firestore().collection(FirebaseManager.shared.getUsersCollection()).document(Constants.username).delete { (error) in
                ds.signal()
            // handle the error here
            if let error = error{
                print("Error deleting data \(error.localizedDescription)")
                
            }
                print("User name deleted")
                // account and storage will be deleted from functions
            } // end of firestore
            ds.wait()
        } // end of status check
    }
    
    
    

}

