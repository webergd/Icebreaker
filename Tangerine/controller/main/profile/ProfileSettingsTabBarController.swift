//
//  ProfileSettingsTabBarController.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-11.
//

import UIKit

class ProfileSettingsTabBarController: UITabBarController {

    var settingsView: UIView!
    var profileView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the tab bars
        let settingsVC = SettingsVC()
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), tag: 0)
        
        let profileVC = ProfileVC()
        profileVC.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), tag: 1)
        
        
        self.viewControllers = [settingsVC, profileVC]
        
        settingsView = settingsVC.view
        profileView = profileVC.view
        
        // Do any additional setup after loading the view.
        self.selectedIndex = 1
        setupSwipe()
    }
    
    // this will add swipe functionality as the doc asked
    func setupSwipe(){
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
    }
    
    // function to handle
    @objc func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        // swipe from right to left
        
        
            if gesture.direction == .left {
                _ = self.tabBarController(self, shouldSelect: self.viewControllers![1])
              // swipe from left to right

            } else if gesture.direction == .right {
                _ = self.tabBarController(self, shouldSelect: self.viewControllers![0])
            }
        
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // set profile tab as default as it is asked in doc
        //self.selectedIndex = 1
    }


}

@objc extension ProfileSettingsTabBarController: UITabBarControllerDelegate  {
    @objc func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {

        guard let fromView = selectedViewController?.view, let toView = viewController.view else {
            return false // Make sure you want this as false
        }

        if fromView != toView {
            
            UIView.transition(from: fromView, to: toView, duration: 0.3, options: selectedIndex == 0 ?  .transitionFlipFromRight : .transitionFlipFromLeft, completion: { (true) in

            })

            self.selectedViewController = viewController
        }

        return true
    }
}
