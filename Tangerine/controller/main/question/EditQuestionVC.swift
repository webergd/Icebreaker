//
//  EditQuestionVC.swift
//  
//
//  Created by Wyatt Weber on 8/3/16.
//  Copyright © 2016 Insightful Inc. All rights reserved.
//

// This file should probably be renamed to PhotoEditorViewController. It started out as the VC we launched the camera from but later the AVCamera was built and this became an image processing VC instead.

import UIKit
import MobileCoreServices
import Firebase
import RealmSwift

// This class has known memory leak issues. As of now we call self.view.window?.rootViewController?.dismiss(animated: true, completion: nil) when returning to mainVC from the CQViewController (because that is the end of the Question creation flow and where we no longer need this to still be alive). This is not a perfect fix and still results in high memory usage (about 250 to 400).

class EditQuestionVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var captionTextFieldTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var otherImageThumbnail: UIButton! // this is a button but in terms of being an outlet we will use it as an imageView
    // so we can hide the deleteThumnailButton:
    @IBOutlet weak var deleteThumbnailButton: UIButton!
    
    // These are the small image icons that tell user whether user is creating an ask or a compare
    @IBOutlet weak var questionTypeLabel: UILabel!
    @IBOutlet weak var topImageIndicator: UIImageView!
    @IBOutlet weak var bottomImageIndicator: UIImageView!
    
    @IBOutlet var longPressTap: UILongPressGestureRecognizer! //MARK: did this unlink itself?
    @IBOutlet weak var clearBlursButton: UIButton!
    @IBOutlet weak var enableBlurringButton: UIButton!
    //@IBOutlet weak var returnToZoomButton: UIButton!
    /// displays to let the user know that the image is being blurred while they long tap on it
    @IBOutlet weak var blurringInProgressLabel: UILabel!
    @IBOutlet weak var addCompareButton: UIButton! // appears as 2
    @IBOutlet weak var reduceToAskButton: UIButton! // appears as a 1
    @IBOutlet weak var mirrorCaptionButton: UIButton!
    @IBOutlet weak var centerFlexibleSpace: UIBarButtonItem!
    
    @IBOutlet weak var publishOrPreviewLabel: UILabel!
    @IBOutlet weak var publishButton: UIButton!
    
    @IBOutlet weak var helpButton: UIButton!
    
    @IBOutlet weak var helpPressBlurLabel: UILabel!
    @IBOutlet weak var helpZoomCropLabel: UILabel!
    @IBOutlet weak var helpAskOrCompareLabel: UILabel!
    
    // many of these are 0.0 becuase I didn't want to bother with an initializer method since they all get set before use anyway.
    let imagePicker = UIImagePickerController()
    var titleHasBeenTapped: Bool = false
    var captionHasBeenTapped: Bool = false
    var tappedLoc: CGPoint = CGPoint(x: 0.0, y: 0.0)
    var captionYValue: CGFloat = 0.0 //this is an arbitrary value to be reset later
    var activeTextField = UITextField()
    var titleFrameRect: CGRect = CGRect()
    var titleTextFieldHeight: CGFloat = 0.0
    var captionTextFieldHeight: CGFloat = 0.0
    var scrollViewFrameRect: CGRect = CGRect()
    var scrollViewHeight: CGFloat = 0.0
    var screenHeight: CGFloat = 0.0
    var screenWidth: CGFloat = 0.0
    var captionTopLimit: CGFloat = 0.0
    var captionBottomLimit: CGFloat = 0.0
    //var captionLocationToSet: CGFloat = 0.0
    var imageScreenSize: CGFloat = 0.0 // this is the height of the image in terms of screen units (pixels or whatever they are)
    // We don't use blurColor anymore
    //    let blurColor = UIColor(red: 172/255, green: 132/255, blue: 76/255, alpha: 0.05)
    var blurringEnabled: Bool = false
    var blurFace: BlurFace = BlurFace(image: currentImage)
    var pressStartTime: TimeInterval = 0.0
    public let phoneScreenWidth: CGFloat = UIScreen.main.bounds.size.width
    var blurRadiusMultiplier: CGFloat = 0.0
    weak var unblurredImageSave: UIImage? = currentImage
    var blursAddedByEditor: Bool = false
    var zoomScaleToLoad: CGFloat =  initialZoomScale
    var contentOffsetToLoad: CGPoint = initialContentOffset
    let enterTitleConstant: String = "Enter a Private Title for Your Photo Here"
    let inactiveImageIndicatorAlphaConstant = 0.6
    
    /// this is where we'll save the link to the profile image or any other image
    var imageRef_1: StorageReference!
    
    var titleTextFieldIsBlank: Bool {
        print("Checking to see if the user entered a title")
        if titleTextField.text == enterTitleConstant
            || titleTextField.text == "(no title)"
            || titleTextField.text == "" {
            print("title is blank")
            return true
        } else {
            print("title is not blank")
            return false
        }
    }
    
    // These are modified later but needed a higher scope for finishEditing to work correctly
    var actionYes = UIAlertAction(title: "", style: .default, handler: nil)
    var actionNo = UIAlertAction(title: "", style: .default, handler: nil)
    
    // should prevent the status bar from displaying at the top of the screen
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    enum CameraError: Swift.Error {
        case noName
    }
    
    enum oneOrTwo: String {
        case one
        case two
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        let makeCompareHelpMessage: String = "Add 2nd image for comparison"
        let revertToAskHelpMessage: String = "Tap ❌ to revert to single image"
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        //Now we check to see which image to display
        
        switch currentCompare.creationPhase {
            
        case .firstPhotoTaken:
            
            load(image: .one)
            
            resetTitleTextField()
            titleHasBeenTapped = false
            addCompareButton.isHidden = false // give the user the option to create a compare
            reduceToAskButton.isHidden = true
            otherImageThumbnail.isHidden = true //if it's a single image, there will be no other image to show a thumbnail of
            topImageIndicator.isHidden = false
            topImageIndicator.alpha = 1.0
            bottomImageIndicator.isHidden  = true
            bottomImageIndicator.alpha = inactiveImageIndicatorAlphaConstant
            publishOrPreviewLabel.text = "TAP TO PUBLISH"
            publishOrPreviewLabel.textColor = .systemGreen //UIColor(red: 0, green: 142, blue: 0, alpha: 1)
            helpAskOrCompareLabel.text = makeCompareHelpMessage

            publishButton.setImage(#imageLiteral(resourceName: "square-arrow.png"), for: UIControl.State.normal)

            
            
        case .secondPhotoTaken:
            load(image: .two)
            resetTitleTextField()
            titleHasBeenTapped = false
            addCompareButton.isHidden = true
            reduceToAskButton.isHidden = true // using the deleteThumbnailButton we never show this
            otherImageThumbnail.isHidden = false //we want them to focus on making image2 right now, no thumbnail
            otherImageThumbnail.alpha = 0.7
            otherImageThumbnail.isEnabled = false
            topImageIndicator.isHidden = false
            topImageIndicator.alpha = inactiveImageIndicatorAlphaConstant
            bottomImageIndicator.isHidden  = false
            bottomImageIndicator.alpha = 1.0
            publishOrPreviewLabel.text = "TAP TO PREVIEW"
            publishOrPreviewLabel.textColor = .systemYellow
            helpAskOrCompareLabel.text = revertToAskHelpMessage
            
            publishButton.setImage(#imageLiteral(resourceName: "Preview-icon.png"), for: UIControl.State.normal)
            
            
            
            
        case .reEditingFirstPhoto:
            load(image: .one)
            addCompareButton.isHidden = true
            reduceToAskButton.isHidden = true // using the deleteThumbnailButton we never show this
            otherImageThumbnail.isHidden = false //displays the thumbnail
            otherImageThumbnail.alpha = 1.0
            otherImageThumbnail.isEnabled = true
            topImageIndicator.isHidden = false
            topImageIndicator.alpha = 1.0
            bottomImageIndicator.isHidden  = false
            bottomImageIndicator.alpha = inactiveImageIndicatorAlphaConstant
            publishOrPreviewLabel.text = "TAP TO PREVIEW"
            publishOrPreviewLabel.textColor = .systemYellow
            helpAskOrCompareLabel.text = revertToAskHelpMessage
            publishButton.setImage(#imageLiteral(resourceName: "Preview-icon.png"), for: UIControl.State.normal)
            
        case .reEditingSecondPhoto:
            load(image: .two)
            addCompareButton.isHidden = true
            reduceToAskButton.isHidden = true // using the deleteThumbnailButton we never show this
            otherImageThumbnail.isHidden = false //displays the thumbnail
            otherImageThumbnail.alpha = 1.0
            otherImageThumbnail.isEnabled = true
            topImageIndicator.isHidden = false
            topImageIndicator.alpha = inactiveImageIndicatorAlphaConstant
            bottomImageIndicator.isHidden  = false
            bottomImageIndicator.alpha = 1.0
            publishOrPreviewLabel.text = "TAP TO PREVIEW"
            publishOrPreviewLabel.textColor = .systemYellow
            helpAskOrCompareLabel.text = revertToAskHelpMessage
            publishButton.setImage(#imageLiteral(resourceName: "Preview-icon.png"), for: UIControl.State.normal)
            
        case .noPhotoTaken: //this should never happen
            print("Error in EditQuestionVC.ViewWillAppear: creationPhase is .noPhotoTaken, something went wrong.")
        }
        
        // only show the delete button if the thumbnail is visible
        deleteThumbnailButton.isHidden = otherImageThumbnail.isHidden
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //if this could animate at twice the speed, it would look better (and be less annoying when switching between thumbnails that are zoomed in far)
        scrollView.setZoomScale(zoomScaleToLoad, animated: true)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleHasBeenTapped = false
        
        otherImageThumbnail.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        
        self.enableBlurringButton.isHidden = false
        self.clearBlursButton.isHidden = !blursAddedByEditor
        
        imagePicker.delegate = self
        captionTextField.delegate = self
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 6.0
        // Hides keyboard when user taps outside of text field
        hideKeyboardOnOutsideTouch()
        
        // This gives a done key but requires other code to dismiss the keyboard
        self.captionTextField.returnKeyType = UIReturnKeyType.done
        
        // This gives a done key but requires other code to dismiss the keyboard
        self.titleTextField.returnKeyType = UIReturnKeyType.done
        
        // This gets us the height of the caption text field to be used later for spacing things out correctly
        self.captionTextFieldHeight = self.captionTextField.frame.height
        
        // This will move the caption text box out of the way when the keyboard pops up:
        NotificationCenter.default.addObserver(self, selector: #selector(EditQuestionVC.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        // This will move the caption text box back down when the keyboard goes away:
        NotificationCenter.default.addObserver(self, selector: #selector(EditQuestionVC.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // This gets the height of the screen for spacing things out later
        // Used only for determining where to move the caption when the keyboard pops up
        self.screenHeight = UIScreen.main.bounds.height
        
        // screenWidth is the same as displayed imageView height since imageView is a square
        self.screenWidth = UIScreen.main.bounds.width
        
        // This gets us the height of the title text field to be used later for spacing things out correctly
        // Shouldn't need this anymore now that title is below imageView
        self.titleTextFieldHeight = self.titleTextField.frame.height
        
        // This sets up the min and max values that the caption's top constraint can have and still be over the image
        //        self.captionTopLimit = self.topLayoutGuide.length //+ self.titleTextFieldHeight  **********
        
        // This constrains the caption drag to stay above the bottom of the image
        self.captionBottomLimit = self.captionTopLimit + screenWidth - self.captionTextFieldHeight
        
        //Enables tap on image to show caption (1 of 2):
        let tapImageGesture = UITapGestureRecognizer(target: self, action: #selector(EditQuestionVC.userTappedImage(_:)))
        imageView.addGestureRecognizer(tapImageGesture)
        imageView.isUserInteractionEnabled = true
        
        //Enables user to drag caption around (1 of 2):
        let dragCaptionGesture = UIPanGestureRecognizer(target: self, action: #selector(EditQuestionVC.userDragged(_:)))
        captionTextField.addGestureRecognizer(dragCaptionGesture)
        captionTextField.isUserInteractionEnabled = true
        
        //Enables user to long press image for blurred circle (1 of 2):
        let pressImageGesture = UILongPressGestureRecognizer(target: self, action: #selector(EditQuestionVC.userPressed(_:) ))
        pressImageGesture.minimumPressDuration = 0.50
        imageView.addGestureRecognizer(pressImageGesture)
        
        //        tempMessageLabel1.fadeOutAfter(seconds: 5)
        
        // Enables image icons to be tapped
        let topImageIndicatorTappedGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(EditQuestionVC.topImageIndicatorTapped(_:)))
        topImageIndicator.isUserInteractionEnabled = true
        topImageIndicator.addGestureRecognizer(topImageIndicatorTappedGestureRecognizer)
        
        let bottomImageIndicatorTappedGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(EditQuestionVC.bottomImageIndicatorTapped(_:)))
        bottomImageIndicator.isUserInteractionEnabled = true
        bottomImageIndicator.addGestureRecognizer(bottomImageIndicatorTappedGestureRecognizer)
        
    }
    
    
    // The next 3 methods (loadImage and the two unpacks) work together to load the correct properties into the EditQuestionVC
    func load(image number: oneOrTwo) {
        
        if currentCompare.imageBeingEdited1 == nil {
            print("imageBeingEdited1 is nil")
        }
        if currentCompare.imageBeingEdited2 == nil {
            print("imageBeingEdited2 is nil")
        }
        if let iBE1 = currentCompare.imageBeingEdited1 {
            
            switch number {
            case .one:
                unpack(image: iBE1)
                if let iBE2 = currentCompare.imageBeingEdited2 { unpack(thumbnail: iBE2) }
            case .two:
                if let iBE2 = currentCompare.imageBeingEdited2 { unpack(image: iBE2) }
                unpack(thumbnail: iBE1)
            }
        } else {
            print("Error: images did not unpack")
        }
        
        print("currentImage width in viewDidLoad is \(currentImage.size.width)")
        
        
        imageView.image = currentImage
        titleTextField.text = currentTitle; print("title set to \(currentTitle)")
        captionTextField.text = currentCaption.text
        captionTextFieldTopConstraint.constant = screenWidth * CGFloat(currentCaption.yLocation)
        
        //        let imageFrameHeightUsed = screenWidth
        //        let calculatedConstraintConstantValue = captionTextFieldTopConstraint.constant
        
        scrollView.setZoomScale(zoomScaleToLoad, animated: false)
        scrollView.setContentOffset(contentOffsetToLoad, animated: false)
    }
    
    func unpack(image iBE: imageBeingEdited) {
        currentImage = iBE.iBEimageBlurredUncropped
        currentTitle = iBE.iBEtitle
        currentCaption = iBE.iBEcaption
        captionTextField.isHidden = !iBE.iBEcaption.exists //hide captionTextField if caption doesn't exist, otherwise, show it.
        unblurredImageSave = iBE.iBEimageCleanUncropped
        blursAddedByEditor = iBE.blursAdded
        contentOffsetToLoad = iBE.iBEContentOffset
        zoomScaleToLoad = iBE.iBEZoomScale
    }
    
    func unpack(thumbnail iBE: imageBeingEdited) {
        otherImageThumbnail.setImage(iBE.iBEimageBlurredCropped, for: .normal)
    }
    
    ///Enables tap on image to show caption (2 of 2):
    @objc func userTappedImage(_ tapImageGesture: UITapGestureRecognizer){
        captionTextField.translatesAutoresizingMaskIntoConstraints = false
        tappedLoc = tapImageGesture.location(in: self.view)
        //print("User tapped: \(tappedLoc)")
        
        if captionTextField.isHidden == true && titleTextField.isEditing == false {
            // Show the captionTextField:
            captionTextField.isHidden = false
            // Position the captionTextField where the user tapped:
            self.captionTextFieldTopConstraint.constant = tappedLoc.y - self.topLayoutGuide.length - (0.5 * captionTextFieldHeight)
            captionTextField.becomeFirstResponder()
            //self.captionTextField.center.y = tappedLoc.y
            if titleTextField.text == enterTitleConstant {
                mirrorCaptionButton.isHidden = false
                centerFlexibleSpace.isEnabled = true
            }
            
        } else {
            // if the caption is displayed and the user taps the image, dismiss the keyboard
            if captionTextField.text == "" {
                mirrorCaptionButton.isHidden = true
                centerFlexibleSpace.isEnabled = false
            }
            view.endEditing(true)
        }
    }
    
    //Enables user to drag caption around (2 of 2):
    @objc func userDragged(_ dragCaptionGesture: UIPanGestureRecognizer){
        let draggedLoc: CGPoint = dragCaptionGesture.location(in: self.view)
        
        let captionLocationToSet = draggedLoc.y - self.topLayoutGuide.length - (0.5 * captionTextFieldHeight)
        self.captionTextFieldTopConstraint.constant = vetCaptionTopConstraint(captionLocationToSet)
        
        // added: 2/13/17
        self.captionYValue = self.captionTextFieldTopConstraint.constant
    }
    
    
    // This determines whether the caption y value is within the prescribed limits within the bounds of the imageView and if it is not, returns the limit that it has crossed.
    func vetCaptionTopConstraint(_ desiredLocation: CGFloat) -> CGFloat {
        // The varible (declared at the top) captionTopConstraint basically just holds the caption's distance from the top of the main View.
        // It is an outlet from Interface Builder, referring to an Interface Builder constraint.
        // The reason it has topConstraint in the name is because that is the Interface Builder constraint we are manipulating.
        if desiredLocation < captionTopLimit {
            return captionTopLimit
        } else if desiredLocation > captionBottomLimit {
            return captionBottomLimit
        } else {
            return desiredLocation
        }
    }
    
    // This is called in the viewDidLoad section in our NSNotificationCenter command
    @objc func keyboardWillShow(_ notification: Notification) {
        // Basically all this is for moving the caption out of the way of the keyboard while we're editing it:
        if self.captionTextField.isEditing == true { //aka if the title is editing, don't do any of this
            mirrorCaptionButton.isHidden = false
            view.bringSubviewToFront(captionTextField)
            //get the height of the keyboard that will show and then shift the text field up by that amount
            if let userInfoDict = notification.userInfo, let keyboardFrameValue = userInfoDict [UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardFrame = keyboardFrameValue.cgRectValue
                
                //this makes the text box movement animated so it looks smoother:
                UIView.animate(withDuration: 0.8, animations: {
                    // Save the captionTextField's Location so we can restore it after editing:
                    self.captionYValue = self.captionTextFieldTopConstraint.constant
                    
                    //get the height of the keyboard that will show and then shift the text field down by that amount
                    self.captionTextFieldTopConstraint.constant = self.screenHeight - keyboardFrame.size.height - self.topLayoutGuide.length - self.captionTextFieldHeight
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
        if self.captionTextField.text == "" {
            self.captionTextField.isHidden = true
            mirrorCaptionButton.isHidden = true
            centerFlexibleSpace.isEnabled = false
        }
        
        //this makes the text box movement animated so it looks smoother:
        UIView.animate(withDuration: 1.0, animations: {
            //moves the caption back to its original location:
            self.captionTextFieldTopConstraint.constant = self.vetCaptionTopConstraint(self.captionYValue)
            
            
        })
        // If the user has entered no text in the titleTextField, reset it to how it was originally:
        if self.titleTextField.text == "" {
            self.titleTextField.text = enterTitleConstant
            self.titleTextField.textColor = UIColor.gray
            self.titleHasBeenTapped = false
            
            if captionTextField.text != "" {
                mirrorCaptionButton.isHidden = false
                centerFlexibleSpace.isEnabled = true
            }
        } else if titleTextField.text != enterTitleConstant  {
            mirrorCaptionButton.isHidden = true
            centerFlexibleSpace.isEnabled = false
        }
        self.view.layoutIfNeeded()
        
        //This is here because the title was somehow getting lost between it displaying correctly in the text field, and the publish button being tapped.
        print("titleTextField value at the end of hiding the keyboard is: \(titleTextField.text!)")
        
    }
    
    // This dismisses the keyboard when the user clicks the DONE button on the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func mirrorCaptionButtonTapped(_ sender: Any) {
        
        // code in here should make the text in the caption equal the text in the title.
        // if it's too long it should truncate and then pop up with a message that says "title text shortened" or something like that.
        
        titleTextField.text = captionTextField.text
        titleTextField.textColor = UIColor.label // sets color to white or black based on dark mode or light mode
        mirrorCaptionButton.isHidden = true
        
    }
    
    func resetTitleTextField() {
        self.titleTextField.text = enterTitleConstant
        self.titleTextField.textColor = UIColor.gray
        currentTitle = ""
    }
    
    
    @IBAction func otherImageThumbnailTapped(_ sender: Any) {
        switch currentCompare.creationPhase {
        case .secondPhotoTaken:
            // MARK need something here to acknowledge image was tapped but we're not doing anything
            print("second photo taken")
        case .reEditingFirstPhoto:
            currentCompare.imageBeingEdited1 = createImageBeingEdited()
            currentCompare.creationPhase = .reEditingSecondPhoto
        case .reEditingSecondPhoto:
            currentCompare.imageBeingEdited2 = createImageBeingEdited()
            currentCompare.creationPhase = .reEditingFirstPhoto
            
        default:
            print("Error in EditQuestionVC.otherImageThumbnailTapped: unexpected enum value for currentCompare.creationPhase")
        }
        
        self.viewWillAppear(false)
        self.viewDidLoad()
        self.viewDidAppear(false)
    }
    
    // this should be renamed to autoBlurFaces, because that's really what it does
    @IBAction func enableBlurring(_ sender: UIButton) {
        //self.lockScrollView()
        
        
        
        blurringInProgressLabel.isHidden = false
        self.enableBlurringButton.isHidden = true
        self.clearBlursButton.isHidden = false
        //self.returnToZoomButton.isHidden = false
        self.blurringEnabled = true
        //the next 2 lines blur detected faces but don't set the blurred image to currentImage yet
        
        currentImage = imageView.image! //this saves a copy of the unblurred image
        
        blurFace.setImage(image: imageView.image)
        imageView.image = blurFace.autoBlurFaces()
        if numFaces < 1 {
            noFacesDetectedMessage()
            self.enableBlurringButton.isHidden = false
            self.clearBlursButton.isHidden = true
        }
        
        blurringInProgressLabel.isHidden = true
    }
    
    public func noFacesDetectedMessage() {
        let alertController = UIAlertController(title: "Tangerine Detected No Faces!", message: "Press and hold each face to manually blur.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    /// Enables user to long press image for a blurred circle (2 of 2). Calls manualBlurFace() in ImageMethods.swift
    func manualBlur(location: CGPoint, radius: CGFloat) {
        
        blurFace.setImage(image: imageView.image)
        
        // These are handled by the computeOrig() method in ImageMethods.swift
        //I needed a way to pass the tapped location on the image rather than on the screen.
        // These are the steps I used to convert it:
        // take zoomscale into account
        // take scrollview offset into account
        // take image's actual size in comparision to its apparent size in imageView into account.
        
        imageView.image = blurFace.manualBlurFace(at: location, with: radius)
    }
    
    /// This calls code in ImageMethods.swift, and manually blurs a location using a radius that depends on press time duration (in seconds).
    @objc func userPressed(_ pressImageGesture: UILongPressGestureRecognizer){
        var helpLabelIsHidden = helpAskOrCompareLabel.isHidden
        if (pressImageGesture.state == UIGestureRecognizer.State.began) {
            
            // we hide the help label while the blurring label displays but want to put it back to how it was.
            helpLabelIsHidden = helpAskOrCompareLabel.isHidden
            helpAskOrCompareLabel.isHidden = true
            
            
            // a cool thing to have here would be a bar that gets bigger on the screen the longer the user holds down
            // in order to give them a visual indication of how big the blur radius is going to be, but perhaps for an updated version later on.
            
            blurringInProgressLabel.text = ":: setting blur radius ::"
            blurringInProgressLabel.isHidden = false
            // we have to call this in order to "start the stopwatch" so we can measure how long the user presses down:
            handleRecognizer(gesture: pressImageGesture)
            return
            
        } else if (pressImageGesture.state == UIGestureRecognizer.State.ended) {
            blurringInProgressLabel.text = ":: blurring in progress ::"
            clearBlursButton.isHidden = false
            
            // So far this is the most natural ratio of time to size I've been able to determine, as far as hold down time to blur size ratio multiplier
            // The idea seems to be around 130 radius size units for every second of hold down, on a 1000 units wide scree
            blurRadiusMultiplier = computeUnderlyingToDisplayedRatio(passedImage: currentImage, screenWidth: screenWidth) * 40
            
            // This takes the amount of time the user held down, multiplies by the blurRadiusMultiplier to get the radius
            let blurRadiusToBePassed: CGFloat = blurRadiusMultiplier * CGFloat(handleRecognizer(gesture: pressImageGesture))
            
            // We pass these two values in for contentOffset and zoomScale because our coordinate point info is coming from the image itself which is oblivious to what the scrollView is doing. The point comes directly from the image, regardless of how it looks in the scrollView.
            let zeroContentOffset: CGPoint = CGPoint(x: 0, y: 0)
            let noZoom: CGFloat = 1.0
            
            // This line translates the coordinates from the UIImageView to the coordinates on the underlying image.
            var convertedPointToBeBlurred: CGPoint = computeOrig(passedImage: currentImage, pointToConvert: pressImageGesture.location(in: imageView), screenWidth: phoneScreenWidth, contentOffset: zeroContentOffset, zoomScale: noZoom)
            
            // We reverse the y coordindate because the mask image that will be blurred is a CIImage.
            // CIImage coordinates start from with the origin at the bottom left vice the top left.
            convertedPointToBeBlurred.y = currentImage.size.height - convertedPointToBeBlurred.y //+ (blurRadiusToBePassed/2)
            manualBlur(location: convertedPointToBeBlurred, radius: blurRadiusToBePassed)
            blurringInProgressLabel.isHidden = true
            
            // This is supposed to make the helpAskOrCompareLabel visible again if it was visible then went away when the member started blurring but for some reason it's not coming back. Needs work but low priority.
            helpAskOrCompareLabel.isHidden = helpLabelIsHidden
            
        }
    }
    
    // This method allows us to find out how long the user has been pressing on the screen for an extended duration
    // It returns that duration in seconds. We use it in userPressed() to determine what the blur radius should be.
    func handleRecognizer(gesture: UILongPressGestureRecognizer) -> Double {
        var duration: TimeInterval = 0
        
        switch (gesture.state) {
        case .began:
            //Keeping start time...
            self.pressStartTime = NSDate.timeIntervalSinceReferenceDate
            
        case .ended:
            //Calculating duration
            duration = NSDate.timeIntervalSinceReferenceDate - self.pressStartTime
            //Note that NSTimeInterval is a double value...
            print("Duration : \(duration)")
            
        default:
            break;
        }
        
        return duration
    }
    
    // This clears out all the blurred circles we drew to blur out the face
    @IBAction func clearBlursTapped(_ sender: UIButton) {
        
        imageView.image = unblurredImageSave
        blurFace = BlurFace(image: unblurredImageSave)
        self.enableBlurringButton.isHidden = false
        self.clearBlursButton.isHidden = true
        self.blurringEnabled = false
    }
    
    func lockScrollView() {
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 1.0
        self.scrollView.isScrollEnabled = false
    }
    
    func unlockScrollView() {
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 6.0
        self.scrollView.isScrollEnabled = true
    }
    
    /// Allows the user to zoom within the scrollView
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    
    
    
    
    /// Takes an image passed in, uses the zoomscale and offset of the scrollview to crop out the visible portion of the image, and return a new image using only the cropped portion.
    func cropImage(_ storedImage: UIImage) -> UIImage {
        print(" ___________________new cropping session has begun______________________")
        
        
        /// determines whether the image is portrait, landscape, or square. Portraits with different h to w ratios would still be considered portraits. We use this value later to avoid redundant logic statements.
        let imageAspectType = computeImageAspectType(passedImage: storedImage)
        
        ///this stores the size of the actual image that is in memory (and currently being resized to fit on the iPhone screen):
        let underlyingImageWidth = storedImage.size.width
        let underlyingImageHeight = storedImage.size.height
        
        print("storedImage.size.width: \(storedImage.size.width)")
        print("storedImage.cgImage!.width: \(storedImage.cgImage!.width)")
        
        ///this determines the "scale" as far as how many times bigger or smaller the longest side of the displayed image is to the actual size of the longest side of the stored image in memory:
        //        let underlyingToDisplayedRatio: CGFloat = computeUnderlyingToDisplayedRatio(passedImage: storedImage, screenWidth: phoneScreenWidth)
        
        /// At and above zoomThreshold, we are now cutting off some of the height AND width. Below it, we are only cutting off height OR width because it's not zoomed in enough yet for us to need to trim both of the dimensions.
        var zoomThreshold: CGFloat { // follows the form: big/little to get a value > 1
            if imageAspectType == ImageAspectType.isPortrait {
                return underlyingImageHeight / underlyingImageWidth
            } else if imageAspectType == ImageAspectType.isLandscape {
                return underlyingImageWidth / underlyingImageHeight
            } else { // the image was a square already
                return 1.0 //this means we will start cropping both sides at the same time (at a zoomscale of 1)
            }
        }
        
        /// This returns the value of the longest side cut down by zoomScale
        var squareSideLength: CGFloat {
            if imageAspectType == ImageAspectType.isPortrait {
                return underlyingImageHeight / scrollView.zoomScale
            } else {
                return underlyingImageWidth / scrollView.zoomScale
            }
        }
        
        let whiteSpaceAsPercent = computeWhiteSpaceAsDecimalPercent(passedImage: storedImage)
        // imageView.frame.height and .width are equal and interchangeable because the imageView has an Interface Builder forced 1:1 aspect ratio and should always be a square.
        let contentOffsetAsPercent = computeContentOffsetAsDecimalPercent(offsetPoint: scrollView.contentOffset, zoomScale: scrollView.zoomScale, imageViewSideLength: imageView.frame.height)
        
        //        print("whiteSpaceAsPercent: \(whiteSpaceAsPercent)")
        //        print("contentOffsetAsPercent: \(contentOffsetAsPercent)")
        //        print("imageViewSideLength: \(imageView.frame.height)")
        //        print("underlyingImageWidth: \(underlyingImageWidth)")
        
        var cropSizeWidth: CGFloat {
            if imageAspectType == ImageAspectType.isPortrait /*&&
                                                              scrollView.zoomScale < zoomThreshold*/ {
                //                print("aspectType is portrait.calculating cropSizeWidth using white space")
                
                let shortSideWidthPercentToCrop = computeShortSideLengthPercentToCrop(zoomScale: scrollView.zoomScale, whiteSpaceAsPercent: whiteSpaceAsPercent, contentOffsetAsPercent: contentOffsetAsPercent.x, imageToCrop: storedImage)
                
                //                print("shortSideWidthPercentToCrop: \(shortSideWidthPercentToCrop)")
                //                print("width to crop: \(underlyingImageWidth * shortSideWidthPercentToCrop)")
                
                return underlyingImageWidth * shortSideWidthPercentToCrop
            } else {
                //                print("image is not a portrait, returning squareSideLength of \(squareSideLength) for the cropSizeWidth")
                return squareSideLength
            }
        }
        
        var cropSizeHeight: CGFloat {
            if imageAspectType == ImageAspectType.isLandscape /*&& scrollView.zoomScale < zoomThreshold*/ {
                //                print("aspectType is LANDSCAPE. calculating cropSizeHeight using white space")
                
                let shortSideHeightPercentToCrop = computeShortSideLengthPercentToCrop(zoomScale: scrollView.zoomScale, whiteSpaceAsPercent: whiteSpaceAsPercent, contentOffsetAsPercent: contentOffsetAsPercent.y, imageToCrop: storedImage)
                
                //                print("shortSideHeightPercentToCrop: \(shortSideHeightPercentToCrop)")
                //                print("height to crop: \(underlyingImageWidth * shortSideHeightPercentToCrop)")
                
                return underlyingImageHeight * shortSideHeightPercentToCrop
            } else {
                //                print("image is not a landscape. Returning squareSideLength of \(squareSideLength) for cropSizeHeight.")
                return squareSideLength
            }
        }
        // zoomScale tells us how far we are zoomed in at a given moment. 2x zoom = zoomScale of 2.
        
        /// we store a copy of the origin (0,0) because that is the point on the scrollview that we want to convert to a point on the image (for cropping). Then we pass it into the conversion method computeOrig
        //        let pointZeroZero: CGPoint = CGPoint(x: 0.0, y: 0.0)
        
        let orig = computeCropOrigin(imageView: imageView, contentOffset: scrollView.contentOffset, zoomScale: scrollView.zoomScale)
        
        //        print("zoomThreshold\(zoomThreshold)")
        //        print("zoomScale\(scrollView.zoomScale)")
        //
        //
        //        print("imageView width: \(imageView.frame.width)")
        //        print("imageView height: \(imageView.frame.height)")
        //
        //        print("cropSizeWidth: \(cropSizeWidth)")
        //        print("cropSizeHeight: \(cropSizeHeight)")
        
        //        print("This is the original content offset that the scroll view has: x: \(scrollView.contentOffset.x), y: \(scrollView.contentOffset.y)")
        //        print("This is the origin passed into the CGRect: \norigin x: \(orig.x), y: \(orig.y)")
        
        //        // for testing
        //        let testOrigXDouble = Double(titleTextField.text!)!
        //        let testOrigXCGFloat = CGFloat(testOrigXDouble)
        
        // Had to use ciImage instead of cgImage because cgImage remembers the image as it originally was prior to any of the modifications we've done on it
        let crop = CGRect(x: orig.x,y: orig.y, width: cropSizeWidth, height: cropSizeHeight)
        //        let cgImageRepresentation: CGImage = storedImage.cgImage()
        if let cgImage = storedImage.cgImage?.cropping(to: crop) {
            
            let image: UIImage = UIImage(cgImage: cgImage) //convert it from a CGImage to a UIImage
            return image
        } else {
            print("cropping failed - image was nil")
            return storedImage
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    /// This method clears the text field to be ready to be typed in and it also reverses the value of titleHasBeenTapped.
    @IBAction func titleTextFieldBeginEditing(_ sender: AnyObject) {
        titleHasBeenTapped = self.resetTextField(titleTextField, tappedYet: titleHasBeenTapped)
    }
    
    @IBAction func titleTextFieldValueChanged(_ sender: AnyObject) {
    }
    /// this sets the text field that we pass in to no text and black text, as long as we have a variable to track whether it has been tapped already:
    func resetTextField(_ textField: UITextField, tappedYet: Bool) -> Bool {
        // print("resetTextField called")
        if tappedYet == false {
            textField.text = ""
            textField.textColor = UIColor.label
        }
        return true
    }
    
    func createImageBeingEdited() -> imageBeingEdited {
        let captionToBePassed = createCaption()
        
        var unblurredImageToBePassed: UIImage
        
        if let unblurredImageUnwrapped = unblurredImageSave {
            unblurredImageToBePassed = self.sFunc_imageFixOrientation(img: unblurredImageUnwrapped)
        } else {
            unblurredImageToBePassed = UIImage(named: "whiteConverse")!
        }
        
        currentImage = self.sFunc_imageFixOrientation(img: self.imageView.image!) //sets the current image to the one we're seeing and essentially saves the blurring to the currentImage, it still hasn't been cropped at this point yet though
        
        let blurredUncroppedToBePassed: UIImage = currentImage
        currentImage = self.cropImage(currentImage) // now we crop it
        let blurredCroppedToBePassed = currentImage // now we store the blurred cropped current image here so we can pass it in
        // the purpose of savng these values is so that if the user decides to edit one of the compares after they have been created, we can display the image in EditQuestionVC as it would have looked right before cropping, without actually cropping it.
        let contentOffsetToBePassed: CGPoint = scrollView.contentOffset
        let zoomScaleToBePassed: CGFloat = scrollView.zoomScale
        
        /// Create a new imageBeingEdited:
        let iBE = imageBeingEdited(iBEtitle: currentTitle, iBEcaption: captionToBePassed, iBEimageCleanUncropped: unblurredImageToBePassed, iBEimageBlurredUncropped: blurredUncroppedToBePassed, iBEimageBlurredCropped: blurredCroppedToBePassed, iBEContentOffset: contentOffsetToBePassed, iBEZoomScale: zoomScaleToBePassed, blursAdded: blursAddedByEditor)
        
        return iBE
    }
    /// create a new Ask using the photo, title, and timestamp
    func createAsk() {
        print("creating ask")
        currentImage = self.sFunc_imageFixOrientation(img:self.imageView.image!) //sets the current image to the one we're seeing and essentially saves the blurring to the currentImage
        currentImage = self.cropImage(currentImage)
        
        // fixes image orientation
        let imageToCreateAskWith: UIImage = self.sFunc_imageFixOrientation(img: currentImage)
        
        let captionToCreateAskWith = createCaption()
        
        
        // the current image needs to be taken care of

        // prepare for segue to the Add Friends view - named CQViewController for some reason)
        
        let vc = SendToFriendsVC()
        vc.modalPresentationStyle = .fullScreen
        
        // Send the ask
        // SEND THE QUESTION TO DATABASE
        let docID = Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION).document().documentID
        
        if let user = Auth.auth().currentUser, let name = user.displayName{
            
            let storageRef = Storage.storage().reference();
            // create an ask here
            // bucket/profiles/username/question_name/imageName_1.jpg
            imageRef_1 = storageRef.child(Constants.PROFILES_FOLDER).child(name).child(docID).child("image_1.jpg")
            
            let imageData: Data? = imageToCreateAskWith.jpegData(compressionQuality: 0.6)
            
            // put guard because imageData is an optional type
            guard let data = imageData else {
                presentDismissAlertOnMainThread(title: "Image Error", message: "Corrupted Image")
                return
            }
            
            
            // upload the file to profileRef
            let uploadTask = imageRef_1.putData(data, metadata: nil){ (metadata,error) in
                // check the meta for error check
                guard metadata != nil else{
                    //error
                    self.presentDismissAlertOnMainThread(title: "Upload Error", message: "An error occured. Try again!")
                    return
                }
                
            } // end of upload task
            
            // start the upload
            uploadTask.resume()
            
            
            // write it to firebase firestore
            
            // create an ASK here
            
            let question = Question(question_name: docID, title_1: currentTitle, imageURL_1: "gs://\(self.imageRef_1.bucket)/\(self.imageRef_1.fullPath)", captionText_1: captionToCreateAskWith.text, yLoc_1: captionToCreateAskWith.yLocation, creator: name, recipients: [String]())
            
            print("ASK \(docID)")
            
            // save to local ASK
            myActiveQuestions.append(ActiveQuestion(question: question))
            saveImageToDiskWith(imageName: "\(docID)_image_1.jpg", image: imageToCreateAskWith,isThumb: true)
            
            // need to increment local and firestore count here
            // locked += 1, toReview += 3
            updateCountOnNewQues()
            
            // move to CQ
            vc.newlyCreatedDocID = docID
            self.present(vc, animated: true, completion: nil)
            
            // save to firestore
            var userList = [String]()
                FirebaseDatabase.Database.database().reference()
                    .child("usernames").observe(.value, with: { snapshot in
                        
                        if let snapDict = snapshot.value as? [String:AnyObject]{
                            
                            for item in snapDict{
                                if item.key != myProfile.username{
                                    userList.append(item.key)
                                }
                                
                            }// end for
                            
                            question.usersNotReviewedBy = userList
                            
                            
                            do{
                            try Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION).document(docID).setData(from: question)
                                clearOutCurrentCompare()
                                
                                userList.removeAll()
                            }catch let error {
                                print("Error writing city to Firestore: \(error)")
                                self.presentDismissAlertOnMainThread(title: "Server Error", message: error.localizedDescription)
                            }
                        } // if let
                        
                    })

        }// end if let user
        
    }
    
    
    @IBAction func helpButtonTapped(_ sender: Any) {
        //        print("help button tapped")
        
        let hidden = helpZoomCropLabel.isHidden || helpAskOrCompareLabel.isHidden || helpPressBlurLabel.isHidden
        
        
        
        if hidden {
            
            if let image = UIImage(named: "question circle green") {
                helpButton.setImage(image, for: .normal)
            }
            
            self.helpPressBlurLabel.fadeInAfter(seconds: 0.0)
            self.helpZoomCropLabel.fadeInAfter(seconds: 0.0)
            self.helpAskOrCompareLabel.fadeInAfter(seconds: 0.0)
            
        } else {
            if let image = UIImage(named: "question circle blue") {
                helpButton.setImage(image, for: .normal)
            }
            
            self.helpPressBlurLabel.fadeOutAfter(seconds: 0.0)
            self.helpZoomCropLabel.fadeOutAfter(seconds: 0.0)
            self.helpAskOrCompareLabel.fadeOutAfter(seconds: 0.0)
            
        }
    }
    
    
    
    
    // continue button
    @IBAction func publishButtonTapped(_ sender: Any) {
        if currentCompare.creationPhase == compareImageState.firstPhotoTaken { //aka there is only one image and it should make an Ask
            actionYes = UIAlertAction(title: "Publish Image with No Title", style: .default) {
                UIAlertAction in
                currentTitle = "(no title)"
                self.createAsk()
            }
            finishEditing(whatToCreate: .ask)
            
        } else { //aka we are for sure making a compare
            actionYes = UIAlertAction(title: "Leave Blank", style: .default) {
                UIAlertAction in
                currentTitle = "(no title)"
                self.createHalfOfCompare()
            }
            finishEditing(whatToCreate: .compare)
            
        }
    }
    // This is similar to publish except it puts some data on hold and then takes the user back to the avCamera to add a second picture.
    @IBAction func compareButtonTapped(_ sender: Any) {
        print("Compare")
        currentCompare.isAsk = false // all this means is that the system now knows we're creating a Compare (with two images). Probably could be named better.
        
        actionYes = UIAlertAction(title: "Leave Blank", style: .default) {
            UIAlertAction in
            currentTitle = "(no title)"
            
            self.createHalfOfCompare()
        }
        finishEditing(whatToCreate: .compare)
    }
    
    
    @IBAction func deleteThumbnailButtonTapped(_ sender: Any) {
        reduceToAskButtonTapped(self)
    }
    
    
    @objc func topImageIndicatorTapped(_ topImageIndicatorTappedGestureRecognizer: UITapGestureRecognizer)
    {
        questionTypeLabel.text = correctQuestionTypeLabel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { // `0.4` is the desired number of seconds.
            self.questionTypeLabel.fadeInAfter(seconds: 0.0)
            self.questionTypeLabel.fadeOutAfter(seconds: 6.0)
        }
    }
    
    @objc func bottomImageIndicatorTapped(_ bottomImageIndicatorTappedGestureRecognizer: UITapGestureRecognizer)
    {
        questionTypeLabel.text = correctQuestionTypeLabel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { // `0.4` is the desired number of seconds.
            self.questionTypeLabel.fadeInAfter(seconds: 0.0)
            self.questionTypeLabel.fadeOutAfter(seconds: 6.0)
        }
    }
    
    func correctQuestionTypeLabel() -> String{
        if currentCompare.creationPhase == .firstPhotoTaken {
            return "SINGLE IMAGE FOR REVIEW"
        } else {
            return "IMAGE 1 vs IMAGE 2"
        }
    }
    
    
    /// This button should be hidden at the onset and unhidden when 2 is hidden. Any time the 2 is unhidden, this should be hidden again.
    @IBAction func reduceToAskButtonTapped(_ sender: Any) {
        print("Reduced")
        //-Store the current iBE to currentCompare.imageBeingEdited1
        currentCompare.imageBeingEdited1 = createImageBeingEdited()
        //-Store nil to currentCompare.ImageBeingEdited2
        currentCompare.imageBeingEdited2 = nil
        //-Change the flag to .firstPhotoTaken
        currentCompare.creationPhase = .firstPhotoTaken
        //-Set isAsk to true
        currentCompare.isAsk = true
        //-Reload all three view methods
        viewWillAppear(false)
        viewDidLoad()
        viewDidAppear(false)
        
        // Without this the title text field just resets because we called ViewDidAppear after switching the flag to .firstPhotoTaken
        if let iBE = currentCompare.imageBeingEdited1 {
            titleTextField.text = iBE.iBEtitle
            if titleTextFieldIsBlank == false {
                // if the title is not blank, then:
                titleTextField.textColor = .label
            } else { //aka if tTF is one of the 3 blank conditions:
                titleTextField.text = enterTitleConstant
                //titleTextField.textColor should already be gray
            }
        }
    }
    
    func createCaption() -> Caption {
        // Create a new caption object from what the user has entered at present
        let captionLocationToSet: CGFloat = captionTextFieldTopConstraint.constant/screenWidth
        
        var newCaption: Caption
        if let captionText = captionTextField.text {
            // recall that if captionText is "", the .exists Bool will return false,
            //   which is functionality that could be replaced by making the caption an optional value.
            newCaption = Caption(text: captionText, yLocation: Double(captionLocationToSet))
        } else { // Occurs if caption text is nil for some reason. This really should never happen.
            newCaption = Caption(text: "", yLocation: Double(captionLocationToSet))
        }
        return newCaption
    }
    
    
    /// Stores the image and caption currently being displayed in the image editor view (EditQuestionVC) to a Compare. This method checks if we are creating the first image of a compare and if it is, creates a new compare and stores the image to it, then segues to the AVCamera to pick the second image.
    /// If the first image is already created, this method stores it as the second image in the compare and segues to the ComparePreviewVC for final publishing approval.
    func createHalfOfCompare() {
        let iBE = createImageBeingEdited()
        
        if currentCompare.creationPhase == .firstPhotoTaken {
            print("create half of compare | first photo taken")
            currentCompare.imageBeingEdited1 = iBE // Stores the imageBeingEdited (iBE) to the first half of the public value known as currentCompare, then goes back to AVCameraViewController to get the second image
            returnToAVCameraViewController()
            
        } else {
            print("create half of compare | second photo taken")
            //everything after this segues to the ComparePreviewViewController
            if currentCompare.creationPhase == .secondPhotoTaken || currentCompare.creationPhase == .reEditingSecondPhoto {
                currentCompare.imageBeingEdited2 = iBE
            } else { //this will only happen if currentCompare.creationPhase == .reEditingFirstPhoto
                currentCompare.imageBeingEdited1 = iBE
            }
            // sets the graphical view controller with the storyboard ID "comparePreviewViewController" to nextVC
            let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "comparePreviewViewController") as! ComparePreviewViewController
            print("moving to compare preview vc")
            // pushes comparePreviewViewController onto the nav stack
            //self.navigationController?.pushViewController(nextVC, animated: true)
            
            nextVC.modalPresentationStyle = .fullScreen
            present(nextVC, animated: true, completion: nil)
            
        }
        
        
    }
    
    /// Depending on creation phase and button that was tapped, creates a new Ask, th first half of a Compare, or the second half of a Compare.
    /// Called when either Publish or Compare button is tapped.
    func finishEditing(whatToCreate: askOrCompare) {
        
        print("Finish Editing")
        /* ********* Explanation *************** *
         if we're in case 1:
         check for title, make an ask
         if we're in case 2:
         check for title
         store the recent changes to the current iBE
         segue to cPVC
         else that means we're in case 3 or 4
         dont check for title
         store the recent changes to the current iBE
         segue to cPVC
         * ************************************** */
        
        //This causes the system to bypass the title checker if the user has come back from ComparePreviewViewController to edit
        if currentCompare.creationPhase == .reEditingFirstPhoto || currentCompare.creationPhase == .reEditingSecondPhoto {
            createHalfOfCompare()
            return
        }
        
        if let title = titleTextField.text {
            if titleTextFieldIsBlank == true {
                let alertController = UIAlertController(title: "You Didn't Enter A Title", message: "It's Recommended but Not Required", preferredStyle: .actionSheet)
                
                // the following code is added to fix crash on iPad : 03 Oct, MM
                if let popoverController = alertController.popoverPresentationController {
                    popoverController.sourceView = self.view
                    popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                }
                
                let actionNo = UIAlertAction(title: "Let Me Enter One", style: .cancel) {
                    UIAlertAction in
                    self.titleTextField.becomeFirstResponder()
                    
                    // if user elects to go back to editing the image, we need to keep the assumption that they still might create an ask so that we don't take away the createCompare button if they navigate back to the avCamera and reload the view without creating anything
                }
                alertController.addAction(actionNo)
                alertController.addAction(actionYes)
                present(alertController, animated: true, completion: nil)
                
            } else {
                currentTitle = title
                if whatToCreate == .ask {
                    print("finish editing | create ask")
                    createAsk()
                } else if whatToCreate == .compare {
                    print("finish editing | create half of compare")
                    createHalfOfCompare()
                }
            }
        }
    }
    
    func returnToAVCameraViewController() {
        print("returnToAVCameraViewController")
        //self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }
    
    func backTwo() {
        guard let navController = self.navigationController else {
            print("error executing backTwo. Could not find the navigationController.")
            return
        }
        let viewControllers: [UIViewController] = navController.viewControllers as [UIViewController]
        self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
    }
    
    @IBAction func menuButtonTapped(_ sender: Any) {
        // clears any photo I've taken, updated from 17th Aug fixes
        clearOutCurrentCompare()
        //        self.backTwo()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // Keep in mind, this only fixes an image if the image knows that it is not upright
    // If I store a sideways image to another image variable, the new image variable believes that it is upright already and this
    //  method will not work on it.
    // The key to making this work is to apply it as early on in the data chain as possible.
    // In other words, as close to the raw image either coming in from the camera or photo libary as possible.
    /// Because of image picker pecularities, often the photo being taken by the camera is actually rotated 90 * x degrees or flipped like a mirror etc. This method corrects that issue and returns a new image that is upright. This method has to be applied very early in the image's "life" to work. It does not work on copies of the original image.
    public func sFunc_imageFixOrientation(img:UIImage) -> UIImage {
        // No-op if the orientation is already correct
        
        if (img.imageOrientation == UIImage.Orientation.up) {
            return img;
        }
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform:CGAffineTransform = CGAffineTransform.identity
        
        if (img.imageOrientation == UIImage.Orientation.down
            || img.imageOrientation == UIImage.Orientation.downMirrored) {
            
            transform = transform.translatedBy(x: img.size.width, y: img.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi)) //seems to be the number of radians we rotate the image
        }
        
        if (img.imageOrientation == UIImage.Orientation.left
            || img.imageOrientation == UIImage.Orientation.leftMirrored) {
            transform = transform.translatedBy(x: img.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
        }
        
        if (img.imageOrientation == UIImage.Orientation.right
            || img.imageOrientation == UIImage.Orientation.rightMirrored) {
            transform = transform.translatedBy(x: 0, y: img.size.height);
            transform = transform.rotated(by: CGFloat(-Double.pi / 2));
        }
        
        if (img.imageOrientation == UIImage.Orientation.upMirrored
            || img.imageOrientation == UIImage.Orientation.downMirrored) {
            transform = transform.translatedBy(x: img.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        }
        
        if (img.imageOrientation == UIImage.Orientation.leftMirrored
            || img.imageOrientation == UIImage.Orientation.rightMirrored) {
            transform = transform.translatedBy(x: img.size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1);
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx:CGContext = CGContext(data: nil, width: Int(img.size.width), height: Int(img.size.height),
                                      bitsPerComponent: img.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                      space: img.cgImage!.colorSpace!,
                                      bitmapInfo: img.cgImage!.bitmapInfo.rawValue)!
        
        ctx.concatenate(transform)
        
        if (img.imageOrientation == UIImage.Orientation.left
            || img.imageOrientation == UIImage.Orientation.leftMirrored
            || img.imageOrientation == UIImage.Orientation.right
            || img.imageOrientation == UIImage.Orientation.rightMirrored
        ) {
            //I'm not sure why there is even an if statement since they perform the same operation in both cases...
            ctx.draw(img.cgImage!, in: CGRect(x:0,y:0,width:img.size.height,height:img.size.width))
            
        } else {
            ctx.draw(img.cgImage!, in: CGRect(x:0,y:0,width:img.size.width,height:img.size.height))
        }
        
        // And now we just create a new UIImage from the drawing context
        let cgimg:CGImage = ctx.makeImage()!
        let imgEnd:UIImage = UIImage(cgImage: cgimg)
        
        return imgEnd
        
    }
    
    /// This is an alternate, more elegant method for fixing image rotation that I am not currently using. It still runs into the original problem of needing to have the correct metadata.
    /// Also, I'm not really sure what UIGraphicsGetImageFromCurrentImageContext() is doing.
    func fixOrientation(img:UIImage) -> UIImage {
        
        if (img.imageOrientation == UIImage.Orientation.up) {
            return img;
        }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale);
        let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        img.draw(in: rect)
        
        //force unwrapped - may need to fix:
        let normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        return normalizedImage;
    }
    
    deinit {
        print("EditQuestionVC instance deinitialized")
    }
}
