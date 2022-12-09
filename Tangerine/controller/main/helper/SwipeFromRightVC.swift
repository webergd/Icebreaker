//
//  SwipeFromRightVCViewController.swift
//  SocialApp
//
//  Created by Mahmud on 2021-11-01.
//

import UIKit

class SwipeFromRightVC: UIViewController {
    
    var ud = UserDefaults.standard
    
    var keepAnimatingSwipe: Bool = false //was true, for now let's just animate it once.
    
    var tutorialLabel: UILabel!
    
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
    
    // Outlets for tutorial boxes to be added:
    @IBOutlet weak var privateLabelExplanationButton: UIButton!
    @IBOutlet weak var ratingExplanationButton: UIButton!
    @IBOutlet weak var numReviewsExplanationButton: UIButton!
    @IBOutlet weak var timeRemainingExplanationButton: UIButton!
    @IBOutlet weak var wearItImageExplanationButton: UIButton!

    @IBOutlet weak var rowSampleImageView: UIImageView!
    @IBOutlet weak var gotItButton: UIButton!
    
    @objc func dismissOnTap(){
//        dismiss(animated: true)
        self.gotItButton.addAttentionRectangle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // `0.4` is the desired number of seconds.
            self.gotItButton.removeAttentionRectangle()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        alertView.layer.cornerRadius = 10
        keepAnimatingSwipe = true
        
        let tg = UITapGestureRecognizer(target: self, action: #selector(dismissOnTap))
        self.view.addGestureRecognizer(tg)

        animateSwipeHand()
        
        
        //Add blue rectangles around the tap for more info areas
        privateLabelExplanationButton.addAttentionRectangle()
        ratingExplanationButton.addAttentionRectangle()
        numReviewsExplanationButton.addAttentionRectangle()
        timeRemainingExplanationButton.addAttentionRectangle()
        wearItImageExplanationButton.addAttentionRectangle()
        
        resetExplanationLabelBackgrounds()
        
        configureTutorialLabel()
        
    }
    
    func animateSwipeHand(){
        print("Swiping- animateSwipeHand() called")
        
        UIView.transition(with: swipeImage,
                          duration: 8,
                          options: [.repeat, .curveEaseInOut])//.repeat) // not sure if there is a better options, I'll be learning it soon
        { [self] in
            swipeImage.frame.origin.x = self.view.frame.width / 1.2
        } completion: { [self] Bool in
            // IF logic prevents animateSwipeHand() from being called repeatedly.
            if keepAnimatingSwipe {
                animateSwipeHand()
                // Adding this 2 second delay prevents the completion from being called repeatedly while View is active.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // `2.0` is the desired number of seconds.
                   // Code we are delaying
                    self.keepAnimatingSwipe = false
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // This is a last resort protection to prevent animateSwipeHand() from being called repeatedly even after the View is dismissed.
        keepAnimatingSwipe = false
    }
    
    
    @IBAction func privateLabelExplanationButtonTapped(_ sender: Any) {
        resetExplanationLabelBackgrounds()
        tutorialLabel.adjustsFontSizeToFitWidth = true
        tutorialLabel.text = "PRIVATE LABEL. \nReviewers can't see it, only you can. \nIt is added to your photo when you are editing it prior to posting."
//        privateLabelExplanationButton.alpha = 0.35  //.setBackgroundColor(.systemOrange, forState: .normal)
        highlight(view: privateLabelExplanationButton)
        tutorialLabel.fadeInAfter(seconds: 0.0)
    }
    
    @IBAction func ratingExplanationButtonTapped(_ sender: Any) {
        resetExplanationLabelBackgrounds()
        tutorialLabel.adjustsFontSizeToFitWidth = true
        tutorialLabel.text = "TANGERINE SCORE \nWe calculate it using a variety of inputs that we believe best approximates how happy you'll be that you wore the item"
        highlight(view: ratingExplanationButton)
        tutorialLabel.fadeInAfter(seconds: 0.0)
    }
    
    @IBAction func numReviewsExplanationButtonTapped(_ sender: Any) {
        resetExplanationLabelBackgrounds()
        tutorialLabel.adjustsFontSizeToFitWidth = true
        tutorialLabel.text = "REVIEWS RECIEVED \nThe total number of members who have reviewed your photo."
        highlight(view: numReviewsExplanationButton)
        tutorialLabel.fadeInAfter(seconds: 0.0)
    }
    
    @IBAction func timeRemainingExplanationButtonTapped(_ sender: Any) {
        resetExplanationLabelBackgrounds()
        tutorialLabel.adjustsFontSizeToFitWidth = true
        tutorialLabel.text = "HOURS REMAINING. \nThe number of hours left before your photo is automatically deleted. \nIt will no longer be viewable by anyone, including you, once deleted."
        highlight(view: timeRemainingExplanationButton)
        tutorialLabel.fadeInAfter(seconds: 0.0)
    }
    
    @IBAction func wearItImageExplanationButtonTapped(_ sender: Any) {
        resetExplanationLabelBackgrounds()
        tutorialLabel.adjustsFontSizeToFitWidth = true
        tutorialLabel.text = "DECISION IMAGE \nIf Tangerine is confident you'll be satisfied wearing this, you'll see a tangerine image and a 'Wear It' message. \nIf it is confident that you won't, you'll see a red X and a 'Nope' message. \nIf undecided, you'll see neither."
        highlight(view: wearItImageExplanationButton)
        tutorialLabel.fadeInAfter(seconds: 0.0)
    }
    
    func highlight(view: UIView) {
        view.backgroundColor = .systemOrange
        view.alpha = 0.35
    }
    
    func resetExplanationLabelBackgrounds() {
        privateLabelExplanationButton.backgroundColor = .clear
        ratingExplanationButton.backgroundColor = .clear
        numReviewsExplanationButton.backgroundColor = .clear
        timeRemainingExplanationButton.backgroundColor = .clear
        wearItImageExplanationButton.backgroundColor = .clear
        
        privateLabelExplanationButton.setTitle("", for: .normal)
        ratingExplanationButton.setTitle("", for: .normal)
        numReviewsExplanationButton.setTitle("", for: .normal)
        timeRemainingExplanationButton.setTitle("", for: .normal)
        wearItImageExplanationButton.setTitle("", for: .normal)
        
        privateLabelExplanationButton.alpha = 1.0
        ratingExplanationButton.alpha = 1.0
        numReviewsExplanationButton.alpha = 1.0
        timeRemainingExplanationButton.alpha = 1.0
        wearItImageExplanationButton.alpha = 1.0
    }
    
    func configureTutorialLabel (){
        tutorialLabel = UILabel()
        tutorialLabel.text = "This is the tutorial label"
        tutorialLabel.textColor = .systemBlue
        tutorialLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        tutorialLabel.numberOfLines = 10
        tutorialLabel.isHidden = true
    
        tutorialLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        
        tutorialLabel.textAlignment = .center
        
        tutorialLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tutorialLabel)
        
        NSLayoutConstraint.activate([
            
            tutorialLabel.centerXAnchor.constraint(equalTo: alertView.centerXAnchor, constant: 0),
            tutorialLabel.topAnchor.constraint(equalTo: rowSampleImageView.bottomAnchor, constant: 16),
            tutorialLabel.heightAnchor.constraint(equalTo: rowSampleImageView.heightAnchor, multiplier: 1.2),
            tutorialLabel.widthAnchor.constraint(equalTo: rowSampleImageView.widthAnchor, multiplier: 1)
        ])
    }
    
}
