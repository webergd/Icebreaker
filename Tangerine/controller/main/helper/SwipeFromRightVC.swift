//
//  SwipeFromRightVCViewController.swift
//  SocialApp
//
//  Created by Mahmud on 2021-11-01.
//

import UIKit

class SwipeFromRightVC: UIViewController {
    
    var ud = UserDefaults.standard
    
    var keepAnimatingSwipe: Bool = true
    
    // the view where we rendered the alert
    @IBOutlet weak var alertView: UIView!
    // we will animate this dude
    @IBOutlet weak var swipeImage: UIImageView!
    
    @IBOutlet weak var leadingAnchor: NSLayoutConstraint!
    // if user taps it we'll just dismiss the alert
    // but we'll show again next time again
    @IBAction func onGotItTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    // I understood, never show yourself action
    // ie: dismiss and never shows
    @IBAction func onNeverShowAgainTapped(_ sender: UIButton) {
        ud.set(true, forKey: Constants.UD_VIEW_RESULT_ALERT_PREF)
        dismiss(animated: true)
    }
    
    @objc func dismissOnTap(){
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        alertView.layer.cornerRadius = 10
        keepAnimatingSwipe = true
        
        let tg = UITapGestureRecognizer(target: self, action: #selector(dismissOnTap))
        self.view.addGestureRecognizer(tg)

        animateSwipeHand()
        
    }
    
    func animateSwipeHand(){
        print("Swiping- animateSwipeHand() called")
        
        UIView.transition(with: swipeImage,
                          duration: 3,
                          options: [.repeat, .curveEaseInOut])//.repeat) // not sure if there is a better options, I'll be learning it soon
        { [self] in
            swipeImage.frame.origin.x = self.view.frame.width / 2
        } completion: { [self] Bool in
            // IF logic prevents animateSwipeHand() from being called repeatedly.
            if keepAnimatingSwipe {
                animateSwipeHand()
                // Adding this 2 second delay prevents the completion from being called repeatedly while View is active.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // `2.0` is the desired number of seconds.
                   // Code we are delaying
                    keepAnimatingSwipe = false
                }
                
            }
        }

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // This is a last resort protection to prevent animateSwipeHand() from being called repeatedly even after the View is dismissed.
        keepAnimatingSwipe = false
    }


}
