//
//  ProfileSettingsTabBarController.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-11.
//

import UIKit

class ProfileSettingsTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
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
        self.selectedIndex = 1
        // swipe from left to right
      } else if gesture.direction == .right {
        self.selectedIndex = 0
      }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // set profile tab as default as it is asked in doc
        //self.selectedIndex = 1
    }


}
